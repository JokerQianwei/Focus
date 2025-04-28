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

    var body: some View {
        VStack(spacing: 20) {
            // 标题
            HStack {
                Text("设置")
                    .font(.title)
                    .fontWeight(.bold)

                Spacer()

                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 10)

            // 设置内容
            Form {
                // 时间设置
                Section(header: Text("时间设置").font(.headline)) {
                    VStack(spacing: 16) {
                        // 专注时间设置
                        VStack(alignment: .leading, spacing: 8) {
                            Text("专注时间")
                                .fontWeight(.medium)

                            HStack(spacing: 8) {
                                ForEach([25, 45, 60, 90, 120], id: \.self) { minute in
                                    Button(action: {
                                        timerManager.workMinutes = minute
                                        if timerManager.isWorkMode && !timerManager.timerRunning {
                                            timerManager.minutes = minute
                                        }
                                    }) {
                                        Text("\(minute) 分钟")
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(timerManager.workMinutes == minute ? .blue : .secondary)
                                    .disabled(timerManager.timerRunning)
                                }
                            }
                        }

                        // 休息时间设置
                        VStack(alignment: .leading, spacing: 8) {
                            Text("休息时间")
                                .fontWeight(.medium)

                            HStack(spacing: 8) {
                                ForEach([5, 10, 15, 20, 30], id: \.self) { minute in
                                    Button(action: {
                                        timerManager.breakMinutes = minute
                                    }) {
                                        Text("\(minute) 分钟")
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(timerManager.breakMinutes == minute ? .green : .secondary)
                                    .disabled(timerManager.timerRunning)
                                }
                            }
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
                            Text("在专注期间，每隔3-5分钟播放提示音，10秒后再次响起")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 24)
                        }
                    }
                }

                // 关于
                Section(header: Text("关于").font(.headline)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("专注时钟")
                            .font(.headline)

                        Text("版本 1.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("一个简单的专注时钟应用，帮助您提高工作效率。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
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
