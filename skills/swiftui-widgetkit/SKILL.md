---
name: swiftui-widgetkit
description: "Implement, review, or improve iOS widgets, Live Activities, and Dynamic Island. Use when building Home Screen or Lock Screen widgets with WidgetKit, defining a TimelineProvider or AppIntentTimelineProvider for timeline refresh, supporting widget families (systemSmall/Medium/Large/ExtraLarge or accessory families), making interactive widgets with Button(intent:)/Toggle(intent:) and AppIntent (iOS 17+), building Control Center / Lock Screen controls with ControlWidget (iOS 18+), creating Live Activities with ActivityKit (ActivityAttributes, ContentState, Activity.request/update/end), laying out the Dynamic Island (compact, minimal, expanded regions), updating activities via ActivityKit push (APNs), or handling widget deep links, containerBackground, and tint/rendering modes."
---

# SwiftUI WidgetKit & Live Activities (iOS 26+)

Build, review, and fix iOS widgets, Live Activities, and Dynamic Island layouts.
Covers WidgetKit timelines, interactive widgets, Control Center controls, and
ActivityKit using SwiftUI and Swift 6.3 patterns.

## Contents

- [Triage Workflow](#triage-workflow)
- [Widget Anatomy](#widget-anatomy)
- [Widget Families](#widget-families)
- [TimelineProvider](#timelineprovider)
- [AppIntentConfiguration (Configurable Widgets, iOS 17+)](#appintentconfiguration-configurable-widgets-ios-17)
- [Interactive Widgets (iOS 17+)](#interactive-widgets-ios-17)
- [containerBackground & Sizing](#containerbackground--sizing)
- [Deep Links](#deep-links)
- [Control Widgets (Control Center / Lock Screen, iOS 18+)](#control-widgets-control-center--lock-screen-ios-18)
- [Live Activities (ActivityKit)](#live-activities-activitykit)
- [Dynamic Island](#dynamic-island)
- [Updating Live Activities (push & local)](#updating-live-activities-push--local)
- [Common Mistakes](#common-mistakes)
- [Review Checklist](#review-checklist)
- [References](#references)

## Triage Workflow

### Step 1: Identify what you are building

| Goal | API | Extension target |
|---|---|---|
| Home Screen / Lock Screen widget | `Widget` + `StaticConfiguration` | Widget Extension |
| User-configurable widget | `Widget` + `AppIntentConfiguration` | Widget Extension |
| Tappable / stateful widget | `Button(intent:)` / `Toggle(intent:)` + `AppIntent` | Widget Extension |
| Control Center / Lock Screen control | `ControlWidget` | Widget Extension |
| Ongoing real-time activity | `ActivityKit` + `ActivityConfiguration` | Widget Extension |
| Dynamic Island presentation | `DynamicIsland` inside `ActivityConfiguration` | Widget Extension |

### Step 2: Confirm the target setup

Widgets and Live Activities ship in a **Widget Extension** target, not the app
target. The `ActivityAttributes` type must live in code **shared** between the
app and the extension (shared file membership or a shared framework). Add
`NSSupportsLiveActivities = YES` to the **app** Info.plist for Live Activities.

### Step 3: Pick the refresh model

| Need | Mechanism |
|---|---|
| Periodic content (weather, calendar) | `TimelineProvider` with scheduled entries + `.atEnd`/`.after(date)` reload |
| User action changes state | Interactive `AppIntent` → call `reloadTimelines` |
| Live, sub-minute updates | **Live Activity** (not a widget timeline) |
| Server-driven Live Activity | ActivityKit **push** (`pushType: .token`) |

## Widget Anatomy

```swift
import WidgetKit
import SwiftUI

struct StatusWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StatusWidget", provider: Provider()) { entry in
            StatusWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)  // REQUIRED iOS 17+
        }
        .configurationDisplayName("Status")
        .description("Shows current status at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

@main
struct StatusWidgetBundle: WidgetBundle {
    var body: some Widget {
        StatusWidget()
        // Add Control widgets and Live Activity configs here too.
    }
}
```

`kind` is a stable string ID — keep it constant across releases.

## Widget Families

| Family | Where | Notes |
|---|---|---|
| `.systemSmall` / `.systemMedium` / `.systemLarge` | Home Screen, Today | Full-color SwiftUI |
| `.systemExtraLarge` | iPad Home Screen | iPad only |
| `.accessoryCircular` | Lock Screen, Apple Watch | Tinted/desaturated — design for monochrome |
| `.accessoryRectangular` | Lock Screen | Tinted; use `.widgetAccentable()` to accent glyphs |
| `.accessoryInline` | Lock Screen above clock | One line of text + optional SF Symbol |

Read the family with `@Environment(\.widgetFamily)` to branch layout:

```swift
@Environment(\.widgetFamily) private var family

var body: some View {
    switch family {
    case .accessoryCircular: GaugeView(entry: entry)
    case .accessoryRectangular: CompactRowView(entry: entry)
    default: FullView(entry: entry)
    }
}
```

Accessory families render **monochrome/tinted** — never rely on color alone.

## TimelineProvider

```swift
struct Entry: TimelineEntry {
    let date: Date
    let status: String
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry {
        Entry(date: .now, status: "—")               // Redacted skeleton
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(Entry(date: .now, status: "Active"))   // Widget gallery preview
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let entries = (0..<4).map { i in
            Entry(date: .now.addingTimeInterval(Double(i) * 900), status: "Active")
        }
        // Reload after the last entry is shown.
        completion(Timeline(entries: entries, policy: .after(.now.addingTimeInterval(3600))))
    }
}
```

**Reload policies:** `.atEnd` (reload when last entry passes), `.after(date)`
(reload at a specific time), `.never` (only when you call
`WidgetCenter.shared.reloadTimelines(ofKind:)`). The system **budgets** refreshes
— widgets are not real-time. Use a Live Activity for live data.

## AppIntentConfiguration (Configurable Widgets, iOS 17+)

User-editable parameters use an `AppIntent` (replaces the old SiriKit Intents).

```swift
import AppIntents

struct SelectAccount: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Select Account"
    @Parameter(title: "Account") var account: AccountEntity?
}

struct ConfigurableWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "ConfigurableWidget",
                               intent: SelectAccount.self,
                               provider: AppIntentProvider()) { entry in
            BalanceView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
// Provider conforms to AppIntentTimelineProvider; getTimeline receives the configured intent.
```

## Interactive Widgets (iOS 17+)

Only `Button(intent:)` and `Toggle(intent:)` work in widgets — no gestures, no
`@State` mutation. The intent runs in the app process, then the widget reloads.

```swift
struct ToggleTask: AppIntent {
    static let title: LocalizedStringResource = "Toggle Task"
    @Parameter(title: "Task ID") var taskID: String

    init() {}
    init(taskID: String) { self.taskID = taskID }

    func perform() async throws -> some IntentResult {
        await TaskStore.shared.toggle(taskID)      // mutate shared store
        return .result()                            // widget reloads automatically
    }
}

// In the widget view:
Toggle(isOn: entry.isDone, intent: ToggleTask(taskID: entry.id)) {
    Text(entry.title)
}
.toggleStyle(.button)
```

Keep `perform()` fast and write to a store shared via App Group so the next
timeline reflects the change.

## containerBackground & Sizing

- **iOS 17+ requires** `.containerBackground(_:for:)`. Without it the widget
  shows blank in the Smart Stack and on the Lock Screen.
- Use `.widgetAccentable()` on glyphs that should pick up the accent tint in
  accessory families.
- Never hardcode frames to a pixel size — lay out with the provided geometry and
  let each family size itself. Use `ViewThatFits`/`Spacer` for flexibility.

## Deep Links

```swift
// systemSmall: whole-widget tap
WidgetView(entry: entry).widgetURL(URL(string: "myapp://item/\(entry.id)"))

// systemMedium/Large: per-element
Link(destination: URL(string: "myapp://item/\(item.id)")!) { RowView(item: item) }
```

Handle the URL in the app via `.onOpenURL` / `onContinueUserActivity`.

## Control Widgets (Control Center / Lock Screen, iOS 18+)

```swift
struct WifiControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "WifiControl") {
            ControlWidgetToggle("Wi-Fi", isOn: WifiState.isOn,
                                action: ToggleWifiIntent()) { isOn in
                Image(systemName: isOn ? "wifi" : "wifi.slash")
            }
        }
        .displayName("Wi-Fi")
    }
}
```

Use `ControlWidgetButton` for actions, `ControlWidgetToggle` for binary state.
State comes from an `AppIntent` (`SetValueIntent`/`ToggleManager`). Controls also
appear on the Lock Screen and the Action Button.

## Live Activities (ActivityKit)

Use a Live Activity for real-time, user-initiated events (delivery, ride, game
score, timer) shown on the Lock Screen and in the Dynamic Island for up to ~8h.

```swift
import ActivityKit

struct DeliveryAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {   // dynamic, changes over time
        var stage: String
        var etaMinutes: Int
    }
    var orderNumber: String                            // static, set at start
}
```

```swift
import WidgetKit
import SwiftUI

struct DeliveryLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DeliveryAttributes.self) { context in
            // Lock Screen / banner presentation
            VStack(alignment: .leading) {
                Text("Order \(context.attributes.orderNumber)")
                Text("\(context.state.stage) · \(context.state.etaMinutes) min")
            }
            .activityBackgroundTint(.black.opacity(0.4))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            // see Dynamic Island section
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { Text(context.state.stage) }
                DynamicIslandExpandedRegion(.trailing) { Text("\(context.state.etaMinutes)m") }
            } compactLeading: {
                Image(systemName: "shippingbox.fill")
            } compactTrailing: {
                Text("\(context.state.etaMinutes)m")
            } minimal: {
                Image(systemName: "shippingbox.fill")
            }
        }
    }
}
```

**Start an activity** (from the app, after checking authorization):

```swift
guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
let attributes = DeliveryAttributes(orderNumber: "A1234")
let initial = DeliveryAttributes.ContentState(stage: "Preparing", etaMinutes: 30)
let activity = try Activity.request(
    attributes: attributes,
    content: .init(state: initial, staleDate: .now.addingTimeInterval(900)),
    pushType: .token   // omit for local-only updates
)
```

See `references/live-activities.md` for the full lifecycle, staleDate/relevance,
and alert configuration.

## Dynamic Island

Provide all three presentations — the system picks based on context:

| Region | Builder | Shown when |
|---|---|---|
| Expanded | `DynamicIslandExpandedRegion(.leading/.trailing/.center/.bottom)` | Long-press or incoming update |
| Compact | `compactLeading:` + `compactTrailing:` | One activity active |
| Minimal | `minimal:` | Multiple activities (system shows one) |

Rules:
- Keep compact/minimal to a glyph or a few characters.
- Expanded regions are a layout — `.center` sits between leading/trailing; `.bottom` spans full width.
- Tap targets in the expanded view use `Link`/`Button(intent:)`; set `.widgetURL` for the whole island.
- Budget total expanded height; the system clips oversized content.

## Updating Live Activities (push & local)

```swift
// Local update
await activity.update(
    .init(state: .init(stage: "On the way", etaMinutes: 12),
          staleDate: .now.addingTimeInterval(600))
)

// End (optionally show a final state, then dismiss)
await activity.end(
    .init(state: .init(stage: "Delivered", etaMinutes: 0), staleDate: nil),
    dismissalPolicy: .after(.now.addingTimeInterval(120))
)
```

**Push updates:** request with `pushType: .token`, read `activity.pushTokenUpdates`,
send the token to your server, and push `content-state` JSON via APNs with
`apns-push-type: liveactivity`. Use high-`relevance-score` updates sparingly —
the system rate-limits frequent pushes. See `references/live-activities.md`.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Missing `.containerBackground` (iOS 17+) | Add it in every configuration's view closure — blank widget otherwise |
| `ActivityAttributes` only in app target | Share the file with the Widget Extension (and server model) |
| Expecting real-time widget refresh | Widgets are budgeted; use a Live Activity for live data |
| Tap gestures / `@State` in widgets | Only `Button(intent:)` / `Toggle(intent:)` are interactive |
| Color-only info in accessory families | They render tinted/monochrome — use shape, glyph, `.widgetAccentable()` |
| Hardcoded frames per family | Lay out responsively; read `\.widgetFamily` |
| Forgetting `NSSupportsLiveActivities` | Add to **app** Info.plist or activities never start |
| No `staleDate` on Live Activity | Set it so the system can mark stale content |
| Pushing updates every few seconds | APNs rate-limits; batch, raise interval, or use local updates |
| Heavy work in `getTimeline` | Pre-fetch in the app; keep the provider fast and synchronous-ish |

## Review Checklist

- [ ] Widget in a Widget Extension target; `kind` stable across releases
- [ ] `.containerBackground(_:for: .widget)` present in every configuration
- [ ] `supportedFamilies` matches what the views actually render
- [ ] Accessory families designed for monochrome; `.widgetAccentable()` where needed
- [ ] `TimelineProvider` reload policy chosen deliberately; no live-data assumption
- [ ] Interactive elements use `AppIntent`; `perform()` mutates a shared store
- [ ] `ActivityAttributes` shared between app, extension, and server model
- [ ] `NSSupportsLiveActivities = YES` in the app Info.plist
- [ ] Dynamic Island provides expanded + compact + minimal; content fits
- [ ] Live Activity sets `staleDate`; `end` uses a sensible `dismissalPolicy`
- [ ] Push updates rate-limited; token refresh handled via `pushTokenUpdates`
- [ ] Deep links via `.widgetURL`/`Link` handled in the app

## References

- `references/live-activities.md` — full ActivityKit lifecycle, push payloads, staleDate/relevance, alerts, watchOS Smart Stack
- Apple: [WidgetKit](https://developer.apple.com/documentation/widgetkit), [ActivityKit](https://developer.apple.com/documentation/activitykit), [Human Interface Guidelines — Widgets / Live Activities](https://developer.apple.com/design/human-interface-guidelines/widgets)
- Related skills: `swiftui-patterns` (view composition/state), `swiftui-layout-components` (layout), `apple-hig-designer` (HIG), `swift-concurrency` (async `perform`/`update`)
