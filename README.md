<p align="center">
  <img src="assets/icon.png" alt="PureMD Logo" width="120" />
</p>

<h1 align="center">PureMD</h1>
<p align="center">
  <em>一款 Modern & Minimalist 的移动端 Markdown 阅读器</em><br>
  <em>沉浸于文字，记录每一次灵感闪光</em>
</p>

<p align="center">
  <a href="#-产品特性">✨ 特性</a> •
  <a href="#-快速启动">🚀 快速启动</a> •
  <a href="#-视觉哲学">🎨 视觉哲学</a> •
  <a href="#-技术栈">🛠️ 技术栈</a> •
  <a href="#-参与贡献">🤝 贡献</a>
</p>

---

## ✨ 产品特性

### 🚀 沉浸式阅读
- **开箱即读**：首次启动自动加载预设文档，打开 App 即进入阅读心流。
- **专注模式**：一键隐藏所有 chrome，只留下清晰的文字与柔和的背景。

### 📂 自由存取
- **深度集成系统选择器**：无障碍浏览 Android 设备中任意 `.md` 文件。
- **最近文件记忆**：智能记录最近打开的文件，方便快速返回上次未完成的阅读或编辑。

### ✍️ 灵动编辑
- **所见即所得编辑**：实时渲染的排版更符合移动端创作直觉，支持平滑切换编辑与预览状态，预览更新经防抖优化更流畅。
- **文件导出**：集成系统文件选择器，支持将笔记保存为新文件或导出为 `.md` / `.markdown` 格式。
- **快捷工具栏**：键盘上方悬浮常用 Markdown 标记（粗体、斜体、链接、列表、待办），降低符号输入成本。
- **自适应布局**：无论是竖屏专注写作，还是横屏宽广阅读，界面都能顺畅适配。

### 🖼️ 桌面组件
- **关键信息卡片**：在主屏即可查看最新笔记片段或每日提醒，无需跳转 App。
- **灵感速记组件**：点击组件瞬间启动新笔记，抓住每个转瞬即逝的想法。

### 🌓 全景适配
- **暗夜模式**：深色主题深度优化对比度与视觉保护，让夜间阅读更舒适。
- **主题个性化**：提供多套现代配色方案（纯黑 OLED、暖棕、冷灰），并支持自定义字体与字号。

---


## 🎨 视觉哲学

**Modern & Minimalist** – 我们相信工具应该退后，让创作走上前台。

- **极简主义 UI**：没有任何多余的装饰，白天的留白与夜晚的静谧，文字成为唯一的主角。
- **Material Design 3 动效**：细腻的微交互与流畅的页面过渡，让每一次滑动、点击都具有质感。
- **触觉与视觉共鸣**：按钮按压的微妙缩放、标记应用时的轻闪烁，为数字创作注入温度。

---

## 🚀 快速启动

### 环境需求
- Flutter SDK: `>=3.10.0` (推荐 3.41+)
- Dart SDK: `>=3.11.4`
- Android Studio / VS Code
- 一台 Android 设备或模拟器 (API 21+)

```bash
# 1. 克隆仓库
git clone https://github.com/For2006/PureMD.git

# 2. 进入项目目录
cd PureMD

# 3. 安装依赖
flutter pub get

# 4. 运行应用
flutter run
```

---


## 🛠️ 技术栈

| 层级 | 技术选型 |
|------|----------|
| 引擎 | Flutter 3.41+ |
| 语言 | Dart 3.11+ |
| 开发工具 | Android Studio |
| 平台 | Android (深度优化适配) |
| UI 体系 | Material Design 3 |
| Markdown 渲染 | flutter_markdown + 自定义扩展 |
| 状态管理 | Riverpod |
| 文件选择 | file_picker |

---

## 🤝 参与贡献

PureMD 期待你的反馈与贡献！无论是修复 typo、改进动画，还是实现新的组件，都欢迎：

1. **Fork** 本仓库
2. 创建特性分支：`git checkout -b feat/awesome-feature`
3. 提交更改：`git commit -m '添加某特性'`
4. 推送分支：`git push origin feat/awesome-feature`
5. 创建 **Pull Request**

也可以在 [Discussions](https://github.com/For2006/PureMD/discussions) 中分享你的使用场景或设计灵感。

---

## 📄 许可证

本项目基于 [MIT License](https://opensource.org/licenses/MIT) 开源。

---
<p align="center">
  <small>Made with ❤️ by <a href="https://github.com/For2006">For2006</a> and the PureMD community</small>
</p>
