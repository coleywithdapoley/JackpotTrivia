App Icon placeholders (replace before App Store submission)
============================================================

Current PNGs are solid royal-blue placeholders generated for development.
Replace with final artwork:

1. Export a master 1024×1024 PNG (no transparency for App Store icon).
2. In Xcode, open Assets.xcassets → AppIcon.
3. Drag the master into the "iOS" 1024pt slot (and dark/tinted variants if needed).
   Xcode generates all required sizes automatically.

Required for iPhone (handled by Xcode from 1024×1024):
- Notification: 20pt @2x, @3x
- Settings: 29pt @2x, @3x
- Spotlight: 40pt @2x, @3x
- App: 60pt @2x, @3x
- App Store marketing: 1024×1024

Brand color reference: #4169E1 (see AppConfig.primaryAccentColor).
