# miniprogram-ci 配置与 CI/CD 集成

## 前置条件

1. 在微信公众平台生成上传密钥：`开发 → 开发管理 → 小程序代码上传密钥`
2. 密钥文件保存为 `deploy/miniprogram-private.key`（加入 .gitignore）
3. 开启 IP 白名单 或 关闭 IP 白名单（CI 服务器 IP 不固定时需关闭）

## 安装依赖

```bash
pnpm add -D miniprogram-ci
```

## 基础脚本（deploy/miniprogram-ci.js）

```js
const ci = require('miniprogram-ci')
const path = require('path')

const APPS = {
  'customer-app': {
    appid: process.env.CUSTOMER_APPID,
    projectPath: path.resolve(__dirname, '../packages/customer-app/dist'),
  },
  'merchant-app': {
    appid: process.env.MERCHANT_APPID,
    projectPath: path.resolve(__dirname, '../packages/merchant-app/dist'),
  },
}

async function main() {
  const [, , command, ...args] = process.argv
  const appName = args.find((a) => a.startsWith('--app='))?.split('=')[1]
  const version = args.find((a) => a.startsWith('--version='))?.split('=')[1] || '1.0.0'
  const desc = args.find((a) => a.startsWith('--desc='))?.split('=')[1] || ''

  if (!appName || !APPS[appName]) {
    console.error(`未知应用: ${appName}，可选: ${Object.keys(APPS).join(', ')}`)
    process.exit(1)
  }

  const { appid, projectPath } = APPS[appName]
  const project = new ci.Project({
    appid,
    type: 'miniProgram',
    projectPath,
    privateKeyPath: path.resolve(__dirname, 'miniprogram-private.key'),
    ignores: ['node_modules/**/*'],
  })

  if (command === 'preview') {
    const result = await ci.preview({
      project,
      desc,
      setting: { minify: false },
      qrcodeFormat: 'image',
      qrcodeOutputDest: path.resolve(__dirname, `${appName}-preview-qrcode.jpg`),
    })
    console.log(`预览二维码已生成: deploy/${appName}-preview-qrcode.jpg`)
    console.log(result)
  } else if (command === 'upload') {
    const result = await ci.upload({
      project,
      version,
      desc,
      setting: { minify: true, autoPrefixWXSS: true },
      onProgressUpdate: (task) => {
        if (task._percent) process.stdout.write(`\r上传进度: ${Math.floor(task._percent * 100)}%`)
      },
    })
    console.log(`\n上传成功 v${version}`)
    console.log(result)
  } else {
    console.error('未知命令，支持: preview | upload')
    process.exit(1)
  }
}

main().catch((e) => {
  console.error('miniprogram-ci 执行失败:', e)
  process.exit(1)
})
```

## 使用方式

```bash
# 预览（扫码调试体验版）
node deploy/miniprogram-ci.js preview --app=customer-app --desc="新功能测试"

# 上传体验版（需在微信公众平台将该版本设为体验版）
node deploy/miniprogram-ci.js upload --app=customer-app --version=1.2.0 --desc="新增代付功能"
```

## GitHub Actions 集成

```yaml
# .github/workflows/miniprogram-ci.yml
name: 小程序自动发布

on:
  push:
    branches: [main]
    paths:
      - 'packages/customer-app/**'
      - 'packages/merchant-app/**'

jobs:
  upload-miniprogram:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: pnpm/action-setup@v4
        with:
          version: 9

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'

      - name: 安装依赖
        run: pnpm install --frozen-lockfile

      - name: 构建消费者小程序
        run: pnpm --filter customer-app build:weapp
        env:
          TARO_APP_API_BASE_URL: ${{ secrets.API_BASE_URL }}

      - name: 上传消费者小程序
        run: node deploy/miniprogram-ci.js upload --app=customer-app --version=${{ github.sha }} --desc="CI 自动构建 ${{ github.sha }}"
        env:
          CUSTOMER_APPID: ${{ secrets.CUSTOMER_APPID }}
          MERCHANT_APPID: ${{ secrets.MERCHANT_APPID }}
```

## 环境变量配置

在 GitHub Secrets 中配置：
- `CUSTOMER_APPID` — 消费者小程序 AppID
- `MERCHANT_APPID` — 买手小程序 AppID
- `API_BASE_URL` — 后端 API 地址

上传密钥通过 `deploy/miniprogram-private.key` 文件传入，在 CI 中可通过：
```yaml
- name: 写入上传密钥
  run: echo "${{ secrets.MINIPROGRAM_PRIVATE_KEY }}" > deploy/miniprogram-private.key
```

## 常见问题

| 错误 | 原因 | 解决 |
|------|------|------|
| `errCode: -1` | IP 未在白名单 | 微信后台关闭 IP 白名单 或 添加 CI 服务器 IP |
| `errCode: 87014` | 包体积超限 | 检查主包 < 2MB，运行 `pnpm build` 后查看 dist 大小 |
| `errCode: 80051` | 版本号格式错误 | 必须是 `x.y.z` 格式，如 `1.2.0` |
| `invalid key` | 密钥文件路径错误 | 检查 `deploy/miniprogram-private.key` 是否存在 |
