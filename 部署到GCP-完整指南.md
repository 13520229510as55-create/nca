# 🚀 NCA 中文字体版 - 部署到 Google Cloud Run 完整指南

支持多种中文字体的 NCA Toolkit，可部署到 Google Cloud Run。

---

## 📋 前置要求

### 1. 安装 Google Cloud SDK (gcloud)

如果尚未安装：

**Mac (Homebrew):**
```bash
brew install --cask google-cloud-sdk
```

**或从官网下载：**
- https://cloud.google.com/sdk/docs/install

### 2. 登录并配置

```bash
# 登录 Google 账号
gcloud auth login

# 设置默认项目（可选）
gcloud config set project gen-lang-client-0960629066
```

### 3. 所需凭证/信息

| 项目 | 说明 | 您需要准备 |
|-----|------|-----------|
| **GCP 项目** | 项目 ID | `gen-lang-client-0960629066` |
| **GCS Bucket** | 存储桶名称 | `n8n-test-3344` |
| **Service Account** | 服务账号 | `nca-test@gen-lang-client-0960629066.iam.gserviceaccount.com` |
| **API Key** | NCA 接口认证 | 自定义（如 `123`）|

---

## 🚀 方式一：一键部署（推荐）

```bash
cd /Users/a58/Downloads/no-code-architects-toolkit
chmod +x deploy-一键部署.sh
./deploy-一键部署.sh
```

**预计时间：** 30-50 分钟（首次构建包含 FFmpeg 编译）

---

## 🔧 方式二：分步部署

### 步骤 1：Cloud Build 构建

```bash
cd /Users/a58/Downloads/no-code-architects-toolkit
gcloud config set project gen-lang-client-0960629066
gcloud builds submit --config=cloudbuild.yaml --timeout=7200
```

### 步骤 2：配置 GCP 凭证

部署完成后，NCA 需要 `GCP_SA_CREDENTIALS` 才能将处理结果上传到 GCS：

```bash
./更新GCP凭证.sh
```

---

## ⚙️ 自定义配置

通过环境变量覆盖默认配置：

```bash
export GCP_PROJECT_ID="您的项目ID"
export GCP_REGION="us-central1"        # 或 asia-east1
export NCA_API_KEY="您的API密钥"
export GCP_BUCKET_NAME="您的桶名称"
./deploy-一键部署.sh
```

---

## 📦 项目已包含的中文字体

| 字体名称 | 说明 |
|---------|------|
| **Noto Sans SC** | 简体中文（推荐）|
| **Noto Sans TC** | 繁体中文 |
| **WenQuanYi Zen Hei** | 文泉驿正黑 |
| **WenQuanYi Micro Hei** | 文泉驿微米黑 |

自定义字体目录 `fonts/` 还包含 NotoSansTC 系列等 70+ 种字体。

---

## 🧪 部署后验证

```bash
# 获取服务 URL
SERVICE_URL=$(gcloud run services describe nca-toolkit-chinese --region=us-central1 --format="value(status.url)")
echo $SERVICE_URL

# 测试 API
curl -X POST "${SERVICE_URL}/v1/toolkit/test" -H "x-api-key: 123"
```

---

## ⚠️ 若提示需要凭证

如果部署时遇到 `GCP_SA_CREDENTIALS` 相关错误：

1. **确认 Service Account 存在：**
   ```bash
   gcloud iam service-accounts list --project=gen-lang-client-0960629066
   ```

2. **确认您有权限创建密钥：**
   ```bash
   ./更新GCP凭证.sh
   ```

3. **或手动添加凭证：**
   - 在 GCP Console → IAM → Service Accounts
   - 选择 `nca-test` → Keys → Add Key → Create new key → JSON
   - 下载后在 Cloud Run 服务中设置环境变量 `GCP_SA_CREDENTIALS` 为 JSON 全文

---

## 📚 相关文件

- `cloudbuild.yaml` - Cloud Build 配置
- `deploy-一键部署.sh` - 一键部署脚本
- `更新GCP凭证.sh` - 凭证更新脚本
- `Dockerfile` - 已包含中文字体安装

---

**部署目录：** `/Users/a58/Downloads/no-code-architects-toolkit/`
