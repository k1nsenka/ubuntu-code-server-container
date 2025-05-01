# M1 Mac上で動作するx86機械学習・開発環境

本番環境(x86)との互換性を保ちながらM1 Mac上で開発できる機械学習環境のDockerセットアップです。Rosetta 2エミュレーションを活用したx86 Dockerコンテナを使用しています。iPadからのリモート開発も可能です。

## 特徴

- **x86互換性**: 本番環境と同じx86アーキテクチャで動作
- **PyTorch対応**: x86版PyTorch 2.5.1がプリインストール済み
- **Jupyter Lab統合**: データ分析作業用のJupyter Lab環境
- **VS Code統合**: iPadのブラウザからコーディングできるCode-Server環境
- **簡単セットアップ**: スクリプト一発で環境構築
- **自動管理**: ファイル変更検知による自動リビルド機能
- **永続データ**: 再起動時も拡張機能やライブラリを保持
- **自動バックアップ**: 定期的なバックアップによるデータ保護
- **環境復元**: 再起動時に前回のバックアップから自動復元

## セットアップ手順

### 初回セットアップ

```bash
# リポジトリをクローン
git clone https://github.com/あなたのユーザー名/リポジトリ名.git
cd リポジトリ名

# 実行権限を付与
chmod +x *.sh

# 必要なディレクトリを作成
mkdir -p docker-data backups

# code-server設定ファイルを作成
cat > code-server-config.yaml << EOL
bind-addr: 0.0.0.0:8080
auth: password
password: password
cert: false
EOL

# コンテナを起動
./start-container.sh
```

### 自動モードの使用

対話的な入力をスキップしてデフォルト設定で起動する場合、`-auto`または`--auto`オプションを使用できます：

```bash
./start-container.sh --auto
```

自動モードでは以下のデフォルト設定が適用されます：

- 6時間ごとの自動バックアップ（30日間保持）
- JupyterLabとCode-Serverの両方が自動起動
- 前回のバックアップからの自動復元
- すべてのユーザー入力をスキップ

これは、Launch Agent経由での自動起動や、スクリプトでの呼び出しに最適です。例えば、Mac起動時に自動的に環境を立ち上げる場合は以下のようにLaunch Agentを設定できます：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.yourname.ml-env</string>
    <key>RunAtLoad</key>
    <true/>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>cd /path/to/repo && ./start-container.sh --auto</string>
    </array>
</dict>
</plist>
```

### ファイルと役割

| ファイル名 | 役割 | 実行方法 |
|------------|------|---------|
| `docker-compose.yml` | Docker環境の定義ファイル | - |
| `Dockerfile` | コンテナのビルド定義 | - |
| `code-server-config.yaml` | Code-Serverの設定ファイル | - |
| `start-container.sh` | メインの起動スクリプト | `./start-container.sh` |
| `start-jupyter.sh` | Jupyter Lab起動スクリプト | `./start-jupyter.sh` |
| `start-code-server.sh` | Code-Server起動スクリプト | `./start-code-server.sh` |
| `backup-restore.sh` | バックアップと復元用スクリプト | `./backup-restore.sh [backup|restore]` |
| `schedule-backup.sh` | 定期バックアップのスケジューラ | `./schedule-backup.sh [hours] [days]` |
| `cleanup-old-backups.sh` | 古いバックアップを削除するスクリプト | `./cleanup-old-backups.sh [days]` |

## iPadからアクセスする方法

1. MacとiPadが同じWiFiネットワークに接続されていることを確認
2. Macのプライベートネットワークアドレスを確認（システム環境設定→ネットワーク）
3. iPadのSafari/Chromeブラウザで以下のURLにアクセス:
   - JupyterLab: `http://[Macのアドレス]:8888`
   - Code-Server: `http://[Macのアドレス]:8080`
   - 初期パスワード: `password`

## 自動バックアップと復元機能

突然のシャットダウンや電源喪失からデータを保護するため、自動バックアップ機能があります：

- **スケジュール設定**: コンテナ起動時に自動バックアップの間隔を設定できます
- **デフォルト設定**: 6時間ごとのバックアップ、30日間保持
- **自動復元**: コンテナ再起動時に最新のバックアップから環境を復元
- **手動での調整**: 
```bash
# カスタム間隔と保持期間の設定（例：12時間ごと、7日間保持）
./schedule-backup.sh 12 7

# 自動バックアップを無効化
./schedule-backup.sh 0
```

## 手動バックアップと復元

必要に応じて手動でバックアップと復元を行うことも可能です：

```bash
# 現在の環境をバックアップ
./backup-restore.sh backup

# バックアップから環境を復元
./backup-restore.sh restore ./backups/ml_env_backup_20250410_120000.tar.gz
```

バックアップには以下の情報が含まれます：
- インストール済みのPythonパッケージリスト
- インストール済みのVS Code拡張機能リスト
- コマンド履歴

## データの永続性

以下のデータは Docker ボリュームによって永続化されます：

- code-server 拡張機能と設定
- VSCode ユーザー設定
- pip キャッシュ
- Python ライブラリ

これにより、コンテナを再起動または再作成しても、インストールした拡張機能やライブラリが保持されます。また、バックアップと復元機能により、万が一データが破損した場合でも前の状態に戻すことができます。

## よくある操作

### 環境の起動/再起動と自動復元

```bash
# 環境を起動/再起動（最新バックアップから復元するか確認）
./start-container.sh

# 環境を起動/再起動（自動的に最新バックアップから復元）
./start-container.sh --auto
```

### Jupyter Labだけを起動

```bash
./start-jupyter.sh
```

### Code-Serverだけを起動

```bash
./start-code-server.sh
```

### 古いバックアップの削除

```bash
# 14日より古いバックアップを削除
./cleanup-old-backups.sh 14
```

## 前提条件

- M1/M2/M3 Mac（Apple Silicon）
- Docker Desktop for Mac
- Docker DesktopでRosetta 2エミュレーションが有効化されていること

## ディレクトリ構造

```
.
├── Dockerfile                # x86環境の定義
├── code-server-config.yaml   # Code-Serverの設定ファイル
├── .docker_files_hash        # Dockerfile差分検査用のハッシュファイル
├── docker-compose.yml        # Docker Compose設定
├── start-container.sh        # 環境起動スクリプト
├── start-jupyter.sh          # Jupyter Lab起動スクリプト
├── start-code-server.sh      # Code-Server起動スクリプト
├── backup-restore.sh         # 環境バックアップ/復元スクリプト
├── schedule-backup.sh        # 自動バックアップスケジュール設定
├── cleanup-old-backups.sh    # 古いバックアップの削除
├── backups/                  # バックアップファイル保存ディレクトリ
└── docker-data/              # データ共有ディレクトリ
```

## パスワード変更方法

Code-Serverのパスワードを変更するには、`code-server-config.yaml`ファイルを編集してください：

```yaml
bind-addr: 0.0.0.0:8080
auth: password
password: 新しいパスワード
cert: false
```

## トラブルシューティング

### コンテナが起動しない場合

```bash
# Dockerログを確認
/usr/local/bin/docker-compose logs

# コンテナを強制的に再ビルド
/usr/local/bin/docker-compose down
/usr/local/bin/docker-compose build --no-cache
/usr/local/bin/docker-compose up -d
```

### Code-Serverにアクセスできない場合

```bash
# Code-Serverの状態を確認
/usr/local/bin/docker-compose exec ml_env ps aux | grep code-server

# 手動で再起動
/usr/local/bin/docker-compose exec ml_env pkill code-server
./start-code-server.sh
```

### docker-composeコマンドでエラーが出る場合

スクリプト内では`/usr/local/bin/docker-compose`のパスを使用しています。異なるパスにインストールされている場合は、各スクリプト内のDOCKER_COMPOSE変数を修正してください：

```bash
# docker-composeの絶対パスを指定
DOCKER_COMPOSE="/正しいパス/docker-compose"
```

### バックアップからの復元に失敗する場合

```bash
# バックアップファイルの内容を確認
tar -tvf ./backups/ml_env_backup_YYYYMMDD_HHMMSS.tar.gz

# 手動で復元を試みる
./backup-restore.sh restore ./backups/ml_env_backup_YYYYMMDD_HHMMSS.tar.gz
```

## ライセンス
MITライセンス

## 貢献

問題報告や機能リクエストは、GitHubのIssuesで受け付けています。Pull Requestも歓迎します。