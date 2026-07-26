# SlotLauncher

A macOS utility that binds up to five system-wide global keyboard shortcuts to user-configured applications. Each shortcut cycles its target through a three-state toggle: **launch** → **hide** → **refocus** → **hide** → ...

Default shortcuts are Cmd+1 through Cmd+5, mapped to Ghostty, Helium, WhatsApp, Feishin, and Obsidian — but every slot and every shortcut is fully customizable via the GUI or by editing a JSON config file by hand.

## Features

| Feature | Detail |
|---------|--------|
| **Global hotkeys** | Shortcuts fire regardless of which app has focus. No Accessibility permission required. |
| **Three-state toggle** | Not running → launch. Running + frontmost → hide. Running + hidden/background → unhide + focus. Cycles indefinitely. |
| **Per-slot customization** | Each slot has its own target app and its own key combo, independently settable. |
| **GUI configuration** | Native SwiftUI settings window with "Change App…" picker and keyboard-shortcut recorder. |
| **Config file** | `~/Library/Application Support/SlotLauncher/config.json` — hand-editable, changes picked up live. |
| **Self-healing** | On first launch, unresolvable bundle IDs automatically prompt the "Choose Application" picker. |

## Default slot mapping

| Shortcut | App | Bundle ID |
|---|---|---|
| ⌘1 | Ghostty | `com.mitchellh.ghostty` |
| ⌘2 | Helium | (picker on first launch) |
| ⌘3 | WhatsApp | `net.whatsapp.WhatsApp` |
| ⌘4 | Feishin | (picker on first launch) |
| ⌘5 | Obsidian | `md.obsidian` |

Helium and Feishin ship with empty bundle IDs because neither publishes a documented `CFBundleIdentifier` — the self-healing picker resolves them the first time the app runs on your machine.

## Requirements

- macOS 14 (Sonoma) or later
- No Accessibility / Input Monitoring permission needed (uses Carbon `RegisterEventHotKey` under the hood)
- App Sandbox must be **disabled** (the app needs to observe and activate other processes)

## Building

### From source

```bash
git clone https://github.com/Rish3666/SlotLauncher-for_mac.git
cd SlotLauncher-for_mac
open Package.swift
```

In Xcode:
1. Select the `SlotLauncher` scheme.
2. Choose **My Mac** as the destination.
3. Go to the target's **Signing & Capabilities** tab and **remove App Sandbox** (Xcode's default may add it).
4. Build and run (⌘R).

The built `.app` will be unsigned — Gatekeeper requires **Control-click → Open** the first time, or run `xattr -cr SlotLauncher.app`.

### From a prebuilt release

*(Not yet available — see "Building from source" above.)*

## Usage

1. Launch SlotLauncher. A settings window appears with five slot rows.
2. For each slot, click **Change App…** to pick the application.
3. The shortcut recorder next to each row lets you rebind the key combo.
4. Close the settings window — the app stays running in the background and the hotkeys keep working.
5. Click the Dock icon or use **SlotLauncher → Show SlotLauncher** in the menu bar to reopen settings.

### Config file location

```
~/Library/Application Support/SlotLauncher/config.json
```

The file is watched for changes — edit it with any text editor while the app is running, and the live mapping updates within ~200ms.

## Known tradeoffs

**Global shortcut capture.** Carbon-registered hotkeys take priority over the frontmost app's own key equivalents. While SlotLauncher is running, Cmd+1 stops being Finder's icon-view shortcut, Cmd+1–9 stop being tab-switching in Chromium-based browsers, etc. Since every shortcut is Recorder-customizable, switching to e.g. `⌘⌥1` is a one-click fix.

**Ghostty interactions.** Ghostty has known rough edges with third-party app activation toggling (unrelated to this app — documented in its own community around its `quick-terminal` feature). If Slot 1's toggle seems inconsistent, check Ghostty's `macos-hidden` / quick-terminal settings before debugging the SlotLauncher code.

## License

SlotLauncher is free software released under the GNU General Public License v3.0. See [LICENSE](LICENSE) for details.
