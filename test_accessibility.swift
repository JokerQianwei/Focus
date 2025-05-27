#!/usr/bin/env swift

import Cocoa
import ApplicationServices

print("🔍 辅助功能权限检测测试")
print("=" * 40)

// 基础检测
let isGrantedBasic = AXIsProcessTrusted()
print("基础检测 (AXIsProcessTrusted): \(isGrantedBasic ? "✅ 已授权" : "❌ 未授权")")

// 带选项的检测
let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
let isGrantedWithOptions = AXIsProcessTrustedWithOptions(options as CFDictionary)
print("选项检测 (AXIsProcessTrustedWithOptions): \(isGrantedWithOptions ? "✅ 已授权" : "❌ 未授权")")

// 最终结果
let finalResult = isGrantedBasic || isGrantedWithOptions
print("最终结果: \(finalResult ? "✅ 已授权" : "❌ 未授权")")

print("=" * 40)
print("测试完成") 