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
        // Use a consistent padding for the main VStack
        VStack(spacing: 16) { // Slightly reduced spacing
            // 标题和关闭按钮
            HStack {
                Text("设置")
                    .font(.largeTitle) // Use largeTitle for main view title
                    .fontWeight(.bold)

                Spacer()

                // Close button styling
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(isHoveringClose ? .primary.opacity(0.8) : .secondary.opacity(0.8))
                        .scaleEffect(isHoveringClose ? 1.1 : 1.0)
                }
                .buttonStyle(.plain) // Use plain button style for icon buttons
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isHoveringClose = hovering
                    }
                }
            }
            .padding(.bottom, 8) // Reduced bottom padding for title

            // 设置内容
            Form {
                // 计时选项 Section
                Section { // Use Section without explicit header text for better grouping
                    Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 10) {
                        // 专注时间
                        GridRow {
                            Text("专注时间")
                                .gridColumnAlignment(.leading)

                            HStack {
                                Spacer()
                                TextField("", text: $workMinutesInput)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 60) // Adjusted width
                                    .multilineTextAlignment(.trailing)
                                    .disabled(timerManager.timerRunning)
                                    .onChange(of: workMinutesInput) { newValue in
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
                                    .frame(width: 30, alignment: .leading) // Ensure alignment
                            }
                        }

                        // 休息时间
                        GridRow {
                            Text("休息时间")
                                .gridColumnAlignment(.leading)

                            HStack {
                                Spacer()
                                TextField("", text: $breakMinutesInput)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 60)
                                    .multilineTextAlignment(.trailing)
                                    .disabled(timerManager.timerRunning)
                                    .onChange(of: breakMinutesInput) { newValue in
                                        let filtered = newValue.filter { "0123456789".contains($0) }
                                        if filtered != newValue { breakMinutesInput = filtered }
                                        if let minutes = Int(filtered), minutes > 0 {
                                            timerManager.breakMinutes = minutes
                                        }
                                    }
                                    // Keep focus effect disabled for consistency if needed
                                    .focusEffectDisabled()

                                Text("分钟")
                                    .foregroundColor(.secondary)
                                    .frame(width: 30, alignment: .leading)
                            }
                        }
                    }
                } header: { // Add header text here for better structure
                    Text("计时")
                        .font(.headline)
                        .padding(.bottom, 4)
                }

                // 提示音间隔 Section
                Section { // Use Section without explicit header text
                    Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 10) {
                        // 最小间隔
                        GridRow {
                            Text("最小间隔")
                                .gridColumnAlignment(.leading)

                            HStack {
                                Spacer()
                                TextField("", text: $promptMinInput)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 60)
                                    .multilineTextAlignment(.trailing)
                                    .disabled(timerManager.timerRunning)
                                    .onChange(of: promptMinInput) { newValue in
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

                        // 最大间隔
                        GridRow {
                            Text("最大间隔")
                                .gridColumnAlignment(.leading)

                            HStack {
                                Spacer()
                                TextField("", text: $promptMaxInput)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 60)
                                    .multilineTextAlignment(.trailing)
                                    .disabled(timerManager.timerRunning)
                                    .onChange(of: promptMaxInput) { newValue in
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

                        // 微休息
                        GridRow {
                            Text("微休息")
                                .gridColumnAlignment(.leading)

                            HStack {
                                Spacer()
                                TextField("", text: $microBreakInput)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 60)
                                    .multilineTextAlignment(.trailing)
                                    .disabled(timerManager.timerRunning)
                                    .onChange(of: microBreakInput) { newValue in
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

                } header: { // Add header text here
                    Text("随机提示音间隔 (专注期间)")
                        .font(.headline)
                        .padding(.bottom, 4)
                }


                // 提示音开关 Section
                Section { // Use Section without explicit header text
                    Toggle(isOn: $timerManager.promptSoundEnabled) {
                        Text("专注期间提示音")
                            // Removed icon from here for cleaner toggle label
                    }
                    .toggleStyle(.switch)
                    .disabled(timerManager.timerRunning)
                    .padding(.vertical, 4) // Add padding for toggle

                    // Conditionally show description text
                    if timerManager.promptSoundEnabled {
                        Text("每隔 \(timerManager.promptMinInterval)-\(timerManager.promptMaxInterval) 分钟播放提示音，并在 \(timerManager.microBreakSeconds) 秒后再次响起。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 2) // Add small top padding
                    }
                } header: { // Add header text here
                    Text("提示音")
                        .font(.headline)
                        .padding(.bottom, 4)
                }

            }
            .formStyle(.grouped) // Keep grouped style for macOS
            .frame(maxWidth: 480) // Constrain form width slightly
            // Remove explicit frame height, let content define height
        }
        .padding() // Apply padding to the outer VStack
        // Remove frame modifier from here, apply padding instead
    }
}

#Preview {
    SettingsView(timerManager: TimerManager.shared)
        .frame(width: 500, height: 600) // Keep frame for preview
}
