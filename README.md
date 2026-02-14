# **Everything App**

A Flutter-based productivity app designed to manage user communications, calendars, and events, all while integrating with state-of-the-art APIs for seamless functionality. This project uses a clean, modular architecture to ensure scalability and maintainability.

---

## **Features**
- **User Login**: Simple email-based login functionality.
- **Event Management**: Display and manage events with add, remove, and list features.
- **State Management**: Powered by `Provider` for global state sharing.
- **Scalable Architecture**: Modularized for easy integration of additional features.
- **Mobile-First**: Designed specifically for Android (expandable to iOS).

---

## **Tech Stack**
- **Language**: Dart (Flutter Framework)
- **State Management**: Provider
- **Database**: SQLite (via `sqflite` package)
- **Backend Integration**: HTTP APIs (stubbed for now)
- **IDE**: Android Studio or Visual Studio Code

---

## **Project Structure**
```
lib/
|
├── main.dart                # App entry point
|
├── core/                    # Core utilities
|   ├── constants/           # App-wide constants
|   ├── utils/               # Helper functions (HTTP, date formatting)
|   └── services/            # External integrations (Auth, API, Storage)
|
├── data/                    # Data layer (local storage, repositories)
|   ├── local_storage.dart   # SQLite/SharedPreferences handler
|   └── repositories/        # Abstracted data handling
|
├── models/                  # Data models (User, Event)
|   ├── user_model.dart
|   └── event_model.dart
|
├── state/                   # State management
|   ├── blocs/               # Bloc-based state (optional)
|   └── providers/           # Provider-based state management
|
├── views/                   # Screens and reusable widgets
|   ├── home/                # Home screen
|   ├── login/               # Login screen
|   └── widgets/             # Reusable UI components
|
└── assets/                  # Static assets (images, fonts, animations, data)
```
---

## **Getting Started**

### **1. Prerequisites**
- Install **Flutter SDK** ([Install Flutter](https://docs.flutter.dev/get-started)).
- Use an IDE like **Android Studio** or **Visual Studio Code**.
- Basic knowledge of Flutter and Dart is recommended.

---

### **2. Clone the Repository**
Clone the repository to your local machine:
git clone https://github.com/sauravbhattacharya001/everything.git
cd everything

---

### **3. Install Dependencies**
To install all the necessary dependencies for the project, run the following command in the project root directory:
flutter pub get

If you encounter any issues with dependencies, try running:
flutter clean
flutter pub get

---

### **4. Run the Application**
To start the application on an Android emulator or connected device, use:
flutter run

If you have multiple devices connected, specify the device ID:
flutter run -d <device-id>

---

### **5. Folder Structure Overview**
Below is the primary structure of the project:
```
lib/
├── main.dart                # App entry point
├── core/                    # Core utilities (constants, services, utils)
├── data/                    # Data layer (repositories, local storage)
├── models/                  # Data models (User, Event)
├── state/                   # State management (Provider/Bloc)
├── views/                   # UI screens and widgets
└── assets/                  # Static resources (images, fonts, animations)
```
---

### **6. Test the Application**
- **Login**: The login functionality is currently stubbed and navigates directly to the Home Screen.
- **Event Management**: Use the floating action button on the Home Screen to dynamically add events.

---

## **How to Contribute**
1. Fork the repository.
2. Create a new branch (feature/new-feature).
3. Commit changes and push to your branch.
4. Create a pull request.

---

## **Future Enhancements**
- **API Integration**: Connect with Microsoft Graph, Google Calendar, and other APIs.
- **Advanced Event Management**: Recurring events, notifications.
- **Authentication**: Add social logins (Google, Facebook).
- **iOS Support**: Expand app compatibility to iOS devices.

---

## **License**
This project is licensed under the MIT License. See the LICENSE file for details.

---

## **Contact**
If you have any questions or suggestions, feel free to reach out:
- **Email**: online.saurav@gmail.com
- **LinkedIn**: [My  LinkedIn Profile](https://linkedin.com/in/sauravbhattacharya)
