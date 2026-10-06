# DeepSeekChat — iOS 聊天 App

SwiftUI 写的 DeepSeek 聊天客户端，界面仿 Muse iOS 端：对话列表、搜索、流式回复、设置页。

## 功能
- 对话列表（新建 / 删除 / 搜索）
- 流式输出（SSE）
- 模型切换：DeepSeek V3 / DeepSeek R1
- API Key 保存在系统钥匙串，不上传
- 聊天记录保存在本机

## 自己编译出 ipa（无 Mac 版，全程手机可操作）

### 1. 准备
- 注册一个 GitHub 账号（免费）
- iPhone 上装 **Working Copy**（Git 客户端，App Store 免费）

### 2. 传代码到 GitHub
1. 在 GitHub 网页/App 上新建一个仓库（Repository），名字随便，如 `deepseek-chat-ios`
2. 打开 Working Copy，克隆（Clone）这个空仓库
3. 把本项目的全部文件拷进仓库目录（DeepSeekChat/、DeepSeekChat.xcodeproj/、.github/）
4. Commit 并 Push

### 3. 云编译
1. 打开 GitHub 仓库页面 → **Actions** 标签页
2. 点 **Build unsigned IPA** → **Run workflow**（或 push 代码后自动触发）
3. 等几分钟构建完成 → 点进那次运行 → 底部 **Artifacts** 下载 `DeepSeekChat-unsigned-ipa`
4. 解压得到 `DeepSeekChat-unsigned.ipa`（未签名）

### 4. 签名安装（用全能签）
1. 把未签名的 ipa 导入全能签
2. 签名后安装到手机
3. 打开 App → 左上角齿轮 → 填写 DeepSeek API Key → 验证通过 → 开始聊天

## 注意
- 全能签用的证书苹果会不定期封，掉了要重签重装
- Bundle ID：`com.myapp.deepseekchat`，如需修改在 `DeepSeekChat.xcodeproj/project.pbxproj` 里搜 `PRODUCT_BUNDLE_IDENTIFIER`
- 最低支持 iOS 17
