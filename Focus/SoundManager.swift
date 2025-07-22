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
class SoundManager: ObservableObject {
    // 单例实例
    static let shared = SoundManager()
    
    // 音频播放器
    private var audioPlayer: AVAudioPlayer?
    
    // 添加音频URL缓存字典
    private var soundURLCache: [String: URL?] = [:]
    
    // 添加音频播放器缓存字典
    private var audioPlayerCache: [String: AVAudioPlayer] = [:]
    
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
    private init() {
        // 从 UserDefaults 加载保存的设置，使用新的默认值
        self.endSoundName = UserDefaults.standard.string(forKey: endSoundKey) ?? "BellRing"  // 专注结束：清铃
        self.microBreakStartSoundName = UserDefaults.standard.string(forKey: microBreakStartSoundKey) ?? "Ding"  // 微休息开始：点击
        self.microBreakEndSoundName = UserDefaults.standard.string(forKey: microBreakEndSoundKey) ?? "Ba"  // 微休息结束：轻提
        self.breakEndSoundName = UserDefaults.standard.string(forKey: breakEndSoundKey) ?? "Piano"  // 休息结束：钢琴
        
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
        print("【播放声音】专注结束 - \(endSoundName)")
        playSystemSound(named: endSoundName)
    }
    
    // 播放微休息开始音效
    @objc private func playMicroBreakStartSound() {
        print("【播放声音】微休息开始 - \(microBreakStartSoundName)")
        playSystemSound(named: microBreakStartSoundName)
    }
    
    // 播放微休息结束音效
    @objc private func playMicroBreakEndSound() {
        print("【播放声音】微休息结束 - \(microBreakEndSoundName)")
        playSystemSound(named: microBreakEndSoundName)
    }
    
    // 播放休息结束音效
    @objc private func playBreakEndSound() {
        print("【播放声音】休息结束 - \(breakEndSoundName)")
        playSystemSound(named: breakEndSoundName)
    }
    
    // 播放系统声音的通用方法
    private func playSystemSound(named soundName: String) {
        // 如果是"无"声音，播放系统声音ID为0但不播放实际音效
        if soundName == "无" {
            print("选择了无声音，不播放音效")
            return
        }
        
        // 从缓存中获取播放器
        if let player = audioPlayerCache[soundName] {
            // 如果播放器正在播放，先停止
            if player.isPlaying {
                player.stop()
                player.currentTime = 0
            }
            
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
enum SoundType {
    case microBreakStart  // 微休息开始
    case microBreakEnd    // 微休息结束
    case focusEnd         // 专注结束
    case breakEnd         // 休息结束
}

// 添加新的通知名称
extension Notification.Name {
    static let playBreakEndSound = Notification.Name("playBreakEndSound")
}