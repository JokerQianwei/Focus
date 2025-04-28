//
//  TimerManager.swift
//  Focus
//
//  Created by 杨乾巍 on 2025/4/28.
//

import Foundation
import Combine

// 计时器管理器，作为单例，在应用程序的不同部分之间共享计时器状态
class TimerManager: ObservableObject {
    // 单例实例
    static let shared = TimerManager()

    // 发布的属性，当这些属性改变时，所有观察者都会收到通知
    @Published var minutes: Int = 90
    @Published var seconds: Int = 0
    @Published var isWorkMode: Bool = true
    @Published var timerRunning: Bool = false
    @Published var workMinutes: Int = 90
    @Published var breakMinutes: Int = 20
    @Published var completedSessions: Int = 0
    @Published var promptSoundEnabled: Bool = true

    // 计时器
    private var timer: Timer? = nil
    private var promptTimer: Timer? = nil
    private var secondPromptTimer: Timer? = nil
    private var nextPromptInterval: TimeInterval = 0

    // 格式化时间显示
    var timeString: String {
        String(format: "%02d:%02d", minutes, seconds)
    }

    // 当前模式文本
    var modeText: String {
        isWorkMode ? "专注时间" : "休息时间"
    }

    // 菜单栏显示文本
    var statusBarText: String {
        timeString
    }

    // 私有初始化方法，防止外部创建实例
    private init() {}

    // 开始计时器
    func startTimer() {
        timerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if self.seconds > 0 {
                self.seconds -= 1
            } else if self.minutes > 0 {
                self.minutes -= 1
                self.seconds = 59
            } else {
                self.stopTimer()

                // 切换模式
                if self.isWorkMode {
                    // 工作模式结束，切换到休息模式
                    self.isWorkMode = false
                    self.minutes = self.breakMinutes
                    self.completedSessions += 1
                } else {
                    // 休息模式结束，切换到工作模式
                    self.isWorkMode = true
                    self.minutes = self.workMinutes
                }

                // 如果切换到工作模式，启动提示音系统
                if self.isWorkMode && self.promptSoundEnabled {
                    self.startPromptTimer()
                }

                // 发送通知
                NotificationCenter.default.post(name: .timerModeChanged, object: nil)
            }

            // 发送通知，计时器已更新
            NotificationCenter.default.post(name: .timerUpdated, object: nil)
        }

        // 如果是工作模式且启用了提示音，启动提示音系统
        if isWorkMode && promptSoundEnabled {
            startPromptTimer()
        }

        // 发送通知，计时器状态已改变
        NotificationCenter.default.post(name: .timerStateChanged, object: nil)
    }

    // 停止计时器
    func stopTimer() {
        timerRunning = false
        timer?.invalidate()
        timer = nil

        // 停止提示音系统
        stopPromptSystem()

        // 发送通知，计时器状态已改变
        NotificationCenter.default.post(name: .timerStateChanged, object: nil)
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

        // 发送通知，计时器已更新
        NotificationCenter.default.post(name: .timerUpdated, object: nil)
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
        promptTimer = Timer.scheduledTimer(withTimeInterval: nextPromptInterval, repeats: false) { [weak self] _ in
            guard let self = self else { return }

            // 播放第一次提示音
            NotificationCenter.default.post(name: .playPromptSound, object: nil)

            // 安排10秒后的第二次提示音
            self.scheduleSecondPrompt()
        }
    }

    // 安排10秒后的第二次提示音
    func scheduleSecondPrompt() {
        secondPromptTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
            guard let self = self else { return }

            // 播放第二次提示音
            NotificationCenter.default.post(name: .playPromptSound, object: nil)

            // 重新启动随机提示音计时器
            self.startPromptTimer()
        }
    }

    // 停止提示音系统
    func stopPromptSystem() {
        promptTimer?.invalidate()
        promptTimer = nil

        secondPromptTimer?.invalidate()
        secondPromptTimer = nil
    }
}

// 通知名称扩展
extension Notification.Name {
    static let timerUpdated = Notification.Name("timerUpdated")
    static let timerStateChanged = Notification.Name("timerStateChanged")
    static let timerModeChanged = Notification.Name("timerModeChanged")
    static let playPromptSound = Notification.Name("playPromptSound")
}
