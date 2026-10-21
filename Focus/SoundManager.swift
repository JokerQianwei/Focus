//
//  SoundManager.swift
//  Focus
//
//  Created by 杨乾巍 on 2025/4/28.
//

import Foundation
import AVFoundation
import AppKit

// 声音管理类，负责处理所有的声音播放请求
class SoundManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    // 单例实例
    static let shared = SoundManager()
    
    // 音频播放器
    private var audioPlayer: AVAudioPlayer?
    
    // 添加音频URL缓存字典
    private var soundURLCache: [String: URL?] = [:]
    
    // 添加音频播放器缓存字典
    private var audioPlayerCache: [String: AVAudioPlayer] = [:]
    
    // 自定义（用户自选文件）音效播放器
    private var customPlayer: AVAudioPlayer?
    private var customScopedURL: CustomSoundStore.ScopedURL?
    private var customPlayingType: SoundType?
    
    // 各类音效当前的自定义文件名，用于界面显示；为空表示使用系统音效
    @Published private(set) var customFileNames: [String: String] = [:]
    
    // UserDefaults中存储声音设置的键
    private let endSoundKey = "endSound"
    private let microBreakStartSoundKey = "microBreakStartSound"  // 新增：微休息开始音效
    private let microBreakEndSoundKey = "microBreakEndSound"      // 新增：微休息结束音效
    private let breakEndSoundKey = "breakEndSound"                // 新增：休息结束音效
    
    // 系统声音选项
    static let systemSoundOptions = [
        "无",
        "Livechat",            // 完成
        "Ba",                  // 轻提
        "DingEnd",             // 连击
        "KeTingEnd",           // 钟声
        "BellNotification",    // 铃声
        "BellRing",            // 清铃
        "Deng",                // 短鸣
        "Ding",                // 点击
        "Notification",        // 通知
        "Notification2",       // 清新
        "Notification3",       // 广播
        "Piano",               // 钢琴
        "Rock",                // 摇滚
    ]
    
    // 文件名到显示名称的映射
    static let fileToDisplayName: [String: String] = [
        "无": "无",
        "KeTingEnd": "钟声",
        "Ba": "轻提",
        "BellNotification": "铃声",
        "BellRing": "清铃",
        "Deng": "短鸣",
        "Ding": "点击",
        "DingEnd": "连击",
        "Livechat": "完成",
        "Notification": "通知",
        "Notification2": "清新",
        "Notification3": "广播",
        "Piano": "钢琴",
        "Rock": "摇滚"
    ]
    
    // 获取声音的显示名称
    static func getDisplayName(for soundName: String) -> String {
        return fileToDisplayName[soundName] ?? soundName
    }
    
    // 获取带默认标记的显示名称
    static func getDisplayNameWithDefault(for soundName: String, defaultSound: String) -> String {
        let displayName = getDisplayName(for: soundName)
        if soundName == defaultSound {
            return "\(displayName)（默认）"
        }
        return displayName
    }
    
    // 获取特定音效类型的有序选项列表
    static func getOrderedSoundOptions(for soundType: SoundType) -> [String] {
        let defaultSound = getDefaultSound(for: soundType)
        var orderedOptions = ["无"]  // "无" 始终在第一位
        
        // 将默认音效放在第二位
        if defaultSound != "无" {
            orderedOptions.append(defaultSound)
        }
        
        // 添加其他音效选项
        let otherOptions = systemSoundOptions.filter { $0 != "无" && $0 != defaultSound }
        orderedOptions.append(contentsOf: otherOptions)
        
        return orderedOptions
    }
    
    // 获取默认音效
    static func getDefaultSound(for soundType: SoundType) -> String {
        switch soundType {
        case .microBreakStart:
            return "Ding"      // 点击
        case .microBreakEnd:
            return "Ba"        // 轻提
        case .focusEnd:
            return "BellRing"  // 清铃
        case .breakEnd:
            return "Piano"     // 钢琴
        }
    }
    
    // 专注开始声音固定为"Ding"
    let startSoundName = "Ding"
    
    // 获取结束声音名称
    @Published var endSoundName: String {
        didSet {
            UserDefaults.standard.set(endSoundName, forKey: endSoundKey)
        }
    }
    
    // 获取微休息开始音效名称
    @Published var microBreakStartSoundName: String {
        didSet {
            UserDefaults.standard.set(microBreakStartSoundName, forKey: microBreakStartSoundKey)
        }
    }
    
    // 获取微休息结束音效名称
    @Published var microBreakEndSoundName: String {
        didSet {
            UserDefaults.standard.set(microBreakEndSoundName, forKey: microBreakEndSoundKey)
        }
    }
    
    // 获取休息结束音效名称
    @Published var breakEndSoundName: String {
        didSet {
            UserDefaults.standard.set(breakEndSoundName, forKey: breakEndSoundKey)
        }
    }
    
    // 私有初始化方法
    private override init() {
        // 从 UserDefaults 加载保存的设置，使用新的默认值
        self.endSoundName = UserDefaults.standard.string(forKey: endSoundKey) ?? "BellRing"  // 专注结束：清铃
        self.microBreakStartSoundName = UserDefaults.standard.string(forKey: microBreakStartSoundKey) ?? "Ding"  // 微休息开始：点击
        self.microBreakEndSoundName = UserDefaults.standard.string(forKey: microBreakEndSoundKey) ?? "Ba"  // 微休息结束：轻提
        self.breakEndSoundName = UserDefaults.standard.string(forKey: breakEndSoundKey) ?? "Piano"  // 休息结束：钢琴
        
        super.init()
        
        // 加载自定义音效文件名（书签本身在播放时解析）
        var names: [String: String] = [:]
        for type in SoundType.allCases {
            if let name = CustomSoundStore.fileName(for: type) {
                names[type.rawValue] = name
            }
        }
        self.customFileNames = names
        
        // 设置音频会话
        setupAudioSession()
        
        // 注册通知观察者
        registerNotificationObservers()
        
        // 预加载常用的音效文件
        preloadCommonSounds()
    }


    
    // 预加载常用的音效文件
    private func preloadCommonSounds() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // 预加载主要使用的音效文件
            let commonSounds = [self.startSoundName, self.endSoundName, 
                               self.microBreakStartSoundName, self.microBreakEndSoundName, 
                               self.breakEndSoundName]
            
            for soundName in commonSounds {
                if soundName != "无" {
                    self.cacheSound(named: soundName)
                }
            }
            
            print("常用音效文件预加载完成")
        }
    }
    
    // 缓存音效文件
    private func cacheSound(named soundName: String) {
        if soundName == "无" { return }
        
        // 如果URL已缓存且播放器已创建，则不需要再次处理
        if self.audioPlayerCache[soundName] != nil { return }
        
        // 获取音效文件URL
        if let url = getSoundURL(for: soundName) {
            // 缓存URL
            self.soundURLCache[soundName] = url
            
            do {
                // 创建并缓存播放器
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                self.audioPlayerCache[soundName] = player
                print("已缓存音效: \(soundName)")
            } catch {
                print("无法创建音效播放器: \(soundName), 错误: \(error.localizedDescription)")
            }
        }
    }
    
    // 设置音频会话
    private func setupAudioSession() {
        // macOS 不需要设置音频会话类别
        // AVAudioSession 是 iOS 特有的
    }
    
    // 注册通知观察者
    private func registerNotificationObservers() {
        // 监听开始声音通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playStartSound),
            name: .playStartSound,
            object: nil
        )
        
        // 监听结束声音通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playEndSound),
            name: .playEndSound,
            object: nil
        )
        
        // 监听微休息开始音效通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playMicroBreakStartSound),
            name: .playMicroBreakStartSound,
            object: nil
        )
        
        // 监听微休息结束音效通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playMicroBreakEndSound),
            name: .playMicroBreakEndSound,
            object: nil
        )
        
        // 监听休息结束音效通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playBreakEndSound),
            name: .playBreakEndSound,
            object: nil
        )
    }
    
    // 播放开始声音
    @objc private func playStartSound() {
        print("【播放声音】专注开始 - \(startSoundName)")
        playSystemSound(named: startSoundName)
    }
    
    // 播放结束声音
    @objc private func playEndSound() {
        playSound(for: .focusEnd)
    }
    
    // 播放微休息开始音效
    @objc private func playMicroBreakStartSound() {
        playSound(for: .microBreakStart)
    }
    
    // 播放微休息结束音效
    @objc private func playMicroBreakEndSound() {
        playSound(for: .microBreakEnd)
    }
    
    // 播放休息结束音效
    @objc private func playBreakEndSound() {
        playSound(for: .breakEnd)
    }
    
    // 播放某类音效：优先自定义文件，否则回退到该类音效当前选中的系统音效
    private func playSound(for type: SoundType) {
        if hasCustomSound(for: type), playCustomSound(for: type) {
            return
        }
        playSystemSound(named: systemSoundName(for: type))
    }
    
    // 某类音效当前选中的系统音效名称
    private func systemSoundName(for type: SoundType) -> String {
        switch type {
        case .microBreakStart:
            return microBreakStartSoundName
        case .microBreakEnd:
            return microBreakEndSoundName
        case .focusEnd:
            return endSoundName
        case .breakEnd:
            return breakEndSoundName
        }
    }
    
    // MARK: - 自定义音效
    
    // 该校验是否设置了自定义文件
    func hasCustomSound(for type: SoundType) -> Bool {
        return customFileNames[type.rawValue] != nil
    }
    
    // 自定义文件名（含扩展名），未设置时为 nil
    func customFileName(for type: SoundType) -> String? {
        return customFileNames[type.rawValue]
    }
    
    // 设置自定义音效：验证 → 复制进容器 → 记录 → 尽力保存书签 → 试听
    func setCustomSound(url: URL, for type: SoundType) throws {
        // NSOpenPanel 返回的 URL 一般已可直接读取，这里兜底开启安全作用域
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        // 1. 先验证文件确实能被解码，避免保存一个无法播放的文件
        let probe = try AVAudioPlayer(contentsOf: url)
        probe.prepareToPlay()

        // 2. 复制进 App 容器。沙盒 + ad-hoc 签名下，持久化书签并不可靠，
        //    播放副本可以彻底绕开临时授权过期、原文件被移动/删除等问题。
        _ = try copyIntoContainer(from: url, for: type)

        // 3. 记录界面显示名
        CustomSoundStore.setFileName(url.lastPathComponent, for: type)
        customFileNames[type.rawValue] = url.lastPathComponent

        // 4. 尽力保存安全作用域书签（失败不影响使用副本播放）
        do {
            try CustomSoundStore.saveBookmark(url: url, for: type)
        } catch {
            CustomSoundStore.clearBookmark(for: type)
            print("书签保存失败(\(type.rawValue))：\(error.localizedDescription)；已使用容器副本，功能不受影响")
        }

        stopAllSounds()
        if !playCustomSound(for: type) {
            playSystemSound(named: systemSoundName(for: type))
        }
    }

    // 清除自定义音效，并播放当前选中的系统音效
    func clearCustomSound(for type: SoundType) {
        if customPlayingType == type {
            stopCustomPlayback()
        }
        removeLocalCopy(for: type)
        CustomSoundStore.clear(for: type)
        customFileNames.removeValue(forKey: type.rawValue)
        playSystemSound(named: systemSoundName(for: type))
    }

    // 试听某类音效（设置界面改动后调用，规则与实际播放一致）
    func playPreview(for type: SoundType) {
        playSound(for: type)
    }

    // 播放自定义音频，返回是否成功
    @discardableResult
    private func playCustomSound(for type: SoundType) -> Bool {
        stopAllSounds()

        // 优先播放容器内的副本
        if let localURL = localCopyURL(for: type),
           startCustomPlayer(url: localURL, type: type, scoped: nil) {
            return true
        }

        // 副本丢失时再尝试书签（兼容旧版本保存的数据）
        if let scoped = CustomSoundStore.resolve(for: type),
           startCustomPlayer(url: scoped.url, type: type, scoped: scoped) {
            return true
        }

        print("自定义音效不可用(\(type.rawValue))，回退系统音效")
        removeLocalCopy(for: type)
        CustomSoundStore.clear(for: type)
        customFileNames.removeValue(forKey: type.rawValue)
        return false
    }

    // 用指定 URL 启动自定义播放器
    private func startCustomPlayer(url: URL, type: SoundType, scoped: CustomSoundStore.ScopedURL?) -> Bool {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.volume = 1.0
            player.prepareToPlay()

            customPlayer = player
            customScopedURL = scoped
            customPlayingType = type

            player.play()
            print("【播放声音】自定义音效(\(type.rawValue)) - \(url.lastPathComponent)")
            return true
        } catch {
            print("自定义音效播放失败(\(type.rawValue)): \(error.localizedDescription)")
            scoped?.release()
            return false
        }
    }

    // MARK: - 自定义音频文件（App 容器内副本）

    private func customSoundsDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        let dir = base.appendingPathComponent("Focus/CustomSounds", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func localCopyURL(for type: SoundType) -> URL? {
        let files = (try? FileManager.default.contentsOfDirectory(at: customSoundsDirectory(), includingPropertiesForKeys: nil)) ?? []
        return files.first { $0.deletingPathExtension().lastPathComponent == type.rawValue }
    }

    private func removeLocalCopy(for type: SoundType) {
        let files = (try? FileManager.default.contentsOfDirectory(at: customSoundsDirectory(), includingPropertiesForKeys: nil)) ?? []
        for file in files where file.deletingPathExtension().lastPathComponent == type.rawValue {
            try? FileManager.default.removeItem(at: file)
        }
    }

    @discardableResult
    private func copyIntoContainer(from url: URL, for type: SoundType) throws -> URL {
        let directory = customSoundsDirectory()
        removeLocalCopy(for: type)
        let ext = url.pathExtension.isEmpty ? "audio" : url.pathExtension
        let destination = directory.appendingPathComponent(type.rawValue).appendingPathExtension(ext)
        try FileManager.default.copyItem(at: url, to: destination)
        return destination
    }

    // 停止自定义音频并释放安全作用域
    private func stopCustomPlayback() {
        if let player = customPlayer, player.isPlaying {
            player.stop()
        }
        customPlayer?.currentTime = 0
        customPlayer = nil
        customPlayingType = nil
        customScopedURL?.release()
        customScopedURL = nil
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard player === customPlayer else { return }
        // 播放结束，释放安全作用域访问
        customPlayer = nil
        customPlayingType = nil
        customScopedURL?.release()
        customScopedURL = nil
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        guard player === customPlayer else { return }
        if let error = error {
            print("自定义音效解码失败: \(error.localizedDescription)")
        }
        stopCustomPlayback()
    }
    
    // 停止所有正在播放的音效
    private func stopAllSounds() {
        for (_, player) in audioPlayerCache {
            if player.isPlaying {
                player.stop()
                player.currentTime = 0
            }
        }
        stopCustomPlayback()
    }
    
    // 播放系统声音的通用方法
    private func playSystemSound(named soundName: String) {
        // 如果是"无"声音，播放系统声音ID为0但不播放实际音效
        if soundName == "无" {
            print("选择了无声音，不播放音效")
            // 停止所有正在播放的音效
            stopAllSounds()
            return
        }
        
        // 停止所有其他正在播放的音效
        stopAllSounds()
        
        // 从缓存中获取播放器
        if let player = audioPlayerCache[soundName] {
            // 重置播放器位置
            player.currentTime = 0
            
            player.play()
            print("使用缓存的播放器播放: \(soundName)")
            return
        }
        
        // 如果播放器不在缓存中，尝试创建并缓存
        if let url = getSoundURLWithCache(for: soundName) {
            do {
                // 创建新的音频播放器
                let player = try AVAudioPlayer(contentsOf: url)
                player.volume = 1.0
                player.prepareToPlay()
                
                // 缓存播放器
                audioPlayerCache[soundName] = player
                
                player.play()
                print("创建并缓存新播放器: \(soundName)")
            } catch {
                print("播放声音失败: \(error.localizedDescription)")
            }
        } else {
            print("没有找到匹配的声音文件: \(soundName)")
        }
    }
    
    // 使用缓存获取声音URL
    private func getSoundURLWithCache(for soundName: String) -> URL? {
        // 如果是"无"，返回nil
        if soundName == "无" {
            return nil
        }
        
        // 检查URL缓存
        if let cachedURL = soundURLCache[soundName] {
            return cachedURL
        }
        
        // 如果缓存中没有，查找URL并缓存结果
        let url = getSoundURL(for: soundName)
        soundURLCache[soundName] = url
        return url
    }
    
    // 获取声音 URL
    private func getSoundURL(for soundName: String) -> URL? {
        // 如果是"无"，返回nil
        if soundName == "无" {
            return nil
        }
        
        // 支持的音频格式列表
        let supportedExtensions = ["mp3", "wav", "aiff", "m4a", "MP3", "WAV", "AIFF", "M4A"]
        
        // 首先尝试查找自定义声音文件
        for ext in supportedExtensions {
            // 先在根目录和Resources目录查找
            if let customSoundURL = Bundle.main.url(forResource: soundName, withExtension: ext) {
                print("找到自定义声音文件: \(soundName).\(ext)")
                return customSoundURL
            }
            
            // 在Resources/Sounds目录查找
            if let customSoundURL = Bundle.main.url(forResource: soundName, withExtension: ext, subdirectory: "Resources/Sounds") {
                print("在Resources/Sounds目录找到自定义声音文件: \(soundName).\(ext)")
                return customSoundURL
            }
            
            // 尝试忽略扩展名大小写
            let soundNameLower = soundName.lowercased()
            if let customSoundURL = Bundle.main.url(forResource: soundNameLower, withExtension: ext) {
                print("找到自定义声音文件(忽略大小写): \(soundNameLower).\(ext)")
                return customSoundURL
            }
            
            if let customSoundURL = Bundle.main.url(forResource: soundNameLower, withExtension: ext, subdirectory: "Resources/Sounds") {
                print("在Resources/Sounds目录找到自定义声音文件(忽略大小写): \(soundNameLower).\(ext)")
                return customSoundURL
            }
        }
        
        return nil
    }
    
    // 播放预览声音
    func playPreviewSound(named soundName: String) {
        // 播放时根据震动设置提供反馈
        playSystemSound(named: soundName)
    }
    
    // 播放测试声音
    func playTestSound() {
        print("【测试】播放测试声音")
        // 使用开始声音作为测试
        playSystemSound(named: startSoundName)
    }
}

// 音效类型枚举
enum SoundType: String, CaseIterable {
    case microBreakStart  // 微休息开始
    case microBreakEnd    // 微休息结束
    case focusEnd         // 专注结束
    case breakEnd         // 休息结束
}

// 添加新的通知名称
extension Notification.Name {
    static let playBreakEndSound = Notification.Name("playBreakEndSound")
}