# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

Focus 是一款基于神经科学研究的 macOS 专注计时器应用，采用随机微休息提醒系统。应用基于 SwiftUI + MVVM 架构构建，支持状态栏运行模式。

## 核心架构

### 单例模式和状态管理
- `TimerManager.shared`: 核心单例，管理所有计时逻辑、设置和数据持久化
- 使用 `@Published` 属性和 `ObservableObject` 协议实现响应式状态管理
- 通过 `NotificationCenter` 处理跨组件通信

### 主要组件关系
```
FocusApp (应用入口)
├── AppDelegate (应用级事件处理)
│   ├── StatusBarController (菜单栏管理)
│   ├── BlackoutWindowController (全屏黑屏功能)
│   └── VideoControlManager (媒体控制)
├── ContentView (主界面)
├── SettingsView (设置界面)
├── StatisticsView (统计界面)
└── TimerManager (核心状态管理)
```

### 数据模型
- `FocusSession`: 专注会话记录，支持详细统计
- `SoundType`: 音效类型枚举，支持多种系统声音
- 使用 UserDefaults 进行设置持久化，JSON 编码存储复杂数据

## 常用开发命令

### 构建和运行
```bash
# 构建项目
xcodebuild -project Focus.xcodeproj -scheme Focus -configuration Debug build

# 构建 Release 版本
xcodebuild -project Focus.xcodeproj -scheme Focus -configuration Release build

# 清理构建
xcodebuild -project Focus.xcodeproj -scheme Focus clean
```

### 测试
```bash
# 运行所有测试
xcodebuild test -project Focus.xcodeproj -scheme Focus -destination 'platform=macOS'

# 运行单元测试
xcodebuild test -project Focus.xcodeproj -scheme Focus -destination 'platform=macOS' -only-testing:FocusTests

# 运行UI测试
xcodebuild test -project Focus.xcodeproj -scheme Focus -destination 'platform=macOS' -only-testing:FocusUITests
```

### 代码分析
```bash
# 检查代码风格和潜在问题
xcodebuild analyze -project Focus.xcodeproj -scheme Focus
```

## 关键特性实现

### 随机微休息系统
- 核心实现在 `TimerManager.startPromptTimer()`
- 使用两个 Timer：主提示音计时器和微休息结束计时器
- 支持自定义音效和黑屏强制休息

### 通知系统
- 使用 `NotificationCenter` 管理应用内通知
- 通过 `UNUserNotificationCenter` 发送系统通知
- 自动请求和管理通知权限

### 数据统计
- `StatisticsManager` 处理专注数据分析
- 支持日/周/月/年多时间段统计
- 使用 `FocusSession` 模型存储详细会话信息

## 开发注意事项

### 权限管理
- 应用需要通知权限才能发送微休息提醒
- 媒体控制功能需要辅助功能权限
- 权限检查和请求逻辑在 `AppDelegate` 中处理

### 音频系统
- 预加载系统音效到 `audioPlayers` 字典
- 支持多种音效类型，包括"无声音"选项
- 使用 `AudioServicesPlaySystemSound` 作为备选方案

### 状态同步
- 主窗口、状态栏、黑屏窗口需要保持状态同步
- 使用 NotificationCenter 发送状态变更通知
- 重要通知：`.timerUpdated`、`.timerStateChanged`、`.timerModeChanged`

### macOS 特性
- 支持暗色/亮色主题自动切换
- 状态栏应用模式，可在后台运行
- 窗口大小固定为 320x490，不可调整

## 测试策略

项目包含多个测试模块：
- `FocusTests`: 基础单元测试
- `TimerManagerIntervalValidationTests`: 计时器间隔验证
- `StatisticsTests`: 统计功能测试
- `MicroBreakNotificationTests`: 微休息通知测试
- `NotificationIntegrationTests`: 通知集成测试
- `FocusUITests`: UI自动化测试

### 测试使用 Swift Testing 框架
- 使用 `@Test` 注解标记测试方法
- 使用 `#expect(...)` 进行断言检查
- 测试目标为 macOS 平台

## 版本要求

- macOS 14.1+
- Xcode 16.1+
- Swift 5.0+
- 支持 Intel 和 Apple Silicon 芯片