# Blank Space

A free, open-source iPhone home screen launcher. Your home screen becomes a short list of app names in plain text. No icons, no dock, no badges, and no subscription.

It is a from-scratch remake of the paid Blank Spaces Launcher. See [docs/RESEARCH-AND-PLAN.md](docs/RESEARCH-AND-PLAN.md) for the teardown and the phased plan.

## How it works

iOS has no launcher replacement, so the "home screen" is two WidgetKit widgets on an otherwise empty page:

- **Top Widget** (medium): blank, the date, or the weekday.
- **Widget 1 to 5** (large): a text-only list of apps. Tapping a name deep-links into the app, which immediately opens the target by URL scheme.

The app and the widgets share one JSON document through an App Group.

## Project layout

```
Blank Space/          app target (SwiftUI, iOS 18+)
BlankSpaceWidgets/    widget extension
BlankSpaceCore/       shared Swift package: models, store, launch routing
docs/                 research and plan
```

## Building

Requires Xcode 26 or newer. Open `Blank Space.xcodeproj`, pick the **Blank Space** scheme, and run on a simulator or device. On a device, automatic signing will register the App Group `group.FactoryOne.Blank-Space` on your team.

Run the package tests from the command line:

```bash
swift test --package-path BlankSpaceCore
```

## Status

Phase 1: launcher MVP. In-app editor with a 200-app catalog, search, custom URL schemes, Shortcut fallback, rename, reorder, delete, up to five pages, and style controls with a live preview. Next: custom wallpaper, in-app setup guide, lock screen widget.
