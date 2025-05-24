//
//  StatusBarController.swift
//  Focus
//
//  Created by 杨乾巍 on 2025/4/28.
//

import AppKit
import SwiftUI
import Combine
import Foundation

class StatusBarController {
    private var statusBar: NSStatusBar
    private var statusItem: NSStatusItem
    private var timerManager: TimerManager
    private var cancellables = Set<AnyCancellable>()
    private var statusBarView: StatusBarView?
    private var soundPlayer: NSSound?
    private var mainWindowController: NSWindowController?

    init() {
        statusBar = NSStatusBar.system
        
        // 获取TimerManager实例
        timerManager = TimerManager.shared
        
        // 作为纯菜单栏应用，状态栏图标必须始终存在
        statusItem = statusBar.statusItem(withLength: 40)
        
        // 创建并设置自定义视图
        if let button = statusItem.button {
            let frame = NSRect(x: 0, y: 0, width: 40, height: button.frame.height)
            statusBarView = StatusBarView(
                frame: frame,
                text: timerManager.timeString,
                textColor: NSColor.controlTextColor
            )
            button.subviews.forEach { $0.removeFromSuperview() }
            button.addSubview(statusBarView!)
            
            // 设置菜单栏项的点击事件
            button.action = #selector(toggleMainWindow(_:))
            button.target = self
        }
        
        // 设置菜单栏项的初始文本
        updateStatusBarText()

        // 确保应用程序不会在所有窗口关闭时退出
        NSApp.setActivationPolicy(.accessory)
        
        // 添加应用程序生命周期相关通知观察者
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillBecomeActive(_:)),
            name: NSApplication.willBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidResignActive(_:)),
            name: NSApplication.didResignActiveNotification,
            object: nil
        )

        // 监听应用程序启动完成通知，以便在启动后获取主窗口控制器
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidFinishLaunching(_:)),
            name: NSApplication.didFinishLaunchingNotification,
            object: nil
        )

        // 订阅TimerManager的通知
        NotificationCenter.default.publisher(for: .timerUpdated)
            .sink { [weak self] _ in
                self?.updateStatusBarText()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .timerStateChanged)
            .sink { [weak self] _ in
                self?.updateStatusBarText()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .timerModeChanged)
            .sink { [weak self] _ in
                self?.updateStatusBarText()
            }
            .store(in: &cancellables)

        // 监听开始声音通知
        NotificationCenter.default.publisher(for: .playStartSound)
            .sink { [weak self] notification in
                self?.playSound(named: "Glass")
            }
            .store(in: &cancellables)

        // 监听结束声音通知
        NotificationCenter.default.publisher(for: .playEndSound)
            .sink { [weak self] notification in
                self?.playSound(named: "Funk")
            }
            .store(in: &cancellables)

        // 监听随机提示音通知
        NotificationCenter.default.publisher(for: .playPromptSound)
            .sink { [weak self] notification in
                self?.playSound(named: "Blow")
            }
            .store(in: &cancellables)

        // 监听状态栏图标可见性更改通知
        NotificationCenter.default.publisher(for: .statusBarIconVisibilityChanged)
            .sink { [weak self] _ in
                self?.updateStatusBarVisibility()
            }
            .store(in: &cancellables)

        // 监听系统外观变化
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.updateStatusBarText()
            }
            .store(in: &cancellables)
            
        // 监听系统外观模式变化（深色/浅色模式切换）
        DistributedNotificationCenter.default().publisher(for: Notification.Name("AppleInterfaceThemeChangedNotification"))
            .sink { [weak self] _ in
                self?.updateStatusBarText()
            }
            .store(in: &cancellables)
    }

    @objc private func applicationWillBecomeActive(_ notification: Notification) {
        // 应用程序即将变为活跃状态，确保状态栏项始终存在
        // 检查statusItem是否有效，如果无效或长度为0则重新创建
        if statusItem.length == 0 {
            // 创建新的状态栏项
            statusItem = statusBar.statusItem(withLength: 40)
            
            // 重新设置自定义视图
            if let button = statusItem.button {
                let frame = NSRect(x: 0, y: 0, width: 40, height: button.frame.height)
                statusBarView = StatusBarView(
                    frame: frame,
                    text: timerManager.timeString,
                    textColor: NSColor.controlTextColor
                )
                button.subviews.forEach { $0.removeFromSuperview() }
                button.addSubview(statusBarView!)
                
                // 重新设置点击事件
                button.action = #selector(toggleMainWindow(_:))
                button.target = self
            }
            
            // 更新状态栏文本
            updateStatusBarText()
        }
    }
    
    @objc private func applicationDidResignActive(_ notification: Notification) {
        // 应用程序失去活跃状态，记录状态
        // 这里不做任何操作，但保留方法以便将来可能的扩展
    }

    @objc private func applicationDidFinishLaunching(_ notification: Notification) {
        // 找到并存储主窗口控制器
        print("应用启动完成，查找主窗口")
        if let mainWindow = findMainWindow() {
            mainWindowController = NSWindowController(window: mainWindow)
            print("应用启动时成功找到主窗口")
        } else {
            print("应用启动时未找到主窗口，稍后重试")
            // 延迟再次尝试
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if let delayedWindow = self.findMainWindow() {
                    self.mainWindowController = NSWindowController(window: delayedWindow)
                    print("延迟查找成功找到主窗口")
                }
            }
        }
    }
    
    // 查找主窗口的辅助方法
    private func findMainWindow() -> NSWindow? {
        print("开始查找主窗口，当前窗口数量: \(NSApp.windows.count)")
        
        // 优先查找 ContentView 相关的窗口
        let mainWindow = NSApp.windows.first { window in
            // 检查窗口是否包含 Focus 应用的主要内容
            let hasContentView = window.contentViewController != nil
            let isReasonableSize = window.frame.width > 250 && window.frame.height > 400
            let isNotStatusBar = window.frame.height > 100
            
            print("检查窗口: 尺寸=\(window.frame), 有内容=\(hasContentView), 合理尺寸=\(isReasonableSize)")
            
            return hasContentView && isReasonableSize && isNotStatusBar
        }
        
        if let foundWindow = mainWindow {
            print("找到主窗口: \(foundWindow)")
            return foundWindow
        }
        
        // 如果没有找到，尝试查找任何非状态栏相关的窗口
        let fallbackWindow = NSApp.windows.first { window in
            let isStatusBarRelated = window.frame.height < 100 || 
                                     window.frame.width < 200
            let isReasonable = !isStatusBarRelated
            
            print("回退检查窗口: 尺寸=\(window.frame), 非状态栏=\(isReasonable)")
            
            return isReasonable
        }
        
        if let foundWindow = fallbackWindow {
            print("找到回退窗口: \(foundWindow)")
            return foundWindow
        }
        
        print("未找到任何合适的窗口")
        return nil
    }

    // 播放声音的辅助函数
    private func playSound(named soundName: String) {
        print("尝试播放声音: \(soundName)")
        
        // 确保在主线程播放声音
        DispatchQueue.main.async {
            // 尝试作为系统声音播放
            if let systemSound = NSSound(named: soundName) {
                print("找到系统声音: \(soundName)")
                // 停止当前可能正在播放的声音，以防重叠
                self.soundPlayer?.stop()
                self.soundPlayer = systemSound
                self.soundPlayer?.volume = 1.0 // 确保音量足够
                self.soundPlayer?.play()
                print("开始播放声音: \(soundName)")
            } else {
                print("错误：未找到系统声音: \(soundName)")
                
                // 尝试播放后备声音
                let backupSounds = ["Ping", "Tink", "Bottle", "Glass", "Hero", "Pop", "Blow", "Submarine", "Funk"]
                
                for backupSound in backupSounds {
                    if let sound = NSSound(named: backupSound) {
                        print("使用后备声音: \(backupSound)")
                        self.soundPlayer?.stop()
                        self.soundPlayer = sound
                        self.soundPlayer?.volume = 1.0
                        self.soundPlayer?.play()
                        break // 找到可用声音后退出循环
                    }
                }
            }
        }
    }

    // 更新菜单栏项的文本
    private func updateStatusBarText() {
        let text = timerManager.statusBarText
        // 每次更新时获取当前的系统控件文本颜色
        let textColor = NSColor.controlTextColor

        // 在主线程上更新UI
        DispatchQueue.main.async { [weak self] in
            // 更新自定义视图
            self?.statusBarView?.update(text: text, textColor: textColor)

            // 确保视图重绘
            self?.statusBarView?.needsDisplay = true
            
            // 强制刷新状态栏按钮
            if let button = self?.statusItem.button {
                button.needsDisplay = true
            }
        }
    }

    // 切换主窗口的显示状态
    @objc private func toggleMainWindow(_ sender: AnyObject?) {
        print("切换主窗口被调用")
        
        // 确保获取最新的主窗口
        if let mainWindow = findMainWindow() {
            mainWindowController = NSWindowController(window: mainWindow)
            print("成功找到并设置主窗口控制器")
        } else {
            print("未找到主窗口，尝试创建新窗口")
        }
        
        guard let windowController = mainWindowController,
              let window = windowController.window else {
            // 如果没有找到主窗口，创建一个新的
            print("窗口控制器不存在，调用创建方法")
            createAndShowMainWindow()
            return
        }
        
        // 判断窗口是否可见和活跃
        let isWindowVisible = window.isVisible && !window.isMiniaturized
        let isWindowActive = window.isKeyWindow || window.isMainWindow
        
        print("窗口状态: 可见=\(isWindowVisible), 活跃=\(isWindowActive), 应用活跃=\(NSApp.isActive)")
        
        if isWindowVisible && (isWindowActive || NSApp.isActive) {
            // 窗口可见且应用处于活跃状态，隐藏窗口
            print("隐藏窗口")
            hideMainWindow(window: window)
        } else {
            // 窗口不可见或应用不活跃，显示窗口
            print("显示窗口")
            showMainWindow(windowController: windowController)
        }
    }
    
    // 显示主窗口
    private func showMainWindow(windowController: NSWindowController) {
        // 保持为菜单栏应用，不切换到regular模式
        DispatchQueue.main.async {
            windowController.showWindow(nil)
            
            // 确保窗口出现在最前面
            if let window = windowController.window {
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
                // 将窗口设置为浮动窗口类型，确保它能在菜单栏应用模式下显示
                window.level = .floating
            }
            
            // 激活应用程序
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    // 隐藏主窗口
    private func hideMainWindow(window: NSWindow) {
        window.orderOut(nil)
        
        // 保持为菜单栏应用，不需要设置激活策略
        // 应用始终保持为accessory模式
    }
    
    // 创建并显示主窗口（备用方案）
    private func createAndShowMainWindow() {
        print("尝试创建并显示主窗口")
        
        // 保持为菜单栏应用
        NSApp.activate(ignoringOtherApps: true)
        
        // 尝试创建新窗口或恢复现有窗口
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // 再次尝试查找主窗口
            if let window = self.findMainWindow() {
                print("延迟查找成功找到主窗口")
                self.mainWindowController = NSWindowController(window: window)
                window.makeKeyAndOrderFront(nil)
                // 设置为浮动窗口
                window.level = .floating
                window.orderFrontRegardless()
                print("主窗口已显示")
            } else {
                print("警告：无法找到主窗口")
                // 尝试通过应用程序菜单强制显示窗口
                if NSApp.mainMenu != nil {
                    print("尝试通过主菜单激活窗口")
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }
    }

    // 更新状态栏图标的可见性（纯菜单栏应用保持图标始终可见）
    private func updateStatusBarVisibility() {
        // 作为纯菜单栏应用，状态栏图标必须始终可见
        // 如果不存在，则创建
        if statusItem.length == 0 {
            // 创建新的状态栏项
            statusItem = statusBar.statusItem(withLength: 40)
            
            // 重新创建并设置自定义视图
            if let button = statusItem.button {
                let frame = NSRect(x: 0, y: 0, width: 40, height: button.frame.height)
                statusBarView = StatusBarView(
                    frame: frame,
                    text: timerManager.timeString,
                    textColor: NSColor.controlTextColor
                )
                button.subviews.forEach { $0.removeFromSuperview() }
                button.addSubview(statusBarView!)
                
                // 重新设置点击事件
                button.action = #selector(toggleMainWindow(_:))
                button.target = self
            }
            
            // 更新状态栏文本
            updateStatusBarText()
        }
    }
}
