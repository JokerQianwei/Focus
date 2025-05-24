//
//  StatisticsManager.swift
//  Focus
//
//  Created by 杨乾巍 on 2025/4/28.
//

import Foundation

/// 统计数据管理器
class StatisticsManager: ObservableObject {
    @Published var currentPeriod: StatisticsPeriod = .month
    @Published var currentUnit: StatisticsUnit = .count
    
    private let timerManager: TimerManager
    
    init(timerManager: TimerManager) {
        self.timerManager = timerManager
    }
    
    // MARK: - 数据生成方法
    
    /// 获取当前时间段的统计数据
    func getStatisticsData() -> [StatisticsDataPoint] {
        let sessions = timerManager.focusSessions.filter { $0.isWorkSession }
        
        switch currentPeriod {
        case .day:
            return getDailyData(sessions: sessions)
        case .week:
            return getWeeklyData(sessions: sessions)
        case .month:
            return getMonthlyData(sessions: sessions)
        case .year:
            return getYearlyData(sessions: sessions)
        }
    }
    
    /// 获取统计摘要
    func getStatisticsSummary() -> StatisticsSummary {
        let workSessions = timerManager.focusSessions.filter { $0.isWorkSession }
        let totalSessions = workSessions.count
        let totalMinutes = workSessions.reduce(0) { $0 + $1.durationMinutes }
        let averageSessionLength = totalSessions > 0 ? totalMinutes / totalSessions : 0
        let longestSession = workSessions.map { $0.durationMinutes }.max() ?? 0
        let currentStreak = calculateCurrentStreak(sessions: workSessions)
        
        return StatisticsSummary(
            totalSessions: totalSessions,
            totalMinutes: totalMinutes,
            averageSessionLength: averageSessionLength,
            longestSession: longestSession,
            currentStreak: currentStreak
        )
    }
    
    /// 获取当前时间段标题
    func getCurrentPeriodTitle() -> String {
        let calendar = Calendar.current
        let now = Date()
        
        switch currentPeriod {
        case .day:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "yyyy年M月d日"
            return formatter.string(from: now)
        case .week:
            let weekOfYear = calendar.component(.weekOfYear, from: now)
            let year = calendar.component(.year, from: now)
            return "\(year)年第\(weekOfYear)周"
        case .month:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "yyyy年M月"
            return formatter.string(from: now)
        case .year:
            let year = calendar.component(.year, from: now)
            return "\(year)年"
        }
    }
    
    /// 获取当前时间段的总值（用于显示在标题中）
    func getCurrentPeriodTotal() -> String {
        let data = getStatisticsData()
        let total = data.reduce(0) { $0 + $1.value }
        
        switch currentUnit {
        case .count:
            return "\(Int(total)) Sessions"
        case .time:
            let hours = Int(total) / 60
            let minutes = Int(total) % 60
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(minutes)m"
            }
        }
    }
    
    // MARK: - 私有方法
    
    private func getDailyData(sessions: [FocusSession]) -> [StatisticsDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        var dataPoints: [StatisticsDataPoint] = []
        
        // 显示最近30天的数据
        for i in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: now) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let daySessions = sessions.filter { session in
                session.startTime >= dayStart && session.startTime < dayEnd
            }
            
            let value: Double
            switch currentUnit {
            case .count:
                value = Double(daySessions.count)
            case .time:
                value = Double(daySessions.reduce(0) { $0 + $1.durationMinutes })
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "M-d"
            let label = formatter.string(from: date)
            
            dataPoints.append(StatisticsDataPoint(
                date: date,
                value: value,
                label: label
            ))
        }
        
        return dataPoints.reversed()
    }
    
    private func getWeeklyData(sessions: [FocusSession]) -> [StatisticsDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        var dataPoints: [StatisticsDataPoint] = []
        
        // 显示最近12周的数据
        for i in 0..<12 {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: now) else { continue }
            let weekStartDate = calendar.dateInterval(of: .weekOfYear, for: weekStart)?.start ?? weekStart
            let weekEndDate = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStartDate)!
            
            let weekSessions = sessions.filter { session in
                session.startTime >= weekStartDate && session.startTime < weekEndDate
            }
            
            let value: Double
            switch currentUnit {
            case .count:
                value = Double(weekSessions.count)
            case .time:
                value = Double(weekSessions.reduce(0) { $0 + $1.durationMinutes })
            }
            
            let weekNumber = calendar.component(.weekOfYear, from: weekStartDate)
            let label = "W\(weekNumber)"
            
            dataPoints.append(StatisticsDataPoint(
                date: weekStartDate,
                value: value,
                label: label
            ))
        }
        
        return dataPoints.reversed()
    }
    
    private func getMonthlyData(sessions: [FocusSession]) -> [StatisticsDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        var dataPoints: [StatisticsDataPoint] = []
        
        // 显示最近12个月的数据
        for i in 0..<12 {
            guard let monthStart = calendar.date(byAdding: .month, value: -i, to: now) else { continue }
            let monthStartDate = calendar.dateInterval(of: .month, for: monthStart)?.start ?? monthStart
            let monthEndDate = calendar.date(byAdding: .month, value: 1, to: monthStartDate)!
            
            let monthSessions = sessions.filter { session in
                session.startTime >= monthStartDate && session.startTime < monthEndDate
            }
            
            let value: Double
            switch currentUnit {
            case .count:
                value = Double(monthSessions.count)
            case .time:
                value = Double(monthSessions.reduce(0) { $0 + $1.durationMinutes })
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MM"
            let label = formatter.string(from: monthStartDate)
            
            dataPoints.append(StatisticsDataPoint(
                date: monthStartDate,
                value: value,
                label: label
            ))
        }
        
        return dataPoints.reversed()
    }
    
    private func getYearlyData(sessions: [FocusSession]) -> [StatisticsDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        var dataPoints: [StatisticsDataPoint] = []
        
        // 显示最近5年的数据
        for i in 0..<5 {
            guard let yearStart = calendar.date(byAdding: .year, value: -i, to: now) else { continue }
            let yearStartDate = calendar.dateInterval(of: .year, for: yearStart)?.start ?? yearStart
            let yearEndDate = calendar.date(byAdding: .year, value: 1, to: yearStartDate)!
            
            let yearSessions = sessions.filter { session in
                session.startTime >= yearStartDate && session.startTime < yearEndDate
            }
            
            let value: Double
            switch currentUnit {
            case .count:
                value = Double(yearSessions.count)
            case .time:
                value = Double(yearSessions.reduce(0) { $0 + $1.durationMinutes })
            }
            
            let year = calendar.component(.year, from: yearStartDate)
            let label = "\(year)"
            
            dataPoints.append(StatisticsDataPoint(
                date: yearStartDate,
                value: value,
                label: label
            ))
        }
        
        return dataPoints.reversed()
    }
    
    private func calculateCurrentStreak(sessions: [FocusSession]) -> Int {
        let calendar = Calendar.current
        let now = Date()
        var streak = 0
        var currentDate = calendar.startOfDay(for: now)
        
        // 检查连续天数
        while true {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            let daySessions = sessions.filter { session in
                session.startTime >= currentDate && session.startTime < nextDay
            }
            
            if daySessions.isEmpty {
                break
            }
            
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }
        
        return streak
    }
} 