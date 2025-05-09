//
//  BlackoutView.swift
//  Focus
//
//  Created by 杨乾巍 on 2025/4/28.
//

import SwiftUI
import AppKit

struct BlackoutView: View {
    // 定时器管理器实例
    @ObservedObject var timerManager: TimerManager
    
    // 剩余休息秒数
    @State private var remainingSeconds: Int
    
    // 关闭黑屏回调
    var onClose: () -> Void
    
    // 计时器
    @State private var timer: Timer?
    
    init(timerManager: TimerManager, onClose: @escaping () -> Void) {
        self.timerManager = timerManager
        self.onClose = onClose
        _remainingSeconds = State(initialValue: timerManager.microBreakSeconds)
    }
    
    var body: some View {
        ZStack {
            // 黑色背景
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 25) {
                // 倒计时标题
                Text("微休息时间")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // 倒计时数字
                Text("\(remainingSeconds)")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()
                
                // 辅助文本
                Text("闭上眼睛，深呼吸...")
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                    .padding(.top, 10)
                
                // 跳过按钮
                Button(action: {
                    stopTimer()
                    onClose()
                }) {
                    Text("跳过")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 25)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.3))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 30)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            startTimer()
            NSApp.activate(ignoringOtherApps: true)
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    // 开始计时器
    private func startTimer() {
        // 停止可能存在的计时器
        stopTimer()
        
        // 初始化剩余时间
        remainingSeconds = timerManager.microBreakSeconds
        
        // 创建新计时器
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingSeconds > 1 {
                remainingSeconds -= 1
            } else {
                // 时间到，关闭黑屏
                stopTimer()
                onClose()
            }
        }
    }
    
    // 停止计时器
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct BlackoutView_Previews: PreviewProvider {
    static var previews: some View {
        BlackoutView(timerManager: TimerManager.shared, onClose: {})
    }
}