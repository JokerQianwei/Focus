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

    var body: some View {
        ZStack {
            // 背景颜色
            Color(NSColor.controlBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 25) {
                // 顶部栏：标题和设置按钮
                ZStack {
                    // 标题居中
                    Text("Focus")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)

                    // 设置按钮靠右
                    HStack {
                        Spacer()
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .onTapGesture {
                                showingSettings = true
                            }
                            .help("设置")
                    }
                    .keyboardShortcut(",", modifiers: .command)
                }
                .padding(.horizontal)

                // 完成信息
                Text("已完成 \(timerManager.completedSessions) 个专注周期")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // 时间显示
                ZStack {
                    Circle()
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

                    Circle()
                        .stroke(timerManager.isWorkMode ? Color.blue : Color.green, lineWidth: 4)
                        .padding(4)

                    Text(timerManager.timeString)
                        .font(.system(size: 70, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                        .monospacedDigit()
                }
                .frame(width: 250, height: 250)

                // 控制按钮
                HStack(spacing: 20) {
                    Button(action: {
                        timerManager.startTimer()
                    }) {
                        Label("开始", systemImage: "play.fill")
                            .frame(width: 100)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(timerManager.timerRunning)

                    Button(action: {
                        timerManager.stopTimer()
                    }) {
                        Label("停止", systemImage: "pause.fill")
                            .frame(width: 100)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(!timerManager.timerRunning)

                    Button(action: {
                        timerManager.resetTimer()
                    }) {
                        Label("重置", systemImage: "arrow.counterclockwise")
                            .frame(width: 100)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                }
                .controlSize(.large)

                // 移除了提示音状态指示器
            }
            .padding()
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
