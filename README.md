# 🚀 Flutter Dev Assistant

**Flutter Dev Assistant** is a powerful, desktop-optimized application designed to help Flutter developers analyze, optimize, and review their codebases entirely locally. Built with Clean Architecture and a feature-first approach, it acts as your personal command center for maintaining high-quality Flutter apps.

---

## ✨ Features

- **📊 Dashboard**: Get a bird's-eye view of your project health, Flutter/Dart versions, and package counts with a beautifully animated, VS Code-like UI.
- **🔍 Code Analyzer**: Detects duplicated widgets, repeated business logic, and code smells across your entire source tree using static AST analysis.
- **⚡ Performance Profiler**: Identifies heavy widget trees, missing `const` constructors, and memory-intensive anti-patterns without running the app.
- **📦 Dependency Auditor**: Scans your `pubspec.yaml` in real-time against `pub.dev` to find unused, outdated, or discontinued packages.
- **🖼️ Asset Scanner**: Finds unused images, duplicate assets, and massive unoptimized files that are bloating your app size.
- **🕸️ Imports Graph**: Generates an interactive, zoomable node graph of your internal dependencies to detect circular imports and unused exports.
- **🤖 AI Code Reviewer**: Integrates directly with Gemini via `google_generative_ai` (using your local API key) to provide deep architectural and SOLID principle reviews of selected files.
- **🚀 Release Readiness**: Your final pre-flight checklist. Verifies Android signing, Firebase configurations, strips debug prints, and generates a shareable PDF report.
- **📦 APK/AAB Analyzer**: Unzips your compiled Android binaries entirely in-memory and renders an interactive squarified Treemap to help you visually track down app bloat.

---

## 🛠️ Architecture & Tech Stack

This project strictly adheres to **Clean Architecture** (Feature-First) principles:

- **State Management**: `provider` for robust, simple, and scalable state handling.
- **Routing**: `go_router` for seamless desktop navigation.
- **Concurrency**: Extensive use of `Isolate.run()` ensures the UI remains buttery smooth at 60 FPS, even when scanning 50,000+ files or parsing gigabytes of ZIP headers.
- **Testing**: Includes unit, widget, and integration tests to ensure production stability.
- **No Heavy Chart Dependencies**: Visualizations (like the Dependency Graph and APK Treemap) are built completely from scratch using highly-performant native `CustomPaint`.

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- macOS/Windows/Linux environment (Desktop is the primary target)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/flutter_dev_assistant.git
   cd flutter_dev_assistant
   ```

2. Fetch dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application (macOS example):
   ```bash
   flutter run -d macos
   ```

### Running Tests

To verify the integrity of the core services and UI:

```bash
# Run unit and widget tests
flutter test

# Run integration tests
flutter test integration_test/app_test.dart
```

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! 
When contributing, please ensure that you respect the feature-first Clean Architecture boundaries (`presentation/`, `domain/`, `data/`) and utilize Isolates for any heavy I/O operations.

---

## 📝 License

This project is open-source and available under the [MIT License](LICENSE).
