//
//  StatusBarController.swift
//  Focus
//
//  Created by 杨乾巍 on 2025/4/28.
//

import AppKit
import SwiftUI
import Combine

class StatusBarController {
    private var statusBar: NSStatusBar
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var timerManager: TimerManager
    private var cancellables = Set<AnyCancellable>()
    private var statusBarView: StatusBarView?

    init() {
        statusBar = NSStatusBar.system
        statusItem = statusBar.statusItem(withLength: 55) // 进一步减小宽度，使方框更紧凑

        // 创建一个弹出窗口，用于显示应用程序的主界面
        popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 500)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView())

        // 获取TimerManager实例
        timerManager = TimerManager.shared

        // 创建并设置自定义视图
        if let button = statusItem.button {
            let frame = NSRect(x: 0, y: 0, width: 55, height: button.frame.height)
            statusBarView = StatusBarView(
                frame: frame,
                text: timerManager.timeString,
                textColor: NSColor.black // 使用黑色文本，不受模式影响
            )
            button.subviews.forEach { $0.removeFromSuperview() }
            button.addSubview(statusBarView!)
        }

        // 设置菜单栏项的初始文本
        updateStatusBarText()

        // 设置菜单栏项的点击事件
        if let button = statusItem.button {
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        // 订阅TimerManager的通知
        NotificationCenter.default.publisher(for: .timerUpdated)
            .sink { [weak self] _ in
                self?.updateStatusBarText()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .timerStateChanged)
            .sink { [weak self] _ in
                self?.updateStatusBarText()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .timerModeChanged)
            .sink { [weak self] _ in
                self?.updateStatusBarText()
            }
            .store(in: &cancellables)
    }

    // 更新菜单栏项的文本
    private func updateStatusBarText() {
        let text = timerManager.statusBarText
        let textColor = NSColor.black // 使用黑色文本，不受模式影响

        // 在主线程上更新UI
        DispatchQueue.main.async { [weak self] in
            // 更新自定义视图
            self?.statusBarView?.update(text: text, textColor: textColor)

            // 确保视图重绘
            self?.statusBarView?.needsDisplay = true
        }
    }

    // 切换弹出窗口的显示状态
    @objc private func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }

    // 显示弹出窗口
    private func showPopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }

    // 关闭弹出窗口
    private func closePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
    }
}
