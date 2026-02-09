FROM ubuntu:focal
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update -y
RUN apt install aria2 npm nodejs -y
COPY . /mirrorbot
WORKDIR /mirrorbot
RUN npm install
RUN NODE_OPTIONS="--max-old-space-size=4096" npm run build
ENTRYPOINT ./aria.sh && NTBA_FIX_319=1 node ./out/index.js
