#!/bin/bash
# NCA 中文字体版 - 使用服务账号部署到 n8n-video-490705 项目
set -e

# 确保 gcloud 可用，使用兼容的 Python
GCLOUD="/opt/homebrew/share/google-cloud-sdk/bin/gcloud"
export PATH="/opt/homebrew/bin:/opt/homebrew/share/google-cloud-sdk/bin:$PATH"
export CLOUDSDK_PYTHON="/opt/homebrew/bin/python3.13"

# 使用默认 gcloud 配置 (~/.config/gcloud)，请在系统终端运行此脚本
# 若在 Cursor 内运行遇权限问题，请在 macOS 终端执行

PROJECT_ID="n8n-video-490705"
REGION="us-central1"
SERVICE_NAME="nca-toolkit-chinese"
BUCKET_NAME="nca-n8n-video-output"
API_KEY="123"
SA_KEY_FILE="/Users/a58/Downloads/n8n-video-490705-bdfd1c091966.json"

echo "🚀 使用服务账号部署 NCA 到 ${PROJECT_ID}..."
echo ""

# 部署需要您的个人账号（Project Owner），服务账号 JSON 仅用于 NCA 的 GCS 上传凭证
echo "🔐 检查认证状态..."
$GCLOUD config set project $PROJECT_ID
if ! $GCLOUD auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q .; then
    echo "❌ 请先登录（需 Project Owner 权限）:"
    echo "   gcloud auth login"
    echo ""
    echo "   然后重新运行本脚本"
    exit 1
fi
echo "   当前账号: $($GCLOUD auth list --filter=status:ACTIVE --format='value(account)')"

# 启用 API（需要 Owner 权限）
echo "🔧 启用 API..."
$GCLOUD services enable cloudbuild.googleapis.com run.googleapis.com containerregistry.googleapis.com storage.googleapis.com storage-api.googleapis.com --quiet 2>/dev/null || echo "   (API 可能已启用)"

# 创建 GCS Bucket（如不存在）
echo "📦 检查/创建 GCS Bucket..."
if ! $GCLOUD storage buckets describe gs://${BUCKET_NAME} 2>/dev/null; then
    echo "   创建 bucket: ${BUCKET_NAME}"
    $GCLOUD storage buckets create gs://${BUCKET_NAME} --project=${PROJECT_ID} --location=${REGION}
fi

# Cloud Build 部署
echo ""
echo "📤 提交 Cloud Build（约 30-50 分钟）..."
cd /Users/a58/Downloads/no-code-architects-toolkit
$GCLOUD builds submit --config=cloudbuild.yaml --timeout=7200 --project=${PROJECT_ID} --substitutions=_BUCKET_NAME=${BUCKET_NAME}

if [ $? -ne 0 ]; then
    echo "❌ Cloud Build 失败"
    exit 1
fi

# 更新 GCP_SA_CREDENTIALS
echo ""
echo "🔑 配置 GCP 凭证..."
export _SA_KEY_FILE="$SA_KEY_FILE" _SERVICE_NAME="$SERVICE_NAME" _REGION="$REGION" _PROJECT_ID="$PROJECT_ID" _BUCKET_NAME="$BUCKET_NAME"
python3 << 'PYEOF'
import subprocess
import json
import sys
import os

with open(os.environ['_SA_KEY_FILE'], 'r') as f:
    sa_data = json.load(f)
sa_json_str = json.dumps(sa_data)

gcloud_path = '/opt/homebrew/share/google-cloud-sdk/bin/gcloud'
cmd = [
    gcloud_path, 'run', 'services', 'update', os.environ['_SERVICE_NAME'],
    '--region', os.environ['_REGION'], '--project', os.environ['_PROJECT_ID'],
    '--update-env-vars', f'GCP_SA_CREDENTIALS={sa_json_str}',
    '--update-env-vars', f"GCP_BUCKET_NAME={os.environ['_BUCKET_NAME']}",
    '--quiet'
]
result = subprocess.run(cmd, capture_output=True, text=True)
print(result.stdout)
if result.stderr:
    print(result.stderr, file=sys.stderr)
sys.exit(result.returncode)
PYEOF

echo ""
SERVICE_URL=$($GCLOUD run services describe ${SERVICE_NAME} --region=${REGION} --project=${PROJECT_ID} --format="value(status.url)")
echo "✅ 部署完成！"
echo "   URL: ${SERVICE_URL}"
echo "   API Key: ${API_KEY}"
