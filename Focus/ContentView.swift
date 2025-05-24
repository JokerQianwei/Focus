//
//  ContentView.swift
//  Focus
//
//  Created by 杨乾巍 on 2025/4/28.
//

import SwiftUI
import UserNotifications
import AVFoundation
import AudioToolbox

struct ContentView: View {
    // 使用环境对象获取TimerManager实例
    @EnvironmentObject private var timerManager: TimerManager

    // 设置视图相关状态
    @State private var showingSettings = false
    @State private var isHoveringPlayPause = false // State for play/pause hover
    @State private var isHoveringReset = false     // State for reset hover
    @State private var isHoveringSettings = false // State for settings hover
    
    // 进度条动画状态
    @State private var animateProgress = false

    // 计算当前进度比例 (0.0-1.0)
    private var progressRatio: Double {
        if timerManager.isWorkMode {
            let totalSeconds = Double(timerManager.workMinutes * 60)
            let remainingSeconds = Double(timerManager.minutes * 60 + timerManager.seconds)
            return remainingSeconds / totalSeconds
        } else {
            let totalSeconds = Double(timerManager.breakMinutes * 60)
            let remainingSeconds = Double(timerManager.minutes * 60 + timerManager.seconds)
            return remainingSeconds / totalSeconds
        }
    }
    
    // 工作模式的渐变色
    private var workModeGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.blue,
                Color.blue.opacity(0.8)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // 休息模式的渐变色
    private var breakModeGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.4, green: 0.8, blue: 0.6),
                Color(red: 0.2, green: 0.7, blue: 0.5)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // 当前模式的渐变色
    private var currentModeGradient: LinearGradient {
        timerManager.isWorkMode ? workModeGradient : breakModeGradient
    }

    var body: some View {
        ZStack {
            // 背景颜色
            Color(NSColor.controlBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 15) {
                // 顶部栏：标题和设置按钮
                HStack {
                    // 左侧占位元素，与右侧设置按钮保持平衡
                    Button(action: {}) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.clear)
                    }
                    .buttonStyle(.plain)
                    .disabled(true)
                    
                    // 标题居中，根据模式改变文本
                    Text(timerManager.isWorkMode ? "Focus" : "Break")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)

                    // 右侧设置按钮
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(isHoveringSettings ? .primary : .secondary)
                            .scaleEffect(isHoveringSettings ? 1.1 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .focusEffectDisabled()
                    .help("设置")
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isHoveringSettings = hovering
                        }
                    }
                    .keyboardShortcut(",", modifiers: .command)
                }
                .padding(.horizontal)
                .padding(.top, -10)

                // 完成信息
                Text("今天已完成 \(timerManager.completedSessionsToday) 个专注周期")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // 时间显示
                ZStack {
                    // 时钟背景
                    Circle()
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

                    // 底层灰色轨道
                    Circle()
                        .stroke(
                            Color.gray.opacity(0.2),
                            style: StrokeStyle(
                                lineWidth: 8,
                                lineCap: .round
                            )
                        )
                        .padding(8)

                    // 进度条圆环
                    Circle()
                        .trim(from: 0, to: CGFloat(animateProgress ? progressRatio : 1))
                        .stroke(
                            currentModeGradient,
                            style: StrokeStyle(
                                lineWidth: 8,
                                lineCap: .round
                            )
                        )
                        .rotationEffect(.degrees(-90))
                        .padding(8)
                        .animation(.easeInOut(duration: 0.7), value: progressRatio)
                        .animation(.easeOut(duration: 1.0), value: animateProgress)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                animateProgress = true
                            }
                        }

                    // 时间文本
                    Text(timerManager.timeString)
                        .font(.system(size: 70, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                        .monospacedDigit()
                }
                .frame(width: 250, height: 250)

                // 控制按钮
                HStack(spacing: 40) {
                    // 合并后的 Play/Pause 按钮
                    Button(action: {
                        if timerManager.timerRunning {
                            timerManager.stopTimer()
                        } else {
                            timerManager.startTimer()
                        }
                    }) {
                        Image(systemName: timerManager.timerRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .frame(width: 65, height: 65)
                            // Adjust background based on hover state
                            .background(Circle().fill(timerManager.timerRunning ? Color.red.opacity(isHoveringPlayPause ? 0.9 : 0.8) : Color.accentColor.opacity(isHoveringPlayPause ? 0.9 : 1.0)))
                            .scaleEffect(isHoveringPlayPause ? 1.05 : 1.0) // Scale effect on hover
                    }
                    .buttonStyle(.plain)
                    .clipShape(Circle())
                    .disabled(timerManager.isWorkMode && timerManager.minutes == 0 && timerManager.seconds == 0)
                    .focusEffectDisabled()
                    .onHover { hovering in // Add hover effect
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isHoveringPlayPause = hovering
                        }
                    }

                    // 重置按钮
                    Button(action: {
                        timerManager.resetTimer()
                        // 重置进度动画
                        animateProgress = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            animateProgress = true
                        }
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 26))
                            .foregroundColor(.primary)
                            .frame(width: 65, height: 65)
                            // Adjust background based on hover state
                            .background(Circle().fill(Color.gray.opacity(isHoveringReset ? 0.3 : 0.2)))
                            .scaleEffect(isHoveringReset ? 1.05 : 1.0) // Scale effect on hover
                    }
                    .buttonStyle(.plain)
                    .clipShape(Circle())
                    .onHover { hovering in // Add hover effect
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isHoveringReset = hovering
                        }
                    }
                }

                // 移除了提示音状态指示器
            }
            .padding(.top, 15)
            .padding([.leading, .trailing, .bottom])
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(timerManager: timerManager)
        }
        .onChange(of: timerManager.isWorkMode) { _ in
            // 在模式切换时重新触发进度动画
            animateProgress = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateProgress = true
            }
        }
    }


}

#Preview {
    ContentView()
        .environmentObject(TimerManager.shared)
}
