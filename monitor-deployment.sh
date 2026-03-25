#!/bin/bash

# ============================================
# 持续监控 NCA Toolkit 部署状态
# ============================================

PROJECT_ID="gen-lang-client-0960629066"
REGION="us-central1"
SERVICE_NAME="nca-toolkit-chinese"
CHECK_INTERVAL=30  # 每30秒检查一次

echo "🚀 开始监控部署状态..."
echo "   每 ${CHECK_INTERVAL} 秒检查一次"
echo "   按 Ctrl+C 停止监控"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 检查计数器
CHECK_COUNT=0
LAST_BUILD_STATUS=""
LAST_SERVICE_STATUS=""

while true; do
    CHECK_COUNT=$((CHECK_COUNT + 1))
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$TIMESTAMP] 检查 #$CHECK_COUNT"
    echo ""
    
    # 检查 Cloud Build 状态
    LATEST_BUILD=$(gcloud builds list --limit=1 --format="value(id,status,createTime)" --project=${PROJECT_ID} 2>/dev/null)
    
    if [ -z "$LATEST_BUILD" ]; then
        if [ "$LAST_BUILD_STATUS" != "NONE" ]; then
            echo "📦 Cloud Build: ⏳ 暂无构建任务"
            LAST_BUILD_STATUS="NONE"
        fi
    else
        BUILD_ID=$(echo $LATEST_BUILD | cut -d' ' -f1)
        BUILD_STATUS=$(echo $LATEST_BUILD | cut -d' ' -f2)
        BUILD_TIME=$(echo $LATEST_BUILD | cut -d' ' -f3-)
        
        if [ "$BUILD_STATUS" != "$LAST_BUILD_STATUS" ]; then
            case $BUILD_STATUS in
                "SUCCESS")
                    echo "📦 Cloud Build: ✅ 构建成功！"
                    LAST_BUILD_STATUS=$BUILD_STATUS
                    ;;
                "WORKING"|"QUEUED")
                    echo "📦 Cloud Build: 🔨 构建中... (开始时间: $BUILD_TIME)"
                    echo "   构建 ID: $BUILD_ID"
                    LAST_BUILD_STATUS=$BUILD_STATUS
                    ;;
                "FAILURE"|"CANCELLED"|"TIMEOUT"|"INTERNAL_ERROR")
                    echo "📦 Cloud Build: ❌ 构建失败: $BUILD_STATUS"
                    echo "   查看日志: gcloud builds log $BUILD_ID"
                    LAST_BUILD_STATUS=$BUILD_STATUS
                    break
                    ;;
                *)
                    echo "📦 Cloud Build: ⚠️  状态: $BUILD_STATUS"
                    LAST_BUILD_STATUS=$BUILD_STATUS
                    ;;
            esac
        fi
    fi
    
    # 检查 Cloud Run 服务状态
    SERVICE_EXISTS=$(gcloud run services describe ${SERVICE_NAME} --region=${REGION} --format="value(name)" --project=${PROJECT_ID} 2>/dev/null)
    
    if [ -z "$SERVICE_EXISTS" ]; then
        if [ "$LAST_SERVICE_STATUS" != "NOT_EXISTS" ]; then
            echo "☁️  Cloud Run: ⏳ 服务尚未部署"
            LAST_SERVICE_STATUS="NOT_EXISTS"
        fi
    else
        SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} --region=${REGION} --format="value(status.url)" --project=${PROJECT_ID} 2>/dev/null)
        SERVICE_STATUS=$(gcloud run services describe ${SERVICE_NAME} --region=${REGION} --format="value(status.conditions[0].status)" --project=${PROJECT_ID} 2>/dev/null)
        
        if [ "$SERVICE_STATUS" = "True" ]; then
            if [ "$LAST_SERVICE_STATUS" != "READY" ]; then
                echo "☁️  Cloud Run: ✅ 服务运行中！"
                echo "   📍 URL: $SERVICE_URL"
                echo ""
                echo "🎉 部署完成！"
                echo ""
                echo "🧪 测试命令："
                echo "   curl -X POST \"${SERVICE_URL}/v1/video/caption\" \\"
                echo "     -H \"x-api-key: 123\" \\"
                echo "     -H \"Content-Type: application/json\" \\"
                echo "     -d '{\"video_url\":\"测试视频URL\",\"settings\":{\"font_family\":\"Noto Sans SC\",\"word_color\":\"#FFFFFF\",\"font_size\":48}}'"
                echo ""
                LAST_SERVICE_STATUS="READY"
                break
            fi
        else
            if [ "$LAST_SERVICE_STATUS" != "DEPLOYING" ]; then
                echo "☁️  Cloud Run: ⏳ 服务部署中..."
                LAST_SERVICE_STATUS="DEPLOYING"
            fi
        fi
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # 等待下一次检查
    sleep $CHECK_INTERVAL
done

echo "监控结束"


