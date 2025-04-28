//
//  VerticallyAlignedTextFieldCell.swift
//  Focus
//
//  Created by 杨乾巍 on 2025/4/28.
//

import AppKit

class VerticallyAlignedTextFieldCell: NSTextFieldCell {
    
    // 重写绘制方法，实现垂直居中
    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        let newRect = super.drawingRect(forBounds: rect)
        
        // 计算文本的高度
        let textSize = self.cellSize(forBounds: rect)
        
        // 计算垂直居中的Y坐标
        let heightDelta = rect.size.height - textSize.height
        if heightDelta > 0 {
            let yOffset = heightDelta / 2
            return NSRect(x: newRect.origin.x, y: newRect.origin.y + yOffset, width: newRect.width, height: newRect.height - heightDelta)
        }
        
        return newRect
    }
    
    // 重写titleRect方法，确保标题区域也是垂直居中的
    override func titleRect(forBounds rect: NSRect) -> NSRect {
        var titleRect = super.titleRect(forBounds: rect)
        let textSize = self.cellSize(forBounds: rect)
        
        let heightDelta = rect.size.height - textSize.height
        if heightDelta > 0 {
            let yOffset = heightDelta / 2
            titleRect.origin.y += yOffset
        }
        
        return titleRect
    }
    
    // 重写selectWithFrame方法，确保选择区域也是垂直居中的
    override func select(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, start selStart: Int, length selLength: Int) {
        let adjustedRect = self.drawingRect(forBounds: rect)
        super.select(withFrame: adjustedRect, in: controlView, editor: textObj, delegate: delegate, start: selStart, length: selLength)
    }
    
    // 重写edit方法，确保编辑区域也是垂直居中的
    override func edit(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, event: NSEvent?) {
        let adjustedRect = self.drawingRect(forBounds: rect)
        super.edit(withFrame: adjustedRect, in: controlView, editor: textObj, delegate: delegate, event: event)
    }
}
