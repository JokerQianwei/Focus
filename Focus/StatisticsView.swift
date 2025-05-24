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
    
    init(timerManager: TimerManager) {
        self.timerManager = timerManager
        self._statisticsManager = StateObject(wrappedValue: StatisticsManager(timerManager: timerManager))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    periodTitleSection
                    controlsSection
                    chartSection
                    summaryCardsSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .frame(width: 500, height: 600)
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
    
    // MARK: - Period Title Section
    private var periodTitleSection: some View {
        VStack(spacing: 4) {
            Text(statisticsManager.getCurrentPeriodTitle())
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            Text(statisticsManager.getCurrentPeriodTotal())
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.blue)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Controls Section
    private var controlsSection: some View {
        HStack(spacing: 12) {
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
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(statisticsManager.currentPeriod == period ? .white : .secondary)
                            .frame(width: 32, height: 28)
                            .background(
                                Rectangle()
                                    .fill(statisticsManager.currentPeriod == period ? Color.blue : Color.clear)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.controlBackgroundColor))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
            
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
                HStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.caption)
                    Text(statisticsManager.currentUnit.rawValue)
                        .font(.system(size: 12, weight: .medium))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.controlBackgroundColor))
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Chart Section
    private var chartSection: some View {
        StatisticsCard(
            title: "数据趋势",
            icon: "chart.line.uptrend.xyaxis",
            iconColor: .blue
        ) {
            let data = statisticsManager.getStatisticsData()
            
            if data.isEmpty {
                EmptyChartView()
            } else {
                BarChartView(
                    data: data,
                    unit: statisticsManager.currentUnit,
                    animate: animateChart,
                    selectedDataPoint: $selectedDataPoint
                )
                .frame(height: 200)
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
            SummaryCard(
                title: "总专注次数",
                value: "\(summary.totalSessions)",
                subtitle: "Sessions",
                icon: "target",
                color: .blue
            )
            
            SummaryCard(
                title: "总专注时长",
                value: summary.formattedTotalTime,
                subtitle: "",
                icon: "clock",
                color: .green
            )
            
            SummaryCard(
                title: "平均时长",
                value: "\(summary.averageSessionLength)",
                subtitle: "分钟",
                icon: "gauge.medium",
                color: .orange
            )
            
            SummaryCard(
                title: "连续天数",
                value: "\(summary.currentStreak)",
                subtitle: "天",
                icon: "flame",
                color: .red
            )
        }
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

// MARK: - Statistics Card Component
struct StatisticsCard<Content: View>: View {
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 20, height: 20)
                    .background(
                        Circle()
                            .fill(iconColor.opacity(0.12))
                    )
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.08), lineWidth: 0.5)
        )
    }
}

// MARK: - Summary Card Component
struct SummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(height: 80)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Bar Chart Component
struct BarChartView: View {
    let data: [StatisticsDataPoint]
    let unit: StatisticsUnit
    let animate: Bool
    @Binding var selectedDataPoint: StatisticsDataPoint?
    
    private let barSpacing: CGFloat = 4
    private let barCornerRadius: CGFloat = 3
    
    var body: some View {
        GeometryReader { geometry in
            let chartWidth = geometry.size.width
            let chartHeight = geometry.size.height - 40 // 留出底部标签空间
            let barWidth = (chartWidth - CGFloat(data.count - 1) * barSpacing) / CGFloat(data.count)
            
            VStack(spacing: 0) {
                // 图表区域
                ZStack(alignment: .bottom) {
                    // 背景网格线
                    GridLinesView(height: chartHeight)
                    
                    // 柱状图
                    HStack(alignment: .bottom, spacing: barSpacing) {
                        ForEach(Array(data.enumerated()), id: \.element.id) { index, dataPoint in
                            VStack(spacing: 4) {
                                ZStack {
                                    // 背景柱
                                    RoundedRectangle(cornerRadius: barCornerRadius)
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(width: barWidth, height: chartHeight)
                                    
                                    // 数据柱
                                    VStack {
                                        Spacer()
                                        RoundedRectangle(cornerRadius: barCornerRadius)
                                            .fill(barGradient)
                                            .frame(
                                                width: barWidth,
                                                height: animate ? chartHeight * dataPoint.normalizedValue : 0
                                            )
                                            .animation(
                                                .easeOut(duration: 0.8)
                                                .delay(Double(index) * 0.05),
                                                value: animate
                                            )
                                    }
                                }
                                .onTapGesture {
                                    selectedDataPoint = selectedDataPoint?.id == dataPoint.id ? nil : dataPoint
                                }
                                .onHover { hovering in
                                    if hovering {
                                        selectedDataPoint = dataPoint
                                    }
                                }
                            }
                        }
                    }
                    
                    // 数值显示
                    if let selected = selectedDataPoint {
                        ValueTooltip(dataPoint: selected, unit: unit)
                    }
                }
                .frame(height: chartHeight)
                
                // 底部标签
                HStack(alignment: .center, spacing: barSpacing) {
                    ForEach(data) { dataPoint in
                        Text(dataPoint.label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: barWidth)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    private var barGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.blue,
                Color.blue.opacity(0.7)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Grid Lines Component
struct GridLinesView: View {
    let height: CGFloat
    
    var body: some View {
        VStack {
            ForEach(0..<5) { i in
                Rectangle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(height: 0.5)
                
                if i < 4 {
                    Spacer()
                }
            }
        }
        .frame(height: height)
    }
}

// MARK: - Value Tooltip Component
struct ValueTooltip: View {
    let dataPoint: StatisticsDataPoint
    let unit: StatisticsUnit
    
    var body: some View {
        VStack(spacing: 4) {
            Text(formatValue())
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
            
            Text(dataPoint.label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black.opacity(0.8))
        )
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    private func formatValue() -> String {
        switch unit {
        case .count:
            return "\(Int(dataPoint.value))"
        case .time:
            let hours = Int(dataPoint.value) / 60
            let minutes = Int(dataPoint.value) % 60
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(minutes)m"
            }
        }
    }
}

// MARK: - Empty Chart View
struct EmptyChartView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("暂无数据")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("开始你的第一个专注会话")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    StatisticsView(timerManager: TimerManager.shared)
} 