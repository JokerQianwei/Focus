//
//  FocusSession.swift
//  Focus
//
//  Created by 杨乾巍 on 2025/4/28.
//

import Foundation

/// 专注会话数据模型
struct FocusSession: Codable, Identifiable {
    let id = UUID()
    let startTime: Date
    let endTime: Date
    let durationMinutes: Int
    let isWorkSession: Bool
    
    // 自定义编码键，排除id属性
    enum CodingKeys: String, CodingKey {
        case startTime
        case endTime
        case durationMinutes
        case isWorkSession
    }
    
    /// 会话时长（以分钟为单位）
    var actualDurationMinutes: Int {
        let duration = endTime.timeIntervalSince(startTime)
        return max(1, Int(duration / 60)) // 至少1分钟
    }
    
    /// 格式化的时长显示
    var formattedDuration: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
}

/// 统计时间段类型
enum StatisticsPeriod: String, CaseIterable, Identifiable {
    case day = "天"
    case week = "周" 
    case month = "月"
    case year = "年"
    
    var id: String { rawValue }
}

/// 统计单位类型
enum StatisticsUnit: String, CaseIterable, Identifiable {
    case count = "数量"
    case time = "时间"
    
    var id: String { rawValue }
}

/// 统计数据点
struct StatisticsDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String
    
    /// 归一化值（0.0-1.0）
    var normalizedValue: Double {
        return value
    }
}

/// 统计摘要
struct StatisticsSummary {
    let totalSessions: Int
    let totalMinutes: Int
    let averageSessionLength: Int
    let longestSession: Int
    let currentStreak: Int
    
    var formattedTotalTime: String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
} 