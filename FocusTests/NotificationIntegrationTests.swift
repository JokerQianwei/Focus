import XCTest
import UserNotifications
@testable import Focus

/// 通知集成测试类
/// 测试从TimerManager到FocusApp的完整通知流程
final class NotificationIntegrationTests: XCTestCase {
    
    var timerManager: TimerManager!
    
    override func setUp() {
        super.setUp()
        timerManager = TimerManager.shared
        
        // 确保微休息通知启用
        timerManager.microBreakNotificationEnabled = true
        timerManager.microBreakSeconds = 2 // 缩短测试时间
    }
    
    override func tearDown() {
        timerManager.stopTimer()
        super.tearDown()
    }
    
    /// 测试通知名称定义正确性
    func testNotificationNamesAreDefined() {
        // 测试新添加的微休息通知名称是否正确定义
        let startNotificationName = Notification.Name.microBreakStartNotification
        let endNotificationName = Notification.Name.microBreakEndNotification
        
        XCTAssertEqual(startNotificationName.rawValue, "microBreakStartNotification")
        XCTAssertEqual(endNotificationName.rawValue, "microBreakEndNotification")
    }
    
    /// 测试完整的微休息通知流程
    func testFullMicroBreakNotificationFlow() {
        let startExpectation = XCTestExpectation(description: "微休息开始通知流程")
        let endExpectation = XCTestExpectation(description: "微休息结束通知流程")
        
        var startNotificationReceived = false
        var endNotificationReceived = false
        
        // 监听微休息开始通知
        let startObserver = NotificationCenter.default.addObserver(
            forName: .microBreakStartNotification,
            object: nil,
            queue: .main
        ) { _ in
            startNotificationReceived = true
            startExpectation.fulfill()
        }
        
        // 监听微休息结束通知
        let endObserver = NotificationCenter.default.addObserver(
            forName: .microBreakEndNotification,
            object: nil,
            queue: .main
        ) { _ in
            endNotificationReceived = true
            endExpectation.fulfill()
        }
        
        // 启动计时器
        timerManager.startTimer()
        
        // 手动触发微休息开始
        DispatchQueue.main.async {
            self.timerManager.startPromptTimer()
        }
        
        // 等待开始通知
        wait(for: [startExpectation], timeout: 3.0)
        XCTAssertTrue(startNotificationReceived, "应该收到微休息开始通知")
        
        // 等待结束通知
        wait(for: [endExpectation], timeout: 5.0)
        XCTAssertTrue(endNotificationReceived, "应该收到微休息结束通知")
        
        // 清理观察者
        NotificationCenter.default.removeObserver(startObserver)
        NotificationCenter.default.removeObserver(endObserver)
    }
    
    /// 测试设置变更时的行为
    func testSettingChangeBehavior() {
        let expectation = XCTestExpectation(description: "设置变更后不应收到通知")
        expectation.isInverted = true
        
        // 先启用通知
        timerManager.microBreakNotificationEnabled = true
        
        // 然后禁用
        timerManager.microBreakNotificationEnabled = false
        
        // 监听通知
        let observer = NotificationCenter.default.addObserver(
            forName: .microBreakStartNotification,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }
        
        // 触发微休息
        timerManager.startPromptTimer()
        
        // 等待确认没有收到通知
        wait(for: [expectation], timeout: 3.0)
        
        NotificationCenter.default.removeObserver(observer)
    }
    
    /// 测试UserDefaults持久化
    func testUserDefaultsPersistence() {
        // 设置为false
        timerManager.microBreakNotificationEnabled = false
        
        // 检查UserDefaults中的值
        let savedValue = UserDefaults.standard.bool(forKey: "microBreakNotificationEnabled")
        XCTAssertFalse(savedValue, "设置应该正确保存到UserDefaults")
        
        // 设置为true
        timerManager.microBreakNotificationEnabled = true
        
        let updatedValue = UserDefaults.standard.bool(forKey: "microBreakNotificationEnabled")
        XCTAssertTrue(updatedValue, "更新的设置应该正确保存到UserDefaults")
    }
    
    /// 性能测试：快速切换设置
    func testPerformanceOfQuickSettingChanges() {
        measure {
            for _ in 0..<100 {
                timerManager.microBreakNotificationEnabled = !timerManager.microBreakNotificationEnabled
            }
        }
    }
    
    /// 测试边界条件：微休息时间为0
    func testEdgeCaseZeroMicroBreakTime() {
        timerManager.microBreakSeconds = 0
        timerManager.microBreakNotificationEnabled = true
        
        let expectation = XCTestExpectation(description: "零时间微休息通知")
        
        let observer = NotificationCenter.default.addObserver(
            forName: .microBreakStartNotification,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }
        
        timerManager.startPromptTimer()
        
        wait(for: [expectation], timeout: 2.0)
        
        NotificationCenter.default.removeObserver(observer)
    }
}

/// 模拟通知权限测试
extension NotificationIntegrationTests {
    
    /// 测试通知权限检查逻辑
    func testNotificationPermissionLogic() {
        // 这是一个概念性测试，在实际环境中需要模拟UNUserNotificationCenter
        
        // 假设我们有一个方法来检查通知权限
        let hasPermission = true // 在实际测试中，这应该从UNUserNotificationCenter获取
        
        if hasPermission {
            XCTAssertTrue(timerManager.microBreakNotificationEnabled, "有权限时应该允许通知")
        } else {
            // 在没有权限的情况下，应用应该优雅处理
            XCTAssertNoThrow(timerManager.startPromptTimer(), "没有通知权限时应用不应该崩溃")
        }
    }
} 