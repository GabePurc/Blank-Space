# Blank Space: research and build plan

Date: 2026-09-07. Goal: rebuild the paid iOS app **Blank Spaces Launcher** as a completely free app, with no subscription, no paywall, no accounts, and no analytics.

## 1. What Blank Spaces is

| Fact | Value |
|---|---|
| App Store name | Blank Spaces Launcher ("Build a Minimalist Dumb Phone") |
| Seller | Ecstasis LLC, App Store id 1570856853 |
| Listing | https://apps.apple.com/us/app/blank-spaces-launcher/id1570856853 |
| Rating | 4.6 from about 8.3K ratings (written reviews skew much lower) |
| Requires | iOS 18.0+, 168 MB, version 2.23 (Aug 26, 2026) |
| Pricing | Weekly $1.99, Monthly $3.99, Yearly $17.99, Lifetime $23.99 |
| Free tier | None in practice. Trial or limited version, then paywall after adding the first app |
| Help center | https://help.blankspaces.app/ |

It turns an iPhone into a "dumb phone": a home screen that is just a short list of app names in plain text on a flat background. No icons, no dock, no badges. Tapping a name opens the app.

### Feature inventory

**Home screen widgets**
- Top widget (medium size): blank, date, day of week, analog clock, weather, or 5-day forecast. Since v2.23 it can also launch an app on tap.
- Launcher widget (large size): vertical list of app names, no icons. Up to about 10 apps per widget. Widgets 2 to 5 are extra pages and also act as blank spacers.
- Widget display name is "-" so no label shows under it. iOS 18 Large icon mode hides labels entirely.
- Lock screen toggle to show the same list on the lock screen.
- Scrolling is faked by putting widgets in a Smart Stack.

**Adding apps**
- Search a curated catalog of app name to URL scheme. Rename, reorder by drag, swipe to delete.
- Custom app: paste a URL scheme, or import an Apple Shortcut that uses the "Open App" action.
- Phone, Calculator, and Clock have no public URL scheme and need the Shortcut route.
- "Fast Launch" on iOS 26 opens some apps without bouncing through the Blank app first.

**Customization (paintbrush)**
- Font, alignment (left/center/right), text size, line spacing.
- Text color dark/light. Widget color light/dark/black.
- Custom wallpaper: import an unedited screenshot and the app slices it so each widget background matches the pixels behind it.
- Bundled wallpapers tuned to hide the dock and iOS 26 Liquid Glass widget borders.

**Focus features**
- App locks via Screen Time: pick apps, always or scheduled by weekday.
- Unlock challenges: breathing exercise, passcode, "touch grass" camera check, push-ups counted by camera.
- Detox Mode: temporary allowlist-only phone for a chosen duration.
- Streaks and badges for days you launched at least one app through the widget. Calendar view.

### What users complain about
- Price. "$23 for a static widget." Paywall shown before the trial, and dismissing it restarts onboarding.
- Launch delay and a black flash when the app bounces through Blank or the Shortcuts app.
- Catalog gaps. Requested apps take months. Apple's own apps need Shortcuts.
- Undisclosed 10-app cap, widget not refreshing after edits, no true black theme on older versions.
- Locks not re-locking after a timed unlock.
- Requests: alphabetized list, auto light/dark wallpaper, more Apple apps.

### Competitors

| App | Price | Difference |
|---|---|---|
| Dumb Phone (dp) | $3.99/mo, $19.99/yr, $39.99 lifetime | More visual opinion, NFC detox unlock |
| Dumbify | $4.99 one-time | Three widgets plus spacer, Shortcuts launching |
| Minimalist Phone: Blank Spaces | €2.99/mo, €17.99 lifetime | Lookalike |
| Dumbphone: Limit Distractions | $3.99 lifetime | Small, new |
| Brick | Free app + $59 NFC device | Blocker, not a launcher |

Nobody in this space is free. That is the whole opening.

## 2. How the trick works on iOS

iOS has no launcher replacement. The "home screen" is two WidgetKit widgets sitting on an otherwise empty page.

1. **Widgets can only open their own app.** Each row is a `Link` to a URL like `blankspace://open/<id>`. The host app receives it in `onOpenURL` and immediately calls `UIApplication.open` on the target's scheme. That round trip is the flash users see.
2. **Other apps open only by URL scheme.** `open(_:)` needs no declaration. There is no public API to list installed apps, so the app ships a catalog of name to scheme. Users can add their own schemes.
3. **Apps without a scheme go through Shortcuts.** Import a Shortcut that runs "Open App", then launch it with `shortcuts://run-shortcut?name=…`. Slower and shows the Shortcuts app briefly.
4. **Faster launch on iOS 18.1+ and 26.** An interactive widget `Button(intent:)` whose `AppIntent.perform()` returns `OpenURLIntent` can open a target without foregrounding our app. This is the likely mechanism behind "Fast Launch" and is worth testing first.
5. **Hiding the dock is cosmetic.** A wallpaper whose bottom band matches the dock tint, plus widget backgrounds that match the wallpaper. Perspective zoom off. iOS 26 glass borders need matched wallpaper and color pairs and can leave a faint outline.
6. **App locking is the Screen Time stack.** FamilyControls authorization, ManagedSettings shields, DeviceActivity schedules. Needs the Family Controls entitlement, which Apple grants by request. Using shields to hide apps has been rejected in review.

## 3. Product decisions for the free remake

- **Free forever.** No StoreKit, no trial, no accounts, no analytics SDK. Privacy label: Data Not Collected.
- **Open source** on GitHub so people can trust it and add apps to the catalog by pull request.
- **Ship the launcher first.** The widget launcher is the value. Locks and streaks come later.
- **Catalog in the repo.** A JSON file of name, scheme, and category, editable by anyone. Ship a generous set of Apple and popular third-party apps on day one.
- **Fix the top complaints.** Try the AppIntent launch path first to remove the flash. No app cap beyond what fits. True black theme from the start. Alphabetize option.
- **Deployment target iOS 18.0** to match the original's audience. Project currently targets 26.5 and should be lowered.

## 4. Architecture

```
Blank Space.xcodeproj
├── Blank Space/            app target (SwiftUI)
│   ├── App/                entry, URL routing, deep-link redirect
│   ├── Editor/             pages, app picker, catalog search, custom app
│   ├── Style/              font, alignment, size, spacing, colors, wallpaper slicer
│   ├── Setup/              in-app guide: add widgets, hide dock, hide pages
│   └── Resources/          catalog.json, bundled wallpapers
├── BlankSpaceWidgets/      widget extension
│   ├── TopWidget           medium: blank / date / clock / weather
│   ├── LauncherWidget      large: app list, 5 instances (pages)
│   └── LockScreenWidget    accessoryRectangular list
├── BlankSpaceCore/         local Swift package shared by both targets
│   ├── Models              AppEntry, Page, Style, Catalog
│   ├── Store               App Group JSON store + WidgetCenter reload
│   └── Launch              scheme validation, Shortcuts URL builder
└── docs/
```

- **Shared storage**: App Group `group.FactoryOne.Blank-Space`. One JSON document for pages and style. The app writes, calls `WidgetCenter.shared.reloadAllTimelines()`, and the widget reads.
- **Launch path**: `Button(intent: OpenAppIntent(id))` in the widget. The intent returns `OpenURLIntent(scheme)`. Fallback for schemes that refuse: `widgetURL` into our app, which redirects in `onOpenURL`.
- **Rendering**: widget draws text only, using the shared Style. `containerBackground` set to the chosen color or the wallpaper slice.
- **Weather**: WeatherKit needs the WeatherKit capability and location permission. Optional, later phase.

## 5. Phases

| Phase | Deliverable | Notes |
|---|---|---|
| 0 | Project scaffold | Widget extension, App Group, shared package, target lowered to iOS 18, CI build on GitHub Actions |
| 1 | Launcher MVP | Large widget with app list, medium top widget with blank/date, catalog with 150+ apps, add/rename/reorder/delete, URL scheme custom apps, light/dark/black |
| 2 | Polish | Font/alignment/size/spacing, custom wallpaper slicer, bundled wallpapers, in-app setup guide, Shortcuts fallback for Phone, five pages, lock screen widget |
| 3 | Launch speed | Test and ship OpenURLIntent path on iOS 18.1+, measure flash, keep redirect fallback |
| 4 | Focus | Streaks stored locally, Detox Mode and app locks behind Family Controls entitlement, breathing unlock |
| 5 | Release | App Store listing as free, TestFlight beta, README with sideload instructions |

## 6. Open questions

- Family Controls entitlement is a request to Apple and can take weeks. Decide whether Phase 4 matters enough to start the request now.
- WeatherKit has a free tier of 500K calls per month per developer, which is fine for a widget but needs the capability enabled on the App ID.
- Whether to keep a fixed 10-row layout or let text size drive the row count.

## Sources

- App Store listing: https://apps.apple.com/us/app/blank-spaces-launcher/id1570856853
- Pricing: https://www.blankspaces.app/pricing
- Setup guide: https://help.blankspaces.app/articles/9333401-how-to-set-up-blank-spaces
- Widget guide: https://help.blankspaces.app/articles/8808377-how-to-add-the-blank-spaces-widgets
- Custom shortcuts: https://help.blankspaces.app/articles/1922492-how-to-add-a-custom-shortcut-or-deep-link
- Fast Launch: https://help.blankspaces.app/articles/3995496-how-to-fix-the-black-screen-when-launching-apps
- Dock hiding on iOS 26: https://help.blankspaces.app/articles/7034987-how-to-hide-the-dock-and-widget-borders-ios-26
- App locks: https://help.blankspaces.app/articles/1116569-how-to-lock-apps
- Widget tap limits: https://developer.apple.com/documentation/widgetkit/linking-to-specific-app-scenes-from-your-widget-or-live-activity
- OpenURLIntent from widgets: https://developer.apple.com/forums/thread/762586
- canOpenURL limits: https://developer.apple.com/documentation/uikit/uiapplication/canopenurl(_:)
- Reviews: https://justuseapp.com/en/app/1570856853/blank-spaces-launcher/reviews
