//
//  SettingsView.swift
//  Focus
//
//  Created by 杨乾巍 on 2025/4/28.
//

import SwiftUI
import UserNotifications

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
    
    // 通知权限状态
    @State private var notificationPermissionGranted = false

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
                LazyVStack(spacing: 20) {
                    timerSettingsSection
                    promptSettingsSection
                    soundSettingsSection
                    behaviorSettingsSection
                    notificationSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .frame(width: 420, height: 600)
        .background(backgroundGradient)
        .onAppear {
            checkNotificationPermission()
        }
    }
    
    // MARK: - 顶部标题栏
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("设置")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        dismiss()
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isHoveringClose ? .white : .secondary)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(isHoveringClose ? .red : Color(.controlBackgroundColor))
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
    
    // MARK: - 计时设置分组
    private var timerSettingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(title: "计时", icon: "timer", iconColor: .blue)
            
            SimpleCard {
                VStack(spacing: 12) {
                    TimeInputRow(
                        title: "专注时间",
                        value: $workMinutesInput,
                        unit: "分钟",
                        icon: "brain.head.profile",
                        isDisabled: timerManager.timerRunning
                    ) { newValue in
                        if let minutes = Int(newValue), minutes > 0 {
                            timerManager.workMinutes = minutes
                            if timerManager.isWorkMode && !timerManager.timerRunning {
                                timerManager.minutes = minutes
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.horizontal, -6)
                    
                    TimeInputRow(
                        title: "休息时间",
                        value: $breakMinutesInput,
                        unit: "分钟",
                        icon: "cup.and.saucer",
                        isDisabled: timerManager.timerRunning
                    ) { newValue in
                        if let minutes = Int(newValue), minutes > 0 {
                            timerManager.breakMinutes = minutes
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 随机提示设置分组
    private var promptSettingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(title: "随机提示音", icon: "waveform.path.ecg", iconColor: .green)
            
            SimpleCard {
                VStack(spacing: 12) {
                    TimeInputRow(
                        title: "最小间隔",
                        value: $promptMinInput,
                        unit: "分钟",
                        icon: "minus.circle",
                        isDisabled: timerManager.timerRunning
                    ) { newValue in
                        if let minutes = Int(newValue), minutes > 0 {
                            timerManager.promptMinInterval = minutes
                        }
                    }
                    
                    Divider()
                        .padding(.horizontal, -6)
                    
                    TimeInputRow(
                        title: "最大间隔",
                        value: $promptMaxInput,
                        unit: "分钟",
                        icon: "plus.circle",
                        isDisabled: timerManager.timerRunning
                    ) { newValue in
                        if let minutes = Int(newValue), minutes > 0 {
                            timerManager.promptMaxInterval = minutes
                        }
                    }
                    
                    Divider()
                        .padding(.horizontal, -6)
                    
                    TimeInputRow(
                        title: "微休息时长",
                        value: $microBreakInput,
                        unit: "秒",
                        icon: "clock.badge.checkmark",
                        isDisabled: timerManager.timerRunning
                    ) { newValue in
                        if let seconds = Int(newValue), seconds > 0 {
                            timerManager.microBreakSeconds = seconds
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 声音设置分组
    private var soundSettingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(title: "声音", icon: "speaker.wave.3", iconColor: .purple)
            
            SimpleCard {
                VStack(spacing: 12) {
                    SimpleToggleRow(
                        title: "启用提示音",
                        icon: "speaker.2",
                        isOn: $timerManager.promptSoundEnabled
                    )
                    
                    if timerManager.promptSoundEnabled {
                        VStack(spacing: 10) {
                            Divider()
                                .padding(.horizontal, -6)
                            
                            SoundSelectionRow(
                                title: "开始音效",
                                icon: "play.circle",
                                selectedSound: timerManager.microBreakStartSoundType,
                                onSelectionChange: { soundType in
                                    NotificationCenter.default.post(
                                        name: .playMicroBreakStartSound,
                                        object: soundType.rawValue
                                    )
                                    timerManager.microBreakStartSoundType = soundType
                                }
                            )
                            
                            Divider()
                                .padding(.horizontal, -6)
                            
                            SoundSelectionRow(
                                title: "结束音效",
                                icon: "stop.circle",
                                selectedSound: timerManager.microBreakEndSoundType,
                                onSelectionChange: { soundType in
                                    NotificationCenter.default.post(
                                        name: .playMicroBreakEndSound,
                                        object: soundType.rawValue
                                    )
                                    timerManager.microBreakEndSoundType = soundType
                                }
                            )
                            
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                                    .font(.caption2)
                                Text("每隔 \(timerManager.promptMinInterval)-\(timerManager.promptMaxInterval) 分钟播放提示音")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
            }
        }
    }
    
    // MARK: - 行为设置分组
    private var behaviorSettingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(title: "行为", icon: "gearshape.2", iconColor: .orange)
            
            SimpleCard {
                VStack(spacing: 12) {
                    ToggleRow(
                        title: "微休息通知",
                        subtitle: "微休息开始和结束时发送系统通知提醒",
                        icon: "bell",
                        isOn: $timerManager.microBreakNotificationEnabled
                    )
                    
                    Divider()
                        .padding(.horizontal, -6)
                    
                    SimpleToggleRow(
                        title: "微休息时全屏模式",
                        icon: "rectangle.fill",
                        isOn: $timerManager.blackoutEnabled
                    )
                    
                    Divider()
                        .padding(.horizontal, -6)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        ToggleRow(
                            title: "微休息时切换暂停/播放状态",
                            subtitle: "推荐看视频/网课时开启",
                            icon: "pause.rectangle",
                            isOn: $timerManager.muteAudioDuringBreak
                        )
                        
                        if timerManager.muteAudioDuringBreak {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                    .font(.caption2)
                                Text("首次使用需授予辅助功能权限")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 通知设置分组
    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(title: "通知设置", icon: "bell.badge", iconColor: .red)
            
            SimpleCard {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "key")
                            .foregroundColor(.secondary)
                            .frame(width: 18)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("通知权限")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                            Text("需要权限来发送提醒")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        PermissionStatusBadge(isGranted: notificationPermissionGranted)
                    }
                }
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
    
    private func openNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - 分组标题组件
struct SectionTitle: View {
    let title: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
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
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - 简单卡片组件
struct SimpleCard<Content: View>: View {
    let content: Content
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
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
}

// MARK: - 设置卡片组件（保留用于兼容性）
struct SettingsCard<Content: View>: View {
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
            HStack(spacing: 10) {
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
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.08), lineWidth: 0.5)
        )
    }
}

// MARK: - 时间输入行组件
struct TimeInputRow: View {
    let title: String
    @Binding var value: String
    let unit: String
    let icon: String
    let isDisabled: Bool
    let onChange: (String) -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 18)
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 4) {
                TextField("", text: $value)
                    .textFieldStyle(ModernInputStyle())
                    .frame(width: 55)
                    .multilineTextAlignment(.center)
                    .disabled(isDisabled)
                    .onChange(of: value) { _, newValue in
                        let filtered = newValue.filter { "0123456789".contains($0) }
                        if filtered != newValue { 
                            value = filtered 
                        }
                        onChange(filtered)
                    }
                
                Text(unit)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - 切换行组件
struct ToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 18)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(ModernToggleStyle())
        }
    }
}

// MARK: - 简单切换行组件（无副标题）
struct SimpleToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 18)
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(ModernToggleStyle())
        }
    }
}

// MARK: - 声音选择行组件
struct SoundSelectionRow: View {
    let title: String
    let icon: String
    let selectedSound: SoundType
    let onSelectionChange: (SoundType) -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 18)
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
            
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
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedSound.displayName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.controlBackgroundColor))
                )
            }
        }
    }
}

// MARK: - 权限状态徽章
struct PermissionStatusBadge: View {
    let isGranted: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(isGranted ? .green : .orange)
                .font(.caption2)
            
            Text(isGranted ? "已授权" : "未授权")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(isGranted ? .green : .orange)
            
            if !isGranted {
                Button("设置") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill((isGranted ? Color.green : Color.orange).opacity(0.1))
        )
    }
}

// MARK: - 现代输入框样式
struct ModernInputStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(.textBackgroundColor))
                    .shadow(color: .black.opacity(0.03), radius: 1, x: 0, y: 0.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.accentColor.opacity(0.25), lineWidth: 0.5)
            )
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
                    RoundedRectangle(cornerRadius: 14)
                        .fill(configuration.isOn ? Color.accentColor : Color(.controlBackgroundColor))
                        .frame(width: 40, height: 22)
                    
                    Circle()
                        .fill(.white)
                        .frame(width: 18, height: 18)
                        .shadow(color: .black.opacity(0.08), radius: 1, x: 0, y: 0.5)
                        .offset(x: configuration.isOn ? 9 : -9)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SettingsView(timerManager: TimerManager.shared)
}
