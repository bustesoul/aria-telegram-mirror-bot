# -------- builder --------
FROM node:20-bookworm AS builder
WORKDIR /mirrorbot
COPY package*.json ./
RUN npm ci
COPY . .
# 复制 example 配置文件供编译用
RUN cp src/.constants.js.example src/.constants.js
RUN cp aria.sh.example aria.sh
ENV NODE_OPTIONS="--max-old-space-size=4096"
RUN npm run build

# -------- runtime --------
FROM node:20-bookworm-slim AS runtime
WORKDIR /mirrorbot

# aria2 放运行阶段装
RUN apt-get update && apt-get install -y aria2 && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
RUN npm ci --omit=dev
COPY --from=builder /mirrorbot/out ./out
COPY aria.sh.example ./aria.sh
RUN chmod +x ./aria.sh

# 配置文件挂载点：/mirrorbot/out/.constants.js 和 /mirrorbot/aria.sh
# 用 bash -lc 才能让 && 正常工作
ENTRYPOINT ["bash", "-lc", "./aria.sh && NTBA_FIX_319=1 node ./out/index.js"]
