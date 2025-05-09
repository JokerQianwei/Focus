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
    private var secondsRemaining: Int = 0
    
    // 黑屏窗口状态
    private var isActive = false
    
    // 存储额外的黑屏窗口
    private var blackoutWindows: [NSWindow] = []
    
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
            secondsRemaining: Binding<Int>(
                get: { self.secondsRemaining },
                set: { self.secondsRemaining = $0 }
            ),
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
        secondsRemaining = timerManager.microBreakSeconds
        
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
        
        // 在主线程运行计时器以确保UI更新流畅
        DispatchQueue.main.async {
            self.countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                
                if self.secondsRemaining > 1 {
                    self.secondsRemaining -= 1
                } else {
                    self.hideBlackoutWindow()
                }
            }
            // 确保计时器在主RunLoop运行
            if let timer = self.countdownTimer {
                RunLoop.main.add(timer, forMode: .common)
            }
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
    @Binding var secondsRemaining: Int
    var onSkip: () -> Void
    @State private var scale: CGFloat = 1.0
    @State private var breatheIn = false
    
    var body: some View {
        ZStack {
            // 为纯黑色背景添加一点渐变，使其看起来更柔和
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(red: 0.05, green: 0.05, blue: 0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            // 添加轻微的圆形光晕效果
            Circle()
                .fill(Color.blue.opacity(0.05))
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .scaleEffect(breatheIn ? 1.1 : 0.9)
                .animation(
                    Animation.easeInOut(duration: 4)
                        .repeatForever(autoreverses: true),
                    value: breatheIn
                )
                .onAppear { breatheIn = true }
            
            VStack(spacing: 40) {
                // 倒计时标题
                Text("微休息时间")
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Color.blue.opacity(0.7), radius: 15, x: 0, y: 0)
                
                // 优雅的倒计时圆环
                ZStack {
                    // 背景圆环
                    Circle()
                        .stroke(lineWidth: 15)
                        .opacity(0.1)
                        .foregroundColor(.white)
                    
                    // 进度圆环
                    Circle()
                        .trim(from: 0.0, to: min(1.0, CGFloat(secondsRemaining) / CGFloat(timerManager.microBreakSeconds)))
                        .stroke(style: StrokeStyle(lineWidth: 15, lineCap: .round, lineJoin: .round))
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: secondsRemaining)
                    
                    // 倒计时数字
                    Text("\(secondsRemaining)")
                        .font(.system(size: 70, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .shadow(color: Color.blue.opacity(0.7), radius: 10, x: 0, y: 0)
                }
                .frame(width: 200, height: 200)
                
                // 滚动切换的休息提示语
                Text(restPromptForTime(secondsRemaining))
                    .font(.system(size: 30, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                    .padding(.top, 10)
                    .frame(height: 40)
                    .id(secondsRemaining % 5) // 每5秒切换一次提示
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut, value: secondsRemaining % 5)
                
                // 更美观的跳过按钮
                Button(action: onSkip) {
                    Text("跳过休息")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 35)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.3)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                .blur(radius: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 40)
                .scaleEffect(scale)
                .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 5)
                .onHover { hovering in
                    withAnimation(.spring()) {
                        scale = hovering ? 1.1 : 1.0
                    }
                }
            }
            .padding(50)
        }
    }
    
    // 不同时间段显示不同的休息提示
    private func restPromptForTime(_ seconds: Int) -> String {
        let prompts = [
            "闭上眼睛，深呼吸...",
            "放松你的肩膀和脖子...",
            "向远处看看，缓解眼睛疲劳...",
            "站起来活动一下身体...",
            "放松一下，片刻即回",
            "喝口水，保持水分补充"
        ]
        
        return prompts[abs(seconds / 5) % prompts.count]
    }
}

// 在BlackoutCountdownView中添加TimerManager的扩展访问
extension BlackoutCountdownView {
    var timerManager: TimerManager { TimerManager.shared }
}