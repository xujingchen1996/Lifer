//
//  LiferActivityAttributes.swift
//  Lifer
//
//  Live Activity 属性定义 - 主 app 和 Widget Extension 共享
//

import Foundation
import ActivityKit
import SwiftUI

/// Lifer Live Activity 属性
///
/// 定义了 Live Activity 的静态属性和动态状态
public struct LiferActivityAttributes: ActivityAttributes {
    /// 活动内容状态 - 动态更新的数据
    public struct ContentState: Codable, Hashable {
        /// 已经过的时间（秒）
        public var elapsedTime: TimeInterval

        /// 活动是否进行中（true=运行中，false=已停止）
        public var isActive: Bool

        /// 是否暂停（用于跟踪暂停状态）
        public var isPaused: Bool

        /// 活动开始时间
        public var startTime: Date

        /// 上次更新时间
        public var lastUpdateTime: Date

        /// 是否使用深色模式
        public var isDarkMode: Bool

        public init(
            elapsedTime: TimeInterval,
            isActive: Bool,
            isPaused: Bool = false,
            startTime: Date,
            lastUpdateTime: Date,
            isDarkMode: Bool = false
        ) {
            self.elapsedTime = elapsedTime
            self.isActive = isActive
            self.isPaused = isPaused
            self.startTime = startTime
            self.lastUpdateTime = lastUpdateTime
            self.isDarkMode = isDarkMode
        }
    }

    /// 活动名称
    public var activityName: String

    /// 活动图标名称（SF Symbol）
    public var iconName: String

    /// 活动颜色（HEX）
    public var colorHex: String

    /// 活动开始时间
    public var startTime: Date

    public init(
        activityName: String,
        iconName: String,
        colorHex: String,
        startTime: Date
    ) {
        self.activityName = activityName
        self.iconName = iconName
        self.colorHex = colorHex
        self.startTime = startTime
    }
}
