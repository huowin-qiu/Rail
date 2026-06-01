#!/bin/sh

# 1. 替换配置文件中的 UUID 和 TUIC 密码
sed -i "s/PASTE_YOUR_UUID_HERE/$UUID/g" config.json
sed -i "s/PASTE_YOUR_TUIC_PASS_HERE/${TUIC_PASS:-my_tuic_password}/g" config.json

# 2. 准备订阅链接数据 (在后台提前生成好)
TUNNEL_DOMAIN="${TUNNEL_DOMAIN:-你的Tunnel域名}"
TUIC_HOST="${TUIC_HOST:-你的服务器公网IP_或域名}"
NODE_NAME="${NODE_NAME:-Railway-Singbox}"

# 对节点名称做简单的 URL 编码兼容空格和中文
ENCODED_VLESS_NAME=$(echo -n "${NODE_NAME}-VLESS" | od -An -tx1 | tr ' ' % | tr -d '\n')
ENCODED_TUIC_NAME=$(echo -n "${NODE_NAME}-TUIC" | od -An -tx1 | tr ' ' % | tr -d '\n')

# 拼接节点
LINK_VLESS="vless://${UUID}@${TUNNEL_DOMAIN}:443?encryption=none&security=tls&sni=${TUNNEL_DOMAIN}&insecure=0&allowInsecure=0&type=ws&host=${TUNNEL_DOMAIN}&path=%2Fvless#${ENCODED_VLESS_NAME}"
LINK_TUIC="tuic://${UUID}:${TUIC_PASS:-my_tuic_password}@${TUIC_HOST}:10086?congestion_control=bbr&udp_relay_mode=native&alpn=h3&sni=google.com&allow_insecure=1#${ENCODED_TUIC_NAME}"

# 合并并做 Base64 编码
ALL_LINKS=$(printf "%s\n%s" "$LINK_VLESS" "$LINK_TUIC")
echo -n "$ALL_LINKS" | base64 | tr -d '\n' > /tmp/sub.txt

# 3. 启动后台轻量级响应服务，监听 8888 端口提供订阅
(while true; do 
    cl_len=$(wc -c </tmp/sub.txt)
    printf "HTTP/1.1 200 OK\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: %s\r\nConnection: close\r\n\r\n%s" "$cl_len" "$(cat /tmp/sub.txt)" | nc -lk -p 8888
done) &

# 4. 后台运行 sing-box
sing-box run -c config.json &

# 5. 运行 Cloudflare Tunnel (保持原作者逻辑)
cloudflared tunnel --no-autoupdate run --token $ARGO_TOKEN
