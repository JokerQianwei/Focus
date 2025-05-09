//
//  SettingsView.swift
//  Focus
//
//  Created by 杨乾巍 on 2025/4/28.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    // 使用TimerManager
    @ObservedObject var timerManager: TimerManager

    // 临时存储输入值的状态
    @State private var workMinutesInput: String
    @State private var breakMinutesInput: String
    @State private var promptMinInput: String
    @State private var promptMaxInput: String
    @State private var microBreakInput: String
    @State private var isHoveringClose = false // State for close button hover

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
        VStack(spacing: 24) {
            HStack {
                Text("设置")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(isHoveringClose ? .red : .gray)
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { hovering in
                    isHoveringClose = hovering
                }
            }
            .padding(.top, 8)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 计时选项 Section
                    Section { 
                        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 15, verticalSpacing: 12) { // Increased spacing
                            // 专注时间
                            GridRow {
                                Text("专注时间")
                                    .font(.body.weight(.medium)) // Adjusted font
                                    .gridColumnAlignment(.leading)

                                HStack {
                                    Spacer()
                                    TextField("", text: $workMinutesInput)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 60) 
                                        .multilineTextAlignment(.trailing)
                                        .disabled(timerManager.timerRunning)
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
                                        .focusEffectDisabled()

                                    Text("分钟")
                                        .foregroundColor(.secondary)
                                        .frame(width: 30, alignment: .leading) 
                                }
                            }

                            Divider() // Add divider between rows

                            // 休息时间
                            GridRow {
                                Text("休息时间")
                                    .font(.body.weight(.medium)) // Adjusted font
                                    .gridColumnAlignment(.leading)

                                HStack {
                                    Spacer()
                                    TextField("", text: $breakMinutesInput)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 60)
                                        .multilineTextAlignment(.trailing)
                                        .disabled(timerManager.timerRunning)
                                        .onChange(of: breakMinutesInput) { _, newValue in
                                            let filtered = newValue.filter { "0123456789".contains($0) }
                                            if filtered != newValue { breakMinutesInput = filtered }
                                            if let minutes = Int(filtered), minutes > 0 {
                                                timerManager.breakMinutes = minutes
                                            }
                                        }
                                        .focusEffectDisabled()

                                    Text("分钟")
                                        .foregroundColor(.secondary)
                                        .frame(width: 30, alignment: .leading)
                                }
                            }

                            // Divider() // Remove divider after the last row in this section
                        }
                    } header: { 
                        Text("计时")
                            .font(.title3) // Adjusted font size
                            .fontWeight(.bold) // Make header bold
                            .padding(.bottom, 5) // Increased padding
                    }

                    // 提示音间隔 Section
                    Section { 
                        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 15, verticalSpacing: 12) { // Increased spacing
                            // 最小间隔
                            GridRow {
                                Text("最小间隔")
                                    .font(.body.weight(.medium)) // Adjusted font
                                    .gridColumnAlignment(.leading)

                                HStack {
                                    Spacer()
                                    TextField("", text: $promptMinInput)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 60)
                                        .multilineTextAlignment(.trailing)
                                        .disabled(timerManager.timerRunning)
                                        .onChange(of: promptMinInput) { _, newValue in
                                            let filtered = newValue.filter { "0123456789".contains($0) }
                                            if filtered != newValue { promptMinInput = filtered }
                                            if let minutes = Int(filtered), minutes > 0 {
                                                timerManager.promptMinInterval = minutes
                                            }
                                        }
                                        .focusEffectDisabled()

                                    Text("分钟")
                                        .foregroundColor(.secondary)
                                        .frame(width: 30, alignment: .leading)
                                }
                            }

                            Divider() // Add divider between rows

                            // 最大间隔
                            GridRow {
                                Text("最大间隔")
                                    .font(.body.weight(.medium)) // Adjusted font
                                    .gridColumnAlignment(.leading)

                                HStack {
                                    Spacer()
                                    TextField("", text: $promptMaxInput)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 60)
                                        .multilineTextAlignment(.trailing)
                                        .disabled(timerManager.timerRunning)
                                        .onChange(of: promptMaxInput) { _, newValue in
                                            let filtered = newValue.filter { "0123456789".contains($0) }
                                            if filtered != newValue { promptMaxInput = filtered }
                                            if let minutes = Int(filtered), minutes > 0 {
                                                timerManager.promptMaxInterval = minutes
                                            }
                                        }
                                        .focusEffectDisabled()

                                    Text("分钟")
                                        .foregroundColor(.secondary)
                                        .frame(width: 30, alignment: .leading)
                                }
                            }

                            Divider() // Add divider between rows

                            // 微休息
                            GridRow {
                                Text("微休息")
                                    .font(.body.weight(.medium)) // Adjusted font
                                    .gridColumnAlignment(.leading)

                                HStack {
                                    Spacer()
                                    TextField("", text: $microBreakInput)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 60)
                                        .multilineTextAlignment(.trailing)
                                        .disabled(timerManager.timerRunning)
                                        .onChange(of: microBreakInput) { _, newValue in
                                            let filtered = newValue.filter { "0123456789".contains($0) }
                                            if filtered != newValue { microBreakInput = filtered }
                                            if let seconds = Int(filtered), seconds > 0 {
                                                timerManager.microBreakSeconds = seconds
                                            }
                                        }
                                        .focusEffectDisabled()

                                    Text("秒")
                                        .foregroundColor(.secondary)
                                        .frame(width: 30, alignment: .leading)
                                }
                            }
                        }

                    } header: { 
                        Text("随机提示音间隔")
                            .font(.title3) // Adjusted font size
                            .fontWeight(.bold) // Make header bold
                            .padding(.bottom, 5) // Increased padding
                    }

                    // 提示音开关 Section
                    Section { 
                        Toggle(isOn: $timerManager.promptSoundEnabled) {
                            Text("专注期间提示音")
                                .font(.body.weight(.medium)) // Adjusted font
                        }
                        .toggleStyle(.switch)
                        .disabled(timerManager.timerRunning)
                        .padding(.vertical, 6) // Increased padding

                        // Conditionally show description text
                        if timerManager.promptSoundEnabled {
                            Text("每隔 \(timerManager.promptMinInterval)-\(timerManager.promptMaxInterval) 分钟播放提示音，并在 \(timerManager.microBreakSeconds) 秒后再次响起。")
                                .font(.callout) // Adjusted font size
                                .foregroundColor(.secondary)
                                .padding(.top, 4) // Increased padding
                        }
                    } header: { 
                        Text("提示音")
                            .font(.title3) // Adjusted font size
                            .fontWeight(.bold) // Make header bold
                            .padding(.bottom, 5) // Increased padding
                    }
                    
                    // 黑屏设置 Section
                    Section {
                        Toggle(isOn: $timerManager.blackoutEnabled) {
                            Text("微休息黑屏")
                                .font(.body.weight(.medium))
                        }
                        .toggleStyle(.switch)
                        .disabled(timerManager.timerRunning)
                        .padding(.vertical, 6)
                        
                        if timerManager.blackoutEnabled {
                            Text("提示音响起时，将显示全屏黑色窗口，并在休息结束后自动关闭。")
                                .font(.callout)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    } header: {
                        Text("黑屏功能")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.bottom, 5)
                    }

                    // 视频暂停功能 Section
                    Section {
                        Toggle(isOn: $timerManager.muteAudioDuringBreak) {
                            Text("微休息时暂停视频")
                                .font(.body.weight(.medium))
                        }
                        .toggleStyle(.switch)
                        .disabled(timerManager.timerRunning)
                        .padding(.vertical, 6)
                        
                        if timerManager.muteAudioDuringBreak {
                            Text("提示音响起时，将暂停正在播放的视频及音乐，微休息结束后恢复播放。")
                                .font(.callout)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    } header: {
                        Text("视频控制")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.bottom, 5)
                    }

                    // 其它设置 Section
                    Section { 
                        Toggle(isOn: $timerManager.showStatusBarIcon) {
                            Text("显示菜单栏图标")
                                .font(.body.weight(.medium))
                        }
                        .toggleStyle(.switch)
                        .padding(.vertical, 6)
                    } header: { 
                        Text("其他设置")
                            .font(.title3) // Adjusted font size
                            .fontWeight(.bold) // Make header bold
                            .padding(.bottom, 5) // Increased padding
                    }

                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .frame(width: 300, height: 480)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

#Preview {
    SettingsView(timerManager: TimerManager.shared)
        .frame(width: 350, height: 550) // Set frame for preview canvas
}
