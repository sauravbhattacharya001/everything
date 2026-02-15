<div align="center">

# 📱 Everything App

**A Flutter-based productivity app for managing communications, calendars, and events**

[![CI](https://github.com/sauravbhattacharya001/everything/actions/workflows/ci.yml/badge.svg)](https://github.com/sauravbhattacharya001/everything/actions/workflows/ci.yml)
[![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)](#tech-stack)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)](#tech-stack)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![GitHub repo size](https://img.shields.io/github/repo-size/sauravbhattacharya001/everything)](https://github.com/sauravbhattacharya001/everything)
[![GitHub last commit](https://img.shields.io/github/last-commit/sauravbhattacharya001/everything)](https://github.com/sauravbhattacharya001/everything/commits/master)

A clean, modular architecture designed for scalability and maintainability.

</div>

---

## ✨ Features

- **User Login** — Simple email-based login functionality
- **Event Management** — Display and manage events with add, remove, and list features
- **State Management** — Powered by `Provider` for global state sharing
- **Scalable Architecture** — Modularized for easy integration of additional features
- **Mobile-First** — Designed specifically for Android (expandable to iOS)

## 🛠️ Tech Stack

| Component | Technology |
|-----------|-----------|
| **Language** | Dart (Flutter Framework) |
| **State Management** | Provider |
| **Database** | SQLite (via `sqflite` package) |
| **Backend Integration** | HTTP APIs (stubbed for now) |
| **IDE** | Android Studio or Visual Studio Code |

## 📁 Project Structure

```
lib/
├── main.dart                # App entry point
├── core/                    # Core utilities
│   ├── constants/           # App-wide constants
│   ├── utils/               # Helper functions (HTTP, date formatting)
│   └── services/            # External integrations (Auth, API, Storage)
├── data/                    # Data layer (local storage, repositories)
│   ├── local_storage.dart   # SQLite/SharedPreferences handler
│   └── repositories/        # Abstracted data handling
├── models/                  # Data models (User, Event)
│   ├── user_model.dart
│   └── event_model.dart
├── state/                   # State management
│   ├── blocs/               # Bloc-based state (optional)
│   └── providers/           # Provider-based state management
├── views/                   # Screens and reusable widgets
│   ├── home/                # Home screen
│   ├── login/               # Login screen
│   └── widgets/             # Reusable UI components
└── assets/                  # Static assets (images, fonts, animations, data)
```

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** — [Install Flutter](https://docs.flutter.dev/get-started)
- **IDE** — Android Studio or Visual Studio Code
- Basic knowledge of Flutter and Dart is recommended

### Clone the Repository

```bash
git clone https://github.com/sauravbhattacharya001/everything.git
cd everything
```

### Install Dependencies

```bash
flutter pub get
```

If you encounter any issues with dependencies:

```bash
flutter clean
flutter pub get
```

### Run the Application

```bash
# Start on default device
flutter run

# Specify a device
flutter run -d <device-id>
```

### Test the Application

- **Login** — The login functionality is currently stubbed and navigates directly to the Home Screen
- **Event Management** — Use the floating action button on the Home Screen to dynamically add events

## 🤝 Contributing

1. Fork the repository
2. Create a new branch (`git checkout -b feature/new-feature`)
3. Commit changes and push to your branch
4. Create a pull request

## 🔮 Future Enhancements

- **API Integration** — Connect with Microsoft Graph, Google Calendar, and other APIs
- **Advanced Event Management** — Recurring events, notifications
- **Authentication** — Add social logins (Google, Facebook)
- **iOS Support** — Expand app compatibility to iOS devices

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

<div align="center">

**Built by [Saurav Bhattacharya](https://github.com/sauravbhattacharya001)**

</div>
