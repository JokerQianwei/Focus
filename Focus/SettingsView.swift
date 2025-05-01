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
    }

    var body: some View {
        // Apply width constraint and padding
        VStack(spacing: 20) { // Increased spacing slightly for larger fonts
            // 标题和关闭按钮 - Use ZStack for centering title
            ZStack {
                // Centered Title
                Text("设置")
                    .font(.title) // Adjusted font size
                    .fontWeight(.semibold)

                // Close button on the right
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2) // Keep button size reasonable
                            .foregroundColor(isHoveringClose ? .primary.opacity(0.8) : .secondary.opacity(0.8))
                            .scaleEffect(isHoveringClose ? 1.1 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .focusEffectDisabled()
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isHoveringClose = hovering
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 10) // Adjusted padding

            // 设置内容
            Form {
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
            .formStyle(.grouped) 
            .frame(maxWidth: .infinity) // Let Form manage its internal width
            .padding(.horizontal, 5) // Add slight horizontal padding to the Form itself
            
        }
        .padding() // Add padding to the outermost VStack
        .frame(width: 350) // Set the desired width for the entire view
    }
}

#Preview {
    SettingsView(timerManager: TimerManager.shared)
        .frame(width: 350, height: 550) // Set frame for preview canvas
}
