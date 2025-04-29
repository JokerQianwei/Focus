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

    var body: some View {
        ZStack {
            // 背景颜色
            Color(NSColor.controlBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 15) {
                // 顶部栏：标题和设置按钮
                ZStack {
                    // 标题居中，根据模式改变文本
                    Text(timerManager.isWorkMode ? "Focus" : "Break")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)

                    // 设置按钮靠右
                    HStack {
                        Spacer()
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(isHoveringSettings ? .primary : .secondary) // Change color on hover
                            .scaleEffect(isHoveringSettings ? 1.1 : 1.0) // Scale effect on hover
                            .onTapGesture {
                                showingSettings = true
                            }
                            .help("设置")
                            .onHover { hovering in
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    isHoveringSettings = hovering
                                }
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
                    Circle()
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

                    Circle()
                        .stroke(timerManager.isWorkMode ? Color.blue : Color(red: 0.4, green: 0.8, blue: 0.6), lineWidth: 4)
                        .padding(4)

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
    }


}

#Preview {
    ContentView()
        .environmentObject(TimerManager.shared)
}
