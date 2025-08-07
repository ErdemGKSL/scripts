#!/usr/bin/env bash
set -e

CONFIG_PATH="/usr/local/etc/redis/redis.conf"
mkdir -p "$(dirname "$CONFIG_PATH")"

cat > "$CONFIG_PATH" <<'EOF'
########################################
# REDIS CONF — GÜVENLİ VE KARARLI
########################################

# Ağ yapılandırması
bind 0.0.0.0
# protected-mode yes
port 6379
timeout 0
tcp-keepalive 300

# Güvenlik
requirepass strongpassword3456
rename-command FLUSHALL ""
rename-command FLUSHDB ""
# rename-command CONFIG ""
# rename-command DEBUG ""
# rename-command SHUTDOWN ""
rename-command SLAVEOF ""
rename-command SAVE ""
rename-command BGSAVE ""

# Bellek yönetimi
# maxmemory 512mb
# maxmemory-policy allkeys-lru

# Kalıcılık
save 900 1
save 300 10
save 60 10000
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /data

# AOF (Append Only File)
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# Performans
lazyfree-lazy-eviction yes
lazyfree-lazy-expire yes
lazyfree-lazy-server-del yes
repl-disable-tcp-nodelay no

# Gelişmiş
daemonize no
supervised no
loglevel notice
logfile ""

# Cluster / Sentinel yok
cluster-enabled no

# Modules
loadmodule /opt/redis-stack/lib/rejson.so
loadmodule /opt/redis-stack/lib/redisearch.so
EOF

if ! command -v docker >/dev/null 2>&1; then
  if command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --noconfirm docker
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y docker
  elif command -v apt >/dev/null 2>&1; then
    sudo apt update && sudo apt install -y docker.io
  else
    exit 1
  fi
fi

sudo docker run -d \
  --name redis-stack-server \
  -p 6379:6379 \
  -v /usr/local/etc/redis/redis.conf:/redis.conf \
  -v redis-data:/data \
  --restart unless-stopped \
  redis/redis-stack-server:latest \
  redis-server /redis.conf
