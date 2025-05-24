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
    @State private var isHoveringClose = false // State for close button hover
    
    // 动画状态
    @State private var activeSection: String? = nil
    @Namespace private var animation
    
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
        // 黑屏功能在 TimerManager 中初始化，不需要在这里初始化
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题栏
            HStack {
                Text("设置")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(isHoveringClose ? .red : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .focusable(false)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHoveringClose = hovering
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Divider()
                .padding(.horizontal)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // 计时选项 Section
                    settingsSection(title: "计时", systemImage: "timer") {
                        VStack(spacing: 16) {
                            // 专注时间
                            HStack(alignment: .center) {
                                Text("专注时间")
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    TextField("", text: $workMinutesInput)
                                        .textFieldStyle(RoundedInputStyle())
                                        .frame(width: 70)
                                        .multilineTextAlignment(.trailing)
                                        .disabled(timerManager.timerRunning)
                                        .focusEffectDisabled()
                                        .onChange(of: workMinutesInput) { _, newValue in
                                            let filtered = newValue.filter { "0123456789".contains($0) }
                                            if filtered != newValue { workMinutesInput = filtered }
                                            if let minutes = Int(filtered), minutes > 0 {
                                                timerManager.workMinutes = minutes
                                                if timerManager.isWorkMode && !timerManager.timerRunning {
                                                    timerManager.minutes = minutes
                                                }
                                            }
                                        }

                                    Text("分钟")
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Divider()
                            
                            // 休息时间
                            HStack(alignment: .center) {
                                Text("休息时间")
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    TextField("", text: $breakMinutesInput)
                                        .textFieldStyle(RoundedInputStyle())
                                        .frame(width: 70)
                                        .multilineTextAlignment(.trailing)
                                        .disabled(timerManager.timerRunning)
                                        .focusEffectDisabled()
                                        .onChange(of: breakMinutesInput) { _, newValue in
                                            let filtered = newValue.filter { "0123456789".contains($0) }
                                            if filtered != newValue { breakMinutesInput = filtered }
                                            if let minutes = Int(filtered), minutes > 0 {
                                                timerManager.breakMinutes = minutes
                                            }
                                        }

                                    Text("分钟")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // 提示音间隔 Section
                    settingsSection(title: "随机提示音", systemImage: "bell.badge") {
                        VStack(spacing: 16) {
                            // 最小间隔
                            HStack(alignment: .center) {
                                Text("最小间隔")
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    TextField("", text: $promptMinInput)
                                        .textFieldStyle(RoundedInputStyle())
                                        .frame(width: 70)
                                        .multilineTextAlignment(.trailing)
                                        .disabled(timerManager.timerRunning)
                                        .focusEffectDisabled()
                                        .onChange(of: promptMinInput) { _, newValue in
                                            let filtered = newValue.filter { "0123456789".contains($0) }
                                            if filtered != newValue { promptMinInput = filtered }
                                            if let minutes = Int(filtered), minutes > 0 {
                                                timerManager.promptMinInterval = minutes
                                            }
                                        }

                                    Text("分钟")
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Divider()
                            
                            // 最大间隔
                            HStack(alignment: .center) {
                                Text("最大间隔")
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    TextField("", text: $promptMaxInput)
                                        .textFieldStyle(RoundedInputStyle())
                                        .frame(width: 70)
                                        .multilineTextAlignment(.trailing)
                                        .disabled(timerManager.timerRunning)
                                        .focusEffectDisabled()
                                        .onChange(of: promptMaxInput) { _, newValue in
                                            let filtered = newValue.filter { "0123456789".contains($0) }
                                            if filtered != newValue { promptMaxInput = filtered }
                                            if let minutes = Int(filtered), minutes > 0 {
                                                timerManager.promptMaxInterval = minutes
                                            }
                                        }

                                    Text("分钟")
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Divider()
                            
                            // 微休息
                            HStack(alignment: .center) {
                                Text("微休息")
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    TextField("", text: $microBreakInput)
                                        .textFieldStyle(RoundedInputStyle())
                                        .frame(width: 70)
                                        .multilineTextAlignment(.trailing)
                                        .disabled(timerManager.timerRunning)
                                        .focusEffectDisabled()
                                        .onChange(of: microBreakInput) { _, newValue in
                                            let filtered = newValue.filter { "0123456789".contains($0) }
                                            if filtered != newValue { microBreakInput = filtered }
                                            if let seconds = Int(filtered), seconds > 0 {
                                                timerManager.microBreakSeconds = seconds
                                            }
                                        }

                                    Text("秒")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // 提示音开关 Section
                    settingsSection(title: "提示音", systemImage: "speaker.wave.2") {
                        VStack(spacing: 12) {
                            Toggle(isOn: $timerManager.promptSoundEnabled) {
                                Text("专注期间提示音")
                                    .foregroundColor(.primary)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                            
                            if timerManager.promptSoundEnabled {
                                Text("每隔 \(timerManager.promptMinInterval)-\(timerManager.promptMaxInterval) 分钟播放提示音，并在 \(timerManager.microBreakSeconds) 秒后再次响起。")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 2)
                                    .padding(.leading, 4)
                                    .animation(.easeInOut, value: timerManager.promptSoundEnabled)
                                    
                                Divider()
                                
                                // 微休息开始声音选择
                                HStack {
                                    Text("微休息开始音效")
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Menu {
                                        ForEach(SoundType.allCases) { soundType in
                                            Button(action: {
                                                // 无论是否变化，都播放所选音效
                                                if timerManager.promptSoundEnabled {
                                                    NotificationCenter.default.post(
                                                        name: .playMicroBreakStartSound,
                                                        object: soundType.rawValue
                                                    )
                                                }
                                                // 更新选择
                                                timerManager.microBreakStartSoundType = soundType
                                            }) {
                                                HStack {
                                                    Text(soundType.displayName)
                                                    if timerManager.microBreakStartSoundType == soundType {
                                                        Spacer()
                                                        Image(systemName: "checkmark")
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(timerManager.microBreakStartSoundType.displayName)
                                                .foregroundColor(.primary)
                                            Image(systemName: "chevron.down")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color(.controlBackgroundColor))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                        )
                                    }
                                    .disabled(!timerManager.promptSoundEnabled)
                                }
                                
                                Divider()
                                
                                // 微休息结束声音选择
                                HStack {
                                    Text("微休息结束音效")
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Menu {
                                        ForEach(SoundType.allCases) { soundType in
                                            Button(action: {
                                                // 无论是否变化，都播放所选音效
                                                if timerManager.promptSoundEnabled {
                                                    NotificationCenter.default.post(
                                                        name: .playMicroBreakEndSound,
                                                        object: soundType.rawValue
                                                    )
                                                }
                                                // 更新选择
                                                timerManager.microBreakEndSoundType = soundType
                                            }) {
                                                HStack {
                                                    Text(soundType.displayName)
                                                    if timerManager.microBreakEndSoundType == soundType {
                                                        Spacer()
                                                        Image(systemName: "checkmark")
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(timerManager.microBreakEndSoundType.displayName)
                                                .foregroundColor(.primary)
                                            Image(systemName: "chevron.down")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color(.controlBackgroundColor))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                        )
                                    }
                                    .disabled(!timerManager.promptSoundEnabled)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // 黑屏设置 Section
                    settingsSection(title: "黑屏功能", systemImage: "display") {
                        VStack(spacing: 12) {
                            Toggle(isOn: $timerManager.blackoutEnabled) {
                                Text("微休息黑屏")
                                    .foregroundColor(.primary)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                            
                            if timerManager.blackoutEnabled {
                                Text("提示音响起时，将显示全屏黑色窗口，并在休息结束后自动关闭。")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 2)
                                    .padding(.leading, 4)
                                    .animation(.easeInOut, value: timerManager.blackoutEnabled)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // 视频暂停功能 Section
                    settingsSection(title: "视频控制", systemImage: "play.slash") {
                        VStack(spacing: 12) {
                            Toggle(isOn: $timerManager.muteAudioDuringBreak) {
                                Text("微休息时暂停/播放视频")
                                    .foregroundColor(.primary)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                            
                            if timerManager.muteAudioDuringBreak {
                                Text("微休息期间自动切换播放/暂停状态，观看视频/网课时建议开启，其他场景可关闭。（首次使用需授予辅助功能权限）")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 2)
                                    .padding(.leading, 4)
                                    .animation(.easeInOut, value: timerManager.muteAudioDuringBreak)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // 其它设置 Section
                    settingsSection(title: "其他设置", systemImage: "gearshape") {
                        VStack(spacing: 12) {
                            // 菜单栏应用说明（不可修改）
                            HStack {
                                Text("菜单栏应用")
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    
                                    Text("始终显示")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                            }
                            
                            Text("作为纯菜单栏应用运行，不会在Dock中显示图标")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .padding(.top, -4)
                                .padding(.leading, 4)
                            
                            Divider()
                            
                            Toggle(isOn: $timerManager.microBreakNotificationEnabled) {
                                Text("微休息通知")
                                    .foregroundColor(.primary)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                            
                            if timerManager.microBreakNotificationEnabled {
                                Text("在微休息开始和结束时发送系统通知")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 2)
                                    .padding(.leading, 4)
                                    .animation(.easeInOut, value: timerManager.microBreakNotificationEnabled)
                            }
                            
                            Divider()
                            
                            // 通知权限状态
                            HStack {
                                Text("通知权限")
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                HStack(spacing: 8) {
                                    Image(systemName: notificationPermissionGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                        .foregroundColor(notificationPermissionGranted ? .green : .orange)
                                    
                                    Text(notificationPermissionGranted ? "已授权" : "未授权")
                                        .foregroundColor(notificationPermissionGranted ? .green : .orange)
                                        .font(.caption)
                                    
                                    if !notificationPermissionGranted {
                                        Button("设置") {
                                            openNotificationSettings()
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                    }
                                }
                            }
                            
                            if !notificationPermissionGranted {
                                Text("需要通知权限来提醒工作和休息时间的结束以及微休息通知")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 2)
                                    .padding(.leading, 4)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
            }
        }
        .frame(width: 340, height: 520)
        .background(Color(NSColor.windowBackgroundColor))
        .fixedSize(horizontal: true, vertical: true)
        .onAppear {
            checkNotificationPermission()
        }
    }
    
    // 检查通知权限状态
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // 打开系统通知设置
    private func openNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }
    
    // 通用的设置区块
    @ViewBuilder
    private func settingsSection<Content: View>(title: String, systemImage: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundColor(.accentColor)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            VStack {
                content()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.windowBackgroundColor).opacity(0.3) : Color(.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// 自定义圆角输入框样式
struct RoundedInputStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.textBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 1)
            .focusEffectDisabled()
            .focusable(false)
    }
}

#Preview {
    SettingsView(timerManager: TimerManager.shared)
        .frame(width: 340, height: 520) // Set frame for preview canvas
}
