#!/bin/bash

# ============================================
# NCA Toolkit 中文字体版 - 一键部署到 Google Cloud Run
# 支持多种中文字体：Noto Sans SC/TC, 文泉驿等
# ============================================

set -e

# ========== 配置（请修改为您的实际值）==========
PROJECT_ID="${GCP_PROJECT_ID:-gen-lang-client-0960629066}"
REGION="${GCP_REGION:-us-central1}"
SERVICE_NAME="nca-toolkit-chinese"
API_KEY="${NCA_API_KEY:-123}"
GCP_BUCKET_NAME="${GCP_BUCKET_NAME:-n8n-test-3344}"
SERVICE_ACCOUNT="${GCP_SERVICE_ACCOUNT:-nca-test@gen-lang-client-0960629066.iam.gserviceaccount.com}"
# ==============================================

echo "🚀 NCA Toolkit 中文字体版 - Google Cloud Run 部署"
echo "================================================"
echo "  项目: ${PROJECT_ID}"
echo "  区域: ${REGION}"
echo "  服务: ${SERVICE_NAME}"
echo "  Bucket: ${GCP_BUCKET_NAME}"
echo "================================================"
echo ""

# 检查 gcloud
if ! command -v gcloud &> /dev/null; then
    echo "❌ 未找到 gcloud CLI"
    echo ""
    echo "请先安装 Google Cloud SDK:"
    echo "  https://cloud.google.com/sdk/docs/install"
    echo ""
    echo "或使用 Homebrew (Mac):"
    echo "  brew install --cask google-cloud-sdk"
    exit 1
fi

# 检查登录
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q .; then
    echo "❌ 请先登录 Google Cloud:"
    echo "   gcloud auth login"
    exit 1
fi

# 进入项目目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 启用 API
echo "🔧 启用必要的 GCP API..."
gcloud config set project ${PROJECT_ID}
gcloud services enable cloudbuild.googleapis.com run.googleapis.com containerregistry.googleapis.com --quiet

# 步骤 1: Cloud Build 构建并部署
echo ""
echo "📦 步骤 1/2: 使用 Cloud Build 构建镜像（约 30-50 分钟）..."
echo "   无需本地 Docker，全部在 GCP 云端完成"
echo ""

gcloud builds submit \
  --config=cloudbuild.yaml \
  --timeout=7200

if [ $? -ne 0 ]; then
    echo "❌ Cloud Build 失败"
    exit 1
fi

# 步骤 2: 配置 GCP 凭证
echo ""
echo "🔐 步骤 2/2: 配置 GCP Service Account 凭证..."
echo "   NCA 需要此凭证才能将处理结果上传到 GCS"
echo ""

KEY_FILE="/tmp/nca-sa-key-$$.json"
if gcloud iam service-accounts keys create "$KEY_FILE" \
  --iam-account="$SERVICE_ACCOUNT" \
  --project="$PROJECT_ID" 2>/dev/null; then

    echo "✅ 密钥已创建，正在更新 Cloud Run 服务..."
    
    # 使用 Python 正确传递 JSON
    python3 << PYEOF
import subprocess
import json
import sys

with open('$KEY_FILE', 'r') as f:
    sa_data = json.load(f)
sa_json_str = json.dumps(sa_data)

cmd = [
    'gcloud', 'run', 'services', 'update', '$SERVICE_NAME',
    '--region', '$REGION', '--project', '$PROJECT_ID',
    '--update-env-vars', f'GCP_SA_CREDENTIALS={sa_json_str}',
    '--quiet'
]
result = subprocess.run(cmd, capture_output=True, text=True)
print(result.stdout)
if result.stderr:
    print(result.stderr, file=sys.stderr)
sys.exit(result.returncode)
PYEOF

    rm -f "$KEY_FILE"
    
    if [ $? -eq 0 ]; then
        echo "✅ 凭证已配置"
    else
        echo "⚠️  凭证更新失败，请手动运行: ./更新GCP凭证.sh"
    fi
else
    echo "⚠️  无法自动创建密钥"
    echo "   请手动运行以下命令配置凭证:"
    echo "   ./更新GCP凭证.sh"
fi

# 完成
SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} --region=${REGION} --format="value(status.url)" 2>/dev/null || echo "")

echo ""
echo "================================================"
echo "✅ 部署完成！"
echo "================================================"
echo ""
echo "📝 服务信息："
echo "   URL: ${SERVICE_URL}"
echo "   API Key: ${API_KEY}"
echo ""
echo "🎨 支持的中文字体："
echo "   - Noto Sans SC (简体中文)"
echo "   - Noto Sans TC (繁体中文)"
echo "   - WenQuanYi Zen Hei (文泉驿正黑)"
echo "   - WenQuanYi Micro Hei (文泉驿微米黑)"
echo ""
echo "🧪 测试命令："
echo "   curl -X POST \"${SERVICE_URL}/v1/toolkit/test\" -H \"x-api-key: ${API_KEY}\""
echo ""
echo "🎉 完成！"
