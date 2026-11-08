mkdir -p cftunnel-relay && cd cftunnel-relay
curl -fsSLO https://raw.githubusercontent.com/qingchencloud/cftunnel/main/docker/relay-server/docker-compose.yml
curl -fsSLO https://raw.githubusercontent.com/qingchencloud/cftunnel/main/docker/relay-server/frps.toml.example
cp frps.toml.example frps.toml
# 编辑 frps.toml，设置你的 auth.token
docker compose up -d
