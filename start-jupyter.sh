#!/bin/bash

# エラーが発生した時点でスクリプトを終了
set -e

# スクリプトの実行ディレクトリに移動
cd "$(dirname "$0")"

# docker-composeの絶対パスを指定
DOCKER_COMPOSE="/usr/local/bin/docker-compose"

# コンテナ名
CONTAINER_NAME="ml_env"

# JupyterLabの起動
echo "Starting JupyterLab..."
$DOCKER_COMPOSE exec -d $CONTAINER_NAME bash -c "jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token=''"

echo "JupyterLab started. Access at http://localhost:8888"
echo "Press Ctrl+C to stop this script, but JupyterLab will continue running in the container."
echo "To close JupyterLab, restart the container or shut it down."

# 任意のキー入力を待つ
read -p "Press any key to continue..." -n1 -s
echo