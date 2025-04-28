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
                    VStack(spacing: 20) {
                        // 专注时间设置
                        HStack {
                            Text("专注时间：")
                                .fontWeight(.medium)
                                .frame(width: 80, alignment: .leading)

                            Spacer()

                            TextField("", text: $workMinutesInput)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 100)
                                .multilineTextAlignment(.center)
                                .disabled(timerManager.timerRunning)
                                .onChange(of: workMinutesInput) { newValue in
                                    // 只保留数字
                                    let filtered = newValue.filter { "0123456789".contains($0) }
                                    if filtered != newValue {
                                        workMinutesInput = filtered
                                    }

                                    if let minutes = Int(filtered), minutes > 0 {
                                        timerManager.workMinutes = minutes
                                        if timerManager.isWorkMode && !timerManager.timerRunning {
                                            timerManager.minutes = minutes
                                        }
                                    }
                                }

                            Text("分钟")
                                .frame(width: 40, alignment: .leading)
                        }

                        // 随机范围设置
                        VStack(alignment: .leading, spacing: 12) {
                            Text("随机范围：")
                                .fontWeight(.medium)
                                .padding(.bottom, 5)

                            HStack {
                                Text("(a)：")
                                    .frame(width: 40, alignment: .leading)

                                Spacer()

                                TextField("", text: $promptMinInput)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 100)
                                    .multilineTextAlignment(.center)
                                    .disabled(timerManager.timerRunning)
                                    .onChange(of: promptMinInput) { newValue in
                                        // 只保留数字
                                        let filtered = newValue.filter { "0123456789".contains($0) }
                                        if filtered != newValue {
                                            promptMinInput = filtered
                                        }

                                        if let minutes = Int(filtered), minutes > 0 {
                                            timerManager.promptMinInterval = minutes
                                        }
                                    }

                                Text("分钟")
                                    .frame(width: 40, alignment: .leading)
                            }
                            .padding(.leading, 10)

                            HStack {
                                Text("(b)：")
                                    .frame(width: 40, alignment: .leading)

                                Spacer()

                                TextField("", text: $promptMaxInput)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 100)
                                    .multilineTextAlignment(.center)
                                    .disabled(timerManager.timerRunning)
                                    .onChange(of: promptMaxInput) { newValue in
                                        // 只保留数字
                                        let filtered = newValue.filter { "0123456789".contains($0) }
                                        if filtered != newValue {
                                            promptMaxInput = filtered
                                        }

                                        if let minutes = Int(filtered), minutes > 0 {
                                            timerManager.promptMaxInterval = minutes
                                        }
                                    }

                                Text("分钟")
                                    .frame(width: 40, alignment: .leading)
                            }
                            .padding(.leading, 10)
                        }

                        // 微休息时间设置
                        HStack {
                            Text("微休息时间：")
                                .fontWeight(.medium)
                                .frame(width: 90, alignment: .leading)

                            Spacer()

                            TextField("", text: $microBreakInput)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 100)
                                .multilineTextAlignment(.center)
                                .disabled(timerManager.timerRunning)
                                .onChange(of: microBreakInput) { newValue in
                                    // 只保留数字
                                    let filtered = newValue.filter { "0123456789".contains($0) }
                                    if filtered != newValue {
                                        microBreakInput = filtered
                                    }

                                    if let seconds = Int(filtered), seconds > 0 {
                                        timerManager.microBreakSeconds = seconds
                                    }
                                }

                            Text("秒")
                                .frame(width: 40, alignment: .leading)
                        }

                        // 休息时间设置
                        HStack {
                            Text("休息时间：")
                                .fontWeight(.medium)
                                .frame(width: 80, alignment: .leading)

                            Spacer()

                            TextField("", text: $breakMinutesInput)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 100)
                                .multilineTextAlignment(.center)
                                .disabled(timerManager.timerRunning)
                                .onChange(of: breakMinutesInput) { newValue in
                                    // 只保留数字
                                    let filtered = newValue.filter { "0123456789".contains($0) }
                                    if filtered != newValue {
                                        breakMinutesInput = filtered
                                    }

                                    if let minutes = Int(filtered), minutes > 0 {
                                        timerManager.breakMinutes = minutes
                                    }
                                }

                            Text("分钟")
                                .frame(width: 40, alignment: .leading)
                        }
                    }
                }

                // 提示音设置
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
