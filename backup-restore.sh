#!/bin/bash

# 環境設定のバックアップと復元を行うスクリプト
# このスクリプトはコンテナ内の拡張機能やライブラリの状態を保存・復元します

# エラーが発生した時点でスクリプトを終了
set -e

# スクリプトの実行ディレクトリに移動
cd "$(dirname "$0")"

# docker-composeの絶対パスを指定
DOCKER_COMPOSE="/usr/local/bin/docker-compose"

# バックアップディレクトリ
BACKUP_DIR="./backups"
mkdir -p "$BACKUP_DIR"

# コンテナ名
CONTAINER_NAME="ml_env"

# バックアップファイル名（日付入り）
BACKUP_TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/ml_env_backup_${BACKUP_TIMESTAMP}.tar.gz"

# バックアップの作成
backup() {
    echo "Creating backup of container environment..."
    
    # コンテナ起動チェック
    if ! $DOCKER_COMPOSE ps | grep -q "Up" | grep "$CONTAINER_NAME"; then
        echo "Container is not running. Starting container..."
        $DOCKER_COMPOSE start
        sleep 5
    fi
    
    # インストール済みPythonパッケージのリストを取得
    echo "Listing installed Python packages..."
    $DOCKER_COMPOSE exec "$CONTAINER_NAME" pip freeze > "${BACKUP_DIR}/requirements_${BACKUP_TIMESTAMP}.txt"
    
    # VSCode拡張機能のリストを取得
    echo "Listing installed VS Code extensions..."
    $DOCKER_COMPOSE exec "$CONTAINER_NAME" code-server --list-extensions > "${BACKUP_DIR}/extensions_${BACKUP_TIMESTAMP}.txt"
    
    # バッシュ履歴のバックアップ
    echo "Backing up bash history..."
    $DOCKER_COMPOSE exec "$CONTAINER_NAME" bash -c "cat ~/.bash_history 2>/dev/null || echo ''" > "${BACKUP_DIR}/bash_history_${BACKUP_TIMESTAMP}.txt"
    
    # Dockerボリュームのバックアップは通常必要ありませんが、
    # 必要な場合は以下のコメントを解除

    # echo "Creating volume backups (this may take some time)..."
    # docker run --rm -v ml-arm64_code_server_data:/source -v $(pwd)/${BACKUP_DIR}:/backup alpine tar -czf /backup/code_server_data_${BACKUP_TIMESTAMP}.tar.gz -C /source .
    # docker run --rm -v ml-arm64_vscode_user_data:/source -v $(pwd)/${BACKUP_DIR}:/backup alpine tar -czf /backup/vscode_user_data_${BACKUP_TIMESTAMP}.tar.gz -C /source .
    
    # バックアップファイルを一つのアーカイブにまとめる
    echo "Creating final backup archive..."
    tar -czf "$BACKUP_FILE" -C "$BACKUP_DIR" "requirements_${BACKUP_TIMESTAMP}.txt" "extensions_${BACKUP_TIMESTAMP}.txt" "bash_history_${BACKUP_TIMESTAMP}.txt"
    
    echo "Backup completed: $BACKUP_FILE"
    echo "To restore this backup later, run: $0 restore $BACKUP_FILE"
}

# バックアップからの復元
restore() {
    local backup_file=$1
    
    if [ -z "$backup_file" ]; then
        echo "Error: No backup file specified."
        echo "Usage: $0 restore <backup_file>"
        exit 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        echo "Error: Backup file not found: $backup_file"
        exit 1
    fi
    
    echo "Restoring from backup: $backup_file"
    
    # 一時ディレクトリの作成
    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT
    
    # バックアップファイルの展開
    tar -xzf "$backup_file" -C "$temp_dir"
    
    # コンテナ起動チェック
    if ! $DOCKER_COMPOSE ps | grep -q "Up" | grep "$CONTAINER_NAME"; then
        echo "Container is not running. Starting container..."
        $DOCKER_COMPOSE start
        sleep 5
    fi
    
    # コンテナ内にファイルをコピーする一時ディレクトリを作成
    $DOCKER_COMPOSE exec "$CONTAINER_NAME" mkdir -p /tmp/restore
    
    # 要件ファイルが存在する場合、コンテナにコピーしてからPythonパッケージをインストール
    local req_file=$(find "$temp_dir" -name "requirements_*.txt" | sort | tail -n 1)
    if [ -n "$req_file" ]; then
        echo "Restoring Python packages from $(basename "$req_file")..."
        # ファイルをコンテナにコピー
        docker cp "$req_file" "$CONTAINER_NAME:/tmp/restore/requirements.txt"
        # コンテナ内でインストール
        $DOCKER_COMPOSE exec "$CONTAINER_NAME" pip install -r /tmp/restore/requirements.txt
    fi
    
    # 拡張機能リストが存在する場合、VSCode拡張機能をインストール
    local ext_file=$(find "$temp_dir" -name "extensions_*.txt" | sort | tail -n 1)
    if [ -n "$ext_file" ]; then
        echo "Restoring VS Code extensions..."
        # ファイルをコンテナにコピー
        docker cp "$ext_file" "$CONTAINER_NAME:/tmp/restore/extensions.txt"
        # 各拡張機能をインストール
        $DOCKER_COMPOSE exec "$CONTAINER_NAME" bash -c "while read extension; do [ -z \"\$extension\" ] && continue; echo \"Installing extension: \$extension\"; code-server --install-extension \"\$extension\"; done < /tmp/restore/extensions.txt"
    fi
    
    # バッシュ履歴の復元
    local hist_file=$(find "$temp_dir" -name "bash_history_*.txt" | sort | tail -n 1)
    if [ -n "$hist_file" ]; then
        echo "Restoring bash history..."
        docker cp "$hist_file" "$CONTAINER_NAME:/tmp/restore/bash_history.txt"
        $DOCKER_COMPOSE exec "$CONTAINER_NAME" bash -c "cat /tmp/restore/bash_history.txt > ~/.bash_history"
    fi
    
    # 一時ディレクトリのクリーンアップ
    $DOCKER_COMPOSE exec "$CONTAINER_NAME" rm -rf /tmp/restore
    
    echo "Restoration completed."
}

# スクリプト使用法の表示
usage() {
    echo "Usage: $0 [backup|restore <backup_file>]"
    echo ""
    echo "Commands:"
    echo "  backup                Create a new backup of the container environment"
    echo "  restore <backup_file> Restore container environment from a backup file"
    echo ""
    echo "Examples:"
    echo "  $0 backup                     # Create a new backup"
    echo "  $0 restore ./backups/ml_env_backup_20250410_120000.tar.gz  # Restore from backup"
}

# メイン関数
main() {
    case "$1" in
        backup)
            backup
            ;;
        restore)
            restore "$2"
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

# スクリプトの実行
if [ $# -eq 0 ]; then
    usage
    exit 1
fi

main "$@"