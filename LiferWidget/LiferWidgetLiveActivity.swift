//
//  LiferWidgetLiveActivity.swift
//  LiferWidget
//
//  Created by Tron Xu on 21/1/2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct LiferWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct LiferWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiferWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension LiferWidgetAttributes {
    fileprivate static var preview: LiferWidgetAttributes {
        LiferWidgetAttributes(name: "World")
    }
}

extension LiferWidgetAttributes.ContentState {
    fileprivate static var smiley: LiferWidgetAttributes.ContentState {
        LiferWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: LiferWidgetAttributes.ContentState {
         LiferWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: LiferWidgetAttributes.preview) {
   LiferWidgetLiveActivity()
} contentStates: {
    LiferWidgetAttributes.ContentState.smiley
    LiferWidgetAttributes.ContentState.starEyes
}
