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
        verticallyAlignedCell.textColor = NSColor.controlTextColor
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
        textField.cell = verticallyAlignedCell
        textField.drawsBackground = false
        textField.frame = NSRect(x: 0, y: 0, width: bounds.width, height: bounds.height)

        // 添加文本字段到视图
        addSubview(textField)

        // 设置文本字段的约束
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.deactivate(textField.constraints)
        NSLayoutConstraint.activate([
            textField.centerXAnchor.constraint(equalTo: centerXAnchor),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor),
            textField.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.98),
            textField.heightAnchor.constraint(equalTo: heightAnchor)
        ])
    }

    // 更新文本和颜色
    func update(text: String, textColor: NSColor) {
        self.text = text
        self.textColor = textColor

        // 更新Cell的文本
        if let cell = textField.cell as? VerticallyAlignedTextFieldCell {
            cell.stringValue = text
            cell.textColor = textColor
        }

        // 确保视图刷新
        needsDisplay = true
        if let superview = self.superview {
            superview.needsDisplay = true
        }
    }
}
