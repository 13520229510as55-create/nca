#!/bin/bash

# 持续检查部署状态
PROJECT_ID="gen-lang-client-0960629066"
REGION="us-central1"
SERVICE_NAME="nca-toolkit-chinese"

echo "🔍 开始持续监控部署状态..."
echo "   每 30 秒检查一次"
echo "   按 Ctrl+C 停止"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

while true; do
    clear
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "🕐 检查时间: $TIMESTAMP"
    echo ""
    
    # 检查 Cloud Build
    echo "📦 Cloud Build 状态："
    LATEST_BUILD=$(gcloud builds list --limit=1 --format="value(id,status,createTime)" --project=${PROJECT_ID} 2>/dev/null)
    
    if [ -z "$LATEST_BUILD" ]; then
        echo "   ⏳ 等待构建任务启动..."
        echo "   (可能正在上传源代码)"
    else
        BUILD_ID=$(echo $LATEST_BUILD | cut -d' ' -f1)
        BUILD_STATUS=$(echo $LATEST_BUILD | cut -d' ' -f2)
        BUILD_TIME=$(echo $LATEST_BUILD | cut -d' ' -f3-)
        
        case $BUILD_STATUS in
            "SUCCESS")
                echo "   ✅ 构建成功！"
                echo "   构建 ID: $BUILD_ID"
                ;;
            "WORKING"|"QUEUED")
                echo "   🔨 构建中..."
                echo "   状态: $BUILD_STATUS"
                echo "   开始时间: $BUILD_TIME"
                echo "   构建 ID: $BUILD_ID"
                echo ""
                echo "   查看详细日志:"
                echo "   gcloud builds log $BUILD_ID"
                ;;
            "FAILURE"|"CANCELLED"|"TIMEOUT")
                echo "   ❌ 构建失败: $BUILD_STATUS"
                echo "   构建 ID: $BUILD_ID"
                echo ""
                echo "   查看错误日志:"
                echo "   gcloud builds log $BUILD_ID"
                break
                ;;
            *)
                echo "   ⚠️  状态: $BUILD_STATUS"
                ;;
        esac
    fi
    
    echo ""
    
    # 检查 Cloud Run
    echo "☁️  Cloud Run 服务状态："
    SERVICE_EXISTS=$(gcloud run services describe ${SERVICE_NAME} --region=${REGION} --format="value(name)" --project=${PROJECT_ID} 2>/dev/null)
    
    if [ -z "$SERVICE_EXISTS" ]; then
        echo "   ⏳ 服务尚未部署"
        echo "   (等待构建完成)"
    else
        SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} --region=${REGION} --format="value(status.url)" --project=${PROJECT_ID} 2>/dev/null)
        SERVICE_STATUS=$(gcloud run services describe ${SERVICE_NAME} --region=${REGION} --format="value(status.conditions[0].status)" --project=${PROJECT_ID} 2>/dev/null)
        
        if [ "$SERVICE_STATUS" = "True" ]; then
            echo "   ✅ 服务运行中！"
            echo "   📍 URL: $SERVICE_URL"
            echo ""
            echo "🎉 部署完成！"
            echo ""
            echo "🧪 测试命令："
            echo "curl -X POST \"${SERVICE_URL}/v1/video/caption\" \\"
            echo "  -H \"x-api-key: 123\" \\"
            echo "  -H \"Content-Type: application/json\" \\"
            echo "  -d '{\"video_url\":\"测试视频URL\",\"settings\":{\"font_family\":\"Noto Sans SC\",\"word_color\":\"#FFFFFF\",\"font_size\":48}}'"
            break
        else
            echo "   ⏳ 服务部署中..."
        fi
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "⏳ 30 秒后再次检查... (按 Ctrl+C 停止)"
    sleep 30
done

echo ""
echo "监控结束"


