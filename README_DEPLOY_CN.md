# aria-telegram-mirror-bot 部署指南

## 一、提前准备（在本地完成）

### 1. 创建 Telegram Bot
1. Telegram 找 [@BotFather](https://t.me/BotFather) → `/newbot`
2. 记录 **Bot Token**：`123456789:ABCdefGHI...`

### 2. 获取你的 Telegram 用户 ID
- 向 [@userinfobot](https://t.me/userinfobot) 发消息，获取数字 ID

### 3. 创建 Google Service Account
1. 打开 [Google Cloud Console](https://console.cloud.google.com/)
2. 创建项目 → 启用 [Drive API](https://console.cloud.google.com/apis/library/drive.googleapis.com)
3. **IAM 与管理** → **服务账号** → **创建服务账号**
4. 点击账号 → **密钥** → **添加密钥** → **JSON**
5. 下载 JSON 文件，待会上传到服务器

### 4. 创建 Google Drive 文件夹
1. [Google Drive](https://drive.google.com/) 新建文件夹
2. 右键 → **共享** → 添加 Service Account 邮箱（`xxx@xxx.iam.gserviceaccount.com`），设为**编辑者**
3. 打开文件夹，从 URL 复制 ID：
   ```
   https://drive.google.com/drive/folders/1A2B3C4D5E6F
                                          └── 这就是 ID
   ```

---

## 二、服务器部署

### 1. 安装 Docker
```bash
curl -fsSL https://get.docker.com | sh
```

### 2. 创建目录结构
```bash
mkdir -p ~/mirror-bot/downloads
cd ~/mirror-bot
```

### 3. 上传 Service Account 密钥
将之前下载的 JSON 上传到服务器，保存为：
```bash
~/mirror-bot/service_account.json
```

### 4. 创建配置文件

**aria.sh**：
```bash
cat > ~/mirror-bot/aria.sh << 'EOF'
#!/bin/bash
ARIA_RPC_SECRET="your_password_here"
MAX_CONCURRENT_DOWNLOADS=3
RPC_LISTEN_PORT=8210

aria2c --enable-rpc --rpc-listen-all=false --rpc-listen-port $RPC_LISTEN_PORT \
  --max-concurrent-downloads=$MAX_CONCURRENT_DOWNLOADS \
  --max-connection-per-server=10 --rpc-max-request-size=1024M \
  --seed-time=0.01 --min-split-size=10M --follow-torrent=mem \
  --split=10 --rpc-secret=$ARIA_RPC_SECRET \
  --max-overall-upload-limit=1 --daemon=true
echo "Aria2c daemon started"
EOF
chmod +x ~/mirror-bot/aria.sh
```

**.constants.js**：
```bash
cat > ~/mirror-bot/.constants.js << 'EOF'
module.exports = Object.freeze({
  TOKEN: '你的Bot_Token',
  ARIA_SECRET: 'your_password_here',  // 与 aria.sh 一致
  ARIA_DOWNLOAD_LOCATION: '/mirrorbot/downloads',
  ARIA_DOWNLOAD_LOCATION_ROOT: '/',
  GDRIVE_PARENT_DIR_ID: '你的Drive文件夹ID',
  SUDO_USERS: [你的TG用户ID],
  AUTHORIZED_CHATS: [],
  ARIA_FILTERED_DOMAINS: [],
  ARIA_FILTERED_FILENAMES: [],
  ARIA_PORT: 8210,
  STATUS_UPDATE_INTERVAL_MS: 12000,
  IS_TEAM_DRIVE: false,
  INDEX_URL: '',
  DRIVE_FILE_PRIVATE: { ENABLED: false, EMAILS: [] },
  DOWNLOAD_NOTIFY_TARGET: { enabled: false, host: '', port: 80, path: '' },
  COMMANDS_USE_BOT_NAME: { ENABLED: false, NAME: "@YourBot" }
});
EOF
```

### 5. 运行容器
```bash
docker run -d \
  --name mirror-bot \
  --restart unless-stopped \
  -v ~/mirror-bot/downloads:/mirrorbot/downloads \
  -v ~/mirror-bot/service_account.json:/mirrorbot/service_account.json:ro \
  -v ~/mirror-bot/.constants.js:/mirrorbot/out/.constants.js:ro \
  -v ~/mirror-bot/aria.sh:/mirrorbot/aria.sh:ro \
  ghcr.io/bustesoul/aria-mirror-bot:latest
```

### 6. 查看日志
```bash
docker logs -f mirror-bot
```

---

## 三、验证

向 Bot 发送：
```
/mirror https://speed.hetzner.de/100MB.bin
```

应该能看到下载进度，完成后返回 Drive 链接。

---

## 四、常用命令

```bash
# 查看状态
docker ps

# 重启
docker restart mirror-bot

# 停止删除
docker stop mirror-bot && docker rm mirror-bot

# 更新镜像
docker pull ghcr.io/bustesoul/aria-mirror-bot:latest
docker stop mirror-bot && docker rm mirror-bot
# 然后重新运行上面的 docker run 命令
```
