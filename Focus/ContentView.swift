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
    // 状态变量
    @State private var minutes: Int = 90
    @State private var seconds: Int = 0
    @State private var timerRunning = false
    @State private var timer: Timer? = nil
    @State private var isWorkMode = true
    @State private var workMinutes: Int = 90
    @State private var breakMinutes: Int = 20
    @State private var completedSessions: Int = 0

    // 提示音系统相关状态
    @State private var promptSoundEnabled = true
    @State private var promptTimer: Timer? = nil
    @State private var secondPromptTimer: Timer? = nil
    @State private var nextPromptInterval: TimeInterval = 0
    @State private var audioPlayer: AVAudioPlayer? = nil

    // 设置视图相关状态
    @State private var showingSettings = false

    // 格式化时间显示
    var timeString: String {
        String(format: "%02d:%02d", minutes, seconds)
    }

    // 当前模式文本
    var modeText: String {
        isWorkMode ? "专注时间" : "休息时间"
    }

    var body: some View {
        ZStack {
            // 背景颜色
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 25) {
                // 顶部栏：标题和设置按钮
                HStack {
                    Spacer()

                    Text("专注时钟")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Spacer()

                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(",", modifiers: .command)
                    .help("设置")
                }
                .padding(.horizontal)

                // 模式和完成信息
                VStack(spacing: 8) {
                    Text(modeText)
                        .font(.title2)
                        .foregroundColor(isWorkMode ? .blue : .green)
                        .fontWeight(.medium)

                    Text("已完成 \(completedSessions) 个专注周期")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // 时间显示
                ZStack {
                    Circle()
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

                    Circle()
                        .stroke(isWorkMode ? Color.blue : Color.green, lineWidth: 4)
                        .padding(4)

                    Text(timeString)
                        .font(.system(size: 70, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                        .monospacedDigit()
                }
                .frame(width: 250, height: 250)

                // 控制按钮
                HStack(spacing: 20) {
                    Button(action: startTimer) {
                        Label("开始", systemImage: "play.fill")
                            .frame(width: 100)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(timerRunning)

                    Button(action: stopTimer) {
                        Label("停止", systemImage: "pause.fill")
                            .frame(width: 100)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(!timerRunning)

                    Button(action: resetTimer) {
                        Label("重置", systemImage: "arrow.counterclockwise")
                            .frame(width: 100)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                }
                .controlSize(.large)

                // 提示音状态指示器（如果启用）
                if promptSoundEnabled && isWorkMode && timerRunning {
                    HStack(spacing: 8) {
                        Image(systemName: "speaker.wave.2")
                            .foregroundColor(.blue)
                        Text("提示音已启用")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .frame(minWidth: 400, minHeight: 500)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                workMinutes: $workMinutes,
                breakMinutes: $breakMinutes,
                promptSoundEnabled: $promptSoundEnabled,
                isWorkMode: $isWorkMode,
                minutes: $minutes,
                timerRunning: timerRunning
            )
        }
    }

    // 初始化音频播放器
    func setupAudioPlayer() {
        guard audioPlayer == nil else { return }

        // 使用系统声音
        let systemSoundID = 1005 // 系统声音ID，这是一个提示音
        let soundURL = URL(fileURLWithPath: "/System/Library/Sounds/Tink.aiff")

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.volume = 0.7 // 设置音量
        } catch {
            print("初始化音频播放器失败: \(error.localizedDescription)")
            // 如果无法使用AVAudioPlayer，则使用系统声音API
            AudioServicesPlaySystemSound(SystemSoundID(systemSoundID))
        }
    }

    // 播放提示音
    func playPromptSound() {
        // 如果音频播放器未初始化，则初始化
        if audioPlayer == nil {
            setupAudioPlayer()
        }

        // 播放声音
        if let player = audioPlayer, player.play() {
            // 成功播放
        } else {
            // 如果播放失败，使用系统声音API
            let systemSoundID = 1005 // 系统声音ID，这是一个提示音
            AudioServicesPlaySystemSound(SystemSoundID(systemSoundID))
        }
    }

    // 启动随机提示音计时器
    func startPromptTimer() {
        guard isWorkMode && promptSoundEnabled else { return }

        // 停止现有计时器
        promptTimer?.invalidate()
        secondPromptTimer?.invalidate()

        // 生成3-5分钟的随机间隔（转换为秒）
        nextPromptInterval = TimeInterval(Int.random(in: 180...300))

        // 创建新的计时器
        promptTimer = Timer.scheduledTimer(withTimeInterval: nextPromptInterval, repeats: false) { [self] _ in
            // 播放第一次提示音
            playPromptSound()

            // 安排10秒后的第二次提示音
            scheduleSecondPrompt()
        }
    }

    // 安排10秒后的第二次提示音
    func scheduleSecondPrompt() {
        secondPromptTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [self] _ in
            // 播放第二次提示音
            playPromptSound()

            // 重新启动随机提示音计时器
            startPromptTimer()
        }
    }

    // 停止提示音系统
    func stopPromptSystem() {
        promptTimer?.invalidate()
        promptTimer = nil

        secondPromptTimer?.invalidate()
        secondPromptTimer = nil
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

                // 如果切换到工作模式，启动提示音系统
                if isWorkMode && promptSoundEnabled {
                    startPromptTimer()
                }
            }
        }

        // 如果是工作模式且启用了提示音，启动提示音系统
        if isWorkMode && promptSoundEnabled {
            startPromptTimer()
        }
    }

    // 停止计时器
    func stopTimer() {
        timerRunning = false
        timer?.invalidate()
        timer = nil

        // 停止提示音系统
        stopPromptSystem()
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
            content.title = "专注时间结束"
            content.body = "休息一下吧！"
        } else {
            content.title = "休息时间结束"
            content.body = "开始新的专注周期！"
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
