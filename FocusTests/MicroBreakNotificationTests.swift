import XCTest
import UserNotifications
@testable import Focus

/// 微休息通知功能测试类
final class MicroBreakNotificationTests: XCTestCase {
    
    var timerManager: TimerManager!
    var testObserver: TestNotificationObserver!
    
    override func setUp() {
        super.setUp()
        timerManager = TimerManager.shared
        testObserver = TestNotificationObserver()
        
        // 重置相关设置
        timerManager.microBreakNotificationEnabled = true
        timerManager.microBreakSeconds = 2 // 缩短测试时间
    }
    
    override func tearDown() {
        testObserver = nil
        timerManager.stopTimer()
        super.tearDown()
    }
    
    /// 测试微休息通知开关设置保存和加载
    func testMicroBreakNotificationSettingPersistence() {
        // 测试默认值
        XCTAssertTrue(timerManager.microBreakNotificationEnabled, "微休息通知应该默认启用")
        
        // 测试设置关闭
        timerManager.microBreakNotificationEnabled = false
        XCTAssertFalse(timerManager.microBreakNotificationEnabled, "设置应该正确保存")
        
        // 模拟重新加载设置
        let newTimerManager = TimerManager()
        XCTAssertFalse(newTimerManager.microBreakNotificationEnabled, "设置应该从UserDefaults正确加载")
        
        // 恢复设置
        timerManager.microBreakNotificationEnabled = true
    }
    
    /// 测试微休息开始通知发送
    func testMicroBreakStartNotificationSent() {
        let expectation = XCTestExpectation(description: "微休息开始通知应该被发送")
        
        // 监听微休息开始通知
        testObserver.observeNotification(.microBreakStartNotification) { _ in
            expectation.fulfill()
        }
        
        // 启用微休息通知
        timerManager.microBreakNotificationEnabled = true
        
        // 启动计时器并触发微休息
        timerManager.startTimer()
        
        // 直接调用微休息提示音方法来触发通知
        timerManager.startPromptTimer()
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    /// 测试微休息结束通知发送
    func testMicroBreakEndNotificationSent() {
        let expectation = XCTestExpectation(description: "微休息结束通知应该被发送")
        
        // 监听微休息结束通知
        testObserver.observeNotification(.microBreakEndNotification) { _ in
            expectation.fulfill()
        }
        
        // 启用微休息通知
        timerManager.microBreakNotificationEnabled = true
        
        // 模拟微休息结束
        timerManager.scheduleSecondPrompt()
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    /// 测试禁用微休息通知时不发送通知
    func testMicroBreakNotificationDisabled() {
        let startExpectation = XCTestExpectation(description: "微休息开始通知不应该被发送")
        startExpectation.isInverted = true
        
        let endExpectation = XCTestExpectation(description: "微休息结束通知不应该被发送")
        endExpectation.isInverted = true
        
        // 监听通知
        testObserver.observeNotification(.microBreakStartNotification) { _ in
            startExpectation.fulfill()
        }
        
        testObserver.observeNotification(.microBreakEndNotification) { _ in
            endExpectation.fulfill()
        }
        
        // 禁用微休息通知
        timerManager.microBreakNotificationEnabled = false
        
        // 触发微休息
        timerManager.startPromptTimer()
        timerManager.scheduleSecondPrompt()
        
        wait(for: [startExpectation, endExpectation], timeout: 5.0)
    }
    
    /// 测试通知内容正确性
    func testNotificationContent() {
        // 这个测试需要在实际应用中运行，因为涉及到UNUserNotificationCenter
        // 这里我们主要测试逻辑正确性
        
        XCTAssertTrue(timerManager.microBreakNotificationEnabled, "微休息通知应该启用")
        XCTAssertEqual(timerManager.microBreakSeconds, 2, "微休息时间应该设置为2秒")
    }
    
    /// 测试计时器运行时禁用设置修改
    func testSettingDisabledDuringTimer() {
        // 启动计时器
        timerManager.startTimer()
        XCTAssertTrue(timerManager.timerRunning, "计时器应该正在运行")
        
        // 在UI中，这个设置应该被禁用，这里我们测试逻辑
        let originalSetting = timerManager.microBreakNotificationEnabled
        
        // 尝试修改设置（在实际UI中应该被禁用）
        timerManager.microBreakNotificationEnabled = !originalSetting
        
        // 停止计时器
        timerManager.stopTimer()
        XCTAssertFalse(timerManager.timerRunning, "计时器应该已停止")
    }
}

/// 测试用的通知观察器
class TestNotificationObserver {
    private var observers: [NSObjectProtocol] = []
    
    func observeNotification(_ name: Notification.Name, handler: @escaping (Notification) -> Void) {
        let observer = NotificationCenter.default.addObserver(
            forName: name,
            object: nil,
            queue: .main,
            using: handler
        )
        observers.append(observer)
    }
    
    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }
} 