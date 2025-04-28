//
//  ContentView.swift
//  Focus
//
//  Created by 杨乾巍 on 2025/4/28.
//

import SwiftUI
import UserNotifications

struct ContentView: View {
    // 状态变量
    @State private var minutes: Int = 25
    @State private var seconds: Int = 0
    @State private var timerRunning = false
    @State private var timer: Timer? = nil
    @State private var isWorkMode = true
    @State private var workMinutes: Int = 25
    @State private var breakMinutes: Int = 5
    @State private var completedSessions: Int = 0

    // 格式化时间显示
    var timeString: String {
        String(format: "%02d:%02d", minutes, seconds)
    }

    // 当前模式文本
    var modeText: String {
        isWorkMode ? "工作时间" : "休息时间"
    }

    var body: some View {
        VStack(spacing: 20) {
            // 标题和模式
            VStack {
                Text("专注时钟")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(modeText)
                    .font(.title2)
                    .foregroundColor(isWorkMode ? .blue : .green)

                Text("已完成 \(completedSessions) 个专注周期")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // 时间显示
            Text(timeString)
                .font(.system(size: 70, weight: .medium, design: .monospaced))
                .padding()
                .background(
                    Circle()
                        .stroke(isWorkMode ? Color.blue : Color.green, lineWidth: 3)
                        .padding(6)
                )

            // 控制按钮
            HStack(spacing: 20) {
                Button(action: startTimer) {
                    Text("开始")
                        .font(.title2)
                        .padding()
                        .frame(width: 100)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(timerRunning)

                Button(action: stopTimer) {
                    Text("停止")
                        .font(.title2)
                        .padding()
                        .frame(width: 100)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!timerRunning)

                Button(action: resetTimer) {
                    Text("重置")
                        .font(.title2)
                        .padding()
                        .frame(width: 100)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }

            // 时间设置
            VStack(spacing: 10) {
                HStack {
                    Text("工作时间:")
                    Picker("工作分钟", selection: $workMinutes) {
                        ForEach(1...60, id: \.self) { minute in
                            Text("\(minute) 分钟").tag(minute)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .disabled(timerRunning)
                    .onChange(of: workMinutes) { newValue in
                        if isWorkMode && !timerRunning {
                            minutes = newValue
                        }
                    }
                }

                HStack {
                    Text("休息时间:")
                    Picker("休息分钟", selection: $breakMinutes) {
                        ForEach(1...30, id: \.self) { minute in
                            Text("\(minute) 分钟").tag(minute)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .disabled(timerRunning)
                }
            }
            .padding()
        }
        .padding()
        .frame(minWidth: 400, minHeight: 500)
    }

    // 开始计时器
    func startTimer() {
        timerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if seconds > 0 {
                seconds -= 1
            } else if minutes > 0 {
                minutes -= 1
                seconds = 59
            } else {
                stopTimer()

                // 发送通知
                sendNotification()

                // 切换模式
                if isWorkMode {
                    // 工作模式结束，切换到休息模式
                    isWorkMode = false
                    minutes = breakMinutes
                    completedSessions += 1
                } else {
                    // 休息模式结束，切换到工作模式
                    isWorkMode = true
                    minutes = workMinutes
                }
            }
        }
    }

    // 停止计时器
    func stopTimer() {
        timerRunning = false
        timer?.invalidate()
        timer = nil
    }

    // 重置计时器
    func resetTimer() {
        stopTimer()
        if isWorkMode {
            minutes = workMinutes
        } else {
            minutes = breakMinutes
        }
        seconds = 0
    }

    // 发送通知
    func sendNotification() {
        let content = UNMutableNotificationContent()

        if isWorkMode {
            content.title = "工作时间结束"
            content.body = "休息一下吧！"
        } else {
            content.title = "休息时间结束"
            content.body = "开始新的工作周期！"
        }

        content.sound = UNNotificationSound.default

        // 立即触发通知
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        // 创建通知请求
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        // 添加通知请求
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知发送失败: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    ContentView()
}
