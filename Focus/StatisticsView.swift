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
    @State private var showContent = false
    
    init(timerManager: TimerManager) {
        self.timerManager = timerManager
        self._statisticsManager = StateObject(wrappedValue: StatisticsManager(timerManager: timerManager))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            ScrollView {
                LazyVStack(spacing: 24) {
                    chartSection
                    summaryCardsSection
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 20)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
            }
        }
        .frame(width: 680, height: 760)
        .background(backgroundView)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                    animateChart = true
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(.systemBlue).opacity(0.1), Color.clear]
                    : [Color(.systemBlue).opacity(0.05), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
            
            HStack(spacing: 16) {
                // 左侧图标和标题
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 44, height: 44)
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                        
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("专注统计")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
                
                // 关闭按钮
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        dismiss()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(isHoveringClose ? Color.red.opacity(0.15) : Color(.controlBackgroundColor))
                            .frame(width: 32, height: 32)
                            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 1)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(isHoveringClose ? .red : .secondary)
                    }
                    .scaleEffect(isHoveringClose ? 1.1 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { hovering in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isHoveringClose = hovering
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)
        }
        .frame(height: 80)
    }
    
    // MARK: - Chart Section
    private var chartSection: some View {
        ModernCard {
            let data = statisticsManager.getStatisticsData()
            
            VStack(alignment: .leading, spacing: 20) {
                // 顶部控制区域
                HStack(spacing: 16) {
                    // 时间段选择器
                    ModernSegmentedControl(
                        selection: $statisticsManager.currentPeriod,
                        options: StatisticsPeriod.allCases,
                        onChange: { _ in
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                animateChart = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    animateChart = true
                                }
                            }
                        }
                    )
                    .frame(maxWidth: .infinity)
                    
                    // 单位选择器
                    ModernMenu(
                        selection: $statisticsManager.currentUnit,
                        options: StatisticsUnit.allCases,
                        icon: "slider.horizontal.3"
                    )
                    .frame(width: 120)
                }
                
                // 时间段导航器
                HStack(spacing: 16) {
                    // 上一个时间段按钮
                    NavigationButton(
                        icon: "chevron.left",
                        isHovering: $isHoveringPrevious,
                        action: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                statisticsManager.navigateToPrevious()
                                animateChart = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    animateChart = true
                                }
                            }
                        }
                    )
                    
                    // 时间段信息 - 一行显示
                    HStack(spacing: 8) {
                        Text(statisticsManager.getCurrentPeriodTitle())
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: statisticsManager.currentDate)
                        
                        Text("-")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(statisticsManager.getCurrentPeriodTotal())
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: statisticsManager.currentDate)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // 下一个时间段按钮
                    NavigationButton(
                        icon: "chevron.right",
                        isHovering: $isHoveringNext,
                        isEnabled: statisticsManager.canNavigateToNext,
                        action: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                statisticsManager.navigateToNext()
                                animateChart = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    animateChart = true
                                }
                            }
                        }
                    )
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.controlBackgroundColor).opacity(0.6))
                        .stroke(Color(.separatorColor).opacity(0.3), lineWidth: 1)
                )
                
                // 图表内容
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
                    .frame(height: 200)
                }
            }
        }
    }
    
    // MARK: - Summary Cards Section
    private var summaryCardsSection: some View {
        let summary = statisticsManager.getStatisticsSummary()
        
        return LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            ModernSummaryCard(
                title: "总专注次数",
                value: "\(summary.totalSessions)",
                subtitle: "次会话",
                icon: "target",
                color: .blue,
                accentColor: .cyan
            )
            
            ModernSummaryCard(
                title: "总专注时长",
                value: summary.formattedTotalTime,
                subtitle: "",
                icon: "clock.fill",
                color: .green,
                accentColor: .mint
            )
            
            ModernSummaryCard(
                title: "平均时长",
                value: "\(summary.averageSessionLength)",
                subtitle: "分钟",
                icon: "gauge.medium",
                color: .orange,
                accentColor: .yellow
            )
            
            ModernSummaryCard(
                title: "连续天数",
                value: "\(summary.currentStreak)",
                subtitle: "天记录",
                icon: "flame.fill",
                color: .red,
                accentColor: .pink
            )
        }
    }
    
    // MARK: - Background View
    private var backgroundView: some View {
        ZStack {
            // 主背景
            Color(.windowBackgroundColor)
            
            // 渐变装饰
            RadialGradient(
                colors: colorScheme == .dark
                    ? [Color.blue.opacity(0.08), Color.clear]
                    : [Color.blue.opacity(0.04), Color.clear],
                center: .topTrailing,
                startRadius: 100,
                endRadius: 400
            )
            
            // 噪点纹理
            Rectangle()
                .fill(Color(.controlBackgroundColor).opacity(0.3))
        }
    }
}

// MARK: - Modern Card Component
struct ModernCard<Content: View>: View {
    let content: Content
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovering = false
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(24)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.controlBackgroundColor))
                        .shadow(
                            color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1),
                            radius: isHovering ? 20 : 12,
                            x: 0,
                            y: isHovering ? 8 : 4
                        )
                    
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(colorScheme == .dark ? 0.1 : 0.3),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .scaleEffect(isHovering ? 1.02 : 1.0)
            .onHover { hovering in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isHovering = hovering
                }
            }
    }
}

// MARK: - Navigation Button Component
struct NavigationButton: View {
    let icon: String
    @Binding var isHovering: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(icon: String, isHovering: Binding<Bool>, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.icon = icon
        self._isHovering = isHovering
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            if isEnabled {
                // 添加轻微的触觉反馈
                NSHapticFeedbackManager.defaultPerformer.perform(
                    NSHapticFeedbackManager.FeedbackPattern.generic,
                    performanceTime: .now
                )
                action()
            }
        }) {
            ZStack {
                // 背景圆形
                Circle()
                    .fill(Color(.controlBackgroundColor))
                    .frame(width: 44, height: 44)
                    .shadow(
                        color: .black.opacity(0.08),
                        radius: isHovering && isEnabled ? 12 : 8,
                        x: 0,
                        y: isHovering && isEnabled ? 4 : 2
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: isHovering && isEnabled
                                        ? [.blue.opacity(0.3), .clear]
                                        : [.clear, .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                // 图标
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        isEnabled
                            ? (isHovering
                                ? LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [.secondary, .secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            : LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .scaleEffect(isPressed ? 0.9 : 1.0)
            }
            .scaleEffect(isHovering && isEnabled ? 1.05 : 1.0)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
        .pressEvents {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = false
            }
        }
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isHovering = hovering
            }
        }
    }
}

// 按压事件扩展
extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

struct PressEventsModifier: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        onPress()
                    }
                    .onEnded { _ in
                        onRelease()
                    }
            )
    }
}

// MARK: - Modern Segmented Control
struct ModernSegmentedControl: View {
    @Binding var selection: StatisticsPeriod
    let options: [StatisticsPeriod]
    let onChange: (StatisticsPeriod) -> Void
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.self) { option in
                segmentButton(for: option)
            }
        }
        .padding(4)
        .background(segmentBackground)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selection)
    }
    
    private func segmentButton(for option: StatisticsPeriod) -> some View {
        Button(action: {
            selection = option
            onChange(option)
        }) {
            Text(option.rawValue)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(selection == option ? .white : .secondary)
                .frame(minWidth: 80)
                .frame(height: 36)
                .background(
                    ZStack {
                        if selection == option {
                            selectedBackground
                        }
                    }
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var selectedBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(
                LinearGradient(
                    colors: [.blue, .cyan],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .opacity
            ))
    }
    
    private var segmentBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color(.controlBackgroundColor))
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Modern Menu
struct ModernMenu: View {
    @Binding var selection: StatisticsUnit
    let options: [StatisticsUnit]
    let icon: String
    
    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selection = option
                    }
                }) {
                    HStack {
                        Text(option.rawValue)
                        if selection == option {
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        } label: {
            menuLabel
        }
        .menuStyle(BorderlessButtonMenuStyle())
    }
    
    private var menuLabel: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
            
            Text(selection == .count ? "次数" : "时长")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
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
    let accentColor: Color
    
    @State private var isHovering = false
    @State private var animatedValue: Double = 0
    @State private var isVisible = false
    
    private var iconGradient: LinearGradient {
        LinearGradient(
            colors: [color, accentColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var topBarGradient: LinearGradient {
        LinearGradient(
            colors: [color, accentColor],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [.white.opacity(0.2), .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部装饰条
            Rectangle()
                .fill(topBarGradient)
                .frame(height: 4)
            
            VStack(alignment: .leading, spacing: 16) {
                // 图标和数值
                HStack(alignment: .top, spacing: 12) {
                    iconView
                    
                    Spacer()
                    
                    valueView
                }
                
                // 标题
                titleView
            }
            .padding(20)
        }
        .background(cardBackground)
        .overlay(cardBorder)
        .scaleEffect(isHovering ? 1.03 : 1.0)
        .onHover { hovering in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isHovering = hovering
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                isVisible = true
            }
            
            // 数值动画
            if let numericValue = extractNumericValue() {
                withAnimation(.spring(response: 1.2, dampingFraction: 0.8).delay(0.4)) {
                    animatedValue = numericValue
                }
            }
        }
    }
    
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.12))
                .frame(width: 40, height: 40)
            
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(iconGradient)
                .scaleEffect(isVisible ? 1.0 : 0.8)
        }
    }
    
    private var valueView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(getAnimatedValueText())
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .opacity(isVisible ? 1.0 : 0.0)
                }
            }
        }
    }
    
    private var titleView: some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.primary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .opacity(isVisible ? 1.0 : 0.0)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.controlBackgroundColor))
            .shadow(
                color: .black.opacity(0.08),
                radius: isHovering ? 12 : 6,
                x: 0,
                y: isHovering ? 4 : 2
            )
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(borderGradient, lineWidth: 1)
    }
    
    private func extractNumericValue() -> Double? {
        // 从value字符串中提取数值
        let numbers = value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Double(numbers)
    }
    
    private func getAnimatedValueText() -> String {
        if let numericValue = extractNumericValue() {
            // 如果是纯数字，显示动画数值
            if value == String(Int(numericValue)) {
                return String(Int(animatedValue))
            }
        }
        // 否则返回原始值
        return value
    }
}

// MARK: - Modern Bar Chart Component
struct ModernBarChartView: View {
    let data: [StatisticsDataPoint]
    let unit: StatisticsUnit
    let period: StatisticsPeriod
    let animate: Bool
    @Binding var selectedDataPoint: StatisticsDataPoint?
    
    private let barSpacing: CGFloat = 4
    private let barCornerRadius: CGFloat = 6
    
    var body: some View {
        GeometryReader { geometry in
            let chartWidth = geometry.size.width
            let chartHeight = geometry.size.height - 60 // 留出底部标签空间
            let barWidth = max(8, (chartWidth - CGFloat(data.count - 1) * barSpacing) / CGFloat(data.count))
            
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
                                        .fill(Color.gray.opacity(0.06))
                                        .frame(width: barWidth, height: chartHeight)
                                    
                                    // 数据柱
                                    RoundedRectangle(cornerRadius: barCornerRadius)
                                        .fill(barGradient(for: dataPoint))
                                        .frame(
                                            width: barWidth,
                                            height: animate ? chartHeight * dataPoint.normalizedValue : 0
                                        )
                                        .animation(
                                            .spring(response: 0.8, dampingFraction: 0.8)
                                            .delay(Double(index) * 0.05),
                                            value: animate
                                        )
                                        .overlay(
                                            // 选中高亮
                                            RoundedRectangle(cornerRadius: barCornerRadius)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [.blue, .cyan],
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    ),
                                                    lineWidth: selectedDataPoint?.id == dataPoint.id ? 3 : 0
                                                )
                                                .shadow(
                                                    color: .blue.opacity(0.3),
                                                    radius: selectedDataPoint?.id == dataPoint.id ? 4 : 0
                                                )
                                        )
                                }
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
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
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                removal: .opacity.animation(.easeInOut(duration: 0.15))
                            ))
                            .zIndex(100)
                    }
                }
                .frame(height: chartHeight)
                
                // 底部标签
                HStack(alignment: .center, spacing: barSpacing) {
                    ForEach(data) { dataPoint in
                        Text(dataPoint.label)
                            .font(.system(size: period == .day ? 10 : 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: barWidth)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                    }
                }
                .padding(.top, 16)
            }
        }
    }
    
    private func barGradient(for dataPoint: StatisticsDataPoint) -> LinearGradient {
        let isSelected = selectedDataPoint?.id == dataPoint.id
        let opacity: Double = isSelected ? 1.0 : 0.8
        
        return LinearGradient(
            gradient: Gradient(colors: [
                Color.blue.opacity(opacity),
                Color.cyan.opacity(opacity * 0.7)
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
            ForEach(0..<5) { i in
                Rectangle()
                    .fill(Color.secondary.opacity(i == 0 ? 0.15 : 0.08))
                    .frame(height: 0.5)
                
                if i < 4 {
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
        VStack(spacing: 8) {
            Text(formatValue())
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(formatLabel())
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.85))
                    .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
                
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
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
    @State private var isAnimating = false
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                // 外圈动画
                Circle()
                    .stroke(Color.blue.opacity(0.1), lineWidth: 2)
                    .frame(width: 100, height: 100)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .opacity(isAnimating ? 0.5 : 1.0)
                
                // 主要图标容器
                Circle()
                    .fill(Color(.controlBackgroundColor))
                    .frame(width: 80, height: 80)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                    .overlay(
                        ZStack {
                            // 背景装饰点
                            ForEach(0..<3) { index in
                                Circle()
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(width: 4, height: 4)
                                    .offset(
                                        x: cos(Double(index) * 2 * .pi / 3) * 20,
                                        y: sin(Double(index) * 2 * .pi / 3) * 20
                                    )
                                    .opacity(showContent ? 1.0 : 0.0)
                                    .scaleEffect(showContent ? 1.0 : 0.5)
                                    .animation(
                                        .spring(response: 0.6, dampingFraction: 0.8)
                                        .delay(Double(index) * 0.1 + 0.3),
                                        value: showContent
                                    )
                            }
                            
                            // 主图标
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .scaleEffect(showContent ? 1.0 : 0.8)
                                .rotationEffect(.degrees(showContent ? 0 : -10))
                        }
                    )
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
                
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                    showContent = true
                }
            }
            
            VStack(spacing: 12) {
                Text("开始专注之旅")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .opacity(showContent ? 1.0 : 0.0)
                
                VStack(spacing: 8) {
                    Text("开始你的第一个专注会话")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                    
                    Text("数据将在这里生动地展示")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .opacity(showContent ? 1.0 : 0.0)
                
                // 引导提示
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(showContent ? 0 : 180))
                    
                    Text("关闭此窗口开始专注")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.blue.opacity(0.1))
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
                .opacity(showContent ? 1.0 : 0.0)
                .scaleEffect(showContent ? 1.0 : 0.8)
                .animation(
                    .spring(response: 0.6, dampingFraction: 0.8).delay(0.8),
                    value: showContent
                )
            }
            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4), value: showContent)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    StatisticsView(timerManager: TimerManager.shared)
} 