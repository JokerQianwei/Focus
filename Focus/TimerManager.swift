//
//  TimerManager.swift
//  Focus
//
//  Created by 杨乾巍 on 2025/4/28.
//

import Foundation
import Combine
import AppKit

// 声音类型枚举
enum SoundType: String, CaseIterable, Identifiable {
    case tink = "Tink"
    case glass = "Glass"
    case bell = "Blow"
    case hero = "Hero"
    case submarine = "Submarine"
    case basso = "Basso"
    case bottle = "Bottle"
    case frog = "Frog"
    case funk = "Funk"
    case morse = "Morse"
    case ping = "Ping"
    case pop = "Pop"
    case purr = "Purr"
    case sosumi = "Sosumi"
    
    var id: String { self.rawValue }
    
    var fileName: String {
        switch self {
            case .tink: return "Tink.aiff"
            case .glass: return "Glass.aiff"
            case .bell: return "Blow.aiff"
            case .hero: return "Hero.aiff"
            case .submarine: return "Submarine.aiff"
            case .basso: return "Basso.aiff"
            case .bottle: return "Bottle.aiff"
            case .frog: return "Frog.aiff"
            case .funk: return "Funk.aiff"
            case .morse: return "Morse.aiff"
            case .ping: return "Ping.aiff"
            case .pop: return "Pop.aiff"
            case .purr: return "Purr.aiff"
            case .sosumi: return "Sosumi.aiff"
        }
    }
    
    var displayName: String {
        switch self {
            case .tink: return "水滴声"
            case .glass: return "玻璃声"
            case .bell: return "铃声"
            case .hero: return "完成声"
            case .submarine: return "潜艇声"
            case .basso: return "低音声"
            case .bottle: return "瓶子声"
            case .frog: return "青蛙声"
            case .funk: return "放克声"
            case .morse: return "电报声"
            case .ping: return "乒乓声"
            case .pop: return "爆破声"
            case .purr: return "呼噜声"
            case .sosumi: return "经典声"
        }
    }
}

// 计时器管理器，作为单例，在应用程序的不同部分之间共享计时器状态
class TimerManager: ObservableObject {
    // 单例实例
    static let shared = TimerManager()

    // UserDefaults中存储设置的键
    private let workMinutesKey = "workMinutes"
    private let breakMinutesKey = "breakMinutes"
    private let promptSoundEnabledKey = "promptSoundEnabled"
    private let promptMinIntervalKey = "promptMinInterval"
    private let promptMaxIntervalKey = "promptMaxInterval"
    private let microBreakSecondsKey = "microBreakSeconds"
    private let completionTimestampsKey = "completionTimestamps" // UserDefaults key
    private let focusSessionsKey = "focusSessions" // 新增：专注会话存储键
    private let showStatusBarIconKey = "showStatusBarIcon" // 控制状态栏图标显示的键
    private let blackoutEnabledKey = "blackoutEnabled" // 控制黑屏功能的键
    private let muteAudioDuringBreakKey = "muteAudioDuringBreak" // 控制微休息期间暂停媒体播放的键
    // 音效相关键
    private let microBreakStartSoundTypeKey = "microBreakStartSoundType"
    private let microBreakEndSoundTypeKey = "microBreakEndSoundType"
    // 微休息通知键
    private let microBreakNotificationEnabledKey = "microBreakNotificationEnabled"

    // 发布的属性，当这些属性改变时，所有观察者都会收到通知
    @Published var minutes: Int = 90
    @Published var seconds: Int = 0
    @Published var isWorkMode: Bool = true
    @Published var timerRunning: Bool = false
    @Published var blackoutEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(blackoutEnabled, forKey: blackoutEnabledKey)
        }
    }
    
    @Published var muteAudioDuringBreak: Bool {
        didSet {
            UserDefaults.standard.set(muteAudioDuringBreak, forKey: muteAudioDuringBreakKey)
        }
    }
    
    // 使用重写的属性来自动保存设置的更改
    @Published var workMinutes: Int {
        didSet {
            UserDefaults.standard.set(workMinutes, forKey: workMinutesKey)
        }
    }
    
    @Published var breakMinutes: Int {
        didSet {
            UserDefaults.standard.set(breakMinutes, forKey: breakMinutesKey)
        }
    }
    
    @Published var promptSoundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(promptSoundEnabled, forKey: promptSoundEnabledKey)
        }
    }
    
    @Published var promptMinInterval: Int {
        didSet {
            UserDefaults.standard.set(promptMinInterval, forKey: promptMinIntervalKey)
            // 确保最小间隔不大于最大间隔
            if promptMinInterval > promptMaxInterval {
                promptMaxInterval = promptMinInterval
            }
        }
    }
    
    @Published var promptMaxInterval: Int {
        didSet {
            UserDefaults.standard.set(promptMaxInterval, forKey: promptMaxIntervalKey)
            // 确保最大间隔不小于最小间隔
            if promptMaxInterval < promptMinInterval {
                promptMaxInterval = promptMinInterval
            }
        }
    }
    
    @Published var microBreakSeconds: Int {
        didSet {
            UserDefaults.standard.set(microBreakSeconds, forKey: microBreakSecondsKey)
        }
    }
    
    // 作为纯菜单栏应用，状态栏图标始终显示（只读属性）
    let showStatusBarIcon: Bool = true
    
    @Published private var completionTimestamps: [Date] = [] // Store completion timestamps
    @Published var focusSessions: [FocusSession] = [] // 新增：专注会话数组

    // 微休息开始和结束的声音设置
    @Published var microBreakStartSoundType: SoundType {
        didSet {
            UserDefaults.standard.set(microBreakStartSoundType.rawValue, forKey: microBreakStartSoundTypeKey)
        }
    }

    @Published var microBreakEndSoundType: SoundType {
        didSet {
            UserDefaults.standard.set(microBreakEndSoundType.rawValue, forKey: microBreakEndSoundTypeKey)
        }
    }
    
    // 微休息通知设置
    @Published var microBreakNotificationEnabled: Bool {
        didSet {
            UserDefaults.standard.set(microBreakNotificationEnabled, forKey: microBreakNotificationEnabledKey)
        }
    }

    // 计时器
    private var timer: Timer? = nil
    private var promptTimer: Timer? = nil
    private var secondPromptTimer: Timer? = nil
    private var nextPromptInterval: TimeInterval = 0
    
    // 新增：当前会话追踪
    private var currentSessionStartTime: Date?

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
    private init() {
        // 从UserDefaults加载保存的设置，如果没有则使用默认值
        // 工作时间设置
        if UserDefaults.standard.object(forKey: workMinutesKey) != nil {
            self.workMinutes = UserDefaults.standard.integer(forKey: workMinutesKey)
        } else {
            self.workMinutes = 90 // 默认值
        }

        // 休息时间设置
        if UserDefaults.standard.object(forKey: breakMinutesKey) != nil {
            self.breakMinutes = UserDefaults.standard.integer(forKey: breakMinutesKey)
        } else {
            self.breakMinutes = 20 // 默认值
        }

        // 声音启用设置
        if UserDefaults.standard.object(forKey: promptSoundEnabledKey) != nil {
            self.promptSoundEnabled = UserDefaults.standard.bool(forKey: promptSoundEnabledKey)
        } else {
            self.promptSoundEnabled = true // 默认值
        }

        // 提示音最小间隔设置
        if UserDefaults.standard.object(forKey: promptMinIntervalKey) != nil {
            self.promptMinInterval = UserDefaults.standard.integer(forKey: promptMinIntervalKey)
        } else {
            self.promptMinInterval = 3 // 默认值
        }

        // 提示音最大间隔设置
        if UserDefaults.standard.object(forKey: promptMaxIntervalKey) != nil {
            self.promptMaxInterval = UserDefaults.standard.integer(forKey: promptMaxIntervalKey)
        } else {
            self.promptMaxInterval = 5 // 默认值
        }

        // 微休息时间设置
        if UserDefaults.standard.object(forKey: microBreakSecondsKey) != nil {
            self.microBreakSeconds = UserDefaults.standard.integer(forKey: microBreakSecondsKey)
        } else {
            self.microBreakSeconds = 10 // 默认值
        }

        // 作为纯菜单栏应用，状态栏图标始终显示，不需要从UserDefaults加载
        
        // 黑屏功能设置
        if UserDefaults.standard.object(forKey: blackoutEnabledKey) != nil {
            self.blackoutEnabled = UserDefaults.standard.bool(forKey: blackoutEnabledKey)
        } else {
            self.blackoutEnabled = false // 默认不启用
        }

        // 微休息期间音频静音设置
        if UserDefaults.standard.object(forKey: muteAudioDuringBreakKey) != nil {
            self.muteAudioDuringBreak = UserDefaults.standard.bool(forKey: muteAudioDuringBreakKey)
        } else {
            self.muteAudioDuringBreak = false // 默认关闭视频控制
        }
        
        // 微休息开始声音设置
        if let soundTypeString = UserDefaults.standard.string(forKey: microBreakStartSoundTypeKey),
           let soundType = SoundType(rawValue: soundTypeString) {
            self.microBreakStartSoundType = soundType
        } else {
            self.microBreakStartSoundType = .glass // 默认值改为玻璃声
        }

        // 微休息结束声音设置
        if let soundTypeString = UserDefaults.standard.string(forKey: microBreakEndSoundTypeKey),
           let soundType = SoundType(rawValue: soundTypeString) {
            self.microBreakEndSoundType = soundType
        } else {
            self.microBreakEndSoundType = .hero // 默认值改为完成声
        }

        // 微休息通知设置
        if UserDefaults.standard.object(forKey: microBreakNotificationEnabledKey) != nil {
            self.microBreakNotificationEnabled = UserDefaults.standard.bool(forKey: microBreakNotificationEnabledKey)
        } else {
            self.microBreakNotificationEnabled = true // 默认启用微休息通知
        }

        // 初始化计时器状态
        self.minutes = self.workMinutes
        
        // 加载专注会话数据
        if let savedSessionsData = UserDefaults.standard.data(forKey: focusSessionsKey),
           let decodedSessions = try? JSONDecoder().decode([FocusSession].self, from: savedSessionsData) {
            self.focusSessions = decodedSessions
            // 清理旧的会话数据
            cleanupOldSessionsIfNeeded()
        }
        
        // 加载完成时间戳（用于向后兼容）
        if let savedTimestampsData = UserDefaults.standard.data(forKey: completionTimestampsKey),
           let decodedTimestamps = try? JSONDecoder().decode([Date].self, from: savedTimestampsData) {
            self.completionTimestamps = decodedTimestamps
            // 如果focusSessions为空但有时间戳，进行数据迁移
            if focusSessions.isEmpty && !decodedTimestamps.isEmpty {
                migrateFromTimestampsToSessions(timestamps: decodedTimestamps)
            }
            // Cleanup timestamps older than the start of the current "day" (5 AM)
            cleanupOldTimestampsIfNeeded()
        }
    }

    // 计算今天（凌晨5点起）完成的专注周期数
    var completedSessionsToday: Int {
        let now = Date()
        let calendar = Calendar.current

        // 获取今天的 5 AM 时间点
        guard var startOfToday5AM = calendar.date(bySettingHour: 5, minute: 0, second: 0, of: now) else {
            print("Error: Could not calculate today's 5 AM.")
            return 0 // 无法计算，返回0
        }

        // 如果当前时间早于凌晨5点，则"今天"是从昨天凌晨5点开始的
        if calendar.component(.hour, from: now) < 5 {
            if let yesterday5AM = calendar.date(byAdding: .day, value: -1, to: startOfToday5AM) {
                startOfToday5AM = yesterday5AM
            } else {
                 print("Error: Could not calculate yesterday's 5 AM.")
                 return 0 // 无法计算，返回0
            }
        }

        // 获取明天的 5 AM 时间点
        guard let startOfTomorrow5AM = calendar.date(byAdding: .day, value: 1, to: startOfToday5AM) else {
             print("Error: Could not calculate tomorrow's 5 AM.")
            return 0 // 无法计算，返回0
        }

        // 筛选出在今天5AM到明天5AM之间的时间戳
        let todayTimestamps = completionTimestamps.filter { $0 >= startOfToday5AM && $0 < startOfTomorrow5AM }

        #if DEBUG
        // print("Calculating completedSessionsToday: Now=\(now), Today5AM=\(startOfToday5AM), Tomorrow5AM=\(startOfTomorrow5AM), Count=\(todayTimestamps.count)")
        // print("All Timestamps: \(completionTimestamps)")
        #endif

        return todayTimestamps.count
    }

    // 开始计时器
    func startTimer() {
        // 如果计时器已经在运行，则不执行任何操作
        guard !timerRunning else { return }

        timerRunning = true
        
        // 记录会话开始时间（仅工作模式）
        if isWorkMode {
            currentSessionStartTime = Date()
        }
        
        // 在计时器实际启动后发送开始声音通知
        if promptSoundEnabled { // 检查是否启用声音
            NotificationCenter.default.post(name: .playStartSound, object: nil)
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if self.seconds > 0 {
                self.seconds -= 1
            } else if self.minutes > 0 {
                self.minutes -= 1
                self.seconds = 59
            } else {
                // 计时器归零，先停止计时器，再处理模式切换和声音
                self.timer?.invalidate()
                self.timer = nil
                self.timerRunning = false // 更新状态

                // 记录当前模式，用于判断播放哪个声音
                let wasWorkMode = self.isWorkMode

                // 切换模式
                if wasWorkMode {
                    // 记录完成的专注会话
                    if let startTime = self.currentSessionStartTime {
                        let endTime = Date()
                        let session = FocusSession(
                            startTime: startTime,
                            endTime: endTime,
                            durationMinutes: self.workMinutes,
                            isWorkSession: true
                        )
                        self.focusSessions.append(session)
                        self.saveFocusSessions()
                        self.currentSessionStartTime = nil
                    }
                    
                    // 工作模式结束，发送结束声音通知，然后切换到休息模式
                    if self.promptSoundEnabled {
                        NotificationCenter.default.post(name: .playEndSound, object: nil)
                    }
                    self.isWorkMode = false
                    self.minutes = self.breakMinutes
                    self.completionTimestamps.append(Date()) // Add current timestamp (保持向后兼容)
                    self.saveCompletionTimestamps() // Save updated timestamps
                    self.stopPromptSystem() // 工作结束，停止随机提示音

                    // 延迟几秒后开始休息模式，但不播放开始声音
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        guard let self = self else { return }
                        
                        // 临时禁用声音
                        let originalSoundEnabled = self.promptSoundEnabled
                        self.promptSoundEnabled = false
                        
                        // 启动休息计时器
                        self.startTimer()
                        
                        // 恢复原始声音设置
                        self.promptSoundEnabled = originalSoundEnabled
                    }

                } else {
                    // 休息模式结束，发送开始声音通知，然后切换到工作模式
                    if self.promptSoundEnabled {
                        NotificationCenter.default.post(name: .playStartSound, object: nil)
                    }
                    self.isWorkMode = true
                    self.minutes = self.workMinutes
                    // 休息结束后不再自动启动计时器
                }

                self.seconds = 0 // 重置秒数

                // 如果切换回工作模式且启用了提示音，则启动随机提示音系统
                if self.isWorkMode && self.promptSoundEnabled {
                    // startPromptTimer() // 考虑是否在这里启动，或者在 startTimer 手动调用时启动
                    // 保留，因为如果用户手动开始专注，提示音应该启动
                }

                // 发送通知
                NotificationCenter.default.post(name: .timerModeChanged, object: nil)
                // 确保状态栏也更新模式切换后的初始时间
                NotificationCenter.default.post(name: .timerUpdated, object: nil)
                // 状态改变通知 (因为计时器状态变为停止或开始休息)
                NotificationCenter.default.post(name: .timerStateChanged, object: nil)

                // // 在模式切换后重新启动计时器（如果需要连续运行） - 已移动到 if wasWorkMode 块内
                //  self.startTimer() // 自动开始下一轮计时
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
        // 仅在计时器实际运行时才执行停止操作
        guard timerRunning else { return }

        timerRunning = false
        timer?.invalidate()
        timer = nil

        // 停止提示音系统
        stopPromptSystem()

        // 发送通知，计时器状态已改变
        NotificationCenter.default.post(name: .timerStateChanged, object: nil)
        // 不需要在这里播放声音，因为这是手动停止
    }

    // 重置计时器
    func resetTimer() {
        stopTimer() // 停止当前计时器和提示音

        let needsModeChange = !isWorkMode // 检查是否处于休息模式

        // 总是重置回工作模式
        isWorkMode = true
        minutes = workMinutes
        seconds = 0

        // 发送通知，告知UI更新
        NotificationCenter.default.post(name: .timerUpdated, object: nil)
        if needsModeChange {
            // 如果之前是休息模式，额外发送模式改变通知
            NotificationCenter.default.post(name: .timerModeChanged, object: nil)
        }
        // 总是发送状态改变通知，因为计时器停止了
        NotificationCenter.default.post(name: .timerStateChanged, object: nil)

        // 可选：如果重置前计时器在运行，则自动开始新的工作计时
        // if wasRunning {
        //     startTimer()
        // }
    }

    // 启动随机提示音计时器
    func startPromptTimer() {
        guard isWorkMode && promptSoundEnabled else { return }

        // 停止现有计时器
        promptTimer?.invalidate()
        secondPromptTimer?.invalidate()

        // 生成随机间隔（转换为秒）
        let minSeconds = promptMinInterval * 60
        let maxSeconds = promptMaxInterval * 60
        
        // 安全检查：确保范围有效
        let safeMinSeconds = min(minSeconds, maxSeconds)
        let safeMaxSeconds = max(minSeconds, maxSeconds)
        
        nextPromptInterval = TimeInterval(Int.random(in: safeMinSeconds...safeMaxSeconds))

        // 创建新的计时器
        promptTimer = Timer.scheduledTimer(withTimeInterval: nextPromptInterval, repeats: false) { [weak self] _ in
            guard let self = self else { return }

            // 播放微休息开始提示音
            NotificationCenter.default.post(
                name: .playMicroBreakStartSound,
                object: self.microBreakStartSoundType.rawValue
            )
            
            // 如果启用了微休息通知，发送通知
            if self.microBreakNotificationEnabled {
                NotificationCenter.default.post(name: .microBreakStartNotification, object: nil)
            }
            
            // 如果启用了黑屏，发送黑屏通知
            if self.blackoutEnabled {
                NotificationCenter.default.post(name: .showBlackout, object: nil)
            }

            // 安排微休息时间后的第二次提示音
            self.scheduleSecondPrompt()
        }
    }

    // 安排微休息时间后的第二次提示音
    func scheduleSecondPrompt() {
        secondPromptTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(microBreakSeconds), repeats: false) { [weak self] _ in
            guard let self = self else { return }

            // 播放微休息结束提示音
            NotificationCenter.default.post(
                name: .playMicroBreakEndSound,
                object: self.microBreakEndSoundType.rawValue
            )
            
            // 如果启用了微休息通知，发送通知
            if self.microBreakNotificationEnabled {
                NotificationCenter.default.post(name: .microBreakEndNotification, object: nil)
            }
            
            // 如果启用了黑屏，发送结束黑屏通知
            if self.blackoutEnabled {
                NotificationCenter.default.post(name: .hideBlackout, object: nil)
            }

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

    // Helper function to save timestamps to UserDefaults
    private func saveCompletionTimestamps() {
        DispatchQueue.global(qos: .background).async {
            if let encoded = try? JSONEncoder().encode(self.completionTimestamps) {
                UserDefaults.standard.set(encoded, forKey: self.completionTimestampsKey)
                #if DEBUG
                // print("Saved \(self.completionTimestamps.count) timestamps.")
                #endif
            } else {
                print("Error: Failed to encode completion timestamps.")
            }
        }
    }

    // Helper function to remove old timestamps on init
    private func cleanupOldTimestampsIfNeeded() {
        let now = Date()
        let calendar = Calendar.current
        guard var startOfCurrentDay5AM = calendar.date(bySettingHour: 5, minute: 0, second: 0, of: now) else { return }
        if calendar.component(.hour, from: now) < 5 {
             if let yesterday5AM = calendar.date(byAdding: .day, value: -1, to: startOfCurrentDay5AM) {
                 startOfCurrentDay5AM = yesterday5AM
             } else {
                 return // Error calculating yesterday
             }
        }

         let originalCount = completionTimestamps.count
         // Remove timestamps before the start of the relevant "day"
         completionTimestamps.removeAll { $0 < startOfCurrentDay5AM }

         if completionTimestamps.count != originalCount {
            print("Cleaned up \(originalCount - completionTimestamps.count) old timestamps.")
            // No need to save here, as this is only called during init before potential modifications
         }
    }

    // Helper function to migrate from timestamps to sessions
    private func migrateFromTimestampsToSessions(timestamps: [Date]) {
        print("开始迁移时间戳数据到专注会话格式...")
        
        // 为每个时间戳创建一个默认的专注会话
        let migratedSessions = timestamps.map { timestamp in
            // 假设每个会话持续工作时间长度
            let startTime = Calendar.current.date(byAdding: .minute, value: -workMinutes, to: timestamp) ?? timestamp
            return FocusSession(
                startTime: startTime,
                endTime: timestamp,
                durationMinutes: workMinutes,
                isWorkSession: true
            )
        }
        
        focusSessions = migratedSessions
        saveFocusSessions()
        
        print("成功迁移 \(migratedSessions.count) 个专注会话")
    }

    // Helper function to clean up old sessions
    private func cleanupOldSessionsIfNeeded() {
        let now = Date()
        let calendar = Calendar.current
        
        // 保留最近3个月的数据
        guard let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now) else { return }
        
        let originalCount = focusSessions.count
        focusSessions.removeAll { $0.startTime < threeMonthsAgo }
        
        if focusSessions.count != originalCount {
            print("清理了 \(originalCount - focusSessions.count) 个旧的专注会话记录")
            saveFocusSessions()
        }
    }

    // Helper function to save focus sessions to UserDefaults
    private func saveFocusSessions() {
        DispatchQueue.global(qos: .background).async {
            if let encoded = try? JSONEncoder().encode(self.focusSessions) {
                UserDefaults.standard.set(encoded, forKey: self.focusSessionsKey)
                #if DEBUG
                // print("Saved \(self.focusSessions.count) sessions.")
                #endif
            } else {
                print("Error: Failed to encode focus sessions.")
            }
        }
    }
}

// 通知名称扩展
extension Notification.Name {
    static let timerUpdated = Notification.Name("timerUpdated")
    static let timerStateChanged = Notification.Name("timerStateChanged")
    static let timerModeChanged = Notification.Name("timerModeChanged")
    static let playPromptSound = Notification.Name("playPromptSound")
    static let playStartSound = Notification.Name("playStartSound")
    static let playEndSound = Notification.Name("playEndSound")
    static let playMicroBreakStartSound = Notification.Name("playMicroBreakStartSound")
    static let playMicroBreakEndSound = Notification.Name("playMicroBreakEndSound")
    static let statusBarIconVisibilityChanged = Notification.Name("statusBarIconVisibilityChanged")
    static let showBlackout = Notification.Name("showBlackout")
    static let hideBlackout = Notification.Name("hideBlackout")
    static let microBreakStartNotification = Notification.Name("microBreakStartNotification")
    static let microBreakEndNotification = Notification.Name("microBreakEndNotification")
}
