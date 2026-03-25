#!/bin/bash

# 更新 Cloud Run 服务的 GCP 凭证

PROJECT_ID="gen-lang-client-0960629066"
REGION="us-central1"
SERVICE_NAME="nca-toolkit-chinese"
SERVICE_ACCOUNT="nca-test@gen-lang-client-0960629066.iam.gserviceaccount.com"

echo "🔧 更新 Cloud Run 服务的 GCP 凭证..."
echo ""

# 创建密钥
KEY_FILE="/tmp/nca-sa-key-$$.json"
echo "📋 创建 Service Account 密钥..."
gcloud iam service-accounts keys create $KEY_FILE \
  --iam-account=$SERVICE_ACCOUNT \
  --project=$PROJECT_ID

if [ ! -f "$KEY_FILE" ]; then
    echo "❌ 无法创建密钥文件"
    exit 1
fi

echo "✅ 密钥文件已创建"
echo ""

# 读取 JSON 并转换为单行
SA_JSON=$(cat $KEY_FILE | tr -d '\n' | sed 's/"/\\"/g')

echo "📋 更新 Cloud Run 服务..."
echo "   这可能需要几分钟..."

# 使用 Python 来正确格式化 JSON 字符串
python3 << PYEOF
import subprocess
import json
import sys

# 读取密钥文件
with open('$KEY_FILE', 'r') as f:
    sa_data = json.load(f)

# 将 JSON 转换为字符串
sa_json_str = json.dumps(sa_data)

# 构建 gcloud 命令
cmd = [
    'gcloud', 'run', 'services', 'update', '$SERVICE_NAME',
    '--region', '$REGION',
    '--project', '$PROJECT_ID',
    '--update-env-vars', f'GCP_SA_CREDENTIALS={sa_json_str}'
]

# 执行命令
result = subprocess.run(cmd, capture_output=True, text=True)
print(result.stdout)
if result.stderr:
    print(result.stderr, file=sys.stderr)
sys.exit(result.returncode)
PYEOF

UPDATE_RESULT=$?

# 清理
rm -f $KEY_FILE

if [ $UPDATE_RESULT -eq 0 ]; then
    echo ""
    echo "✅ 服务已更新！"
    echo ""
    echo "🧪 等待服务重启（10秒）..."
    sleep 10
    echo ""
    echo "测试服务..."
    curl -s -H "x-api-key: 123" "https://nca-toolkit-chinese-67158488565.us-central1.run.app/v1/toolkit/test" | head -c 200
    echo ""
else
    echo ""
    echo "❌ 更新失败"
    exit 1
fi


