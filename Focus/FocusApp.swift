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
    private var blackoutWindowController: BlackoutWindowController?
    private var videoControlManager: VideoControlManager?

    // 音频播放器字典，用于存储预加载的音效
    private var audioPlayers: [SoundType: AVAudioPlayer] = [:]

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 设置通知中心代理（不主动申请权限）
        // UNUserNotificationCenter.current().delegate = self
        requestNotificationPermission()
        
        // 初始化菜单栏控制器
        statusBarController = StatusBarController()
        
        // 初始化黑屏窗口控制器
        blackoutWindowController = BlackoutWindowController.shared
        
        // 初始化视频控制管理器
        videoControlManager = VideoControlManager.shared
        
        // 初始化主窗口控制器并显示窗口
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let mainWindow = NSApp.windows.first(where: { window in
                // 查找主窗口：包含内容且尺寸合理
                let hasContentView = window.contentViewController != nil
                let isReasonableSize = window.frame.width > 250 && window.frame.height > 400
                let isNotStatusBar = window.frame.height > 100
                return hasContentView && isReasonableSize && isNotStatusBar
            }) {
                self.mainWindowController = NSWindowController(window: mainWindow)
                
                // 默认显示主窗口
                self.showMainWindowOnStartup(window: mainWindow)
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
        
        // 监听微休息开始音效请求
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playMicroBreakStartSound),
            name: .playMicroBreakStartSound,
            object: nil
        )

        // 监听微休息结束音效请求
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playMicroBreakEndSound),
            name: .playMicroBreakEndSound,
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
        
        // 监听黑屏显示请求
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowBlackout),
            name: .showBlackout,
            object: nil
        )
        
        // 监听黑屏隐藏请求
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHideBlackout),
            name: .hideBlackout,
            object: nil
        )
        
        // 监听微休息开始通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sendMicroBreakStartNotification),
            name: .microBreakStartNotification,
            object: nil
        )
        
        // 监听微休息结束通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sendMicroBreakEndNotification),
            name: .microBreakEndNotification,
            object: nil
        )
        
        // 调试：测试通知权限（仅在调试模式下）
        #if DEBUG
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            NotificationTest.shared.testNotificationPermission()
        }
        #endif
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
        // 预加载所有可能的音效
        for soundType in SoundType.allCases {
            let soundURL = URL(fileURLWithPath: "/System/Library/Sounds/\(soundType.fileName)")
            
            do {
                let player = try AVAudioPlayer(contentsOf: soundURL)
                player.prepareToPlay()
                player.volume = 0.7 // 设置音量
                
                // 存储到字典中
                audioPlayers[soundType] = player
            } catch {
                print("初始化音频播放器失败: \(soundType.rawValue) - \(error.localizedDescription)")
            }
        }
        
        // 为保持兼容性，仍然初始化默认的audioPlayer
        let defaultSoundURL = URL(fileURLWithPath: "/System/Library/Sounds/Tink.aiff")
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: defaultSoundURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.volume = 0.7
        } catch {
            print("初始化默认音频播放器失败: \(error.localizedDescription)")
        }
    }
    
    // 播放特定类型的声音
    private func playSound(of type: SoundType) {
        // 如果选择了"无"，则不播放任何声音
        if type == .none {
            return
        }
        
        // 首先尝试使用预加载的播放器
        if let player = audioPlayers[type] {
            // 重置播放器并播放
            player.currentTime = 0
            if player.play() {
                return // 播放成功，直接返回
            }
        }
        
        // 如果预加载的播放器不可用或播放失败，尝试即时加载
        let soundURL = URL(fileURLWithPath: "/System/Library/Sounds/\(type.fileName)")

        do {
            let player = try AVAudioPlayer(contentsOf: soundURL)
            player.prepareToPlay()
            player.volume = 0.7
            if player.play() {
                // 更新预加载的播放器
                audioPlayers[type] = player
            } else {
                // 播放失败，使用系统声音API
                AudioServicesPlaySystemSound(SystemSoundID(1005))
            }
        } catch {
            print("音频播放失败: \(error.localizedDescription)")
            // 尝试使用系统声音API作为备选
            AudioServicesPlaySystemSound(SystemSoundID(1005))
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
    
    // 播放微休息开始音效
    @objc private func playMicroBreakStartSound(_ notification: Notification) {
        if let soundTypeString = notification.object as? String,
           let soundType = SoundType(rawValue: soundTypeString) {
            playSound(of: soundType)
        } else {
            // 使用默认音效
            playSound(of: .tink)
        }
    }

    // 播放微休息结束音效
    @objc private func playMicroBreakEndSound(_ notification: Notification) {
        if let soundTypeString = notification.object as? String,
           let soundType = SoundType(rawValue: soundTypeString) {
            playSound(of: soundType)
        } else {
            // 使用默认音效
            playSound(of: .hero)
        }
    }

    // 发送计时器通知
    @objc private func sendTimerNotification() {
        // 首先检查通知权限
        checkNotificationPermission { hasPermission in
            if !hasPermission {
                print("没有通知权限，无法发送通知")
                // 可以选择显示权限提示
                self.showNotificationPermissionAlert()
                return
            }
            
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
    }

    // 当应用程序在前台时接收到通知
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 即使应用程序在前台，也显示通知
        completionHandler([.banner, .sound])
    }

    // 状态栏图标可见性变化的处理（纯菜单栏应用不需要处理）
    @objc private func statusBarIconVisibilityChanged() {
        // 作为纯菜单栏应用，状态栏图标始终保持可见
        // 此方法保留以兼容现有通知系统，但不执行任何操作
    }
    
    // 处理显示黑屏请求
    @objc private func handleShowBlackout() {
        if TimerManager.shared.blackoutEnabled {
            // 委托给专门的黑屏控制器处理
            blackoutWindowController?.showBlackoutWindow()
        }
        
        // 暂停视频播放（通过静音系统）
        videoControlManager?.pauseVideo()
    }
    
    // 处理隐藏黑屏请求
    @objc private func handleHideBlackout() {
        if TimerManager.shared.blackoutEnabled {
            // 委托给专门的黑屏控制器处理
            blackoutWindowController?.hideBlackoutWindow()
        }
        
        // 恢复视频播放（通过恢复系统音量）
        videoControlManager?.resumeVideo()
    }
    
    // 发送微休息开始通知
    @objc private func sendMicroBreakStartNotification() {
        // 首先检查通知权限
        checkNotificationPermission { hasPermission in
            if !hasPermission {
                print("没有通知权限，无法发送微休息通知")
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = "微休息开始"
            content.body = "休息 \(TimerManager.shared.microBreakSeconds) 秒，放松一下眼睛吧！"
            content.sound = UNNotificationSound.default

            // 立即触发通知
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

            // 创建通知请求
            let request = UNNotificationRequest(
                identifier: "microbreak-start-\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )

            // 添加通知请求
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("微休息开始通知发送失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // 发送微休息结束通知
    @objc private func sendMicroBreakEndNotification() {
        // 首先检查通知权限
        checkNotificationPermission { hasPermission in
            if !hasPermission {
                print("没有通知权限，无法发送微休息通知")
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = "微休息结束"
            content.body = "继续专注工作吧！"
            content.sound = UNNotificationSound.default

            // 立即触发通知
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

            // 创建通知请求
            let request = UNNotificationRequest(
                identifier: "microbreak-end-\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )

            // 添加通知请求
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("微休息结束通知发送失败: \(error.localizedDescription)")
                }
            }
        }
    }

    // 改进的通知权限请求方法
    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        // 首先检查当前权限状态
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    // 首次请求权限
                    self.performNotificationRequest(center: center)
                    
                case .denied:
                    // 权限被拒绝，引导用户到系统设置
                    print("通知权限被拒绝，需要在系统设置中手动开启")
                    self.showNotificationPermissionAlert()
                    
                case .authorized, .provisional, .ephemeral:
                    // 权限已获取
                    print("通知权限已获取")
                    
                @unknown default:
                    // 未知状态，尝试请求
                    self.performNotificationRequest(center: center)
                }
            }
        }
    }
    
    // 执行通知权限请求
    private func performNotificationRequest(center: UNUserNotificationCenter) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("通知权限已获取")
                } else if let error = error {
                    print("通知权限请求失败: \(error.localizedDescription)")
                    self.showNotificationPermissionAlert()
                } else {
                    print("通知权限被用户拒绝")
                    self.showNotificationPermissionAlert()
                }
            }
        }
    }
    
    // 显示通知权限提示对话框
    private func showNotificationPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "需要通知权限"
        alert.informativeText = "Focus 需要通知权限来提醒您工作和休息时间。请在系统偏好设置中开启通知权限。"
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "稍后设置")
        alert.alertStyle = .informational
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // 打开系统偏好设置的通知页面
            self.openNotificationSettings()
        }
    }
    
    // 打开系统通知设置
    private func openNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }
    
    // 应用启动时显示主窗口
    private func showMainWindowOnStartup(window: NSWindow) {
        // 设置窗口属性，确保在菜单栏应用模式下正确显示
        window.level = .floating
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        
        // 激活应用程序，确保窗口可见
        NSApp.activate(ignoringOtherApps: true)
        
        print("主窗口已在启动时显示")
    }
    
    // 检查通知权限状态的公共方法
    func checkNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
}
