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
├── Config/                 # App environment & Dependency Container (AppContainer)
├── Theme/                  # App styling tokens, custom colors, fonts
├── Services/               # NetworkClient, KeychainStorage, AppRouter, Service Protocols
├── Models/                 # Domain entities (Trip, LoadState, ChecklistCategory, User, AuthDTOs)
├── Views/
│   ├── Auth/               # Authentication views & view models
│   ├── Common/             # Shared UI components (ErrorStateView)
│   ├── MyTrips/            # Active & upcoming trips dashboard
│   ├── ArchivedTrips/      # Archived trips history
│   ├── TripDetails/        # Trip checklists, weather card, AI & Add Item drawers
│   ├── NewTrip/            # Trip creation modal sheet & destination search
│   └── Navigation/         # MainTabView, SettingsView, AppRouter
```

---

## 🛠️ Technology Stack

- **UI Framework**: SwiftUI
- **Architecture**: MVVM + Network Layer (`NetworkClientProtocol`)
- **Dependency Injection**: `AppContainer` central registry
- **State & Navigation**: Combine (`@Published`), `enum LoadState<Value>`, `AppRouter`
- **Security**: iOS Keychain (`KeychainStorage`), ATS `NSAllowsLocalNetworking`
- **Project Generator**: XcodeGen
- **Minimum iOS Version**: iOS 16.0

---

## Практична робота 4. Взаємодія із сервером та обробка даних

### 1. Джерело даних та специфікація API

Джерелом даних для застосунку є REST API ReadyRoam Backend:

- **Базова адреса (Base URL)**:
  - Development (локальний сервер): `http://192.168.0.102:5050`
  - Production (запланований домен): `https://api.readyroam.app` (наразі відсутній, робота здійснюється через Development середовище / локальний backend)
- **Авторизація**: Запити, що потребують автентифікації (`requiresAuth: true`), використовують заголовок `Authorization: Bearer <token>`. Токен безпечно зберігається у iOS Keychain через `KeychainStorage`.

#### Основні Endpoints API

| Ендпоінт | HTTP Метод | Авторизація | Параметри / Body | Формат відповіді |
| :--- | :--- | :--- | :--- | :--- |
| `/auth/login` | `POST` | Hi | `SignInRequest` (email, password) | `SignInResult` (token, user) |
| `/trips` | `GET` | Так | `limit`, `offset`, `isArchived` | `PaginatedTripsResponseDto` |
| `/trips` | `POST` | Так | `CreateTripRequestDto` | `TripResponseDto` |
| `/trips/{id}/items` | `GET` | Так | `id` (UUID) | `[TripSectionGroupResponse]` |
| `/trips/{id}/items/bulk`| `POST` | Так | `[CreateTripItemRequest]` | `[TripItemResponse]` |
| `/destinations` | `GET` | Hi | `query`, `limit` | `[DestinationDto]` |
| `/weather/live` | `GET` | Hi | `city`, `country` | `WeatherResponse` |

### 2. Мережевий шар та архітектура

- **Мережевий клієнт (`URLSessionNetworkClient`)**: Модульний компонент на базі `URLSession`, що реалізує протокол `NetworkClientProtocol`.
- **Потокова модель (Async/Await без `@MainActor` на клієнті)**: Клас `URLSessionNetworkClient` не ізольований на `@MainActor`. Це забезпечує виконання десеріалізації JSON через `JSONDecoder` у фонових потоках, не блокуючи UI. Оновлення інтерфейсу здійснюється ViewModels на `@MainActor`.
- **Конфігурація таймаутів**: Встановлено 15-секундний таймаут запиту через `URLSessionConfiguration.timeoutIntervalForRequest = 15`.
- **Впровадження залежностей (DI)**: Мережевий клієнт передається через протоколи в сервіси (`TripService`, `DestinationService`, `TripItemService`), які зареєстровані в `AppContainer.shared`.

### 3. Класифікація та обробка помилок

Мережевий шар розрізняє три типи відмов (`APIError`):

1. **Транспортні помилки (`networkError`)**:
   - `URLError.notConnectedToInternet` / `.networkConnectionLost` -> *"No internet connection. Please check your network settings and try again."*
   - `URLError.timedOut` -> *"The request timed out. Please try again."*
2. **HTTP Статус-коди (`httpError`, `unauthorized`, `notFound`)**:
   - Статус `401`: Автентифікацію скинуто (`APIError.unauthorized`).
   - Перевірка статусів в діапазоні `200...299`. У разі помилки витягується текстове повідомлення від сервера через `ServerErrorParser`.
3. **Помилки декодування (`decodingError`)**:
   - Логування невідповідностей структури JSON та створення форматованого опису помилки.

### 4. Управління станами екрана та функція Retry

Усі основні екрани керують станом завантаження даних за допомогою універсального типу `LoadState<Value>`:

```swift
public enum LoadState<Value>: Equatable {
    case idle
    case loading
    case loaded(Value)
    case empty
    case failed(message: String)
}
```

У разі помилки відображається уніфікований компонент `ErrorStateView`:
- Повідомлення про помилку з локалізованим описом причини.
- Кнопка **«Retry»**, яка ініціює повторний асинхронний запит до API (`loadInitialTrips()`, `loadArchivedTrips()`, `fetchDestinations()`).

### 5. Інструкція з перевірки станів

1. **Перевірка успішного запиту (`.loaded`)**:
   - Запустіть застосунок та авторизуйтесь. Переконайтесь, що список поїздок у `MyTripsView` завантажується із сервера та відображає картки.
2. **Перевірка порожнього стану (`.empty`)**:
   - Перейдіть на вкладку «Archive» (якщо архівних поїздок немає) або у модальному вікні створення поїздки введіть у пошук дестинацію, якої не існує (наприклад, "Xyz123"). Відобразиться стан порожнього результату.
3. **Перевірка помилки та кнопки Повтору (`.failed` + Retry)**:
   - Увімкніть режим "Авіарежим" (Airplane Mode) на пристрої/симуляторі або вимкніть мережу.
   - Спробуйте оновити список (Pull-to-refresh) або натиснути завантаження поїздок.
   - На екрані з'явиться `ErrorStateView` із повідомленням *"No internet connection. Please check your network settings and try again."* та кнопкою **«Retry»**.
   - Увімкніть мережу назад і натисніть кнопку **«Retry»** — запит буде повторено успішно.

---

## 🧪 Building & Running Tests

To build from the command line:

```bash
xcodegen generate
xcodebuild -project ReadyRoam.xcodeproj -scheme ReadyRoam -destination 'generic/platform=iOS Simulator' build
```
