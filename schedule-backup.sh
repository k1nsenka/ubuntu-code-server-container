#!/bin/bash

# 定期的なバックアップをスケジュールするスクリプト
# このスクリプトは crontab を使用して定期的なバックアップを設定します

# エラーが発生した時点でスクリプトを終了
set -e

# スクリプトの実行ディレクトリに移動
cd "$(dirname "$0")"

# docker-composeの絶対パスを指定
DOCKER_COMPOSE="/usr/local/bin/docker-compose"

# スクリプトへの絶対パス
BACKUP_SCRIPT="$(pwd)/backup-restore.sh"
CLEANUP_SCRIPT="$(pwd)/cleanup-old-backups.sh"

# デフォルトバックアップ頻度 (時間単位)
DEFAULT_BACKUP_HOURS=6

# デフォルトの保持日数
DEFAULT_RETENTION_DAYS=30

# スクリプトの使用方法
usage() {
    echo "Usage: $0 [hours] [retention_days]"
    echo "  hours          バックアップ間隔を時間単位で指定 (デフォルト: ${DEFAULT_BACKUP_HOURS}時間)"
    echo "  retention_days バックアップを保持する日数 (デフォルト: ${DEFAULT_RETENTION_DAYS}日)"
    echo ""
    echo "Examples:"
    echo "  $0              # ${DEFAULT_BACKUP_HOURS}時間ごとにバックアップ、${DEFAULT_RETENTION_DAYS}日間保持"
    echo "  $0 12           # 12時間ごとにバックアップ、${DEFAULT_RETENTION_DAYS}日間保持"
    echo "  $0 24 7         # 1日に1回バックアップ、7日間保持"
    echo "  $0 0            # 自動バックアップをキャンセル"
}

# バックアップスケジュールの設定
setup_backup_schedule() {
    local hours=$1
    local retention_days=$2
    
    # 現在のcrontabを取得
    local current_crontab=$(crontab -l 2>/dev/null || echo "")
    
    # 既存のバックアップスケジュールを削除
    local filtered_crontab=$(echo "$current_crontab" | grep -v "$BACKUP_SCRIPT\|$CLEANUP_SCRIPT")
    
    if [ "$hours" -gt 0 ]; then
        # 新しいバックアップスケジュールを追加
        local new_crontab="${filtered_crontab}"$'\n'
        
        # バックアップの実行スケジュール
        new_crontab="${new_crontab}0 */${hours} * * * \"$BACKUP_SCRIPT\" backup > \"$(pwd)/backups/backup_log_\$(date +\%Y\%m\%d_\%H\%M\%S).txt\" 2>&1"
        
        # 古いバックアップの削除スケジュール (毎日午前3時に実行)
        new_crontab="${new_crontab}"$'\n'"0 3 * * * \"$CLEANUP_SCRIPT\" ${retention_days} >> \"$(pwd)/backups/cleanup_log_\$(date +\%Y\%m\%d).txt\" 2>&1"
        
        echo "バックアップを${hours}時間ごとに実行し、${retention_days}日間保持するようにスケジュールしました"
    else
        # スケジュールを削除
        local new_crontab="${filtered_crontab}"
        echo "自動バックアップのスケジュールをキャンセルしました"
    fi
    
    # 更新したcrontabを設定
    echo "$new_crontab" | crontab -
    
    # スケジュールされたタスクを表示
    echo "現在のバックアップスケジュール:"
    crontab -l | grep -v "^#" | grep .
}

# バックアップディレクトリの作成
mkdir -p "$(dirname "$0")/backups"

# 実行権限の確認
if [ ! -x "$BACKUP_SCRIPT" ]; then
    echo "バックアップスクリプトに実行権限を付与します..."
    chmod +x "$BACKUP_SCRIPT"
fi

if [ ! -x "$CLEANUP_SCRIPT" ]; then
    echo "クリーンアップスクリプトに実行権限を付与します..."
    chmod +x "$CLEANUP_SCRIPT"
fi

# 引数の処理
backup_hours=$DEFAULT_BACKUP_HOURS
retention_days=$DEFAULT_RETENTION_DAYS

if [ $# -ge 1 ]; then
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        usage
        exit 0
    elif [[ "$1" =~ ^[0-9]+$ ]]; then
        backup_hours=$1
    else
        echo "エラー: バックアップ間隔は数値で指定してください"
        usage
        exit 1
    fi
fi

if [ $# -ge 2 ]; then
    if [[ "$2" =~ ^[0-9]+$ ]]; then
        retention_days=$2
    else
        echo "エラー: 保持日数は数値で指定してください"
        usage
        exit 1
    fi
fi

# バックアップスケジュールの設定
setup_backup_schedule $backup_hours $retention_days

# 即時バックアップを実行
if [ "$backup_hours" != "0" ]; then
    echo "初回バックアップを実行しています..."
    "$BACKUP_SCRIPT" backup
    echo "初回バックアップが完了しました"
fi