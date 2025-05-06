//
//  StatusBarController.swift
//  Focus
//
//  Created by 杨乾巍 on 2025/4/28.
//

import AppKit
import SwiftUI
import Combine

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
        
        // 根据设置决定是否创建状态栏图标
        if timerManager.showStatusBarIcon {
            statusItem = statusBar.statusItem(withLength: 52)
            
            // 创建并设置自定义视图
            if let button = statusItem.button {
                let frame = NSRect(x: 0, y: 0, width: 52, height: button.frame.height)
                statusBarView = StatusBarView(
                    frame: frame,
                    text: timerManager.timeString,
                    textColor: NSColor.white
                )
                button.subviews.forEach { $0.removeFromSuperview() }
                button.addSubview(statusBarView!)
                
                // 设置菜单栏项的点击事件
                button.action = #selector(toggleMainWindow(_:))
                button.target = self
            }
            
            // 设置菜单栏项的初始文本
            updateStatusBarText()
        } else {
            // 如果设置为不显示图标，则创建一个长度为0的空状态栏项
            statusItem = statusBar.statusItem(withLength: 0)
        }

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
    }

    @objc private func applicationWillBecomeActive(_ notification: Notification) {
        // 应用程序即将变为活跃状态，根据设置确保状态栏项存在
        if timerManager.showStatusBarIcon {
            // 检查statusItem是否有效，如果无效或长度为0则重新创建
            if statusItem.length == 0 {
                // 创建新的状态栏项
                statusItem = statusBar.statusItem(withLength: 52)
                
                // 重新设置自定义视图
                if let button = statusItem.button {
                    let frame = NSRect(x: 0, y: 0, width: 52, height: button.frame.height)
                    statusBarView = StatusBarView(
                        frame: frame,
                        text: timerManager.timeString,
                        textColor: NSColor.white
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
    
    @objc private func applicationDidResignActive(_ notification: Notification) {
        // 应用程序失去活跃状态，记录状态
        // 这里不做任何操作，但保留方法以便将来可能的扩展
    }

    @objc private func applicationDidFinishLaunching(_ notification: Notification) {
        // 找到并存储主窗口控制器
        if let mainWindow = findMainWindow() {
            mainWindowController = NSWindowController(window: mainWindow)
        }
    }
    
    // 查找主窗口的辅助方法
    private func findMainWindow() -> NSWindow? {
        // 查找标题不为空且不是状态栏相关窗口的窗口
        return NSApp.windows.first(where: { window in
            // 状态栏窗口通常很小且位于屏幕顶部
            let isStatusBarRelated = window.frame.height < 30 && 
                                     window.frame.origin.y > NSScreen.main?.frame.height ?? 0 - 30
            
            // 主窗口通常有标题且不是状态栏相关窗口
            return !window.title.isEmpty && !isStatusBarRelated
        })
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
        let textColor = NSColor.white // 使用白色文本，确保在深色模式下可见

        // 在主线程上更新UI
        DispatchQueue.main.async { [weak self] in
            // 更新自定义视图
            self?.statusBarView?.update(text: text, textColor: textColor)

            // 确保视图重绘
            self?.statusBarView?.needsDisplay = true
        }
    }

    // 切换主窗口的显示状态
    @objc private func toggleMainWindow(_ sender: AnyObject?) {
        // 这里不要立即激活应用程序，可能会导致状态栏图标消失
        
        // 查找主窗口
        if mainWindowController?.window == nil {
            if let mainWindow = findMainWindow() {
                mainWindowController = NSWindowController(window: mainWindow)
            }
        }
        
        if let windowController = mainWindowController {
            if let window = windowController.window, window.isVisible {
                // 如果窗口可见，先隐藏窗口
                window.orderOut(nil)
                // 然后确保应用程序保持运行状态
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NSApp.setActivationPolicy(.accessory)
                }
            } else {
                // 如果窗口不可见，先设置应用程序为常规应用，再显示窗口
                NSApp.setActivationPolicy(.regular)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    windowController.showWindow(nil)
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        } else {
            // 如果没有找到主窗口，尝试恢复应用程序状态
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            print("未找到主窗口，请确保应用程序已正确启动")
        }
    }

    // 更新状态栏图标的可见性
    private func updateStatusBarVisibility() {
        if timerManager.showStatusBarIcon {
            if statusItem.length == 0 {
                // 创建新的状态栏项
                statusItem = statusBar.statusItem(withLength: 52)
                
                // 重新创建并设置自定义视图
                if let button = statusItem.button {
                    let frame = NSRect(x: 0, y: 0, width: 52, height: button.frame.height)
                    statusBarView = StatusBarView(
                        frame: frame,
                        text: timerManager.timeString,
                        textColor: NSColor.white
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
        } else {
            // 完全移除状态栏项而不是设置长度为0
            statusBar.removeStatusItem(statusItem)
            // 重新创建一个空的状态栏项，以便后续可以恢复
            statusItem = statusBar.statusItem(withLength: 0)
        }
    }
}
