# Live Activities — Full Reference (ActivityKit, iOS 16.1+ / iOS 26)

Deep reference for the SKILL.md `swiftui-widgetkit` skill. Covers the complete
ActivityKit lifecycle, push updates, staleness/relevance, alerts, and platform
behavior.

## Lifecycle Overview

```
request()  →  update() … update()  →  end()  →  (system dismiss)
   │              │                      │
authorization   local or push        final ContentState
check           ContentState         + dismissalPolicy
```

## 1. Authorization

```swift
let info = ActivityAuthorizationInfo()
guard info.areActivitiesEnabled else { return }   // user toggle in Settings

// Observe changes (e.g. user disables Live Activities while running)
for await enabled in info.activityEnablementUpdates {
    if !enabled { /* stop trying to start activities */ }
}
```

There is no prompt — `areActivitiesEnabled` reflects the per-app Settings toggle.
Always gate `Activity.request` on it.

## 2. Requesting (starting)

```swift
let attributes = DeliveryAttributes(orderNumber: "A1234")
let content = ActivityContent(
    state: .init(stage: "Preparing", etaMinutes: 30),
    staleDate: .now.addingTimeInterval(15 * 60),   // mark stale if no update by then
    relevanceScore: 100                            // higher = preferred in Dynamic Island when multiple
)

do {
    let activity = try Activity.request(
        attributes: attributes,
        content: content,
        pushType: .token        // .token for APNs-driven; nil for local-only
    )
    // Persist activity.id if you need to resume control after relaunch.
} catch {
    // Common: too many active activities, or activities disabled.
    print("Activity request failed: \(error)")
}
```

Limits: a small number of concurrent activities per app; exceeding throws.

## 3. Updating

### Local update
```swift
await activity.update(
    ActivityContent(
        state: .init(stage: "On the way", etaMinutes: 12),
        staleDate: .now.addingTimeInterval(10 * 60),
        relevanceScore: 100
    )
)
```

### Update with an alert (lights up the screen / haptic)
```swift
await activity.update(
    ActivityContent(state: newState, staleDate: nil),
    alertConfiguration: AlertConfiguration(
        title: "Arriving soon",
        body: "Your order is 2 minutes away.",
        sound: .default
    )
)
```

## 4. Ending

```swift
await activity.end(
    ActivityContent(state: .init(stage: "Delivered", etaMinutes: 0), staleDate: nil),
    dismissalPolicy: .after(.now.addingTimeInterval(2 * 60))  // linger 2 min then remove
)
```

`dismissalPolicy`:
- `.default` — system decides (up to ~4h on Lock Screen).
- `.immediate` — remove now.
- `.after(date)` — remove at `date` (cap ~4h out).

## 5. Observing State Across Launches

```swift
// Re-acquire running activities after app relaunch
for activity in Activity<DeliveryAttributes>.activities {
    // resume control, observe updates
}

// Observe a single activity's state + content updates
for await state in activity.activityStateUpdates {   // .active, .stale, .ended, .dismissed
    if state == .dismissed { break }
}
for await content in activity.contentUpdates {
    // reflect server-pushed content in app UI if needed
}
```

## 6. Push Updates (APNs)

### Get & forward the token
```swift
for await tokenData in activity.pushTokenUpdates {
    let token = tokenData.map { String(format: "%02x", $0) }.joined()
    await Server.register(activityID: activity.id, token: token)   // send to your backend
}
```

### APNs payload (`apns-push-type: liveactivity`)
```json
{
  "aps": {
    "timestamp": 1716500000,
    "event": "update",
    "content-state": { "stage": "On the way", "etaMinutes": 12 },
    "stale-date": 1716500600,
    "relevance-score": 100,
    "alert": { "title": "Arriving soon", "body": "2 minutes away" }
  }
}
```
- `event`: `"update"` or `"end"`.
- `content-state` keys must match your `ContentState` Codable shape exactly.
- Required headers: `apns-topic: <bundleID>.push-type.liveactivity`,
  `apns-push-type: liveactivity`, `apns-priority: 10`.

### Start a Live Activity via push (iOS 17.2+)
Set `pushType: .token` widgets can be started remotely using
`Activity.pushToStartTokenUpdates` and an APNs `event: "start"` payload that
includes both `attributes` and the initial `content-state`.

## 7. Staleness & Relevance

- **staleDate**: when reached, the activity enters `.stale`; the UI should show a
  "may be out of date" treatment. Always set it unless you update continuously.
- **relevanceScore**: when multiple activities are active, the system shows the
  highest-scoring one in the Dynamic Island compact/minimal slot.

## 8. Frequency & Budget

- Frequent APNs updates are rate-limited. For high-frequency cases request the
  **frequent updates** entitlement (`NSSupportsLiveActivitiesFrequentUpdates`) and
  still expect throttling.
- Prefer fewer, meaningful updates. Use `staleDate` so the UI degrades gracefully
  between updates rather than pushing every few seconds.

## 9. Platform Notes

- **watchOS**: Live Activities surface in the Smart Stack automatically (iOS 18+
  pairing); design the Lock Screen presentation to read well small.
- **iPad**: Dynamic Island is iPhone-only; the Lock Screen/banner presentation is
  used elsewhere.
- **StandBy / Always-On**: Lock Screen presentation is reused; avoid pure-white
  fills and respect reduced luminance.

## 10. Testing

- Simulator supports Live Activities; trigger updates from the app to verify
  Lock Screen + Dynamic Island layouts.
- For push, use the APNs sandbox with the activity push token and inspect with a
  tool like `apnstool`/`curl --http2`.
- Verify `.stale` rendering by setting a short `staleDate` and not updating.

## Info.plist Keys

| Key | Target | Purpose |
|---|---|---|
| `NSSupportsLiveActivities` | App | Enable Live Activities (required) |
| `NSSupportsLiveActivitiesFrequentUpdates` | App | Allow higher-frequency push updates |
