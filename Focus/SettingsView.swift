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
                    timerSettingsCard
                    promptSettingsCard
                    soundSettingsCard
                    blackoutSettingsCard
                    videoControlCard
                    notificationCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
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
                VStack(alignment: .leading, spacing: 2) {
                    Text("设置")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("个性化你的专注体验")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        dismiss()
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isHoveringClose ? .white : .secondary)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(isHoveringClose ? .red : Color(.controlBackgroundColor))
                        )
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHoveringClose = hovering
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)
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
    
    // MARK: - 计时设置卡片
    private var timerSettingsCard: some View {
        SettingsCard(
            title: "计时设置",
            subtitle: "设置专注和休息时间",
            icon: "timer",
            iconColor: .blue
        ) {
            VStack(spacing: 16) {
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
                    .padding(.horizontal, -8)
                
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
    
    // MARK: - 随机提示设置卡片
    private var promptSettingsCard: some View {
        SettingsCard(
            title: "随机提示",
            subtitle: "科学的微休息间隔",
            icon: "waveform.path.ecg",
            iconColor: .green
        ) {
            VStack(spacing: 16) {
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
                    .padding(.horizontal, -8)
                
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
                    .padding(.horizontal, -8)
                
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
    
    // MARK: - 声音设置卡片
    private var soundSettingsCard: some View {
        SettingsCard(
            title: "提示音效",
            subtitle: "个性化你的声音体验",
            icon: "speaker.wave.3",
            iconColor: .purple
        ) {
            VStack(spacing: 16) {
                ToggleRow(
                    title: "启用提示音",
                    subtitle: "专注期间播放提示音",
                    icon: "speaker.2",
                    isOn: $timerManager.promptSoundEnabled
                )
                
                if timerManager.promptSoundEnabled {
                    VStack(spacing: 12) {
                        Divider()
                            .padding(.horizontal, -8)
                        
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
                            .padding(.horizontal, -8)
                        
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
                                .font(.caption)
                            Text("每隔 \(timerManager.promptMinInterval)-\(timerManager.promptMaxInterval) 分钟播放提示音")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        }
    }
    
    // MARK: - 黑屏设置卡片
    private var blackoutSettingsCard: some View {
        SettingsCard(
            title: "黑屏功能",
            subtitle: "强制休息模式",
            icon: "display",
            iconColor: .gray
        ) {
            ToggleRow(
                title: "微休息黑屏",
                subtitle: "全屏黑色窗口强制休息",
                icon: "rectangle.fill",
                isOn: $timerManager.blackoutEnabled
            )
        }
    }
    
    // MARK: - 视频控制卡片
    private var videoControlCard: some View {
        SettingsCard(
            title: "视频控制",
            subtitle: "智能媒体管理",
            icon: "play.slash",
            iconColor: .orange
        ) {
            VStack(alignment: .leading, spacing: 8) {
                ToggleRow(
                    title: "自动暂停视频",
                    subtitle: "微休息时暂停/播放视频",
                    icon: "pause.rectangle",
                    isOn: $timerManager.muteAudioDuringBreak
                )
                
                if timerManager.muteAudioDuringBreak {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("首次使用需授予辅助功能权限")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        }
    }
    
    // MARK: - 通知设置卡片
    private var notificationCard: some View {
        SettingsCard(
            title: "通知设置",
            subtitle: "系统提醒配置",
            icon: "bell.badge",
            iconColor: .red
        ) {
            VStack(spacing: 16) {
                ToggleRow(
                    title: "微休息通知",
                    subtitle: "发送系统通知提醒",
                    icon: "bell",
                    isOn: $timerManager.microBreakNotificationEnabled
                )
                
                Divider()
                    .padding(.horizontal, -8)
                
                HStack {
                    Image(systemName: "key")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("通知权限")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        Text("需要权限来发送提醒")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    PermissionStatusBadge(isGranted: notificationPermissionGranted)
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

// MARK: - 设置卡片组件
struct SettingsCard<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(iconColor.opacity(0.15))
                    )
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
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
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 6) {
                TextField("", text: $value)
                    .textFieldStyle(ModernInputStyle())
                    .frame(width: 60)
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
                    .font(.system(size: 12, weight: .medium))
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
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
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
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
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
                HStack(spacing: 6) {
                    Text(selectedSound.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
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
        HStack(spacing: 6) {
            Image(systemName: isGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(isGranted ? .green : .orange)
                .font(.caption)
            
            Text(isGranted ? "已授权" : "未授权")
                .font(.caption)
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
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill((isGranted ? Color.green : Color.orange).opacity(0.1))
        )
    }
}

// MARK: - 现代输入框样式
struct ModernInputStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.textBackgroundColor))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
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
                    RoundedRectangle(cornerRadius: 16)
                        .fill(configuration.isOn ? Color.accentColor : Color(.controlBackgroundColor))
                        .frame(width: 44, height: 24)
                    
                    Circle()
                        .fill(.white)
                        .frame(width: 20, height: 20)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .offset(x: configuration.isOn ? 10 : -10)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SettingsView(timerManager: TimerManager.shared)
}
