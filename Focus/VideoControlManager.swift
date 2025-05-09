//
//  VideoControlManager.swift
//  Focus
//
//  Created by AI Assistant on 2025/7/16.
//

import Foundation
import AppKit

// 视频控制管理器，用于控制系统媒体播放，实现微休息期间暂停视频功能
class VideoControlManager {
    // 单例实例
    static let shared = VideoControlManager()
    
    // 私有初始化方法，防止外部创建实例
    private init() {}
    
    // 暂停视频（模拟按下媒体键）
    func pauseVideo() {
        guard TimerManager.shared.muteAudioDuringBreak else { return }
        
        // 模拟按下播放/暂停键 (F8)
        simulateMediaKeyPress(.playPause)
        print("已发送暂停媒体播放命令")
    }
    
    // 恢复视频播放（模拟按下媒体键）
    func resumeVideo() {
        guard TimerManager.shared.muteAudioDuringBreak else { return }
        
        // 模拟按下播放/暂停键 (F8)
        simulateMediaKeyPress(.playPause)
        print("已发送恢复媒体播放命令")
    }
    
    // 模拟按下媒体键
    private func simulateMediaKeyPress(_ key: MediaKey) {
        // 获取keyCode
        let keyCode: Int
        switch key {
        case .playPause:
            keyCode = 16 // NX_KEYTYPE_PLAY (16)
        case .next:
            keyCode = 17 // NX_KEYTYPE_NEXT (17)
        case .previous:
            keyCode = 18 // NX_KEYTYPE_PREVIOUS (18)
        case .volumeUp:
            keyCode = 0  // NX_KEYTYPE_SOUND_UP (0)
        case .volumeDown:
            keyCode = 1  // NX_KEYTYPE_SOUND_DOWN (1)
        case .mute:
            keyCode = 7  // NX_KEYTYPE_MUTE (7)
        }
        
        // 使用NSEvent发送媒体键事件
        let keyDownEvent = NSEvent.otherEvent(
            with: .systemDefined,
            location: NSPoint.zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: 0xa00),
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: Int16(8),
            data1: (keyCode << 16) | (0xa << 8),
            data2: -1
        )
        
        if let event = keyDownEvent, let cgEvent = event.cgEvent {
            cgEvent.post(tap: .cghidEventTap)
        }
        
        // 短暂延迟
        usleep(10000) // 10毫秒
        
        // 发送键释放事件
        let keyUpEvent = NSEvent.otherEvent(
            with: .systemDefined,
            location: NSPoint.zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: 0xa00),
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: Int16(8),
            data1: (keyCode << 16) | (0xb << 8),
            data2: -1
        )
        
        if let event = keyUpEvent, let cgEvent = event.cgEvent {
            cgEvent.post(tap: .cghidEventTap)
        }
    }
    
    // 媒体键枚举
    enum MediaKey {
        case playPause
        case next
        case previous
        case volumeUp
        case volumeDown
        case mute
    }
} 