#!/bin/bash

# ============================================
# 监控构建错误和状态
# ============================================

PROJECT_ID="gen-lang-client-0960629066"
REGION="us-central1"
SERVICE_NAME="nca-toolkit-chinese"
BUILD_ID="b3ea0838-c218-4c03-89c8-73fe6a6d34fc"

echo "🔍 监控构建状态和错误..."
echo "构建 ID: $BUILD_ID"
echo "每 30 秒检查一次"
echo "按 Ctrl+C 停止"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

ERROR_DETECTED=false

while true; do
    TIMESTAMP=$(date '+%H:%M:%S')
    echo "[$TIMESTAMP] 检查状态..."
    echo ""
    
    # 获取构建状态
    BUILD_INFO=$(gcloud builds describe $BUILD_ID --project=$PROJECT_ID --format="value(status,statusDetail,logUrl)" 2>/dev/null)
    
    if [ -z "$BUILD_INFO" ]; then
        # 如果找不到，获取最新的构建
        LATEST=$(gcloud builds list --limit=1 --format="value(id,status)" --project=$PROJECT_ID 2>/dev/null)
        if [ -n "$LATEST" ]; then
            BUILD_ID=$(echo $LATEST | cut -d' ' -f1)
            BUILD_INFO=$(gcloud builds describe $BUILD_ID --project=$PROJECT_ID --format="value(status,statusDetail,logUrl)" 2>/dev/null)
        fi
    fi
    
    if [ -n "$BUILD_INFO" ]; then
        BUILD_STATUS=$(echo $BUILD_INFO | cut -d$'\t' -f1)
        BUILD_DETAIL=$(echo $BUILD_INFO | cut -d$'\t' -f2)
        BUILD_LOG_URL=$(echo $BUILD_INFO | cut -d$'\t' -f3)
        
        case $BUILD_STATUS in
            "SUCCESS")
                echo "✅ Cloud Build: 构建成功！"
                echo ""
                echo "☁️  检查 Cloud Run 部署..."
                SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.url)" --project=$PROJECT_ID 2>/dev/null)
                
                if [ -n "$SERVICE_URL" ]; then
                    echo "✅ Cloud Run: 服务已部署！"
                    echo "📍 URL: $SERVICE_URL"
                    echo ""
                    echo "🎉 部署完成！"
                    break
                else
                    echo "⏳ Cloud Run: 等待部署..."
                fi
                ;;
            "FAILURE"|"CANCELLED"|"TIMEOUT"|"INTERNAL_ERROR"|"EXPIRED")
                echo "❌ Cloud Build: 构建失败！"
                echo "   状态: $BUILD_STATUS"
                if [ -n "$BUILD_DETAIL" ]; then
                    echo "   详情: $BUILD_DETAIL"
                fi
                echo ""
                echo "📋 获取错误日志..."
                echo ""
                
                # 获取错误日志
                ERROR_LOG=$(gcloud builds log $BUILD_ID --project=$PROJECT_ID 2>&1 | tail -50)
                
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "❌ 错误日志（最后 50 行）："
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "$ERROR_LOG"
                echo ""
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo ""
                echo "📊 查看完整日志："
                echo "   gcloud builds log $BUILD_ID"
                echo ""
                echo "🌐 在控制台查看："
                echo "   $BUILD_LOG_URL"
                echo ""
                
                ERROR_DETECTED=true
                break
                ;;
            "WORKING"|"QUEUED")
                echo "🔨 Cloud Build: 构建中... ($BUILD_STATUS)"
                echo "   构建 ID: $BUILD_ID"
                echo ""
                echo "   查看实时日志:"
                echo "   gcloud builds log $BUILD_ID --stream"
                echo ""
                echo "   控制台查看:"
                echo "   $BUILD_LOG_URL"
                ;;
            *)
                echo "⚠️  Cloud Build: 未知状态 ($BUILD_STATUS)"
                ;;
        esac
    else
        echo "⚠️  无法获取构建信息"
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    sleep 30
done

if [ "$ERROR_DETECTED" = true ]; then
    echo ""
    echo "❌ 检测到构建错误！"
    echo ""
    echo "💡 常见错误和解决方案："
    echo ""
    echo "1. Dockerfile 语法错误"
    echo "   - 检查 Dockerfile 格式"
    echo "   - 确认所有命令正确"
    echo ""
    echo "2. 依赖安装失败"
    echo "   - 检查网络连接"
    echo "   - 确认包名正确"
    echo ""
    echo "3. 权限问题"
    echo "   - 检查 Cloud Build API 是否启用"
    echo "   - 确认服务账户权限"
    echo ""
    echo "4. 资源不足"
    echo "   - 检查配额限制"
    echo "   - 增加构建超时时间"
    echo ""
    exit 1
fi

echo ""
echo "✅ 监控完成"


