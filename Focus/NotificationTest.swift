//
//  NotificationTest.swift
//  Focus
//
//  Created for debugging notification permissions
//

import Foundation
import UserNotifications

class NotificationTest {
    static let shared = NotificationTest()
    
    private init() {}
    
    // 测试通知权限状态
    func testNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                print("=== 通知权限状态检查 ===")
                print("授权状态: \(self.authorizationStatusString(settings.authorizationStatus))")
                print("通知中心设置: \(settings.notificationCenterSetting)")
                print("锁屏设置: \(settings.lockScreenSetting)")
                print("横幅设置: \(settings.alertSetting)")
                print("声音设置: \(settings.soundSetting)")
                print("角标设置: \(settings.badgeSetting)")
                print("========================")
                
                if settings.authorizationStatus == .denied {
                    print("⚠️ 通知权限被拒绝，请在系统偏好设置中手动开启")
                } else if settings.authorizationStatus == .authorized {
                    print("✅ 通知权限已授权")
                    self.sendTestNotification()
                }
            }
        }
    }
    
    // 发送测试通知
    private func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Focus 通知测试"
        content.body = "如果您看到这条通知，说明通知权限工作正常！"
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test-notification",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 测试通知发送失败: \(error.localizedDescription)")
            } else {
                print("📤 测试通知已发送")
            }
        }
    }
    
    // 授权状态转换为可读字符串
    private func authorizationStatusString(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "未确定"
        case .denied:
            return "已拒绝"
        case .authorized:
            return "已授权"
        case .provisional:
            return "临时授权"
        case .ephemeral:
            return "临时权限"
        @unknown default:
            return "未知状态"
        }
    }
} 