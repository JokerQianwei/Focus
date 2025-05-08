//
//  BlackoutManager.swift
//  Focus
//
//  Created by 杨乾巍 on 2025/4/28.
//

import Foundation
import SwiftUI
import AppKit

// 管理强制休息黑屏功能的单例类
class BlackoutManager: ObservableObject {
    // 单例实例
    static let shared = BlackoutManager()
    
    // 发布的属性，当这些属性改变时，所有观察者都会收到通知
    @Published var isBreakActive = false
    @Published var remainingSeconds = 0
    
    // 黑屏窗口
    private var overlayWindow: BreakOverlayWindow?
    
    // 更新计时器
    private var timer: Timer?
    
    // 原始鼠标和键盘事件监视器
    private var eventMonitors: [Any] = []
    
    // 私有初始化方法，防止外部创建实例
    private init() {}
    
    // 开始强制休息
    func startForcedBreak(duration: Int) {
        // 如果已经在休息中，不执行任何操作
        guard !isBreakActive else { return }
        
        // 更新状态
        isBreakActive = true
        remainingSeconds = duration
        
        // 创建并显示黑屏窗口
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 创建覆盖窗口
            self.overlayWindow = BreakOverlayWindow()
            self.overlayWindow?.contentView = NSHostingView(rootView: BreakOverlayView(blackoutManager: self))
            self.overlayWindow?.makeKeyAndOrderFront(nil)
            
            // 启动计时器来更新倒计时
            self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                } else {
                    self.endForcedBreak()
                }
            }
            
            // 设置鼠标和键盘事件监视器来阻止用户输入
            self.setupEventMonitors()
        }
    }
    
    // 结束强制休息
    func endForcedBreak() {
        // 停止计时器
        timer?.invalidate()
        timer = nil
        
        // 关闭黑屏窗口
        DispatchQueue.main.async { [weak self] in
            self?.overlayWindow?.close()
            self?.overlayWindow = nil
        }
        
        // 移除事件监视器
        for monitor in eventMonitors {
            NSEvent.removeMonitor(monitor)
        }
        eventMonitors.removeAll()
        
        // 更新状态
        isBreakActive = false
        remainingSeconds = 0
    }
    
    // 设置事件监视器来阻止用户输入
    private func setupEventMonitors() {
        // 监控鼠标点击事件
        let mouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { _ in
            // 拦截事件，返回nil表示事件不会传递给应用程序
            return nil
        }
        
        // 监控键盘事件
        let keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { _ in
            // 拦截事件，返回nil表示事件不会传递给应用程序
            return nil
        }
        
        eventMonitors.append(mouseMonitor)
        eventMonitors.append(keyboardMonitor)
    }
}

// 黑屏窗口类
class BreakOverlayWindow: NSWindow {
    init() {
        // 获取主屏幕的尺寸
        let screenRect = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        
        // 调用父类初始化方法
        super.init(contentRect: screenRect, 
                   styleMask: [.borderless], 
                   backing: .buffered, 
                   defer: false)
        
        // 配置窗口属性
        self.backgroundColor = .black
        self.isOpaque = false
        self.hasShadow = false
        self.level = .screenSaver // 置于屏幕保护程序级别，确保在所有窗口之上
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary] // 在所有空间中显示
        self.ignoresMouseEvents = false // 必须设为false才能捕获鼠标事件
    }
}

// 黑屏覆盖视图
struct BreakOverlayView: View {
    @ObservedObject var blackoutManager: BlackoutManager
    
    var body: some View {
        ZStack {
            // 黑色背景
            Color.black.opacity(0.95).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("强制休息时间")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                
                Text("请离开电脑，眺望远处")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Spacer().frame(height: 40)
                
                // 倒计时显示
                Text("\(blackoutManager.remainingSeconds)")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundColor(.white)
                
                Text("秒后恢复")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
} 