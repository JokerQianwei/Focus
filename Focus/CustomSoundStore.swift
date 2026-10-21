//
//  CustomSoundStore.swift
//  Focus
//
//  用户自选提示音的持久化。
//  App 开启了沙盒，用户通过 NSOpenPanel 选中的文件在下次启动时默认不可访问，
//  因此这里用「安全作用域书签」保存授权，在播放时解析书签并开启安全作用域访问。
//

import Foundation

enum CustomSoundStore {

    // MARK: - UserDefaults Keys

    private static func bookmarkKey(for type: SoundType) -> String {
        return "customSoundBookmark.\(type.rawValue)"
    }

    private static func fileNameKey(for type: SoundType) -> String {
        return "customSoundFileName.\(type.rawValue)"
    }

    // MARK: - 查询

    static func hasBookmark(for type: SoundType) -> Bool {
        return UserDefaults.standard.data(forKey: bookmarkKey(for: type)) != nil
    }

    static func fileName(for type: SoundType) -> String? {
        return UserDefaults.standard.string(forKey: fileNameKey(for: type))
    }

    // MARK: - 保存 / 清除

    /// 记录用于界面显示的文件名
    static func setFileName(_ name: String, for type: SoundType) {
        UserDefaults.standard.set(name, forKey: fileNameKey(for: type))
    }

    /// 生成并保存安全作用域书签（调用方需保证此刻对该文件有访问权限）
    static func saveBookmark(url: URL, for type: SoundType) throws {
        let bookmark = try url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        UserDefaults.standard.set(bookmark, forKey: bookmarkKey(for: type))
    }

    /// 只清除书签，保留文件名（容器副本仍可播放）
    static func clearBookmark(for type: SoundType) {
        UserDefaults.standard.removeObject(forKey: bookmarkKey(for: type))
    }

    /// 清除某类音效的自定义记录（书签 + 文件名）
    static func clear(for type: SoundType) {
        UserDefaults.standard.removeObject(forKey: bookmarkKey(for: type))
        UserDefaults.standard.removeObject(forKey: fileNameKey(for: type))
    }

    // MARK: - 解析

    /// 已开启安全作用域访问的 URL 包装，release() 必须与 resolve() 成对调用
    struct ScopedURL {
        let url: URL
        let didStartAccessing: Bool

        /// 播放结束/切换音效时释放安全作用域
        func release() {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
    }

    /// 解析书签并开启安全作用域访问。
    /// 书签损坏或文件已被移动/删除时，自动清除该书签并返回 nil，由调用方回退到系统音效。
    static func resolve(for type: SoundType) -> ScopedURL? {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey(for: type)) else {
            return nil
        }

        var isStale = false
        let url: URL
        do {
            url = try URL(
                resolvingBookmarkData: data,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
        } catch {
            print("自定义音效书签解析失败(\(type.rawValue)): \(error.localizedDescription)，已回退系统音效")
            clearBookmark(for: type)
            return nil
        }

        let didStartAccessing = url.startAccessingSecurityScopedResource()

        // 沙盒下必须先开启访问，才能可靠地判断文件是否还存在
        guard FileManager.default.fileExists(atPath: url.path) else {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
            print("自定义音效文件不存在(\(type.rawValue)): \(url.path)，已回退系统音效")
            clearBookmark(for: type)
            return nil
        }

        // 书签过期（文件被移动等）时重建一次
        if isStale {
            try? saveBookmark(url: url, for: type)
        }

        return ScopedURL(url: url, didStartAccessing: didStartAccessing)
    }
}
