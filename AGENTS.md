# Open Birthday

iOS app built in Swift/SwiftUI that shows countdowns to your contacts' birthdays with widgets and smart notifications.

## Project Structure

```
BirthdayCalendar/       — Main app target
  App/                  — App entry point, root navigation
  Models/               — SwiftData models (Person, AppSettings)
  DesignSystem/         — All UI/UX components, themes, typography
    Themes/             — GradientTheme, LiquidGlassTheme, MidCenturyTheme
    Components/         — Reusable views (AvatarView, BirthdayRowView, etc.)
  Views/                — Feature screens
    Onboarding/
    BirthdayList/
    AddEdit/
    Settings/
  Services/             — ContactsService, NotificationService, PersistenceService
  Resources/            — Info.plist, Assets, Entitlements

Shared/                 — Code shared between app + widget extension
  WidgetDataStore.swift — JSON store in App Group container for widgets
  SharedModels.swift    — Lightweight structs for widget consumption

BirthdayWidgets/        — Widget extension target
  Widgets: SmallNext, SmallNextFav, MediumNext, MediumNextFav
```

## Tech Stack

- **iOS 17+** minimum deployment target
- **SwiftUI** for all UI
- **SwiftData** for main app persistence
- **WidgetKit** for home screen widgets
- **Contacts framework** for importing contacts
- **UserNotifications** for scheduled birthday reminders
- **App Group** `group.com.open.birthdaycalendar` for app ↔ widget data sharing

## Key Features

- Import birthdays from Contacts or add manually
- Show age if birth year is known; otherwise show a rotating pun from the pool
- Birthday list grouped: Today / This Week / This Month / Later
- Search (no filter tabs)
- Past birthdays silently roll to next year
- Favorite / Normal friends distinction
- Per-person: disable notifications, delete from list
- Notifications:
  - Normal friends: same-day at 9am
  - Fav friends: same-day 9am + X days before (customizable in Settings, default 7)
- Contact photo import; emoji fallback if no photo

## Widgets

| Size   | Content |
|--------|---------|
| Small  | Next birthday (anyone) |
| Small  | Next fav birthday |
| Medium | Next birthday (hero) + 3 upcoming on left |
| Medium | Next birthday (hero) + 3 upcoming favs on left |

## Themes

Three themes selectable in Settings:
1. **Gradient** — rich, elegant color gradients
2. **Liquid Glass** — translucent blur layers, glassy cards
3. **Mid Century** — warm tones, bold shapes, retro typography

All themes support light + dark mode.

## Settings

- Theme picker (Gradient / Liquid Glass / Mid Century)
- Days before for fav early reminder (default: 7)
- Standard reminder time (default: 9:00 AM)

## Design System Rules

- All colors, fonts, spacing come from `DesignSystem/`
- Never hardcode colors or font sizes in feature views
- Use `ThemeManager` environment object everywhere
- Components in `DesignSystem/Components/` must be theme-agnostic (receive theme via parameter or env)

## Build

Requires [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
xcodegen generate
open BirthdayCalendar.xcodeproj
```

Set your development team in Xcode before running.
The App Group `group.com.open.birthdaycalendar` must be enabled in both targets' Signing & Capabilities.
