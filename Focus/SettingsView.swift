//
//  SettingsView.swift
//  Focus
//
//  Created by 杨乾巍 on 2025/4/28.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    // 绑定到ContentView的状态变量
    @Binding var workMinutes: Int
    @Binding var breakMinutes: Int
    @Binding var promptSoundEnabled: Bool
    @Binding var isWorkMode: Bool
    @Binding var minutes: Int
    let timerRunning: Bool
    
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
                                        workMinutes = minute
                                        if isWorkMode && !timerRunning {
                                            minutes = minute
                                        }
                                    }) {
                                        Text("\(minute) 分钟")
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(workMinutes == minute ? .blue : .secondary)
                                    .disabled(timerRunning)
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
                                        breakMinutes = minute
                                    }) {
                                        Text("\(minute) 分钟")
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(breakMinutes == minute ? .green : .secondary)
                                    .disabled(timerRunning)
                                }
                            }
                        }
                    }
                }
                
                // 提示音设置
                Section(header: Text("提示音设置").font(.headline)) {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $promptSoundEnabled) {
                            HStack {
                                Image(systemName: "speaker.wave.2")
                                    .foregroundColor(.blue)
                                Text("专注期间提示音")
                                    .fontWeight(.medium)
                            }
                        }
                        .toggleStyle(.switch)
                        .disabled(timerRunning)
                        
                        if promptSoundEnabled {
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
    SettingsView(
        workMinutes: .constant(90),
        breakMinutes: .constant(20),
        promptSoundEnabled: .constant(true),
        isWorkMode: .constant(true),
        minutes: .constant(90),
        timerRunning: false
    )
}
