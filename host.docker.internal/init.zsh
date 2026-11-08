mkdir -p cftunnel-relay && cd cftunnel-relay
curl -fsSLO https://raw.githubusercontent.com/qingchencloud/cftunnel/main/docker/relay-server/docker-compose.yml
curl -fsSLO https://raw.githubusercontent.com/qingchencloud/cftunnel/main/docker/relay-server/frps.toml.example
cp frps.toml.example frps.toml
# 编辑 frps.toml，设置你的 auth.token
docker compose up -d
cftunnel init                                          # 配置 CF API Token
cftunnel create my-tunnel                              # 创建隧道
cftunnel add clawapp 3210 --domain chat.trycloudflare.com    # 添加路由（自动创建 DNS）
cftunnel up                                            # 启动
cftunnel install                                       # 注册开机自启
