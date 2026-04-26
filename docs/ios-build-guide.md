# PureMD iOS 构建指南

## 前置条件

- macOS 系统（需要最新版本）
- Xcode 16+
- CocoaPods（`sudo gem install cocoapods`）

## 构建步骤

1. **安装依赖**
   ```bash
   flutter pub get
   ```

2. **进入 iOS 目录安装 Pod 依赖**
   ```bash
   cd ios
   pod install
   cd ..
   ```

3. **配置签名**

   打开 `ios/Runner.xcworkspace`，在 Xcode 中：
   - 选择 Target `Runner` → `Signing & Capabilities`
   - 选择你的 Apple 开发者 Team
   - 设置 Bundle Identifier（建议使用 `com.puremd.app`）

4. **构建 Release 版本**

   ```bash
   # 构建 IPA（需要 Apple Developer 账号）
   flutter build ios --release --no-codesign

   # 或者直接导出 Archive（推荐）
   flutter build ipa --release
   ```

5. **导出 IPA**

   构建完成后，IPA 文件位于：
   ```
   build/ios/ipa/PureMD.ipa
   ```

## 常见问题

- **CocoaPods 安装失败**：运行 `pod repo update` 后重试
- **签名错误**：确保已在 Xcode 中添加了有效的 Apple Developer 账号
- **Swift 版本不兼容**：确保 Xcode 版本 >= 16

## 发布到 App Store

使用 Xcode 的 Organizer（Window → Organizer）打开 Archive，然后选择 "Distribute App" → "App Store Connect" 上传。
