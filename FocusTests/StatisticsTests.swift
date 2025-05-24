//
//  StatisticsTests.swift
//  FocusTests
//
//  Created by 杨乾巍 on 2025/4/28.
//

import XCTest
@testable import Focus

class StatisticsTests: XCTestCase {
    
    var timerManager: TimerManager!
    var statisticsManager: StatisticsManager!
    
    override func setUpWithError() throws {
        timerManager = TimerManager.shared
        statisticsManager = StatisticsManager(timerManager: timerManager)
    }
    
    override func tearDownWithError() throws {
        timerManager = nil
        statisticsManager = nil
    }
    
    // MARK: - FocusSession Tests
    
    func testFocusSessionCreation() throws {
        let startTime = Date()
        let endTime = Calendar.current.date(byAdding: .minute, value: 25, to: startTime)!
        
        let session = FocusSession(
            startTime: startTime,
            endTime: endTime,
            durationMinutes: 25,
            isWorkSession: true
        )
        
        XCTAssertEqual(session.durationMinutes, 25)
        XCTAssertTrue(session.isWorkSession)
        XCTAssertEqual(session.actualDurationMinutes, 25)
    }
    
    func testFocusSessionFormattedDuration() throws {
        let session = FocusSession(
            startTime: Date(),
            endTime: Date(),
            durationMinutes: 90,
            isWorkSession: true
        )
        
        XCTAssertEqual(session.formattedDuration, "1小时30分钟")
        
        let shortSession = FocusSession(
            startTime: Date(),
            endTime: Date(),
            durationMinutes: 25,
            isWorkSession: true
        )
        
        XCTAssertEqual(shortSession.formattedDuration, "25分钟")
    }
    
    // MARK: - StatisticsManager Tests
    
    func testStatisticsPeriodSelection() throws {
        XCTAssertEqual(statisticsManager.currentPeriod, .month)
        XCTAssertEqual(statisticsManager.currentUnit, .count)
        
        statisticsManager.currentPeriod = .day
        statisticsManager.currentUnit = .time
        
        XCTAssertEqual(statisticsManager.currentPeriod, .day)
        XCTAssertEqual(statisticsManager.currentUnit, .time)
    }
    
    func testStatisticsDataGeneration() throws {
        // 测试数据生成不会崩溃
        let dailyData = statisticsManager.getStatisticsData()
        XCTAssertNotNil(dailyData)
        
        statisticsManager.currentPeriod = .week
        let weeklyData = statisticsManager.getStatisticsData()
        XCTAssertNotNil(weeklyData)
        
        statisticsManager.currentPeriod = .month
        let monthlyData = statisticsManager.getStatisticsData()
        XCTAssertNotNil(monthlyData)
        
        statisticsManager.currentPeriod = .year
        let yearlyData = statisticsManager.getStatisticsData()
        XCTAssertNotNil(yearlyData)
    }
    
    func testStatisticsSummaryGeneration() throws {
        let summary = statisticsManager.getStatisticsSummary()
        
        XCTAssertGreaterThanOrEqual(summary.totalSessions, 0)
        XCTAssertGreaterThanOrEqual(summary.totalMinutes, 0)
        XCTAssertGreaterThanOrEqual(summary.averageSessionLength, 0)
        XCTAssertGreaterThanOrEqual(summary.longestSession, 0)
        XCTAssertGreaterThanOrEqual(summary.currentStreak, 0)
    }
    
    func testCurrentPeriodTitle() throws {
        statisticsManager.currentPeriod = .day
        let dayTitle = statisticsManager.getCurrentPeriodTitle()
        XCTAssertTrue(dayTitle.contains("年"))
        XCTAssertTrue(dayTitle.contains("月"))
        XCTAssertTrue(dayTitle.contains("日"))
        
        statisticsManager.currentPeriod = .month
        let monthTitle = statisticsManager.getCurrentPeriodTitle()
        XCTAssertTrue(monthTitle.contains("年"))
        XCTAssertTrue(monthTitle.contains("月"))
        
        statisticsManager.currentPeriod = .year
        let yearTitle = statisticsManager.getCurrentPeriodTitle()
        XCTAssertTrue(yearTitle.contains("年"))
    }
    
    func testCurrentPeriodTotal() throws {
        statisticsManager.currentUnit = .count
        let countTotal = statisticsManager.getCurrentPeriodTotal()
        XCTAssertTrue(countTotal.contains("Sessions"))
        
        statisticsManager.currentUnit = .time
        let timeTotal = statisticsManager.getCurrentPeriodTotal()
        XCTAssertTrue(timeTotal.contains("m") || timeTotal.contains("h"))
    }
    
    // MARK: - Data Model Tests
    
    func testStatisticsPeriodEnum() throws {
        let allPeriods = StatisticsPeriod.allCases
        XCTAssertEqual(allPeriods.count, 4)
        XCTAssertTrue(allPeriods.contains(.day))
        XCTAssertTrue(allPeriods.contains(.week))
        XCTAssertTrue(allPeriods.contains(.month))
        XCTAssertTrue(allPeriods.contains(.year))
    }
    
    func testStatisticsUnitEnum() throws {
        let allUnits = StatisticsUnit.allCases
        XCTAssertEqual(allUnits.count, 2)
        XCTAssertTrue(allUnits.contains(.count))
        XCTAssertTrue(allUnits.contains(.time))
    }
    
    func testStatisticsSummaryFormattedTime() throws {
        let summary = StatisticsSummary(
            totalSessions: 5,
            totalMinutes: 150,
            averageSessionLength: 30,
            longestSession: 60,
            currentStreak: 3
        )
        
        XCTAssertEqual(summary.formattedTotalTime, "2小时30分钟")
        
        let shortSummary = StatisticsSummary(
            totalSessions: 1,
            totalMinutes: 45,
            averageSessionLength: 45,
            longestSession: 45,
            currentStreak: 1
        )
        
        XCTAssertEqual(shortSummary.formattedTotalTime, "45分钟")
    }
    
    // MARK: - Performance Tests
    
    func testStatisticsDataGenerationPerformance() throws {
        measure {
            statisticsManager.currentPeriod = .day
            _ = statisticsManager.getStatisticsData()
            
            statisticsManager.currentPeriod = .week
            _ = statisticsManager.getStatisticsData()
            
            statisticsManager.currentPeriod = .month
            _ = statisticsManager.getStatisticsData()
            
            statisticsManager.currentPeriod = .year
            _ = statisticsManager.getStatisticsData()
        }
    }
} 