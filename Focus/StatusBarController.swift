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
    private var window: NSWindow?
    private var timerManager: TimerManager
    private var cancellables = Set<AnyCancellable>()
    private var statusBarView: StatusBarView?
    private var soundPlayer: NSSound?

    init() {
        statusBar = NSStatusBar.system
        statusItem = statusBar.statusItem(withLength: 52)

        // 获取TimerManager实例
        timerManager = TimerManager.shared

        // 创建主窗口
        let contentView = ContentView()
            .environmentObject(timerManager)  // 注入 TimerManager 环境对象
        let hostingView = NSHostingView(rootView: contentView)
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window?.contentView = hostingView
        window?.title = "Focus"
        window?.center()
        window?.isReleasedWhenClosed = false

        // 创建并设置自定义视图
        if let button = statusItem.button {
            let frame = NSRect(x: 0, y: 0, width: 52, height: button.frame.height)
            statusBarView = StatusBarView(
                frame: frame,
                text: timerManager.timeString,
                textColor: NSColor.black
            )
            button.subviews.forEach { $0.removeFromSuperview() }
            button.addSubview(statusBarView!)
        }

        // 设置菜单栏项的初始文本
        updateStatusBarText()

        // 设置菜单栏项的点击事件
        if let button = statusItem.button {
            button.action = #selector(toggleWindow(_:))
            button.target = self
        }

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
        let textColor = NSColor.black // 使用黑色文本，不受模式影响

        // 在主线程上更新UI
        DispatchQueue.main.async { [weak self] in
            // 更新自定义视图
            self?.statusBarView?.update(text: text, textColor: textColor)

            // 确保视图重绘
            self?.statusBarView?.needsDisplay = true
        }
    }

    // 切换窗口的显示状态
    @objc private func toggleWindow(_ sender: AnyObject?) {
        if let window = window {
            if window.isVisible {
                window.close()
            } else {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}
