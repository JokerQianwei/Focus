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
                LazyVStack(spacing: 24) {
                    timerSettingsSection
                    behaviorSettingsSection
                    generalSettingsSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
        }
        .frame(width: 480, height: 640)
        .background(Color(.windowBackgroundColor))
        .onAppear {
            checkNotificationPermission()
        }
    }
    
    // MARK: - 顶部标题栏
    private var headerView: some View {
        HStack {
            Text("设置")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    dismiss()
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color(.controlBackgroundColor))
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHoveringClose = hovering
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - 时段设置
    private var timerSettingsSection: some View {
        SettingsSection(title: "时段") {
            SettingsGroup {
                TimeSettingRow(
                    title: "Flow 持续时间",
                    value: $workMinutesInput,
                    unit: "分钟",
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
                    .padding(.leading, 16)
                
                TimeSettingRow(
                    title: "休息时间",
                    value: $breakMinutesInput,
                    unit: "分钟",
                    isDisabled: timerManager.timerRunning
                ) { newValue in
                    if let minutes = Int(newValue), minutes > 0 {
                        timerManager.breakMinutes = minutes
                    }
                }
            }
            
            SettingsGroup {
                TimeSettingRow(
                    title: "提示最小间隔",
                    value: $promptMinInput,
                    unit: "分钟",
                    isDisabled: timerManager.timerRunning
                ) { newValue in
                    if let minutes = Int(newValue), minutes > 0 {
                        timerManager.promptMinInterval = minutes
                    }
                }
                
                Divider()
                    .padding(.leading, 16)
                
                TimeSettingRow(
                    title: "提示最大间隔",
                    value: $promptMaxInput,
                    unit: "分钟",
                    isDisabled: timerManager.timerRunning
                ) { newValue in
                    if let minutes = Int(newValue), minutes > 0 {
                        timerManager.promptMaxInterval = minutes
                    }
                }
                
                Divider()
                    .padding(.leading, 16)
                
                TimeSettingRow(
                    title: "微休息时长",
                    value: $microBreakInput,
                    unit: "秒",
                    isDisabled: timerManager.timerRunning
                ) { newValue in
                    if let seconds = Int(newValue), seconds > 0 {
                        timerManager.microBreakSeconds = seconds
                    }
                }
            }
        }
    }
    
    // MARK: - 行为设置
    private var behaviorSettingsSection: some View {
        SettingsSection(title: "行为") {
            SettingsGroup {
                SimpleToggleRow(
                    title: "微休息黑屏",
                    isOn: $timerManager.blackoutEnabled
                )
                
                Divider()
                    .padding(.leading, 16)
                
                SimpleToggleRow(
                    title: "自动暂停视频",
                    isOn: $timerManager.muteAudioDuringBreak
                )
            }
        }
    }
    
    // MARK: - 一般设置
    private var generalSettingsSection: some View {
        SettingsSection(title: "一般") {
            SettingsGroup {
                HStack {
                    Image(systemName: "bell")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    
                    Text("通知")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Toggle("", isOn: $timerManager.microBreakNotificationEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()
                    .padding(.leading, 16)
                
                HStack {
                    Image(systemName: "speaker.wave.2")
                        .foregroundColor(.purple)
                        .frame(width: 20)
                    
                    Text("提示音效")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Toggle("", isOn: $timerManager.promptSoundEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                if timerManager.promptSoundEnabled {
                    Divider()
                        .padding(.leading, 16)
                    
                    VStack(spacing: 0) {
                        SoundPickerRow(
                            title: "开始音效",
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
                            .padding(.leading, 16)
                        
                        SoundPickerRow(
                            title: "结束音效",
                            selectedSound: timerManager.microBreakEndSoundType,
                            onSelectionChange: { soundType in
                                NotificationCenter.default.post(
                                    name: .playMicroBreakEndSound,
                                    object: soundType.rawValue
                                )
                                timerManager.microBreakEndSoundType = soundType
                            }
                        )
                    }
                }
            }
            
            if !notificationPermissionGranted {
                SettingsGroup {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("通知权限")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                            Text("需要权限来发送提醒")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("设置") {
                            openNotificationSettings()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
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

// MARK: - 设置分组组件
struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 16)
            
            content
        }
    }
}

// MARK: - 设置组容器
struct SettingsGroup<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - 时间设置行
struct TimeSettingRow: View {
    let title: String
    @Binding var value: String
    let unit: String
    let isDisabled: Bool
    let onChange: (String) -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 4) {
                TextField("", text: $value)
                    .textFieldStyle(.plain)
                    .frame(width: 40)
                    .multilineTextAlignment(.trailing)
                    .disabled(isDisabled)
                    .foregroundColor(isDisabled ? .secondary : .primary)
                    .onChange(of: value) { _, newValue in
                        let filtered = newValue.filter { "0123456789".contains($0) }
                        if filtered != newValue { 
                            value = filtered 
                        }
                        onChange(filtered)
                    }
                
                Text(unit)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - 简单开关行
struct SimpleToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.mini)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - 声音选择行
struct SoundPickerRow: View {
    let title: String
    let selectedSound: SoundType
    let onSelectionChange: (SoundType) -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            Spacer()
            
            Menu {
                ForEach(SoundType.allCases) { soundType in
                    Button(soundType.displayName) {
                        onSelectionChange(soundType)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedSound.displayName)
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .menuStyle(.borderlessButton)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    SettingsView(timerManager: TimerManager.shared)
}
