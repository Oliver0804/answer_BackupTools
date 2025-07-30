#!/bin/bash
# Apache Answer Volume 工具：備份 / 還原選單腳本

BACKUP_DIR="/root/answer_backups"
VOLUME_NAME="answer-data"
CONTAINER_NAME="answer"
IMAGE="apache/answer:1.6.0"

mkdir -p "$BACKUP_DIR"

show_menu() {
  echo "==============================="
  echo " Apache Answer Docker 工具"
  echo "==============================="
  echo "1) 備份 Answer 資料庫"
  echo "2) 還原 Answer 資料庫"
  echo "0) 離開"
  echo "-------------------------------"
  read -p "請選擇操作項目: " CHOICE
}

backup_data() {
  DATE=$(date +%F)
  BACKUP_FILE="$BACKUP_DIR/answer-data-$DATE.tar.gz"
  VOLUME_PATH="/var/lib/docker/volumes/$VOLUME_NAME/_data"

  echo "[*] 備份中：$BACKUP_FILE"
  tar czvf "$BACKUP_FILE" -C "$VOLUME_PATH" .
  echo "[✔] 備份完成"
}

restore_data() {
  echo "[*] 可用備份清單："
  echo "-------------------------------"
  ls "$BACKUP_DIR"/answer-data-*.tar.gz | nl
  echo "-------------------------------"
  read -p "請輸入要還原的備份編號: " SELECTION

  SELECTED_FILE=$(ls "$BACKUP_DIR"/answer-data-*.tar.gz | sed -n "${SELECTION}p")
  if [ -z "$SELECTED_FILE" ]; then
    echo "[✘] 無效選擇，取消還原。"
    return
  fi

  echo "[*] 停止舊容器（若有）"
  docker rm -f "$CONTAINER_NAME" 2>/dev/null

  echo "[*] 刪除原 volume（若有）"
  docker volume rm "$VOLUME_NAME" 2>/dev/null

  echo "[*] 建立新 volume 並還原資料"
  docker volume create "$VOLUME_NAME"
  TARGET_PATH="/var/lib/docker/volumes/$VOLUME_NAME/_data"
  mkdir -p "$TARGET_PATH"
  tar xzvf "$SELECTED_FILE" -C "$TARGET_PATH"
  echo "[✔] 還原完成"

  echo "[*] 啟動新容器..."
  docker run -d -p 80:80 \
    -v "$VOLUME_NAME":/data \
    --name "$CONTAINER_NAME" \
    "$IMAGE"
  echo "[✔] 容器啟動完成：$CONTAINER_NAME"
}

while true; do
  show_menu
  case "$CHOICE" in
    1)
      backup_data
      ;;
    2)
      restore_data
      ;;
    0)
      echo "Bye!"
      break
      ;;
    *)
      echo "[!] 無效選擇，請重新輸入。"
      ;;
  esac
  echo
done
