#!/bin/bash

# エラーが発生した時点でスクリプトを終了
set -e

# スクリプトの実行ディレクトリに移動
cd "$(dirname "$0")"

# docker-composeの絶対パスを指定
DOCKER_COMPOSE="/usr/local/bin/docker-compose"

# コンテナ名
CONTAINER_NAME="ml_env"

# Code-Serverの起動
echo "Starting Code-Server..."
$DOCKER_COMPOSE exec -d $CONTAINER_NAME bash -c "code-server --bind-addr 0.0.0.0:8080 --auth password --password password /workspace"

echo "Code-Server started. Access at http://localhost:8080"
echo "Default password: password"
echo "You can change the password in code-server-config.yaml"
echo ""
echo "Press Ctrl+C to stop this script, but Code-Server will continue running in the container."
echo "To close Code-Server, restart the container or shut it down."

# 任意のキー入力を待つ
read -p "Press any key to continue..." -n1 -s
echo