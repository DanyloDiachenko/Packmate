# ReadyRoam (Packmate) 🧳✈️

ReadyRoam is an iOS application built with SwiftUI for planning trips, managing packing checklists, tracking weather forecasts, and viewing archived journeys.

---

## 🚀 Quickstart & Project Setup

This project uses **[XcodeGen](https://github.com/yonaskolb/XcodeGen)** to generate the Xcode project file (`ReadyRoam.xcodeproj`) dynamically from `project.yml`.

> **Note**: `.xcodeproj` and `project.xcworkspace` files are intentionally excluded from git via `.gitignore` to prevent merge conflicts in team workflows.

### Prerequisites

- **Xcode 14.0+**
- **iOS 16.0+ SDK**
- **Homebrew** (for installing XcodeGen)

### Installation & Launch Steps

1. **Clone the repository**:
   ```bash
   git clone https://github.com/DanyloDiachenko/Packmate.git
   cd Packmate
   ```

2. **Install XcodeGen** (if not already installed):
   ```bash
   brew install xcodegen
   ```

3. **Generate the Xcode project**:
   ```bash
   xcodegen generate
   ```

4. **Open in Xcode**:
   ```bash
   open ReadyRoam.xcodeproj
   ```

5. **Configure Development Team (Signing)**:
   - Select the `ReadyRoam` target in Xcode.
   - Go to **Signing & Capabilities**.
   - Select your personal Apple Developer Team under **Team**.

---

## 📁 Project Structure

The codebase is organized modularly by domain features:

```text
ReadyRoam/
├── Auth/                   # Authentication flow (Login, Register, User Session)
│   ├── Views/
│   ├── ViewModels/
│   └── Models/
├── MyTrips/                # Main trips dashboard (Active, Upcoming trips)
│   ├── Views/
│   ├── ViewModels/
│   └── Components/
├── ArchivedTrips/          # Past/Archived trips history
│   ├── Views/
│   ├── ViewModels/
│   └── Components/
├── TripDetails/            # Detailed view for a single trip (Checklists, Weather)
│   ├── Views/
│   ├── ViewModels/
│   └── Components/
├── NewTrip/                # Trip creation flow & destination search
│   ├── Views/
│   ├── ViewModels/
│   └── Components/
├── Services/               # Network API service layer & mock clients
└── Models/                 # Shared domain data models
```

---

## 🛠️ Technology Stack

- **UI Framework**: SwiftUI
- **Architecture**: MVVM with async/await (`@MainActor`, Task-based concurrent loading)
- **Project Generator**: XcodeGen
- **Minimum iOS Version**: iOS 16.0

---

## 🧪 Building & Running Tests

To build from the command line:

```bash
xcodegen generate
xcodebuild -project ReadyRoam.xcodeproj -scheme ReadyRoam -destination 'generic/platform=iOS Simulator' build
```

---

# Practical 2: Архітектура, патерни проєктування та SOLID


### 1. Обґрунтування вибору архітектури (MVVM)

У проєкті обрано архітектуру **MVVM (Model-View-ViewModel)** у поєднанні з декларативним фреймворком SwiftUI та реактивними зв'язками `Combine` (`@Published` / `ObservableObject`).

**Обґрунтування вибору**:
- **SwiftUI сумісність**: SwiftUI Views є чистою функцією стану. ViewModel ізолює стан екрана (`@Published`) та бізнес-логіку від рендерингу UI.
- **Тестованість**: ViewModels не мають залежностей від UI-компонентів, отримують сервіси через протоколи (`TripServiceProtocol`) та легко тестуються мок-сервісами (наприклад, [MockTripService.swift](file:///Users/d-diachenko/Documents/GitHub/Packmate/ReadyRoam/Services/MockTripService.swift)).
- **Чіткий розподіл відповідальностей**:
  - **View**: Декларативний опис UI та обробка дій користувача.
  - **ViewModel**: Керування станом, пагінацією, фільтрацією та обробкою помилок екрана.
  - **Model**: Легковагові value-типи даних (структури `Trip`, `TripItemResponse`, `UserProfile`).
  - **Services**: Мережеві запити REST API та безпечне зберігання токенів.

#### Схема взаємодії компонентів

```text
+-----------------------------------------------------------------------+
|                                VIEW                                   |
| (MyTripsView, TripDetailsView, SettingsView, AuthView, NewTripView)   |
+-----------------------------------------------------------------------+
                                   |
           Rebinds State & Events  | Calls ViewModel Methods
                                   v
+-----------------------------------------------------------------------+
|                              VIEWMODEL                                |
| (MyTripsViewModel, TripDetailsViewModel, AuthViewModel, NewTripVM)    |
+-----------------------------------------------------------------------+
                                   |
           Invokes Async Operations| Depends on Service Protocols
                                   v
+-----------------------------------------------------------------------+
|                           SERVICE / CONTAINER                         |
| (AppContainer, AuthService, TripService, TripItemService, Keychain)   |
+-----------------------------------------------------------------------+
                                   |
           Executes HTTP Requests  | Decodes JSON Data
                                   v
+-----------------------------------------------------------------------+
|                                MODEL                                  |
| (Trip, TripItemResponse, UserProfile, Endpoint, APIError)             |
+-----------------------------------------------------------------------+
```

---

### 2. Застосування патернів проєктування трьох категорій

| Категорія | Патерн | Компонент у коді | Задача, учасники та призначення |
| :--- | :--- | :--- | :--- |
| **Породжувальний** | **Factory / DI Container** | [AppContainer.swift](file:///Users/d-diachenko/Documents/GitHub/Packmate/ReadyRoam/Config/AppContainer.swift) | **Задача**: Створення та централізоване збирання залежностей сервісів і мережевого клієнта.<br>**Учасники**: `AppContainer` (Фабрика/Контейнер), `URLSessionNetworkClient`, `AuthService`, `TripService`, `KeychainStorage`.<br>**Призначення**: Збирає графік залежностей у потрібному порядку та виключає дублювання екземплярів сервісів. |
| **Структурний** | **Adapter** | [KeychainStorage.swift](file:///Users/d-diachenko/Documents/GitHub/Packmate/ReadyRoam/Services/KeychainStorage.swift) | **Задача**: Адаптація низькорівневого C-API Apple `Security.framework` (`SecItemAdd`, `SecItemCopyMatching`) до Swift-протоколу `TokenStorageProtocol` / `AccessTokenProvider`.<br>**Учасники**: `KeychainStorage` (Adapter), `TokenStorageProtocol` (Target Protocol), `Security.framework` (Adaptee).<br>**Призначення**: Забезпечує безпечне збереження токенів авторизації через зручний Swift API. |
| **Поведінковий** | **Observer** | [AuthService.swift](file:///Users/d-diachenko/Documents/GitHub/Packmate/ReadyRoam/Services/AuthService.swift), [MyTripsViewModel.swift](file:///Users/d-diachenko/Documents/GitHub/Packmate/ReadyRoam/Views/MyTrips/ViewModels/MyTripsViewModel.swift) | **Задача**: Автоматичне сповіщення інтерфейсу SwiftUI про зміну стану без ручного оновлення UI.<br>**Учасники**: `AuthService`, `MyTripsViewModel` (Publishers / Observables), SwiftUI Views (Observers).<br>**Призначення**: При зміні `@Published var trips` чи `isAuthenticated` UI автоматично перемальовується. |

---

### 3. Демонстрація принципів SOLID

1. **Single Responsibility Principle (SRP — Принцип єдиного обов'язку)**:
   - `AuthService` відповідає виключно за процес авторизації та профілю користувача.
   - `KeychainStorage` відповідає лише за безпечне зберігання токена у Keychain.
   - `ServerErrorParser` відповідає тільки за декодування помилок сервера.
   - `MyTripsViewModel` відповідає лише за стан екрана поїздок.

2. **Open/Closed Principle (OCP — Принцип відкритості/закритості)**:
   - Поведінка мережевого клієнта та сервісів розширюється через протоколи (`NetworkClientProtocol`, `TripServiceProtocol`).
   - Можна додати новий тип сервісу чи інший транспорт без зміни коду ViewModels.

3. **Liskov Substitution Principle (LSP — Принцип підстановки Лісков)**:
   - Реальний сервіс [TripService.swift](file:///Users/d-diachenko/Documents/GitHub/Packmate/ReadyRoam/Services/TripService.swift) та тестовий [MockTripService.swift](file:///Users/d-diachenko/Documents/GitHub/Packmate/ReadyRoam/Services/MockTripService.swift) однаково реалізують `TripServiceProtocol`.
   - Будь-який із них можна передати у `MyTripsViewModel` без порушення коректності роботи.

4. **Interface Segregation Principle (ISP — Принцип розділення інтерфейсу)**:
   - Замість монолітного інтерфейсу створено вузькоспеціалізовані протоколи: `AccessTokenProvider`, `TokenStorageProtocol`, `TripServiceProtocol`, `AuthServiceProtocol`, `TripItemServiceProtocol`.

5. **Dependency Inversion Principle (DIP — Принцип інверсії залежностей)**:
   - Модулі верхнього рівня (ViewModels) залежать від абстракцій (`TripServiceProtocol`), а не від конкретних реалізацій типів.
   - **Демонстрація заміни конкретного сервісу на тестовий/мок**:
     ```swift
     // Використання реального REST API сервісу через AppContainer:
     let realViewModel = MyTripsViewModel(
         tripService: AppContainer.shared.tripService,
         tripItemService: AppContainer.shared.tripItemService
     )

     // Заміна на тестовий/мок сервіс без зміни коду MyTripsViewModel:
     let mockViewModel = MyTripsViewModel(
         tripService: MockTripService(),
         tripItemService: AppContainer.shared.tripItemService
     )
     ```

---

### 4. Виправлення антипатернів

| Виявлена проблема | Опис виправлення |
| :--- | :--- |
| **Прихована глобальна залежність (Singleton)** | Видалено дефолтні значення `.shared` у всіх 7 ViewModels та прибрано `static let shared` із 5 сервісів. Всі залежності передаються через ініціалізатори. |
| **Невикористання AppContainer** | `AppContainer` зроблено єдиним джерелом ініціалізації сервісів. UI-представлення отримують залежності через `AppContainer` та `@EnvironmentObject`. |
| **Пряме звернення UI до сервісу** | Виклики `AuthService.shared` у `ContentView`, `SettingsView`, `MyTripsView` замінено на `@EnvironmentObject var authService: AuthService`. |
| **Надмірна відповідальність AuthService** | Моделі запитів винесено в [AuthDTOs.swift](file:///Users/d-diachenko/Documents/GitHub/Packmate/ReadyRoam/Models/AuthDTOs.swift), збереження токенів — у `KeychainStorage`, парсинг помилок — у `ServerErrorParser`. |
| **Незахищений токен у UserDefaults** | Токени перенесено у сховище `KeychainStorage` на основі iOS `Security.framework` з автоматичною міграцією та видаленням із `UserDefaults`. |
| **Дублювання парсингу помилок** | Дублювання парсингу `BackendErrorResponse` та `ProblemDetailsResponse` об'єднано у стабільний утилітарний клас [ServerErrorParser.swift](file:///Users/d-diachenko/Documents/GitHub/Packmate/ReadyRoam/Services/ServerErrorParser.swift). |
