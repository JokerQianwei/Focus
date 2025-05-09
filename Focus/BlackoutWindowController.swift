//
//  BlackoutWindowController.swift
//  Focus
//
//  Created by 杨乾巍 on 2025/5/9.
//

import Cocoa
import SwiftUI

class BlackoutWindowController: NSWindowController {
    // 单例模式
    static let shared = BlackoutWindowController()
    
    private let timerManager = TimerManager.shared
    private var countdownTimer: Timer?
    
    // 黑屏窗口状态
    private var isActive = false
    
    // 存储额外的黑屏窗口
    private var blackoutWindows: [NSWindow] = []
    
    // 记录开始时间
    private var startTime: TimeInterval = 0
    
    // 初始化方法
    private override init(window: NSWindow?) {
        // 创建全屏黑色窗口
        let customWindow = NSWindow(
            contentRect: NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // 设置窗口属性
        customWindow.backgroundColor = .black
        customWindow.isOpaque = true
        customWindow.hasShadow = false
        customWindow.level = .screenSaver // 使窗口保持在很高层级，但允许系统菜单仍可交互
        customWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        customWindow.isReleasedWhenClosed = false
        customWindow.ignoresMouseEvents = false // 允许鼠标事件以便点击跳过按钮
        
        // 先完成基本的初始化
        super.init(window: customWindow)
        
        // 在super.init之后设置内容视图
        setupContentView()
        
        // 注册观察者，接收显示和隐藏通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showBlackoutWindow),
            name: .showBlackout,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hideBlackoutWindow),
            name: .hideBlackout,
            object: nil
        )
    }
    
    // 设置内容视图的辅助方法
    private func setupContentView() {
        let countdownView = BlackoutCountdownView(
            onSkip: { self.hideBlackoutWindow() }
        )
        
        let hostingController = NSHostingController(rootView: countdownView)
        window?.contentView = hostingController.view
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopCountdownTimer()
    }
    
    // 显示黑屏窗口
    @objc func showBlackoutWindow() {
        guard !isActive, timerManager.blackoutEnabled else { return }
        
        isActive = true
        
        // 为每个屏幕创建覆盖窗口
        createOverlayWindowsForAllScreens()
        
        // 启动倒计时
        startCountdownTimer()
    }
    
    // 为每个屏幕创建覆盖窗口
    private func createOverlayWindowsForAllScreens() {
        // 确保主窗口在特定的位置和大小
        if let mainWindow = self.window {
            NSApp.activate(ignoringOtherApps: true)
            
            // 定位主窗口到主屏幕中央
            if let mainScreen = NSScreen.main {
                mainWindow.setFrame(mainScreen.frame, display: true)
                
                // 显示主窗口
                mainWindow.alphaValue = 0
                mainWindow.orderFront(nil)
                mainWindow.makeKey()
                
                // 淡入动画
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.5
                    mainWindow.animator().alphaValue = 1.0
                })
            }
        }
        
        // 处理其他屏幕 - 为每个额外屏幕创建覆盖窗口
        for screen in NSScreen.screens where screen != NSScreen.main {
            let overlayWindow = createBlackoutWindow(for: screen)
            blackoutWindows.append(overlayWindow)
            
            // 显示覆盖窗口
            overlayWindow.alphaValue = 0
            overlayWindow.orderFront(nil)
            
            // 淡入动画
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.5
                overlayWindow.animator().alphaValue = 1.0
            })
        }
    }
    
    // 创建黑屏覆盖窗口
    private func createBlackoutWindow(for screen: NSScreen) -> NSWindow {
        let overlayWindow = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // 设置窗口属性
        overlayWindow.backgroundColor = .black
        overlayWindow.isOpaque = true
        overlayWindow.hasShadow = false
        overlayWindow.level = .screenSaver
        overlayWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        overlayWindow.isReleasedWhenClosed = false
        
        // 创建简单的黑色视图
        let blackView = NSView()
        blackView.wantsLayer = true
        blackView.layer?.backgroundColor = NSColor.black.cgColor
        
        overlayWindow.contentView = blackView
        
        return overlayWindow
    }
    
    // 隐藏黑屏窗口
    @objc func hideBlackoutWindow() {
        guard isActive else { return }
        
        isActive = false
        stopCountdownTimer()
        
        // 淡出主窗口
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            window?.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            self?.window?.orderOut(nil)
            self?.window?.alphaValue = 1.0
        })
        
        // 淡出并关闭所有覆盖窗口
        for overlayWindow in blackoutWindows {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                overlayWindow.animator().alphaValue = 0.0
            }, completionHandler: { [weak overlayWindow] in
                overlayWindow?.close()
            })
        }
        
        // 清空窗口数组
        blackoutWindows.removeAll()
    }
    
    // 开始倒计时
    private func startCountdownTimer() {
        stopCountdownTimer() // 确保先停止可能存在的计时器
        
        // 使用DispatchQueue.main.async确保在主线程上运行
        DispatchQueue.main.async {
            // 使用Timer来确保在休息结束时自动关闭黑屏
            self.countdownTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(self.timerManager.microBreakSeconds), repeats: false) { [weak self] _ in
                self?.hideBlackoutWindow()
            }
            
            // 确保计时器在主RunLoop运行，优先级设为最高
            if let timer = self.countdownTimer {
                RunLoop.main.add(timer, forMode: .common)
            }
            
            // 记录开始时间
            self.startTime = Date().timeIntervalSince1970
        }
    }
    
    // 停止倒计时
    private func stopCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
}

// 黑屏倒计时视图
struct BlackoutCountdownView: View {
    var onSkip: () -> Void
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // 简单黑色背景
            Color.black.edgesIgnoringSafeArea(.all)
            
            // 简化的跳过按钮
            Button(action: onSkip) {
                Text("跳过休息")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(scale)
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.2)) {
                    scale = hovering ? 1.05 : 1.0
                }
            }
        }
    }
}

// 在BlackoutCountdownView中添加TimerManager的扩展访问
extension BlackoutCountdownView {
    var timerManager: TimerManager { TimerManager.shared }
}