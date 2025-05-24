//
//  TimerManagerIntervalValidationTests.swift
//  FocusTests
//
//  Created by Assistant on 2025/1/27.
//

import XCTest
@testable import Focus

/// 测试TimerManager中的间隔验证逻辑
class TimerManagerIntervalValidationTests: XCTestCase {
    
    var timerManager: TimerManager!
    
    override func setUp() {
        super.setUp()
        timerManager = TimerManager.shared
    }
    
    override func tearDown() {
        // 重置为默认值
        timerManager.promptMinInterval = 3
        timerManager.promptMaxInterval = 5
        super.tearDown()
    }
    
    /// 测试设置最小间隔大于最大间隔时，最大间隔会自动调整
    func testMinIntervalGreaterThanMaxInterval() {
        // 设置初始值
        timerManager.promptMinInterval = 3
        timerManager.promptMaxInterval = 5
        
        // 设置最小间隔大于最大间隔
        timerManager.promptMinInterval = 8
        
        // 验证最大间隔被自动调整为等于最小间隔
        XCTAssertEqual(timerManager.promptMinInterval, 8)
        XCTAssertEqual(timerManager.promptMaxInterval, 8)
    }
    
    /// 测试设置最大间隔小于最小间隔时，最大间隔会自动调整
    func testMaxIntervalLessThanMinInterval() {
        // 设置初始值
        timerManager.promptMinInterval = 5
        timerManager.promptMaxInterval = 8
        
        // 设置最大间隔小于最小间隔
        timerManager.promptMaxInterval = 3
        
        // 验证最大间隔被自动调整为等于最小间隔
        XCTAssertEqual(timerManager.promptMinInterval, 5)
        XCTAssertEqual(timerManager.promptMaxInterval, 5)
    }
    
    /// 测试正常情况下间隔设置不会被修改
    func testNormalIntervalSettings() {
        // 设置正常的间隔值
        timerManager.promptMinInterval = 3
        timerManager.promptMaxInterval = 7
        
        // 验证值没有被修改
        XCTAssertEqual(timerManager.promptMinInterval, 3)
        XCTAssertEqual(timerManager.promptMaxInterval, 7)
    }
    
    /// 测试相等的间隔值
    func testEqualIntervalValues() {
        // 设置相等的间隔值
        timerManager.promptMinInterval = 5
        timerManager.promptMaxInterval = 5
        
        // 验证值保持不变
        XCTAssertEqual(timerManager.promptMinInterval, 5)
        XCTAssertEqual(timerManager.promptMaxInterval, 5)
    }
    
    /// 测试startPromptTimer方法在无效间隔时不会崩溃
    func testStartPromptTimerWithInvalidInterval() {
        // 设置一个可能导致问题的间隔配置
        timerManager.promptMinInterval = 10
        timerManager.promptMaxInterval = 5  // 这会被自动调整为10
        
        // 确保间隔已被正确调整
        XCTAssertEqual(timerManager.promptMaxInterval, 10)
        
        // 设置为工作模式并启用提示音
        timerManager.isWorkMode = true
        timerManager.promptSoundEnabled = true
        
        // 这个调用不应该崩溃
        XCTAssertNoThrow {
            self.timerManager.startPromptTimer()
        }
        
        // 清理
        timerManager.stopPromptSystem()
    }
} 