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
    
    @ObservedObject var timerManager: TimerManager
    @StateObject private var statisticsManager: StatisticsManager
    
    @State private var isHoveringClose = false
    @State private var animateChart = false
    @State private var selectedDataPoint: StatisticsDataPoint?
    @State private var isHoveringPrevious = false
    @State private var isHoveringNext = false
    
    init(timerManager: TimerManager) {
        self.timerManager = timerManager
        self._statisticsManager = StateObject(wrappedValue: StatisticsManager(timerManager: timerManager))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    periodNavigationSection
                    controlsSection
                    chartSection
                    summaryCardsSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
        .frame(width: 560, height: 700)
        .background(backgroundGradient)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 1.0)) {
                    animateChart = true
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Image(systemName: "chart.bar.fill")
                .font(.title2)
                .foregroundColor(.blue)
            
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
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Period Navigation Section
    private var periodNavigationSection: some View {
        VStack(spacing: 12) {
            // 时间段导航
            HStack {
                // 上一个时间段按钮
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        statisticsManager.navigateToPrevious()
                        animateChart = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            animateChart = true
                        }
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isHoveringPrevious ? .primary : .secondary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(isHoveringPrevious ? Color.blue.opacity(0.1) : Color(.controlBackgroundColor))
                        )
                        .scaleEffect(isHoveringPrevious ? 1.05 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHoveringPrevious = hovering
                    }
                }
                
                Spacer()
                
                // 时间段标题和统计
                VStack(spacing: 6) {
                    Text(statisticsManager.getCurrentPeriodTitle())
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .animation(.easeInOut, value: statisticsManager.currentDate)
                    
                    Text(statisticsManager.getCurrentPeriodTotal())
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                        .animation(.easeInOut, value: statisticsManager.currentDate)
                }
                
                Spacer()
                
                // 下一个时间段按钮
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        statisticsManager.navigateToNext()
                        animateChart = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            animateChart = true
                        }
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(statisticsManager.canNavigateToNext ? (isHoveringNext ? .primary : .secondary) : .gray.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(isHoveringNext && statisticsManager.canNavigateToNext ? Color.blue.opacity(0.1) : Color(.controlBackgroundColor))
                        )
                        .scaleEffect(isHoveringNext && statisticsManager.canNavigateToNext ? 1.05 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!statisticsManager.canNavigateToNext)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHoveringNext = hovering
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Controls Section
    private var controlsSection: some View {
        HStack(spacing: 16) {
            // 时间段选择器
            HStack(spacing: 0) {
                ForEach(StatisticsPeriod.allCases) { period in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            statisticsManager.currentPeriod = period
                            animateChart = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                animateChart = true
                            }
                        }
                    }) {
                        Text(period.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(statisticsManager.currentPeriod == period ? .white : .secondary)
                            .frame(width: 40, height: 32)
                            .background(
                                Rectangle()
                                    .fill(statisticsManager.currentPeriod == period ? Color.blue : Color.clear)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.controlBackgroundColor))
                    .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Spacer()
            
            // 单位选择器
            Menu {
                ForEach(StatisticsUnit.allCases) { unit in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
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
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.caption)
                    Text(statisticsManager.currentUnit.rawValue)
                        .font(.system(size: 13, weight: .medium))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.controlBackgroundColor))
                        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
                )
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Chart Section
    private var chartSection: some View {
        ModernStatisticsCard(
            title: "数据趋势",
            icon: "chart.line.uptrend.xyaxis",
            iconColor: .blue
        ) {
            let data = statisticsManager.getStatisticsData()
            
            if data.isEmpty {
                EmptyChartView()
            } else {
                ModernBarChartView(
                    data: data,
                    unit: statisticsManager.currentUnit,
                    period: statisticsManager.currentPeriod,
                    animate: animateChart,
                    selectedDataPoint: $selectedDataPoint
                )
                .frame(height: 180)
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Summary Cards Section
    private var summaryCardsSection: some View {
        let summary = statisticsManager.getStatisticsSummary()
        
        return LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ], spacing: 8) {
            ModernSummaryCard(
                title: "总专注次数",
                value: "\(summary.totalSessions)",
                subtitle: "次",
                icon: "target",
                color: .blue
            )
            
            ModernSummaryCard(
                title: "总专注时长",
                value: summary.formattedTotalTime,
                subtitle: "",
                icon: "clock",
                color: .green
            )
            
            ModernSummaryCard(
                title: "平均时长",
                value: "\(summary.averageSessionLength)",
                subtitle: "分钟",
                icon: "gauge.medium",
                color: .orange
            )
            
            ModernSummaryCard(
                title: "连续天数",
                value: "\(summary.currentStreak)",
                subtitle: "天",
                icon: "flame",
                color: .red
            )
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Background Gradient
    private var backgroundGradient: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(.windowBackgroundColor), Color(.windowBackgroundColor).opacity(0.8)]
                : [Color(.windowBackgroundColor), Color(.controlBackgroundColor).opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Modern Statistics Card Component
struct ModernStatisticsCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(iconColor.opacity(0.12))
                    )
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.secondary.opacity(0.06), lineWidth: 0.5)
        )
    }
}

// MARK: - Modern Summary Card Component
struct ModernSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 顶部：图标和数值在同一行
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(color.opacity(0.12))
                    )
                
                Spacer()
                
                // 数值和单位在同一行
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // 底部：标题
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(12)
        .frame(height: 85)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(isHovering ? 0.3 : 0.1), lineWidth: 1)
        )
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Modern Bar Chart Component
struct ModernBarChartView: View {
    let data: [StatisticsDataPoint]
    let unit: StatisticsUnit
    let period: StatisticsPeriod
    let animate: Bool
    @Binding var selectedDataPoint: StatisticsDataPoint?
    
    private let barSpacing: CGFloat = 3
    private let barCornerRadius: CGFloat = 4
    
    var body: some View {
        GeometryReader { geometry in
            let chartWidth = geometry.size.width
            let chartHeight = geometry.size.height - 50 // 留出底部标签空间
            let barWidth = max(6, (chartWidth - CGFloat(data.count - 1) * barSpacing) / CGFloat(data.count))
            
            VStack(spacing: 0) {
                // 图表区域
                ZStack(alignment: .bottom) {
                    // 背景网格线
                    ModernGridLinesView(height: chartHeight)
                    
                    // 柱状图
                    HStack(alignment: .bottom, spacing: barSpacing) {
                        ForEach(Array(data.enumerated()), id: \.element.id) { index, dataPoint in
                            VStack(spacing: 0) {
                                ZStack(alignment: .bottom) {
                                    // 背景柱
                                    RoundedRectangle(cornerRadius: barCornerRadius)
                                        .fill(Color.gray.opacity(0.08))
                                        .frame(width: barWidth, height: chartHeight)
                                    
                                    // 数据柱
                                    RoundedRectangle(cornerRadius: barCornerRadius)
                                        .fill(barGradient(for: dataPoint))
                                        .frame(
                                            width: barWidth,
                                            height: animate ? chartHeight * dataPoint.normalizedValue : 0
                                        )
                                        .animation(
                                            .easeOut(duration: 0.8)
                                            .delay(Double(index) * 0.03),
                                            value: animate
                                        )
                                        .overlay(
                                            // 选中高亮
                                            RoundedRectangle(cornerRadius: barCornerRadius)
                                                .stroke(Color.blue, lineWidth: selectedDataPoint?.id == dataPoint.id ? 2 : 0)
                                        )
                                }
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedDataPoint = selectedDataPoint?.id == dataPoint.id ? nil : dataPoint
                                    }
                                }
                                .onHover { hovering in
                                    if hovering {
                                        selectedDataPoint = dataPoint
                                    }
                                }
                            }
                        }
                    }
                    
                    // 悬停提示
                    if let selected = selectedDataPoint {
                        ModernValueTooltip(dataPoint: selected, unit: unit, period: period)
                            .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    }
                }
                .frame(height: chartHeight)
                
                // 底部标签
                HStack(alignment: .center, spacing: barSpacing) {
                    ForEach(data) { dataPoint in
                        Text(dataPoint.label)
                            .font(.system(size: period == .day ? 9 : 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: barWidth)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 12)
            }
        }
    }
    
    private func barGradient(for dataPoint: StatisticsDataPoint) -> LinearGradient {
        let isSelected = selectedDataPoint?.id == dataPoint.id
        let baseColor = isSelected ? Color.blue : Color.blue.opacity(0.8)
        
        return LinearGradient(
            gradient: Gradient(colors: [
                baseColor,
                baseColor.opacity(0.6)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Modern Grid Lines Component
struct ModernGridLinesView: View {
    let height: CGFloat
    
    var body: some View {
        VStack {
            ForEach(0..<4) { i in
                Rectangle()
                    .fill(Color.secondary.opacity(0.08))
                    .frame(height: 0.5)
                
                if i < 3 {
                    Spacer()
                }
            }
        }
        .frame(height: height)
    }
}

// MARK: - Modern Value Tooltip Component
struct ModernValueTooltip: View {
    let dataPoint: StatisticsDataPoint
    let unit: StatisticsUnit
    let period: StatisticsPeriod
    
    var body: some View {
        VStack(spacing: 6) {
            Text(formatValue())
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            
            Text(formatLabel())
                .font(.caption2)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.85))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
        )
    }
    
    private func formatValue() -> String {
        switch unit {
        case .count:
            let count = Int(dataPoint.value)
            return "\(count) 次"
        case .time:
            let hours = Int(dataPoint.value) / 60
            let minutes = Int(dataPoint.value) % 60
            if hours > 0 {
                return "\(hours)小时\(minutes)分钟"
            } else {
                return "\(minutes)分钟"
            }
        }
    }
    
    private func formatLabel() -> String {
        switch period {
        case .day:
            return "\(dataPoint.label):00"
        case .week, .month, .year:
            return dataPoint.label
        }
    }
}

// MARK: - Empty Chart View
struct EmptyChartView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.4))
            
            VStack(spacing: 6) {
                Text("暂无数据")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("开始你的第一个专注会话")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    StatisticsView(timerManager: TimerManager.shared)
} 