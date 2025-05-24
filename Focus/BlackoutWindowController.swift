//
//  BlackoutWindowController.swift
//  Focus
//
//  Created by 杨乾巍 on 2025/5/9.
//

import Cocoa
import SwiftUI
import Combine

// 倒计时状态管理类
class BlackoutCountdownState: ObservableObject {
    @Published var remainingSeconds: Int = 0
    private var cancellable: AnyCancellable?
    
    func startCountdown(from seconds: Int) {
        // 设置初始值
        remainingSeconds = seconds
        
        // 取消现有订阅
        cancellable?.cancel()
        
        // 创建新的计时器发布者
        let timerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        
        // 订阅计时器事件
        cancellable = timerPublisher.sink { [weak self] _ in
            guard let self = self else { return }
            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
                print("Countdown state updated: \(self.remainingSeconds) seconds remaining")
            }
        }
    }
    
    func stopCountdown() {
        cancellable?.cancel()
        remainingSeconds = 0
    }
    
    deinit {
        cancellable?.cancel()
    }
}

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
    
    // 添加倒计时状态管理器
    private let countdownState = BlackoutCountdownState()
    
    // 深绿色主题色 - 移到类级别作为静态属性
    private static var primaryGreenColor: NSColor {
        return NSColor(red: 0.106, green: 0.263, blue: 0.196, alpha: 1.0) // #1B4332
    }
    
    private static var secondaryGreenColor: NSColor {
        return NSColor(red: 0.157, green: 0.392, blue: 0.294, alpha: 1.0) // #28634B
    }
    
    // 初始化方法
    private override init(window: NSWindow?) {
        // 创建全屏深绿色窗口
        let customWindow = NSWindow(
            contentRect: NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // 设置窗口属性 - 使用静态属性
        customWindow.backgroundColor = Self.primaryGreenColor
        customWindow.isOpaque = true
        customWindow.hasShadow = false
        customWindow.level = .screenSaver
        customWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        customWindow.isReleasedWhenClosed = false
        customWindow.ignoresMouseEvents = false
        
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
            onSkip: { self.hideBlackoutWindow() },
            countdownState: countdownState
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
    
    // 显示黑屏窗口（直接进入黑屏状态）
    @objc func showBlackoutWindow() {
        guard !isActive, timerManager.blackoutEnabled else { return }
        
        isActive = true
        
        // 直接创建全屏黑屏窗口
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
                
                // 温和的淡入动画
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 1.0 // 适中的过渡时间
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
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
            
            // 温和的淡入动画
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 1.0
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
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
        
        // 设置窗口属性 - 使用深绿色
        overlayWindow.backgroundColor = Self.primaryGreenColor
        overlayWindow.isOpaque = true
        overlayWindow.hasShadow = false
        overlayWindow.level = .screenSaver
        overlayWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        overlayWindow.isReleasedWhenClosed = false
        
        // 创建深绿色渐变视图
        let greenView = NSView()
        greenView.wantsLayer = true
        
        // 创建渐变层
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            Self.primaryGreenColor.cgColor,
            Self.secondaryGreenColor.cgColor,
            Self.primaryGreenColor.cgColor
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        
        greenView.layer = gradientLayer
        overlayWindow.contentView = greenView
        
        return overlayWindow
    }
    
    // 隐藏黑屏窗口
    @objc func hideBlackoutWindow() {
        guard isActive else { return }
        
        isActive = false
        stopCountdownTimer()
        
        // 温和的淡出主窗口
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.6 // 适中的淡出时间
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window?.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            self?.window?.orderOut(nil)
            self?.window?.alphaValue = 1.0
        })
        
        // 淡出并关闭所有覆盖窗口
        for overlayWindow in blackoutWindows {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.6
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
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
            // 启动共享的倒计时状态
            self.countdownState.startCountdown(from: self.timerManager.microBreakSeconds)
            
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
        countdownState.stopCountdown()
    }
}

// 黑屏倒计时视图
struct BlackoutCountdownView: View {
    var onSkip: () -> Void
    @State private var scale: CGFloat = 1.0
    @State private var closeScale: CGFloat = 1.0
    @State private var breathingEffect: Bool = false
    
    // 使用ObservedObject而不是State来观察共享的倒计时状态
    @ObservedObject var countdownState: BlackoutCountdownState
    
    // 深绿色主题
    private var primaryGreen: Color {
        Color(red: 0.106, green: 0.263, blue: 0.196) // #1B4332
    }
    
    private var secondaryGreen: Color {
        Color(red: 0.157, green: 0.392, blue: 0.294) // #28634B
    }
    
    private var accentGreen: Color {
        Color(red: 0.239, green: 0.549, blue: 0.420) // #3D8C6B
    }
    
    var body: some View {
        ZStack {
            // 深绿色渐变背景
            LinearGradient(
                gradient: Gradient(colors: [primaryGreen, secondaryGreen, primaryGreen]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            .scaleEffect(breathingEffect ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: breathingEffect)
            
            // 装饰性圆圈
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(accentGreen.opacity(0.2), lineWidth: 2)
                    .frame(width: CGFloat(200 + index * 100))
                    .scaleEffect(breathingEffect ? 1.1 : 0.9)
                    .animation(
                        .easeInOut(duration: 4.0 + Double(index) * 0.5)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.3),
                        value: breathingEffect
                    )
            }
            
            // 倒计时显示，使用共享状态的值，居中显示
            VStack(spacing: 16) {
                // 微休息图标
                Image(systemName: "leaf.fill")
                    .font(.system(size: 32))
                    .foregroundColor(accentGreen)
                    .scaleEffect(breathingEffect ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: breathingEffect)
                
                Text("\(countdownState.remainingSeconds)")
                    .font(.system(size: 88, weight: .ultraLight, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()
                    .scaleEffect(scale)
                    .animation(.easeInOut(duration: 1.0), value: scale)
                
                Text("闭眼！深呼吸！")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(2.0)
            }
            
            // 左上角的关闭按钮
            VStack {
                HStack {
                    Button(action: onSkip) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(accentGreen.opacity(0.3)))
                            .overlay(
                                Circle()
                                    .stroke(accentGreen.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(closeScale)
                    .onHover { hovering in
                        withAnimation(.easeOut(duration: 0.2)) {
                            closeScale = hovering ? 1.1 : 1.0
                        }
                    }
                    
                    Spacer()
                }
                
                Spacer()
            }
            .padding(20)
        }
        .onAppear {
            breathingEffect = true
            print("BlackoutCountdownView appeared with \(countdownState.remainingSeconds) seconds")
        }
        .onChange(of: countdownState.remainingSeconds) { oldValue, newValue in
            // 数字变化时的脉冲效果
            withAnimation(.easeInOut(duration: 0.3)) {
                scale = 1.1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    scale = 1.0
                }
            }
        }
    }
}

// 在BlackoutCountdownView中添加TimerManager的扩展访问
extension BlackoutCountdownView {
    var timerManager: TimerManager { TimerManager.shared }
}