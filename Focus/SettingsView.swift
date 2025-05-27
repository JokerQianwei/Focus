//
//  SettingsView.swift
//  Focus
//
//  Created by 杨乾巍 on 2025/4/28.
//

import SwiftUI
import UserNotifications
import ApplicationServices

// MARK: - 设计系统
struct DesignSystem {
    // 间距系统
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }
    
    // 圆角系统
    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
    }
    
    // 阴影系统
    struct Shadow {
        static let subtle = (color: Color.black.opacity(0.03), radius: CGFloat(2), x: CGFloat(0), y: CGFloat(1))
        static let soft = (color: Color.black.opacity(0.06), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(2))
        static let medium = (color: Color.black.opacity(0.1), radius: CGFloat(12), x: CGFloat(0), y: CGFloat(4))
    }
    
    // 颜色系统
    struct Colors {
        static let accent = Color.accentColor
        static let primary = Color.primary
        static let secondary = Color.secondary
        static let tertiary = Color(.tertiaryLabelColor)
        static let background = Color(.windowBackgroundColor)
        static let cardBackground = Color(.controlBackgroundColor)
        static let separator = Color(.separatorColor)
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // 使用TimerManager
    @ObservedObject var timerManager: TimerManager

    // 临时存储输入值的状态
    @State private var workMinutesInput: String
    @State private var breakMinutesInput: String
    @State private var promptMinInput: String
    @State private var promptMaxInput: String
    @State private var microBreakInput: String
    @State private var isHoveringClose = false
    
    // 权限状态
    @State private var notificationPermissionGranted = false
    @State private var accessibilityPermissionGranted = false
    
    // 动画状态
    @State private var isVisible = false

    init(timerManager: TimerManager) {
        self.timerManager = timerManager
        // 初始化输入字段
        _workMinutesInput = State(initialValue: String(timerManager.workMinutes))
        _breakMinutesInput = State(initialValue: String(timerManager.breakMinutes))
        _promptMinInput = State(initialValue: String(timerManager.promptMinInterval))
        _promptMaxInput = State(initialValue: String(timerManager.promptMaxInterval))
        _microBreakInput = State(initialValue: String(timerManager.microBreakSeconds))
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.lg) {
                    timerSettingsSection
                    promptSettingsSection
                    soundSettingsSection
                    behaviorSettingsSection
                    notificationSection
                }
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.vertical, DesignSystem.Spacing.lg)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 20)
            }
        }
        .frame(width: 360, height: 520)
        .background(modernBackgroundGradient)
        .onAppear {
            checkNotificationPermission()
            checkAccessibilityPermission()
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                isVisible = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            // 当应用重新激活时（比如从系统设置返回），重新检查权限
            checkNotificationPermission()
            checkAccessibilityPermission()
        }
    }
    
    // MARK: - 顶部标题栏
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("设置")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.primary)
                    
                    // Text("个性化您的专注体验")
                    //     .font(.system(size: 13, weight: .medium))
                    //     .foregroundColor(DesignSystem.Colors.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        dismiss()
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(isHoveringClose ? .white : DesignSystem.Colors.secondary)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(isHoveringClose ? 
                                     Color.red.opacity(0.8) : 
                                     DesignSystem.Colors.cardBackground)
                                .shadow(
                                    color: DesignSystem.Shadow.subtle.color,
                                    radius: DesignSystem.Shadow.subtle.radius,
                                    x: DesignSystem.Shadow.subtle.x,
                                    y: DesignSystem.Shadow.subtle.y
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHoveringClose = hovering
                    }
                }
                .scaleEffect(isHoveringClose ? 1.05 : 1.0)
            }
            .padding(.horizontal, DesignSystem.Spacing.xxl)
            .padding(.top, DesignSystem.Spacing.xl)
            .padding(.bottom, DesignSystem.Spacing.lg)
        }
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(DesignSystem.Colors.separator.opacity(0.3))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
    
    // MARK: - 现代背景渐变
    private var modernBackgroundGradient: some View {
        ZStack {
            // 主背景
            DesignSystem.Colors.background
            
            // 渐变装饰
            LinearGradient(
                colors: colorScheme == .dark 
                    ? [Color.blue.opacity(0.02), Color.purple.opacity(0.02), Color.clear]
                    : [Color.blue.opacity(0.03), Color.purple.opacity(0.03), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // MARK: - 计时设置分组
    private var timerSettingsSection: some View {
        ModernSettingsSection(
            title: "计时设置",
            icon: "timer",
            iconColor: .blue
        ) {
            VStack(spacing: DesignSystem.Spacing.md) {
                ModernTimeInputRow(
                    title: "专注时间",
                    value: $workMinutesInput,
                    unit: "分钟",
                    icon: "brain.head.profile",
                    iconColor: .blue,
                    isDisabled: timerManager.timerRunning
                ) { newValue in
                    if let minutes = Int(newValue), minutes > 0 {
                        timerManager.workMinutes = minutes
                        if timerManager.isWorkMode && !timerManager.timerRunning {
                            timerManager.minutes = minutes
                        }
                    }
                }
                
                ModernDivider()
                
                ModernTimeInputRow(
                    title: "休息时间",
                    value: $breakMinutesInput,
                    unit: "分钟",
                    icon: "cup.and.saucer",
                    iconColor: .orange,
                    isDisabled: timerManager.timerRunning
                ) { newValue in
                    if let minutes = Int(newValue), minutes > 0 {
                        timerManager.breakMinutes = minutes
                    }
                }
            }
        }
    }
    
    // MARK: - 随机提示设置分组
    private var promptSettingsSection: some View {
        ModernSettingsSection(
            title: "随机提示音",
            icon: "waveform.path.ecg",
            iconColor: .green
        ) {
            VStack(spacing: DesignSystem.Spacing.md) {
                ModernTimeInputRow(
                    title: "最小间隔",
                    value: $promptMinInput,
                    unit: "分钟",
                    icon: "minus.circle",
                    iconColor: .green,
                    isDisabled: timerManager.timerRunning
                ) { newValue in
                    if let minutes = Int(newValue), minutes > 0 {
                        timerManager.promptMinInterval = minutes
                    }
                }
                
                ModernDivider()
                
                ModernTimeInputRow(
                    title: "最大间隔",
                    value: $promptMaxInput,
                    unit: "分钟",
                    icon: "plus.circle",
                    iconColor: .green,
                    isDisabled: timerManager.timerRunning
                ) { newValue in
                    if let minutes = Int(newValue), minutes > 0 {
                        timerManager.promptMaxInterval = minutes
                    }
                }
                
                ModernDivider()
                
                ModernTimeInputRow(
                    title: "微休息时长",
                    value: $microBreakInput,
                    unit: "秒",
                    icon: "clock.badge.checkmark",
                    iconColor: .mint,
                    isDisabled: timerManager.timerRunning
                ) { newValue in
                    if let seconds = Int(newValue), seconds > 0 {
                        timerManager.microBreakSeconds = seconds
                    }
                }
            }
        }
    }
    
    // MARK: - 声音设置分组
    private var soundSettingsSection: some View {
        ModernSettingsSection(
            title: "声音效果",
            icon: "speaker.wave.3",
            iconColor: .purple
        ) {
            VStack(spacing: DesignSystem.Spacing.md) {
                ModernToggleRow(
                    title: "启用提示音",
                    icon: "speaker.2",
                    iconColor: .purple,
                    isOn: $timerManager.promptSoundEnabled
                )
                
                if timerManager.promptSoundEnabled {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        ModernDivider()
                        
                        ModernSoundSelectionRow(
                            title: "开始音效",
                            icon: "play.circle",
                            iconColor: .green,
                            selectedSound: timerManager.microBreakStartSoundType,
                            onSelectionChange: { soundType in
                                NotificationCenter.default.post(
                                    name: .playMicroBreakStartSound,
                                    object: soundType.rawValue
                                )
                                timerManager.microBreakStartSoundType = soundType
                            }
                        )
                        
                        ModernDivider()
                        
                        ModernSoundSelectionRow(
                            title: "结束音效",
                            icon: "stop.circle",
                            iconColor: .red,
                            selectedSound: timerManager.microBreakEndSoundType,
                            onSelectionChange: { soundType in
                                NotificationCenter.default.post(
                                    name: .playMicroBreakEndSound,
                                    object: soundType.rawValue
                                )
                                timerManager.microBreakEndSoundType = soundType
                            }
                        )
                        
                        ModernInfoBox(
                            icon: "info.circle",
                            text: "每隔 \(timerManager.promptMinInterval)-\(timerManager.promptMaxInterval) 分钟播放提示音",
                            color: .blue
                        )
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .offset(y: -10)),
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    ))
                }
            }
        }
    }
    
    // MARK: - 行为设置分组
    private var behaviorSettingsSection: some View {
        ModernSettingsSection(
            title: "行为控制",
            icon: "gearshape.2",
            iconColor: .orange
        ) {
            VStack(spacing: DesignSystem.Spacing.md) {
                ModernToggleRow(
                    title: "微休息通知",
                    subtitle: "发送系统通知提醒",
                    icon: "bell",
                    iconColor: .orange,
                    isOn: $timerManager.microBreakNotificationEnabled
                )
                
                ModernDivider()
                
                ModernToggleRow(
                    title: "全屏模式",
                    subtitle: "微休息时启用全屏遮罩",
                    icon: "rectangle.fill",
                    iconColor: .indigo,
                    isOn: $timerManager.blackoutEnabled
                )
                
                ModernDivider()
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    ModernToggleRow(
                        title: "媒体控制",
                        subtitle: "切换暂停/播放音视频状态",
                        icon: "pause.rectangle",
                        iconColor: .pink,
                        isOn: $timerManager.muteAudioDuringBreak
                    )
                    
                    if timerManager.muteAudioDuringBreak {
                        ModernWarningBox(
                            icon: "exclamationmark.triangle",
                            text: "首次使用需授予辅助功能权限"
                        )
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .offset(y: -10)),
                            removal: .opacity.combined(with: .scale(scale: 0.95))
                        ))
                    }
                }
            }
        }
    }
    
    // MARK: - 权限设置分组
    private var notificationSection: some View {
        ModernSettingsSection(
            title: "权限",
            icon: "bell.badge",
            iconColor: .red
        ) {
            VStack(spacing: DesignSystem.Spacing.md) {
                ModernPermissionRow(
                    title: "通知权限",
                    subtitle: "允许应用发送通知提醒",
                    icon: "bell",
                    iconColor: .orange,
                    isGranted: notificationPermissionGranted,
                    onSettingsAction: openNotificationSettings
                )
                
                ModernDivider()
                
                ModernPermissionRow(
                    title: "辅助功能权限",
                    subtitle: "媒体控制功能需要此权限",
                    icon: "accessibility",
                    iconColor: .blue,
                    isGranted: accessibilityPermissionGranted,
                    onSettingsAction: openAccessibilitySettings
                )
            }
        }
    }
    
    // MARK: - 辅助方法
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func checkAccessibilityPermission() {
        // 使用更可靠的检测方法，包括带提示的检查
        let isGrantedBasic = AXIsProcessTrusted()
        
        // 尝试使用带选项的检查方法
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let isGrantedWithOptions = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        let finalResult = isGrantedBasic || isGrantedWithOptions
        
        #if DEBUG
        print("🔍 辅助功能权限检测:")
        print("  - 基础检测: \(isGrantedBasic ? "已授权" : "未授权")")
        print("  - 选项检测: \(isGrantedWithOptions ? "已授权" : "未授权")")
        print("  - 最终结果: \(finalResult ? "已授权" : "未授权")")
        #endif
        
        DispatchQueue.main.async {
            self.accessibilityPermissionGranted = finalResult
        }
        
        // 如果权限未授予，启动定时器定期检查
        if !finalResult {
            startAccessibilityPermissionMonitoring()
        }
    }
    
    // 启动辅助功能权限监听
    private func startAccessibilityPermissionMonitoring() {
        #if DEBUG
        print("🔄 开始监听辅助功能权限变化...")
        #endif
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            // 使用与检测相同的逻辑
            let isGrantedBasic = AXIsProcessTrusted()
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
            let isGrantedWithOptions = AXIsProcessTrustedWithOptions(options as CFDictionary)
            let finalResult = isGrantedBasic || isGrantedWithOptions
            
            DispatchQueue.main.async {
                if finalResult != self.accessibilityPermissionGranted {
                    #if DEBUG
                    print("✅ 辅助功能权限状态变化:")
                    print("  - 基础检测: \(isGrantedBasic ? "已授权" : "未授权")")
                    print("  - 选项检测: \(isGrantedWithOptions ? "已授权" : "未授权")")
                    print("  - 最终结果: \(finalResult ? "已授权" : "未授权")")
                    #endif
                    
                    self.accessibilityPermissionGranted = finalResult
                    if finalResult {
                        timer.invalidate() // 权限获得后停止监听
                        #if DEBUG
                        print("🛑 停止监听辅助功能权限变化")
                        #endif
                    }
                }
            }
        }
    }
    
    private func openNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - 现代设置分组组件
struct ModernSettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false
    
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
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // 分组标题
            HStack(spacing: DesignSystem.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.xs)
            
            // 内容卡片
            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .padding(DesignSystem.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(.regularMaterial)
                    .shadow(
                        color: DesignSystem.Shadow.soft.color,
                        radius: isHovered ? DesignSystem.Shadow.medium.radius : DesignSystem.Shadow.soft.radius,
                        x: DesignSystem.Shadow.soft.x,
                        y: DesignSystem.Shadow.soft.y
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .stroke(
                        LinearGradient(
                            colors: [
                                iconColor.opacity(0.1),
                                iconColor.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
        }
    }
}

// MARK: - 现代时间输入行组件
struct ModernTimeInputRow: View {
    let title: String
    @Binding var value: String
    let unit: String
    let icon: String
    let iconColor: Color
    let isDisabled: Bool
    let onChange: (String) -> Void
    
    @State private var isFocused = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(DesignSystem.Colors.primary)
            
            Spacer()
            
            HStack(spacing: DesignSystem.Spacing.sm) {
                TextField("", text: $value)
                    .textFieldStyle(ModernInputFieldStyle(isFocused: isFocused))
                    .frame(width: 60)
                    .multilineTextAlignment(.center)
                    .disabled(isDisabled)
                    .onFocusChange { focused in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isFocused = focused
                        }
                    }
                    .onChange(of: value) { _, newValue in
                        let filtered = newValue.filter { "0123456789".contains($0) }
                        if filtered != newValue { 
                            value = filtered 
                        }
                        onChange(filtered)
                    }
                
                Text(unit)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.secondary)
                    .frame(width: 35, alignment: .leading)
            }
        }
    }
}

// MARK: - 现代切换行组件
struct ModernToggleRow: View {
    let title: String
    let subtitle: String?
    let icon: String
    let iconColor: Color
    @Binding var isOn: Bool
    
    init(title: String, subtitle: String? = nil, icon: String, iconColor: Color, isOn: Binding<Bool>) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self._isOn = isOn
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(DesignSystem.Colors.secondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(ModernToggleStyle())
        }
    }
}

// MARK: - 现代声音选择行组件
struct ModernSoundSelectionRow: View {
    let title: String
    let icon: String
    let iconColor: Color
    let selectedSound: SoundType
    let onSelectionChange: (SoundType) -> Void
    
    @State private var isMenuOpen = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(DesignSystem.Colors.primary)
            
            Spacer()
            
            Menu {
                ForEach(SoundType.allCases) { soundType in
                    Button(action: {
                        onSelectionChange(soundType)
                    }) {
                        HStack {
                            Text(soundType.displayName)
                            if selectedSound == soundType {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Text(selectedSound.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.primary)
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.secondary)
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .fill(DesignSystem.Colors.cardBackground)
                        .shadow(
                            color: DesignSystem.Shadow.subtle.color,
                            radius: DesignSystem.Shadow.subtle.radius,
                            x: DesignSystem.Shadow.subtle.x,
                            y: DesignSystem.Shadow.subtle.y
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .stroke(DesignSystem.Colors.separator.opacity(0.3), lineWidth: 0.5)
                )
            }
            .scaleEffect(isMenuOpen ? 0.98 : 1.0)
            .onMenuOpen { isOpen in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isMenuOpen = isOpen
                }
            }
        }
    }
}

// MARK: - 现代权限行组件
struct ModernPermissionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let isGranted: Bool
    let onSettingsAction: () -> Void
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(DesignSystem.Colors.secondary)
            }
            
            Spacer()
            
            ModernPermissionBadge(
                isGranted: isGranted,
                onSettingsAction: onSettingsAction
            )
        }
    }
}

// MARK: - 现代权限徽章
struct ModernPermissionBadge: View {
    let isGranted: Bool
    let onSettingsAction: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        if isGranted {
            // 已授权状态 - 紧凑水平布局
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 12, weight: .semibold))
                
                Text("已授权")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.green.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.green.opacity(0.25), lineWidth: 0.5)
            )
        } else {
            // 未授权状态 - 水平布局保持对齐
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 12, weight: .semibold))
                    
                    Text("未授权")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                Button("前往设置") {
                    onSettingsAction()
                }
                .buttonStyle(CompactMiniButtonStyle())
                .scaleEffect(isHovered ? 1.02 : 1.0)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isHovered = hovering
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.orange.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.orange.opacity(0.25), lineWidth: 0.5)
            )
        }
    }
}

// MARK: - 现代信息框
struct ModernInfoBox: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 12, weight: .medium))
            
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignSystem.Colors.secondary)
            
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .fill(color.opacity(0.08))
        )
    }
}

// MARK: - 现代警告框
struct ModernWarningBox: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .font(.system(size: 12, weight: .medium))
            
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignSystem.Colors.secondary)
            
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .fill(Color.orange.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - 现代分割线
struct ModernDivider: View {
    var body: some View {
        Rectangle()
            .fill(DesignSystem.Colors.separator.opacity(0.3))
            .frame(height: 0.5)
            .padding(.horizontal, -DesignSystem.Spacing.sm)
    }
}

// MARK: - 现代输入框样式
struct ModernInputFieldStyle: TextFieldStyle {
    let isFocused: Bool
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(Color(.textBackgroundColor))
                    .shadow(
                        color: DesignSystem.Shadow.subtle.color,
                        radius: DesignSystem.Shadow.subtle.radius,
                        x: DesignSystem.Shadow.subtle.x,
                        y: DesignSystem.Shadow.subtle.y
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .stroke(
                        isFocused ? Color.accentColor.opacity(0.6) : DesignSystem.Colors.separator.opacity(0.3),
                        lineWidth: isFocused ? 1.5 : 0.5
                    )
            )
            .scaleEffect(isFocused ? 1.02 : 1.0)
    }
}

// MARK: - 现代切换开关样式
struct ModernToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                configuration.isOn.toggle()
            }
        }) {
            HStack {
                configuration.label
                
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(configuration.isOn ? Color.accentColor : DesignSystem.Colors.cardBackground)
                        .frame(width: 44, height: 26)
                        .shadow(
                            color: DesignSystem.Shadow.subtle.color,
                            radius: DesignSystem.Shadow.subtle.radius,
                            x: DesignSystem.Shadow.subtle.x,
                            y: DesignSystem.Shadow.subtle.y
                        )
                    
                    Circle()
                        .fill(.white)
                        .frame(width: 22, height: 22)
                        .shadow(
                            color: DesignSystem.Shadow.soft.color,
                            radius: DesignSystem.Shadow.soft.radius,
                            x: DesignSystem.Shadow.soft.x,
                            y: DesignSystem.Shadow.soft.y
                        )
                        .offset(x: configuration.isOn ? 9 : -9)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 现代迷你按钮样式
struct ModernMiniButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, 6)
            .frame(minWidth: 60, minHeight: 24)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: configuration.isPressed 
                                ? [Color.accentColor.opacity(0.8), Color.accentColor.opacity(0.9)]
                                : [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(
                        color: DesignSystem.Shadow.soft.color,
                        radius: configuration.isPressed ? 2 : DesignSystem.Shadow.soft.radius,
                        x: DesignSystem.Shadow.soft.x,
                        y: configuration.isPressed ? 1 : DesignSystem.Shadow.soft.y
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - 紧凑迷你按钮样式
struct CompactMiniButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(minWidth: 50, minHeight: 20)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(
                        LinearGradient(
                            colors: configuration.isPressed 
                                ? [Color.accentColor.opacity(0.8), Color.accentColor.opacity(0.9)]
                                : [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(
                        color: Color.black.opacity(0.1),
                        radius: configuration.isPressed ? 1 : 2,
                        x: 0,
                        y: configuration.isPressed ? 0.5 : 1
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
    }
}

// MARK: - 扩展：菜单打开状态检测
extension View {
    func onMenuOpen(perform action: @escaping (Bool) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: NSMenu.didBeginTrackingNotification)) { _ in
            action(true)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSMenu.didEndTrackingNotification)) { _ in
            action(false)
        }
    }
}

// MARK: - 扩展：焦点状态检测
extension View {
    func onFocusChange(perform action: @escaping (Bool) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: NSControl.textDidBeginEditingNotification)) { _ in
            action(true)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSControl.textDidEndEditingNotification)) { _ in
            action(false)
        }
    }
}

#Preview {
    SettingsView(timerManager: TimerManager.shared)
}
