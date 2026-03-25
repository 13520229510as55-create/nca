#!/bin/bash
# 使用服务账号 JSON 将本项目上传到 Cloud Build（gcloud builds submit）
set -e

GCLOUD="/opt/homebrew/share/google-cloud-sdk/bin/gcloud"
export PATH="/opt/homebrew/bin:/opt/homebrew/share/google-cloud-sdk/bin:$PATH"
export CLOUDSDK_PYTHON="${CLOUDSDK_PYTHON:-/opt/homebrew/bin/python3.13}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CLOUDSDK_CONFIG="${SCRIPT_DIR}/.gcloud-config"
mkdir -p "$CLOUDSDK_CONFIG"

# 可通过环境变量覆盖
PROJECT_ID="${GCP_PROJECT_ID:-n8n-video-490705}"
BUCKET_NAME="${GCP_BUCKET_NAME:-nca-n8n-video-output}"
SA_KEY_FILE="${GCP_SA_KEY_FILE:-/Users/a58/Downloads/n8n-video-490705-bdfd1c091966.json}"

if [[ ! -f "$SA_KEY_FILE" ]]; then
  echo "❌ 找不到密钥文件: $SA_KEY_FILE"
  echo "   设置: export GCP_SA_KEY_FILE=/path/to/your-key.json"
  exit 1
fi

echo "🔐 使用服务账号: $SA_KEY_FILE"
$GCLOUD auth activate-service-account --key-file="$SA_KEY_FILE"
$GCLOUD config set project "$PROJECT_ID"

echo "📤 上传源码并触发 Cloud Build（约 30–50 分钟）..."
cd "$SCRIPT_DIR"
$GCLOUD builds submit \
  --config=cloudbuild.yaml \
  --timeout=7200 \
  --project="$PROJECT_ID" \
  --substitutions=_BUCKET_NAME="$BUCKET_NAME"

echo "✅ Cloud Build 已提交，可在控制台查看进度："
echo "   https://console.cloud.google.com/cloud-build/builds?project=$PROJECT_ID"
