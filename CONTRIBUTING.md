# Contributing to SlotLauncher

Thanks for your interest! This is a personal utility project, but issues, suggestions, and pull requests are welcome.

## How to contribute

### Reporting bugs

Open an [issue](https://github.com/Rish3666/SlotLauncher-for_mac/issues) with:

- A clear description of the problem
- Steps to reproduce
- macOS version and hardware (Apple Silicon / Intel)
- Whether the target app in question is a native macOS app, a Catalyst app, or a Rosetta-translated app

### Suggesting enhancements

Open an issue describing the feature, why it's useful, and (if applicable) how it should behave. Keep in mind this project aims to stay focused — features that require new TCC permissions or App Sandbox entitlements are likely out of scope.

### Pull requests

1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/my-change`).
3. Make your changes. Keep the existing code style: no comments, concise, Swift-native APIs.
4. Verify the project builds with `swift build` or in Xcode.
5. Commit with a clear, one-line message.
6. Push and open a pull request against `master`.

### Code style

- No comments in source code — the code and the spec comments in `SlotLauncherApp.swift` are the documentation.
- Use SwiftUI and Combine for UI / state management.
- Stick to `NSWorkspace` / `NSRunningApplication` APIs for app activation. Do not introduce Apple Events or the Accessibility API without a clear justification.
- `@MainActor` on all UI-facing classes.
- Avoid adding new dependencies unless unavoidable.

## Development setup

```bash
git clone https://github.com/Rish3666/SlotLauncher-for_mac.git
cd SlotLauncher-for_mac
open Package.swift
```

Disable App Sandbox in the target's Signing & Capabilities tab before building for the first time.

## License

By contributing, you agree that your contributions will be licensed under the GPL v3.0 — the same license as the project itself.
