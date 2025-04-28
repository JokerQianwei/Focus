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
        VStack(spacing: 20) {
            // 标题
            HStack {
                Text("设置")
                    .font(.title)
                    .fontWeight(.bold)

                Spacer()

                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .onTapGesture {
                        dismiss()
                    }
            }
            .padding(.bottom, 10)

            // 设置内容
            Form {
                // 计时选项
                Section(header: Text("计时选项").font(.headline)) {
                    // 使用 Grid 布局替代 VStack 和 HStack+Spacer
                    Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 12) {
                        // 专注时间设置
                        GridRow {
                            Text("专注时间：")
                                .fontWeight(.medium)
                                .gridColumnAlignment(.trailing) // 标签右对齐

                            TextField("", text: $workMinutesInput)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(maxWidth: 80) // 限制输入框最大宽度
                                .multilineTextAlignment(.center)
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
                        }

                        // 休息时间设置 (调整顺序，放在专注时间下面)
                        GridRow {
                            Text("休息时间：")
                                .fontWeight(.medium)
                                .gridColumnAlignment(.trailing)

                            TextField("", text: $breakMinutesInput)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(maxWidth: 80)
                                .multilineTextAlignment(.center)
                                .disabled(timerManager.timerRunning)
                                .onChange(of: breakMinutesInput) { newValue in
                                    let filtered = newValue.filter { "0123456789".contains($0) }
                                    if filtered != newValue { breakMinutesInput = filtered }
                                    if let minutes = Int(filtered), minutes > 0 {
                                        timerManager.breakMinutes = minutes
                                    }
                                }

                            Text("分钟")
                        }

                        // 提示音设置 (放在一起)
                        Divider() // 添加分隔线

                        GridRow {
                            // 使用 VStack 容纳多个控件，并跨越后面两列
                            VStack(alignment: .leading, spacing: 8) {
                                Text("随机提示音间隔：")
                                    .fontWeight(.medium)
                                Text("(专注期间触发)")
                                     .font(.caption)
                                     .foregroundColor(.secondary)
                            }
                            .gridCellColumns(3) // 让这个 VStack 占据 GridRow 的所有列
                        }

                        // 最小间隔
                        GridRow(alignment: .firstTextBaseline) {
                            Text("最小：")
                                .fontWeight(.medium)
                                .gridColumnAlignment(.trailing)
                                .padding(.leading, 20) // 增加缩进

                            TextField("", text: $promptMinInput)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(maxWidth: 80)
                                .multilineTextAlignment(.center)
                                .disabled(timerManager.timerRunning)
                                .onChange(of: promptMinInput) { newValue in
                                    let filtered = newValue.filter { "0123456789".contains($0) }
                                    if filtered != newValue { promptMinInput = filtered }
                                    if let minutes = Int(filtered), minutes > 0 {
                                        timerManager.promptMinInterval = minutes
                                    }
                                }

                            Text("分钟")
                        }

                        // 最大间隔
                        GridRow(alignment: .firstTextBaseline) {
                            Text("最大：")
                                .fontWeight(.medium)
                                .gridColumnAlignment(.trailing)
                                .padding(.leading, 20) // 增加缩进

                            TextField("", text: $promptMaxInput)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(maxWidth: 80)
                                .multilineTextAlignment(.center)
                                .disabled(timerManager.timerRunning)
                                .onChange(of: promptMaxInput) { newValue in
                                    let filtered = newValue.filter { "0123456789".contains($0) }
                                    if filtered != newValue { promptMaxInput = filtered }
                                    if let minutes = Int(filtered), minutes > 0 {
                                        timerManager.promptMaxInterval = minutes
                                    }
                                }

                            Text("分钟")
                        }

                        // 微休息时间设置
                        GridRow(alignment: .firstTextBaseline) {
                             Text("微休息：")
                                 .fontWeight(.medium)
                                 .gridColumnAlignment(.trailing)
                                 .padding(.leading, 20) // 增加缩进

                            TextField("", text: $microBreakInput)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(maxWidth: 80)
                                .multilineTextAlignment(.center)
                                .disabled(timerManager.timerRunning)
                                .onChange(of: microBreakInput) { newValue in
                                    let filtered = newValue.filter { "0123456789".contains($0) }
                                    if filtered != newValue { microBreakInput = filtered }
                                    if let seconds = Int(filtered), seconds > 0 {
                                        timerManager.microBreakSeconds = seconds
                                    }
                                }
                            Text("秒")
                        }
                    }
                }

                // 提示音开关设置 (保持不变)
                Section(header: Text("提示音设置").font(.headline)) {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $timerManager.promptSoundEnabled) {
                            HStack {
                                Image(systemName: "speaker.wave.2")
                                    .foregroundColor(.blue)
                                Text("专注期间提示音")
                                    .fontWeight(.medium)
                            }
                        }
                        .toggleStyle(.switch)
                        .disabled(timerManager.timerRunning)

                        if timerManager.promptSoundEnabled {
                            Text("在专注期间，每隔\(timerManager.promptMinInterval)-\(timerManager.promptMaxInterval)分钟播放提示音，\(timerManager.microBreakSeconds)秒后再次响起")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 24)
                        }
                    }
                }
            }
            .formStyle(.grouped)
        }
        .padding()
        .frame(width: 500, height: 600)
    }
}

#Preview {
    SettingsView(timerManager: TimerManager.shared)
}
