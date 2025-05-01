#!/bin/bash

# 古いバックアップファイルを削除するスクリプト
# このスクリプトは古いバックアップを自動的に削除してディスク容量を節約します

# エラーが発生した時点でスクリプトを終了
set -e

# スクリプトの実行ディレクトリに移動
cd "$(dirname "$0")"

# docker-composeの絶対パスを指定
DOCKER_COMPOSE="/usr/local/bin/docker-compose"

# バックアップディレクトリ
BACKUP_DIR="./backups"

# デフォルトの保持日数
DEFAULT_DAYS=30

# スクリプトの使用方法
usage() {
    echo "Usage: $0 [days]"
    echo "  days  保持する日数 (デフォルト: ${DEFAULT_DAYS}日)"
    echo ""
    echo "Examples:"
    echo "  $0        # ${DEFAULT_DAYS}日より古いバックアップを削除"
    echo "  $0 7      # 7日より古いバックアップを削除"
}

# 古いバックアップの削除
cleanup_old_backups() {
    local days=$1
    
    # バックアップディレクトリの存在確認
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "バックアップディレクトリが存在しません: $BACKUP_DIR"
        return 1
    fi
    
    echo "${days}日より古いバックアップファイルを削除します..."
    
    # 古いバックアップファイルの数を確認
    local old_files=$(find "$BACKUP_DIR" -name "ml_env_backup_*.tar.gz" -type f -mtime +${days} | wc -l)
    
    if [ $old_files -eq 0 ]; then
        echo "削除対象のバックアップファイルはありません。"
        return 0
    fi
    
    echo "削除対象のバックアップファイル数: $old_files"
    
    # 古いバックアップファイルを削除
    find "$BACKUP_DIR" -name "ml_env_backup_*.tar.gz" -type f -mtime +${days} -delete
    
    # 古いログファイルも削除
    find "$BACKUP_DIR" -name "backup_log_*.txt" -type f -mtime +${days} -delete
    
    echo "古いバックアップファイルの削除が完了しました。"
    
    # 残っているバックアップの数を表示
    local remaining=$(find "$BACKUP_DIR" -name "ml_env_backup_*.tar.gz" -type f | wc -l)
    echo "残りのバックアップファイル数: $remaining"
}

# バックアップディレクトリの確認
mkdir -p "$BACKUP_DIR"

# 引数の処理
if [ $# -eq 0 ]; then
    # 引数がなければデフォルト値を使用
    cleanup_old_backups $DEFAULT_DAYS
elif [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
    exit 0
else
    # 引数が数値かチェック
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        cleanup_old_backups $1
    else
        echo "エラー: 保持日数は数値で指定してください"
        usage
        exit 1
    fi
fi