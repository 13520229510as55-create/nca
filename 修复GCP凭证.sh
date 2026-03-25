#!/bin/bash

# ============================================
# 修复 Cloud Run 服务的 GCP 凭证问题
# ============================================

PROJECT_ID="gen-lang-client-0960629066"
REGION="us-central1"
SERVICE_NAME="nca-toolkit-chinese"
SERVICE_ACCOUNT="nca-test@gen-lang-client-0960629066.iam.gserviceaccount.com"

echo "🔧 修复 Cloud Run 服务的 GCP 凭证..."
echo ""

# 方法 1：使用现有 Service Account 的密钥
echo "📋 方法 1：创建 Service Account 密钥..."
echo ""

# 创建临时密钥文件
KEY_FILE="/tmp/nca-sa-key.json"
gcloud iam service-accounts keys create $KEY_FILE \
  --iam-account=$SERVICE_ACCOUNT \
  --project=$PROJECT_ID 2>/dev/null

if [ -f "$KEY_FILE" ]; then
    echo "✅ 密钥文件已创建"
    
    # 读取密钥内容
    SA_CREDENTIALS=$(cat $KEY_FILE | jq -c .)
    
    # 更新 Cloud Run 服务
    echo ""
    echo "☁️  更新 Cloud Run 服务环境变量..."
    
    gcloud run services update $SERVICE_NAME \
      --region=$REGION \
      --project=$PROJECT_ID \
      --update-env-vars GCP_SA_CREDENTIALS="$SA_CREDENTIALS" \
      --quiet
    
    if [ $? -eq 0 ]; then
        echo "✅ 服务已更新！"
        echo ""
        echo "🧹 清理临时文件..."
        rm -f $KEY_FILE
        echo "✅ 完成！"
    else
        echo "❌ 更新失败"
        exit 1
    fi
else
    echo "❌ 无法创建密钥文件"
    echo ""
    echo "📋 方法 2：使用 Cloud Run 默认服务账户..."
    echo ""
    echo "需要手动授予 GCS 权限："
    echo "gcloud projects add-iam-policy-binding $PROJECT_ID \\"
    echo "  --member=\"serviceAccount:67158488565-compute@developer.gserviceaccount.com\" \\"
    echo "  --role=\"roles/storage.admin\""
    echo ""
    echo "然后更新服务使用默认服务账户："
    echo "gcloud run services update $SERVICE_NAME \\"
    echo "  --region=$REGION \\"
    echo "  --service-account=67158488565-compute@developer.gserviceaccount.com"
    exit 1
fi

echo ""
echo "✅ 修复完成！"
echo ""
echo "🧪 测试服务..."
sleep 5
curl -s -H "x-api-key: 123" "https://nca-toolkit-chinese-j5ylpd7ioq-uc.a.run.app/v1/toolkit/test" | jq -r '.message' 2>/dev/null || echo "测试中..."


