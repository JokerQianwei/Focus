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
    @Published var currentUnit: StatisticsUnit = .time
    @Published var currentDate: Date = Date()
    
    private let timerManager: TimerManager
    
    init(timerManager: TimerManager) {
        self.timerManager = timerManager
    }
    
    // MARK: - 时间段导航方法
    
    /// 导航到下一个时间段
    func navigateToNext() {
        let calendar = Calendar.current
        switch currentPeriod {
        case .day:
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        case .week:
            currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate
        case .month:
            currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
        case .year:
            currentDate = calendar.date(byAdding: .year, value: 1, to: currentDate) ?? currentDate
        }
    }
    
    /// 导航到上一个时间段
    func navigateToPrevious() {
        let calendar = Calendar.current
        switch currentPeriod {
        case .day:
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        case .week:
            currentDate = calendar.date(byAdding: .weekOfYear, value: -1, to: currentDate) ?? currentDate
        case .month:
            currentDate = calendar.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
        case .year:
            currentDate = calendar.date(byAdding: .year, value: -1, to: currentDate) ?? currentDate
        }
    }
    
    /// 检查是否可以导航到下一个时间段
    var canNavigateToNext: Bool {
        let calendar = Calendar.current
        let now = Date()
        
        switch currentPeriod {
        case .day:
            return calendar.startOfDay(for: currentDate) < calendar.startOfDay(for: now)
        case .week:
            let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: currentDate)?.start ?? currentDate
            let nowWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return currentWeekStart < nowWeekStart
        case .month:
            let currentMonthStart = calendar.dateInterval(of: .month, for: currentDate)?.start ?? currentDate
            let nowMonthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return currentMonthStart < nowMonthStart
        case .year:
            let currentYearStart = calendar.dateInterval(of: .year, for: currentDate)?.start ?? currentDate
            let nowYearStart = calendar.dateInterval(of: .year, for: now)?.start ?? now
            return currentYearStart < nowYearStart
        }
    }
    
    // MARK: - 数据生成方法
    
    /// 获取当前时间段的统计数据
    func getStatisticsData() -> [StatisticsDataPoint] {
        let sessions = timerManager.focusSessions.filter { $0.isWorkSession }
        
        let rawData: [StatisticsDataPoint]
        switch currentPeriod {
        case .day:
            rawData = getDailyData(sessions: sessions)
        case .week:
            rawData = getWeeklyData(sessions: sessions)
        case .month:
            rawData = getMonthlyData(sessions: sessions)
        case .year:
            rawData = getYearlyData(sessions: sessions)
        }
        
        // 数据归一化处理
        return normalizeData(rawData)
    }
    
    /// 数据归一化处理
    private func normalizeData(_ dataPoints: [StatisticsDataPoint]) -> [StatisticsDataPoint] {
        guard !dataPoints.isEmpty else { return [] }
        
        let maxValue = dataPoints.map { $0.value }.max() ?? 1.0
        
        // 避免除以0的情况
        let safeMaxValue = maxValue == 0 ? 1.0 : maxValue
        
        return dataPoints.map { dataPoint in
            StatisticsDataPoint(
                date: dataPoint.date,
                value: dataPoint.value,
                label: dataPoint.label,
                normalizedValue: dataPoint.value / safeMaxValue
            )
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
        
        switch currentPeriod {
        case .day:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "yyyy年M月d日"
            return formatter.string(from: currentDate)
        case .week:
            let weekOfYear = calendar.component(.weekOfYear, from: currentDate)
            let year = calendar.component(.year, from: currentDate)
            return "\(year)年第\(weekOfYear)周"
        case .month:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "yyyy年M月"
            return formatter.string(from: currentDate)
        case .year:
            let year = calendar.component(.year, from: currentDate)
            return "\(year)年"
        }
    }
    
    /// 获取当前时间段的总值（用于显示在标题中）
    func getCurrentPeriodTotal() -> String {
        let data = getStatisticsData()
        let total = data.reduce(0) { $0 + $1.value }
        
        switch currentUnit {
        case .count:
            return "\(Int(total)) 次专注"
        case .time:
            let hours = Int(total) / 60
            let minutes = Int(total) % 60
            if hours > 0 {
                return "\(hours)小时\(minutes)分钟"
            } else {
                return "\(minutes)分钟"
            }
        }
    }
    
    // MARK: - 私有方法
    
    /// 获取天数据 - 按24小时分组
    private func getDailyData(sessions: [FocusSession]) -> [StatisticsDataPoint] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: currentDate)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        
        // 筛选当天的会话
        let daySessions = sessions.filter { session in
            session.startTime >= dayStart && session.startTime < dayEnd
        }
        
        var dataPoints: [StatisticsDataPoint] = []
        
        // 创建24个小时的数据点
        for hour in 0..<24 {
            guard let hourStart = calendar.date(byAdding: .hour, value: hour, to: dayStart),
                  let hourEnd = calendar.date(byAdding: .hour, value: 1, to: hourStart) else { continue }
            
            let hourSessions = daySessions.filter { session in
                session.startTime >= hourStart && session.startTime < hourEnd
            }
            
            let value: Double
            switch currentUnit {
            case .count:
                value = Double(hourSessions.count)
            case .time:
                value = Double(hourSessions.reduce(0) { $0 + $1.durationMinutes })
            }
            
            let label = String(format: "%02d", hour)
            
            dataPoints.append(StatisticsDataPoint(
                date: hourStart,
                value: value,
                label: label
            ))
        }
        
        return dataPoints
    }
    
    /// 获取周数据 - 显示一周7天
    private func getWeeklyData(sessions: [FocusSession]) -> [StatisticsDataPoint] {
        let calendar = Calendar.current
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentDate)!
        let weekStart = weekInterval.start
        
        var dataPoints: [StatisticsDataPoint] = []
        
        // 创建7天的数据点
        for dayOffset in 0..<7 {
            guard let dayStart = calendar.date(byAdding: .day, value: dayOffset, to: weekStart),
                  let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { continue }
            
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
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "E"
            let label = formatter.string(from: dayStart)
            
            dataPoints.append(StatisticsDataPoint(
                date: dayStart,
                value: value,
                label: label
            ))
        }
        
        return dataPoints
    }
    
    /// 获取月数据 - 显示当月每一天
    private func getMonthlyData(sessions: [FocusSession]) -> [StatisticsDataPoint] {
        let calendar = Calendar.current
        let monthInterval = calendar.dateInterval(of: .month, for: currentDate)!
        let monthStart = monthInterval.start
        let monthEnd = monthInterval.end
        
        var dataPoints: [StatisticsDataPoint] = []
        var currentDay = monthStart
        
        while currentDay < monthEnd {
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: currentDay)!
            
            let daySessions = sessions.filter { session in
                session.startTime >= currentDay && session.startTime < dayEnd
            }
            
            let value: Double
            switch currentUnit {
            case .count:
                value = Double(daySessions.count)
            case .time:
                value = Double(daySessions.reduce(0) { $0 + $1.durationMinutes })
            }
            
            let day = calendar.component(.day, from: currentDay)
            let label = "\(day)"
            
            dataPoints.append(StatisticsDataPoint(
                date: currentDay,
                value: value,
                label: label
            ))
            
            currentDay = dayEnd
        }
        
        return dataPoints
    }
    
    /// 获取年数据 - 显示12个月
    private func getYearlyData(sessions: [FocusSession]) -> [StatisticsDataPoint] {
        let calendar = Calendar.current
        let yearInterval = calendar.dateInterval(of: .year, for: currentDate)!
        let yearStart = yearInterval.start
        
        var dataPoints: [StatisticsDataPoint] = []
        
        // 创建12个月的数据点
        for monthOffset in 0..<12 {
            guard let monthStart = calendar.date(byAdding: .month, value: monthOffset, to: yearStart),
                  let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { continue }
            
            let monthSessions = sessions.filter { session in
                session.startTime >= monthStart && session.startTime < monthEnd
            }
            
            let value: Double
            switch currentUnit {
            case .count:
                value = Double(monthSessions.count)
            case .time:
                value = Double(monthSessions.reduce(0) { $0 + $1.durationMinutes })
            }
            
            let month = calendar.component(.month, from: monthStart)
            let label = "\(month)月"
            
            dataPoints.append(StatisticsDataPoint(
                date: monthStart,
                value: value,
                label: label
            ))
        }
        
        return dataPoints
    }
    
    private func calculateCurrentStreak(sessions: [FocusSession]) -> Int {
        let calendar = Calendar.current
        let now = Date()
        var streak = 0
        var currentDate = calendar.startOfDay(for: now)
        
        // 检查连续天数，从今天开始向前推
        while true {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            let daySessions = sessions.filter { session in
                session.startTime >= currentDate && session.startTime < nextDay
            }
            
            // 如果当前日期没有会话，中断连续计数
            if daySessions.isEmpty {
                break
            }
            
            streak += 1
            
            // 向前推一天
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDay
        }
        
        return streak
    }
} 