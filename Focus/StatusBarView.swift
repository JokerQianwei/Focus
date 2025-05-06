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
    private var verticallyAlignedCell = VerticallyAlignedTextFieldCell()

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

        // 配置自定义Cell
        verticallyAlignedCell.isEditable = false
        verticallyAlignedCell.isBordered = false
        verticallyAlignedCell.backgroundColor = NSColor.clear
        verticallyAlignedCell.textColor = NSColor.white // 使用白色文本，确保在深色模式下可见
        verticallyAlignedCell.alignment = .center
        verticallyAlignedCell.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        verticallyAlignedCell.stringValue = text
        verticallyAlignedCell.usesSingleLineMode = true
        verticallyAlignedCell.lineBreakMode = .byClipping
        verticallyAlignedCell.isScrollable = false
        verticallyAlignedCell.wraps = false
        verticallyAlignedCell.truncatesLastVisibleLine = true

        // 配置文本字段
        textField.isEditable = false
        textField.isBordered = false
        textField.backgroundColor = NSColor.clear
        textField.cell = verticallyAlignedCell // 使用自定义的垂直居中Cell

        // 使文本字段的背景透明
        textField.drawsBackground = false

        // 设置文本字段的大小，使其填满整个视图
        textField.frame = NSRect(x: 0, y: 0, width: bounds.width, height: bounds.height)

        // 添加文本字段到视图
        addSubview(textField)

        // 设置文本字段的约束，使其完全居中，减小左右间距
        textField.translatesAutoresizingMaskIntoConstraints = false

        // 移除所有现有约束
        NSLayoutConstraint.deactivate(textField.constraints)

        // 添加新约束，确保文本字段完全居中
        NSLayoutConstraint.activate([
            // 水平居中
            textField.centerXAnchor.constraint(equalTo: centerXAnchor),
            // 垂直居中
            textField.centerYAnchor.constraint(equalTo: centerYAnchor),
            // 设置宽度为视图宽度的98%，进一步减小左右间距
            textField.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.98),
            // 设置高度等于视图高度
            textField.heightAnchor.constraint(equalTo: heightAnchor)
        ])

        // 这段代码已经在上面设置过，这里删除重复的部分
    }

    // 更新文本和颜色
    func update(text: String, textColor: NSColor) {
        self.text = text
        self.textColor = textColor

        // 更新Cell的文本
        if let cell = textField.cell as? VerticallyAlignedTextFieldCell {
            cell.stringValue = text
            cell.textColor = NSColor.white // 保持白色文本，确保在深色模式下可见
        }

        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // 绘制圆角矩形边框
        let borderPath = NSBezierPath(roundedRect: bounds.insetBy(dx: 2, dy: 2), xRadius: 6, yRadius: 6)

        // 使用白色边框
        NSColor.white.withAlphaComponent(0.6).setStroke() // 使用半透明白色，看起来更柔和
        borderPath.lineWidth = 1.0
        borderPath.stroke()
    }
}
