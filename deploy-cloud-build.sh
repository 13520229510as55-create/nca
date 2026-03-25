#!/bin/bash

# ============================================
# NCA Toolkit 中文版部署脚本 - 使用 Cloud Build
# 不需要本地 Docker
# ============================================

set -e

# ========== 配置 ==========
PROJECT_ID="gen-lang-client-0960629066"
REGION="us-central1"
SERVICE_NAME="nca-toolkit-chinese"
API_KEY="123"
GCP_BUCKET_NAME="n8n-test-3344"
# =========================

echo "🚀 开始使用 Cloud Build 部署 NCA Toolkit 中文版..."
echo ""

# 检查 gcloud 是否已登录
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "❌ 错误：请先登录 gcloud"
    echo "   运行: gcloud auth login"
    exit 1
fi

# 设置项目
echo "📋 设置 GCP 项目: ${PROJECT_ID}"
gcloud config set project ${PROJECT_ID}

# 启用必要的 API
echo ""
echo "🔧 启用必要的 API..."
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com

# 使用 Cloud Build 构建并部署
echo ""
echo "🔨 使用 Cloud Build 构建镜像并部署到 Cloud Run..."
echo "   这可能需要 30-40 分钟，请耐心等待..."
echo ""

gcloud builds submit --tag gcr.io/${PROJECT_ID}/nca-toolkit-chinese:latest \
  --timeout=3600

if [ $? -ne 0 ]; then
    echo "❌ Cloud Build 失败！"
    exit 1
fi

# 部署到 Cloud Run
echo ""
echo "☁️  部署到 Cloud Run..."

# 检查服务是否已存在
if gcloud run services describe ${SERVICE_NAME} --region=${REGION} --format="value(name)" 2>/dev/null | grep -q .; then
    echo "   更新现有服务..."
    UPDATE_FLAG="--update-env-vars"
else
    echo "   创建新服务..."
    UPDATE_FLAG="--set-env-vars"
fi

gcloud run deploy ${SERVICE_NAME} \
    --image gcr.io/${PROJECT_ID}/nca-toolkit-chinese:latest \
    --platform managed \
    --region ${REGION} \
    --allow-unauthenticated \
    ${UPDATE_FLAG} API_KEY=${API_KEY} \
    ${UPDATE_FLAG} GCP_BUCKET_NAME=${GCP_BUCKET_NAME} \
    ${UPDATE_FLAG} MAX_QUEUE_LENGTH=10 \
    ${UPDATE_FLAG} GUNICORN_WORKERS=4 \
    ${UPDATE_FLAG} GUNICORN_TIMEOUT=300 \
    --memory 2Gi \
    --cpu 2 \
    --timeout 600 \
    --min-instances 0 \
    --max-instances 10

if [ $? -ne 0 ]; then
    echo "❌ Cloud Run 部署失败！"
    exit 1
fi

# 获取服务 URL
SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} --region=${REGION} --format="value(status.url)")

echo ""
echo "✅ 部署完成！"
echo ""
echo "📝 服务信息："
echo "   服务名称: ${SERVICE_NAME}"
echo "   区域: ${REGION}"
echo "   URL: ${SERVICE_URL}"
echo ""
echo "🧪 测试中文字体："
echo "   curl -X POST \"${SERVICE_URL}/v1/video/caption\" \\"
echo "     -H \"x-api-key: ${API_KEY}\" \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -d '{\"video_url\":\"测试视频URL\",\"settings\":{\"font_family\":\"Noto Sans SC\",\"word_color\":\"#FFFFFF\",\"font_size\":48}}'"
echo ""
echo "🎉 完成！现在可以使用中文字体了！"


