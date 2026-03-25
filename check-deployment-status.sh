#!/bin/bash

# ============================================
# 检查 NCA Toolkit 部署状态
# ============================================

PROJECT_ID="gen-lang-client-0960629066"
REGION="us-central1"
SERVICE_NAME="nca-toolkit-chinese"

echo "🔍 检查部署状态..."
echo ""

# 检查 Cloud Build 状态
echo "📦 Cloud Build 状态："
LATEST_BUILD=$(gcloud builds list --limit=1 --format="value(id,status,createTime)" 2>/dev/null)

if [ -z "$LATEST_BUILD" ]; then
    echo "   ⏳ 暂无构建任务"
else
    BUILD_ID=$(echo $LATEST_BUILD | cut -d' ' -f1)
    BUILD_STATUS=$(echo $LATEST_BUILD | cut -d' ' -f2)
    BUILD_TIME=$(echo $LATEST_BUILD | cut -d' ' -f3-)
    
    case $BUILD_STATUS in
        "SUCCESS")
            echo "   ✅ 构建成功 ($BUILD_TIME)"
            ;;
        "WORKING"|"QUEUED")
            echo "   🔨 构建中... ($BUILD_TIME)"
            echo "   查看详情: gcloud builds log $BUILD_ID"
            ;;
        "FAILURE"|"CANCELLED"|"TIMEOUT"|"INTERNAL_ERROR")
            echo "   ❌ 构建失败: $BUILD_STATUS"
            echo "   查看日志: gcloud builds log $BUILD_ID"
            ;;
        *)
            echo "   ⚠️  状态: $BUILD_STATUS"
            ;;
    esac
fi

echo ""

# 检查 Cloud Run 服务状态
echo "☁️  Cloud Run 服务状态："
SERVICE_EXISTS=$(gcloud run services describe ${SERVICE_NAME} --region=${REGION} --format="value(name)" 2>/dev/null)

if [ -z "$SERVICE_EXISTS" ]; then
    echo "   ⏳ 服务尚未部署"
else
    SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} --region=${REGION} --format="value(status.url)" 2>/dev/null)
    SERVICE_STATUS=$(gcloud run services describe ${SERVICE_NAME} --region=${REGION} --format="value(status.conditions[0].status)" 2>/dev/null)
    
    if [ "$SERVICE_STATUS" = "True" ]; then
        echo "   ✅ 服务运行中"
        echo "   📍 URL: $SERVICE_URL"
        
        # 测试服务是否可访问
        echo ""
        echo "🧪 测试服务连接..."
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "x-api-key: 123" "${SERVICE_URL}/v1/toolkit/test" 2>/dev/null || echo "000")
        
        if [ "$HTTP_CODE" = "200" ]; then
            echo "   ✅ API 可访问 (HTTP $HTTP_CODE)"
        elif [ "$HTTP_CODE" = "000" ]; then
            echo "   ⚠️  无法连接到服务"
        else
            echo "   ⚠️  HTTP 状态码: $HTTP_CODE"
        fi
    else
        echo "   ⏳ 服务部署中..."
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""


