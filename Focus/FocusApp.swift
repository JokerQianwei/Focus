//
//  FocusApp.swift
//  Focus
//
//  Created by 杨乾巍 on 2025/4/28.
//

import SwiftUI
import UserNotifications
import AVFoundation
import AudioToolbox

@main
struct FocusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var timerManager = TimerManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(timerManager)
                .frame(width: 320, height: 470)
                .fixedSize(horizontal: true, vertical: true)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize)
        .commands {
            // 添加自定义菜单命令
            CommandGroup(replacing: .appInfo) {
                Button("关于专注时钟") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey.applicationName: "专注时钟",
                            NSApplication.AboutPanelOptionKey.applicationVersion: "1.0",
                            NSApplication.AboutPanelOptionKey.credits: NSAttributedString(
                                string: "一个简单的专注时钟应用，帮助您提高工作效率。"
                            )
                        ]
                    )
                }
            }
        }
    }
}

// 应用程序代理，用于处理应用程序级别的事件
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var statusBarController: StatusBarController?
    private var audioPlayer: AVAudioPlayer?
    private var mainWindowController: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 请求通知权限
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("通知权限已获取")
            } else if let error = error {
                print("通知权限请求失败: \(error.localizedDescription)")
            }
        }

        // 初始化菜单栏控制器
        statusBarController = StatusBarController()
        
        // 初始化主窗口控制器
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let mainWindow = NSApp.windows.first(where: { !$0.title.isEmpty }) {
                self.mainWindowController = NSWindowController(window: mainWindow)
            }
        }

        // 设置音频播放器
        setupAudioPlayer()
        
        // 禁用窗口状态恢复
        NSWindow.allowsAutomaticWindowTabbing = false
        UserDefaults.standard.set(false, forKey: "NSQuitAlwaysKeepsWindows")

        // 确保窗口尺寸固定
        ensureFixedWindowSize()

        // 监听提示音播放请求
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playPromptSound),
            name: .playPromptSound,
            object: nil
        )

        // 监听计时器模式变化，发送通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sendTimerNotification),
            name: .timerModeChanged,
            object: nil
        )
        
        // 监听状态栏图标可见性变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(statusBarIconVisibilityChanged),
            name: .statusBarIconVisibilityChanged,
            object: nil
        )
    }
    
    // 当应用程序激活时也确保窗口尺寸
    func applicationDidBecomeActive(_ notification: Notification) {
        ensureFixedWindowSize()
    }
    
    // 确保窗口尺寸固定的方法
    private func ensureFixedWindowSize() {
        if let window = NSApplication.shared.windows.first {
            window.styleMask.remove(.resizable)
            window.setContentSize(NSSize(width: 320, height: 490))
            
            // 如果窗口处于缩放状态，则取消缩放
            if window.isZoomed {
                window.zoom(nil)
            }
            
            window.setFrameAutosaveName("") // 清除自动保存的名称，防止系统恢复
        }
    }

    // 初始化音频播放器
    private func setupAudioPlayer() {
        // 使用系统声音
        let soundURL = URL(fileURLWithPath: "/System/Library/Sounds/Tink.aiff")

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.volume = 0.7 // 设置音量
        } catch {
            print("初始化音频播放器失败: \(error.localizedDescription)")
        }
    }

    // 播放提示音
    @objc private func playPromptSound() {
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

    // 发送计时器通知
    @objc private func sendTimerNotification() {
        let timerManager = TimerManager.shared
        let content = UNMutableNotificationContent()

        if timerManager.isWorkMode {
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

    // 当应用程序在前台时接收到通知
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 即使应用程序在前台，也显示通知
        completionHandler([.banner, .sound])
    }

    // 状态栏图标可见性变化的处理
    @objc private func statusBarIconVisibilityChanged() {
        // 在这里可以添加额外的逻辑，如果需要的话
        // 例如，如果图标不可见且窗口也不可见，可以将窗口设为可见
        if !TimerManager.shared.showStatusBarIcon {
            let windowsVisible = NSApp.windows.contains(where: { $0.isVisible })
            if !windowsVisible {
                // 如果没有可见窗口，显示主窗口
                NSApp.setActivationPolicy(.regular)
                // 检查是否已有主窗口控制器，如果没有则尝试获取
                if mainWindowController == nil {
                    if let mainWindow = NSApp.windows.first(where: { !$0.title.isEmpty }) {
                        mainWindowController = NSWindowController(window: mainWindow)
                    }
                }
                
                if let controller = mainWindowController {
                    controller.showWindow(self)
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }
    }
}
