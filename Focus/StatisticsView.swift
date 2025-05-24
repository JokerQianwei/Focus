//
//  StatisticsView.swift
//  Focus
//
//  Created by 杨乾巍 on 2025/4/28.
//

import SwiftUI

struct StatisticsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @StateObject private var statisticsManager: StatisticsManager
    @State private var isHoveringClose = false
    
    init(timerManager: TimerManager) {
        _statisticsManager = StateObject(wrappedValue: StatisticsManager(timerManager: timerManager))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            VStack(spacing: 16) {
                periodAndUnitSelector
                chartSection
                summarySection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .frame(width: 520, height: 480)
        .background(backgroundGradient)
    }
    
    // MARK: - 顶部标题栏
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("专注统计")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        dismiss()
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(isHoveringClose ? .white : .secondary)
                        .frame(width: 22, height: 22)
                        .background(
                            Circle()
                                .fill(isHoveringClose ? Color.gray.opacity(0.6) : Color(.controlBackgroundColor))
                        )
                        .shadow(color: .black.opacity(0.08), radius: 1, x: 0, y: 0.5)
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHoveringClose = hovering
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 12)
        }
        .background(.ultraThinMaterial)
    }
    
    // MARK: - 背景渐变
    private var backgroundGradient: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(.windowBackgroundColor), Color(.windowBackgroundColor).opacity(0.8)]
                : [Color(.windowBackgroundColor), Color(.controlBackgroundColor).opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - 时间段和单位选择器
    private var periodAndUnitSelector: some View {
        HStack(spacing: 12) {
            // 时间段选择器
            HStack(spacing: 4) {
                ForEach(StatisticsPeriod.allCases) { period in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            statisticsManager.currentPeriod = period
                        }
                    }) {
                        Text(period.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(statisticsManager.currentPeriod == period ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(statisticsManager.currentPeriod == period 
                                          ? Color.accentColor 
                                          : Color(.controlBackgroundColor))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Spacer()
            
            // 单位选择菜单
            Menu {
                ForEach(StatisticsUnit.allCases) { unit in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            statisticsManager.currentUnit = unit
                        }
                    }) {
                        HStack {
                            Text(unit.rawValue)
                            if statisticsManager.currentUnit == unit {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text("单位")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(statisticsManager.currentUnit.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(.controlBackgroundColor))
                )
            }
        }
    }
    
    // MARK: - 图表区域
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 图表标题
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(statisticsManager.getCurrentPeriodTitle())
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(statisticsManager.getCurrentPeriodTotal())
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // 数据图表
            StatisticsChart(
                data: statisticsManager.getStatisticsData(),
                unit: statisticsManager.currentUnit,
                period: statisticsManager.currentPeriod
            )
            .frame(height: 200)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.08), lineWidth: 0.5)
        )
    }
    
    // MARK: - 统计摘要
    private var summarySection: some View {
        let summary = statisticsManager.getStatisticsSummary()
        
        return HStack(spacing: 12) {
            SummaryCard(
                title: "总专注次数",
                value: "\(summary.totalSessions)",
                icon: "target",
                color: .blue
            )
            
            SummaryCard(
                title: "总专注时长",
                value: summary.formattedTotalTime,
                icon: "clock",
                color: .green
            )
            
            SummaryCard(
                title: "平均时长",
                value: "\(summary.averageSessionLength)分钟",
                icon: "chart.bar",
                color: .orange
            )
            
            SummaryCard(
                title: "连续天数",
                value: "\(summary.currentStreak)天",
                icon: "flame",
                color: .red
            )
        }
    }
}

// MARK: - 统计图表组件
struct StatisticsChart: View {
    let data: [StatisticsDataPoint]
    let unit: StatisticsUnit
    let period: StatisticsPeriod
    
    private var maxValue: Double {
        data.map(\.value).max() ?? 1.0
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: period == .day ? 2 : 4) {
            ForEach(data) { point in
                VStack(spacing: 4) {
                    // 数据条
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.8, blue: 0.6),
                                    Color(red: 0.2, green: 0.7, blue: 0.5)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(
                            width: period == .day ? 8 : 12,
                            height: point.value == 0 ? 2 : max(4, (point.value / maxValue) * 150)
                        )
                        .opacity(point.value == 0 ? 0.2 : 1.0)
                        .cornerRadius(period == .day ? 2 : 3)
                    
                    // 标签
                    if shouldShowLabel(for: point) {
                        Text(point.label)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(period == .day ? -45 : 0))
                    }
                }
                .help(getTooltipText(for: point))
            }
        }
        .padding(.horizontal, 8)
    }
    
    private func shouldShowLabel(for point: StatisticsDataPoint) -> Bool {
        switch period {
        case .day:
            // 每5个显示一个标签
            let index = data.firstIndex(where: { $0.id == point.id }) ?? 0
            return index % 5 == 0
        case .week, .month, .year:
            return true
        }
    }
    
    private func getTooltipText(for point: StatisticsDataPoint) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        
        switch period {
        case .day:
            formatter.dateFormat = "M月d日"
        case .week:
            formatter.dateFormat = "yyyy年第w周"
        case .month:
            formatter.dateFormat = "yyyy年M月"
        case .year:
            formatter.dateFormat = "yyyy年"
        }
        
        let dateString = formatter.string(from: point.date)
        
        switch unit {
        case .count:
            return "\(dateString): \(Int(point.value)) 次专注"
        case .time:
            let hours = Int(point.value) / 60
            let minutes = Int(point.value) % 60
            if hours > 0 {
                return "\(dateString): \(hours)小时\(minutes)分钟"
            } else {
                return "\(dateString): \(minutes)分钟"
            }
        }
    }
}

// MARK: - 摘要卡片组件
struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(color.opacity(0.12))
                )
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.06), lineWidth: 0.5)
        )
    }
}

#Preview {
    StatisticsView(timerManager: TimerManager.shared)
} 