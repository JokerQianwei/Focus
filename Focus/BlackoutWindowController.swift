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
        
        if let window = self.window {
            // 更新窗口位置和大小，确保覆盖所有屏幕
            let allScreensFrame = NSScreen.screens.reduce(NSRect.zero) { result, screen in
                return result.union(screen.frame)
            }
            window.setFrame(allScreensFrame, display: true)
            
            // 确保在全屏应用上方显示
            NSApp.activate(ignoringOtherApps: true)
            
            // 显示窗口
            window.alphaValue = 0
            window.orderFront(nil)
            window.makeKey()
            
            // 淡入动画
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.5
                window.animator().alphaValue = 1.0
            })
            
            // 启动倒计时
            startCountdownTimer()
        }
    }
    
    // 隐藏黑屏窗口
    @objc func hideBlackoutWindow() {
        guard isActive else { return }
        
        isActive = false
        stopCountdownTimer()
        
        // 淡出动画
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            window?.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            self?.window?.orderOut(nil)
            self?.window?.alphaValue = 1.0
        })
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
    
    var body: some View {
        ZStack {
            // 为纯黑色背景添加一点纹理，使其看起来更柔和
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                // 添加一个非常淡的网格纹理
                Rectangle()
                    .fill(Color.white.opacity(0.02))
                    .edgesIgnoringSafeArea(.all)
            }
            
            VStack(spacing: 30) {
                // 倒计时标题
                Text("微休息时间")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Color.blue.opacity(0.5), radius: 10, x: 0, y: 0)
                
                // 倒计时数字
                Text("\(secondsRemaining)")
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()
                    .shadow(color: Color.blue.opacity(0.5), radius: 10, x: 0, y: 0)
                    .animation(.easeInOut(duration: 0.5), value: secondsRemaining)
                
                // 辅助文本
                Text("闭上眼睛，深呼吸...")
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                    .padding(.top, 10)
                
                // 跳过按钮
                Button(action: onSkip) {
                    Text("跳过")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.3))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 40)
                .scaleEffect(scale)
                .shadow(color: Color.black.opacity(0.5), radius: 5, x: 0, y: 2)
                .onHover { hovering in
                    withAnimation(.spring()) {
                        scale = hovering ? 1.1 : 1.0
                    }
                }
            }
        }
    }
}