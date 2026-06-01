FROM alpine:latest

# 设置版本变量，方便以后维护
ARG SING_BOX_VERSION=1.10.1
ARG CLOUDFLARED_VERSION=latest

# 安装必要的下载工具、基础库以及订阅所需的 netcat、coreutils
RUN apk add --no-cache ca-certificates bash wget tar netcat-openbsd coreutils

WORKDIR /app

# 1. 下载并安装 sing-box
RUN wget https://github.com/SagerNet/sing-box/releases/download/v${SING_BOX_VERSION}/sing-box-${SING_BOX_VERSION}-linux-amd64.tar.gz && \
    tar -zxvf sing-box-${SING_BOX_VERSION}-linux-amd64.tar.gz && \
    mv sing-box-${SING_BOX_VERSION}-linux-amd64/sing-box /usr/local/bin/sing-box && \
    rm -rf sing-box-${SING_BOX_VERSION}-linux-amd64*

# 2. 下载并安装 cloudflared
RUN wget -O /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/${CLOUDFLARED_VERSION}/download/cloudflared-linux-amd64

# 3. 复制文件
COPY . .

# 4. 赋予执行权限
RUN chmod +x /usr/local/bin/sing-box && \
    chmod +x /usr/local/bin/cloudflared && \
    chmod +x start.sh

# 声明端口：8080(原VLESS本地端口), 8888(订阅端口), 10086/udp(TUIC直连端口)
EXPOSE 8080
EXPOSE 8888
EXPOSE 10086/udp

# 启动脚本
CMD ["./start.sh"]
