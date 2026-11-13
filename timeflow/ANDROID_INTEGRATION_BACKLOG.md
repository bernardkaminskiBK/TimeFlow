# TimeFlow Android Integration Backlog

This document captures optional Android integrations that can make an active
TimeFlow session visible and controllable outside the Flutter application.

## Recommended roadmap

### 1. Ongoing tracking notification

This is the best first integration for TimeFlow.

While a session is running, show a persistent system notification containing:

- The tracked activity name.
- An Android system chronometer based on the session timestamps.
- `Pause` and `Stop` actions.

When paused, replace the actions with:

- `Resume`.
- `Stop`.

When stopped and awaiting a decision, provide:

- `Resume`.
- `Save`.
- `Discard`.

Tapping the notification should open TimeFlow on the Home screen without
changing the current session.

Use the Android chronometer for display only. The persisted session timestamps
and accumulated duration must remain the source of truth, just as they are in
the Flutter stopwatch today.

### 2. Reliable notification actions

Notification actions should eventually work even when the Flutter UI or engine
is not alive.

The Android side must therefore be able to read and update the same persisted
stopwatch session that Flutter uses. The existing SharedPreferences session
storage is a useful starting point, but both Kotlin and Dart must share an
explicit, versioned data contract.

Important requirements:

- Preserve the single active session rule.
- Keep pause/resume calculations identical on Kotlin and Dart sides.
- Make each action idempotent to prevent duplicate taps from corrupting state.
- Rebuild or remove the notification whenever session state changes.
- Reconcile native changes when Flutter starts or resumes.
- Continue treating timestamps and accumulated duration as the source of truth;
  never persist a counter that is incremented every second.

Flutter can communicate with the native Android implementation using a typed
Pigeon API or a small platform channel.

### 3. Foreground service evaluation

Evaluate whether the ongoing notification should be backed by an Android
foreground service.

Do not add a service only to increment elapsed time. Its purpose would be to
make active tracking visible to Android and improve the reliability of external
controls.

Before implementation, verify:

- The foreground service type appropriate for the current Android target SDK.
- Required manifest permissions and runtime notification permission behavior.
- Google Play foreground service declarations and policy requirements.
- Behavior on Android versions and OEMs used for physical testing.
- Process death, force-stop, device reboot, and notification-disabled cases.

There is no obvious dedicated foreground service type for a general focus
stopwatch. `specialUse` may be relevant, but it requires a clear justification
and policy review. Do not assume it is automatically the right choice.

### 4. Home screen widget

After the notification controls are stable, consider an optional Android home
screen widget.

Possible states:

- Ready: selected activity and `Start focus`.
- Running: activity, elapsed time, `Pause`, and `Stop`.
- Paused: activity, frozen time, `Resume`, and `Stop`.
- Stopped: summary plus `Save` and `Discard` where space permits.

Start with one compact, resizable control widget. The widget is an Android
system surface built with RemoteViews or Jetpack Glance; it does not render the
normal Flutter widget tree. Reuse the same native session contract created for
notification actions.

### 5. Quick Settings tile

Consider a custom Android Quick Settings tile as a later convenience feature.

Suggested behavior:

- Ready: open TimeFlow so the user can confirm the activity and start.
- Running: pause the current session.
- Paused: resume the current session.
- Long press: open TimeFlow.

Avoid hiding destructive or ambiguous behavior behind a single tile tap. Stop,
Save, and Discard are better suited to the expanded notification or full app.

## Lower-priority ideas

- App shortcuts for `Start focus`, `Add manual entry`, and `Open History`.
- Android Live Updates on supported versions if an active focus session meets
  current platform eligibility and OEM behavior is acceptable.
- Wear OS integration only after the phone experience is complete.

Picture-in-picture is not recommended for TimeFlow. Android positions it mainly
for video, calls, and navigation, and a floating stopwatch window would be more
intrusive than the notification, widget, or Quick Settings options.

## Suggested implementation order

1. Define and test the shared native/Dart session contract.
2. Display a read-only ongoing notification with a system chronometer.
3. Add Pause, Resume, and Stop actions.
4. Add Save and Discard for stopped sessions.
5. Test process death, reboot, lock screen, and notification permissions.
6. Decide whether a foreground service is justified and policy-compliant.
7. Reuse the integration for a home screen widget.
8. Add a Quick Settings tile if it still provides meaningful value.

## Official references

- [Flutter platform channels](https://docs.flutter.dev/platform-integration/platform-channels)
- [Android notification actions](https://developer.android.com/develop/ui/compose/notifications/create-notification)
- [Android foreground service types](https://developer.android.com/develop/background-work/services/fgs/service-types)
- [Android App Widgets](https://developer.android.com/develop/ui/views/appwidgets/overview)
- [Android Quick Settings tiles](https://developer.android.com/develop/ui/views/quicksettings-tiles)
- [Android Live Updates](https://developer.android.com/develop/ui/views/notifications/live-update)

