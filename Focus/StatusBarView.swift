//
//  StatusBarView.swift
//  Focus
//
//  Created by 杨乾巍 on 2025/4/28.
//

import AppKit

class StatusBarView: NSView {
    private let textField = NSTextField()
    private var text: String = ""
    private var textColor: NSColor = .white

    init(frame: NSRect, text: String, textColor: NSColor) {
        self.text = text
        self.textColor = textColor
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        // 设置视图的背景为透明
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        // 配置文本字段
        textField.isEditable = false
        textField.isBordered = false
        textField.backgroundColor = NSColor.clear
        textField.textColor = NSColor.black // 使用黑色文本，不受模式影响
        textField.alignment = .center
        textField.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        textField.stringValue = text

        // 使文本字段的背景透明
        textField.drawsBackground = false

        // 设置文本字段的大小，使其填满整个视图
        textField.frame = bounds

        // 添加文本字段到视图
        addSubview(textField)

        // 设置文本字段的约束，使其完全居中，减小左右间距
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.centerXAnchor.constraint(equalTo: centerXAnchor),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor),
            textField.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.95), // 增加宽度比例，减小左右间距
            textField.heightAnchor.constraint(equalTo: heightAnchor)
        ])

        // 调整文本字段的行为
        if let cell = textField.cell as? NSTextFieldCell {
            cell.usesSingleLineMode = true
            cell.lineBreakMode = .byClipping
            cell.isScrollable = false // 防止文本滚动
        }
    }

    // 更新文本和颜色
    func update(text: String, textColor: NSColor) {
        self.text = text
        self.textColor = textColor
        textField.stringValue = text
        textField.textColor = NSColor.black // 保持黑色文本，不受模式影响
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // 绘制圆角矩形边框
        let borderPath = NSBezierPath(roundedRect: bounds.insetBy(dx: 2, dy: 2), xRadius: 6, yRadius: 6)

        // 使用黑色边框
        NSColor.black.withAlphaComponent(0.6).setStroke() // 使用半透明黑色，看起来更柔和
        borderPath.lineWidth = 1.0
        borderPath.stroke()
    }
}
