#!/bin/bash

PROJECT_ID="gen-lang-client-0960629066"
REGION="us-central1"
SERVICE_NAME="nca-toolkit-chinese"
BUILD_ID="ba0f9a60-5c1d-4a66-a3f6-62a05f93e9d9"

echo "🔍 持续监控部署状态..."
echo "构建 ID: $BUILD_ID"
echo "每 30 秒检查一次"
echo "按 Ctrl+C 停止"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

while true; do
    TIMESTAMP=$(date '+%H:%M:%S')
    echo "[$TIMESTAMP] 检查状态..."
    echo ""
    
    # 检查构建状态
    BUILD_STATUS=$(gcloud builds describe $BUILD_ID --project=$PROJECT_ID --format="value(status)" 2>/dev/null)
    
    if [ -z "$BUILD_STATUS" ]; then
        # 如果找不到，获取最新的构建
        LATEST=$(gcloud builds list --limit=1 --format="value(id,status)" --project=$PROJECT_ID 2>/dev/null)
        if [ -n "$LATEST" ]; then
            BUILD_ID=$(echo $LATEST | cut -d' ' -f1)
            BUILD_STATUS=$(echo $LATEST | cut -d' ' -f2)
        else
            BUILD_STATUS="UNKNOWN"
        fi
    fi
    
    case $BUILD_STATUS in
        "SUCCESS")
            echo "📦 Cloud Build: ✅ 构建成功！"
            echo ""
            echo "☁️  检查 Cloud Run..."
            SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.url)" --project=$PROJECT_ID 2>/dev/null)
            
            if [ -n "$SERVICE_URL" ]; then
                echo "☁️  Cloud Run: ✅ 服务已部署！"
                echo "📍 URL: $SERVICE_URL"
                echo ""
                echo "🎉 部署完成！"
                echo ""
                echo "🧪 测试命令："
                echo "curl -X POST \"$SERVICE_URL/v1/video/caption\" \\"
                echo "  -H \"x-api-key: 123\" \\"
                echo "  -H \"Content-Type: application/json\" \\"
                echo "  -d '{\"video_url\":\"测试视频URL\",\"settings\":{\"font_family\":\"Noto Sans SC\",\"word_color\":\"#FFFFFF\",\"font_size\":48}}'"
                break
            else
                echo "☁️  Cloud Run: ⏳ 等待部署..."
            fi
            ;;
        "WORKING"|"QUEUED")
            echo "📦 Cloud Build: 🔨 构建中... ($BUILD_STATUS)"
            echo "   构建 ID: $BUILD_ID"
            echo ""
            echo "   查看日志: gcloud builds log $BUILD_ID --stream"
            ;;
        "FAILURE"|"CANCELLED"|"TIMEOUT")
            echo "📦 Cloud Build: ❌ 构建失败 ($BUILD_STATUS)"
            echo "   构建 ID: $BUILD_ID"
            echo ""
            echo "   查看日志: gcloud builds log $BUILD_ID"
            break
            ;;
        *)
            echo "📦 Cloud Build: ⚠️  状态: $BUILD_STATUS"
            ;;
    esac
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    sleep 30
done

echo ""
echo "监控结束"


