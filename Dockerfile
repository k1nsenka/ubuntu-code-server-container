FROM --platform=linux/amd64 ubuntu:22.04

# 基本的なパッケージのインストール
RUN apt-get update && apt-get install -y \
    sudo \
    wget \
    vim \
    git \
    build-essential \
    python3 \
    python3-pip \
    python3-dev \
    python3-venv \
    curl \
    gpg \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# タイムゾーンを設定
ENV TZ=Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Pythonのエイリアス設定
RUN ln -sf /usr/bin/python3 /usr/bin/python && \
    ln -sf /usr/bin/pip3 /usr/bin/pip

# 必要なPythonパッケージのインストール
RUN pip install --upgrade pip && \
    pip install \
    numpy \
    pandas \
    matplotlib \
    scikit-learn \
    jupyter \
    jupyterlab \
    torch \
    torchvision \
    torchaudio

# code-serverのインストール
RUN curl -fsSL https://code-server.dev/install.sh | sh

# code-serverの設定ディレクトリ作成
RUN mkdir -p /root/.config/code-server
COPY code-server-config.yaml /root/.config/code-server/config.yaml

# 作業ディレクトリの作成
WORKDIR /workspace

# コンテナ起動時のコマンド
CMD ["/bin/bash"]