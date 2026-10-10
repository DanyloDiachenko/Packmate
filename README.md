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

# Practical 1: Створення проєкту, Git та основи Swift

### 1. Опис предметної області (Domain Description)

**ReadyRoam (Packmate)** — це мобільний застосунок для інтелектуального планування подорожей, складання списків речей (чек-листів) та моніторингу статусу поїздок.

- **Цільовий користувач**: Мандрівники, які шукають зручний спосіб організувати поїздку, розбити речі за категоріями та відстежувати готовність до виїзду.
- **Основні сценарії**:
  1. Реєстрація та вхід користувача (`User`), збереження авторизованої сесії.
  2. Перегляд активної поїздки (`Trip`) та майбутніх планів у розрізі дат і днів до виїзду.
  3. Відмічання спакованих речей (`TripItem`) із динамічним перерахунком прогресу підготовки у відсотках.
  4. Переміщення завершених поїздок до архіву.

#### Ключові сутності предметної області (Domain Entities)
1. **`User` / `UserProfile`** (`struct`) — сутність користувача ([AuthService.swift](file:///Users/d-diachenko/Documents/GitHub/Packmate/ReadyRoam/Services/AuthService.swift#L105)) (`id`, `email`, `username`, стан авторизованої сесії).
2. **`Trip`** (`struct`) — сутність поїздки ([Trip.swift](file:///Users/d-diachenko/Documents/GitHub/Packmate/ReadyRoam/Models/Trip.swift#L3)) (дестинація, країна, прапор, дати, стан пакування `packedItems`/`totalItems`, статуси `isActive`/`isArchived`).
3. **`TripItem` / `TripItemResponse`** (`struct`) — сутність елемента чек-листа ([TripItemDTOs.swift](file:///Users/d-diachenko/Documents/GitHub/Packmate/ReadyRoam/Models/TripItemDTOs.swift#L29)) (`id`, `tripId`, `section`, `title`, `quantity`, прапорець стану `isTaken`, `tag`).

---

### 2. Реалізація конструкцій Swift у коді проєкту

Усі обов’язкові конструкції Swift представлені у робочих файлах кодової бази:

| Конструкція Swift | Файл кодової бази | Приклад використання в коді |
| :--- | :--- | :--- |
| **Struct** | [Trip.swift](file:///Users/d-diachenko/Documents/GitHub/Packmate/ReadyRoam/Models/Trip.swift#L3), [TripItemDTOs.swift](file:///Users/d-diachenko/Documents/GitHub/Packmate/ReadyRoam/Models/TripItemDTOs.swift#L29) | `struct Trip`, `struct TripItemResponse: Codable, Identifiable` |
| **Class** | [TripService.swift](file:///Users/d-diachenko/Documents/GitHub/Packmate/ReadyRoam/Services/TripService.swift#L3), [MyTripsViewModel.swift](file:///Users/d-diachenko/Documents/GitHub/Packmate/ReadyRoam/Views/MyTrips/ViewModels/MyTripsViewModel.swift#L4) | `final class TripService: TripServiceProtocol`, `@MainActor final class MyTripsViewModel` |
| **Protocol** | [ServiceProtocols.swift](file:///Users/d-diachenko/Documents/GitHub/Packmate/ReadyRoam/Services/ServiceProtocols.swift#L26) | `protocol TripServiceProtocol: ObservableObject` |
| **Enum** | [NewTripType.swift](file:///Users/d-diachenko/Documents/GitHub/Packmate/ReadyRoam/Views/NewTrip/Models/NewTripType.swift#L4) | `enum NewTripType: String, CaseIterable, Identifiable` |
| **var / let** | [TripItemDTOs.swift](file:///Users/d-diachenko/Documents/GitHub/Packmate/ReadyRoam/Models/TripItemDTOs.swift#L30-L36) | `let id: UUID`, `let tripId: UUID`, `var isTaken: Bool`, `var quantity: Int` |
| **Properties & Init** | [Trip.swift](file:///Users/d-diachenko/Documents/GitHub/Packmate/ReadyRoam/Models/Trip.swift#L22-L78) | Computed property `packingPercentage: Int` та кастомний `init(...)` |
| **Array** | [TripItemDTOs.swift](file:///Users/d-diachenko/Documents/GitHub/Packmate/ReadyRoam/Models/TripItemDTOs.swift#L52) | `var items: [TripItemResponse]` — колекція речей у секції |
| **Set** | [NewTripViewModel.swift](file:///Users/d-diachenko/Documents/GitHub/Packmate/ReadyRoam/Views/NewTrip/ViewModels/NewTripViewModel.swift#L16) | `@Published var selectedTripTypes: Set<NewTripType> = []` |
| **Dictionary** | [NetworkClient.swift](file:///Users/d-diachenko/Documents/GitHub/Packmate/ReadyRoam/Services/NetworkClient.swift#L13) | `public let headers: [String: String]?` (словник HTTP-заголовків) |
| **Optional & Unwrapping** | [TripItemDTOs.swift](file:///Users/d-diachenko/Documents/GitHub/Packmate/ReadyRoam/Models/TripItemDTOs.swift#L36), [Trip.swift](file:///Users/d-diachenko/Documents/GitHub/Packmate/ReadyRoam/Models/Trip.swift#L102) | `var tag: String?`, `guard totalItems > 0 else { return 0 }`, `if let d = dDate, let r = rDate` |
| **Conditional Flow** | [Trip.swift](file:///Users/d-diachenko/Documents/GitHub/Packmate/ReadyRoam/Models/Trip.swift#L33-L39) | `if daysUntil <= 0 { ... } else if daysUntil == 1 { ... } else { ... }` |
| **Switch** | [NewTripType.swift](file:///Users/d-diachenko/Documents/GitHub/Packmate/ReadyRoam/Views/NewTrip/Models/NewTripType.swift#L15-L24) | `switch self { case .relaxation: return "beach.umbrella" ... }` |
| **Higher-Order Functions** | [MyTripsViewModel.swift](file:///Users/d-diachenko/Documents/GitHub/Packmate/ReadyRoam/Views/MyTrips/ViewModels/MyTripsViewModel.swift) | `dtos.map { Trip(from: $0) }`, `allTrips.filter { !$0.isArchived }` |

---

### 3. Виконання та перевірка сценарію

Завершений сценарій предметної області виконується при відкритті головного екрана **MyTripsView**:

1. При завантаженні `MyTripsView` запускається викликом `loadTrips()`.
2. Сервіс `TripService` запитує поїздки `[TripResponseDto]`.
3. Отриманий масив трансформаційно відображається через `.map { Trip(from: $0) }`.
4. Елементи чек-листа `[TripItemResponse]` групуються та відображаються у деталях поїздки.
5. Здійснюється фільтрація активної поїздки та майбутніх поїздок через `.filter { ... }`.
6. Розраховується рівень готовності пакування `packingPercentage` на основі станів `isTaken` в `TripItemResponse`.
