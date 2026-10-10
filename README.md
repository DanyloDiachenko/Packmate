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
├── Services/               # Service protocols, network client, keychain storage, AppRouter
├── Models/                 # Domain entities (Trip, ChecklistCategory, User, AuthDTOs)
├── Views/
│   ├── Auth/               # Authentication views & view models
│   ├── MyTrips/            # Active & upcoming trips dashboard
│   ├── ArchivedTrips/      # Archived trips history
│   ├── TripDetails/        # Trip checklists, weather card, AI & Add Item drawers
│   ├── NewTrip/            # Trip creation modal sheet & destination search
│   └── Navigation/         # MainTabView, SettingsView, AppRouter
```

---

## 🛠️ Technology Stack

- **UI Framework**: SwiftUI
- **Architecture**: MVVM + Router/Coordinator (`AppRouter`)
- **Dependency Injection**: `AppContainer` central registry
- **State & Navigation**: Combine (`@Published`), SwiftUI `NavigationStack(path:)`
- **Project Generator**: XcodeGen
- **Minimum iOS Version**: iOS 16.0

---

## Практична робота 3. Інтерфейс, навігація та анімації

### 1. Карта навігації (Navigation Map)

| Початковий екран | Дія користувача | Цільовий екран | Тип переходу | Передані дані |
| :--- | :--- | :--- | :--- | :--- |
| `AuthView` | Авторизація / Вхід | `MainTabView` | Root View Swap | Токен та профіль користувача (`AuthService`) |
| `MyTripsView` | Натискання картки поїздки | `TripDetailsView` | NavigationStack Push | Модель `Trip` (`Route.tripDetails`) |
| `MyTripsView` | Натискання FAB кнопки «+» | `NewTripView` | Modal Sheet (`.sheet`) | `Sheet.newTrip` |
| `NewTripView` | Створення поїздки («Create») | `MyTripsView` | Dismiss Sheet + Event | Notification `didCreateNewTrip` |
| `ArchivedTripsView` | Натискання архівного запису | `TripDetailsView` | NavigationStack Push | Модель `Trip` (`isReadOnly: true`) |
| `MyTripsView` / `ArchivedTripsView` | Натискання іконки профілю / шестерні | `SettingsView` | Tab Switch | Зміна `selectedTab = .settings` |
| `TripDetailsView` | Натискання «Back» або свайп назад | Попередній екран | NavigationStack Pop | Виклик `router.pop()` |
| `SettingsView` | Натискання «Log Out» | `AuthView` | Root View Swap | Очищення сесії `authService.logout()` |

### 2. Відокремлене керування навігацією (AppRouter / Coordinator)

Усі маршрути, шляхи стеків та презентації модальних вікон винесені в єдиний координатор `AppRouter`:

- **Стек навігації без втрати стану**: `myTripsPath` та `archivePath` зберігаються незалежно у відповідних `NavigationStack(path:)`. При перемиканні вкладок стан і позиція прокручування екранів не скидаються.
- **Типізовані маршрути (`Route`)**: Екрани деталей отримують повну модель сутності `Trip` через роути `.tripDetails(Trip)` та `.archivedTripDetails(Trip)`.
- **Централізований оверлей модалок (`Sheet`)**: Презентація екрана створення поїздки `NewTripView` здійснюється через модифікатор `.sheet(item: $router.presentedSheet)`.

### 3. Передавання даних та оновлення попередніх екранів

-При відкритті `TripDetailsView` передається об'єкт `Trip`. Видалення поїздки через діалог підтвердження викликає `onTripDeleted`, видаляє об'єкт з ViewModel та повертає користувача назад за допомогою `router.pop()`.
- При створенні нової поїздки в `NewTripView` відправляється сповіщення `Notification.Name.didCreateNewTrip`. `MyTripsView` підписаний на це сповіщення та автоматично оновлює список з сервера/mock-сервісу.

### 4. Інтерактивні анімації та інтерфейс

В інтерфейсі реалізовано власні анімації, прив'язані до дій користувача:

- **Висувні панелі (Sliding Drawers)**: Панелі AI підказок (`AISuggestionsDrawer`) та додавання елементів (`AddItemDrawer`) висуваються знизу з фізикою пружини (`Animation.spring(response: 0.38, dampingFraction: 0.82)`), розмиванням фону (`.blur(radius:)`) та підтримкою жесту перетягування (DragGesture).
- **Раскладні категорії (Accordion Categories)**: Анімоване розгортання та згортання категорій чекліста (`ChecklistCategoryCard`) з плавною зміною висоти та поворотними іконками.
- **Свайп для видалення елемента**: Власний жест зсуву рядка (`SwipeableChecklistItemRow`) для відкриття кнопки видалення.
- **Floating Action Button (FAB)**: Анімована поява/зникнення плаваючої кнопки додавання поїздки зі зміною масштабу та прозорості (`.transition(.scale.combined(with: .opacity))`).
- **Скелетони завантаження (Skeleton Loading Pulse)**: Анімоване пульсування заповнювачів під час завантаження списку поїздок.

### 5. Інструкція проходження користувацького сценарію

1. **Авторизація**: Увійдіть в додаток (натисніть «Sign In»).
2. **Перегляд активних поїздок (`MyTripsView`)**: Перегляньте список поїздок.
3. **Перехід до деталей (`TripDetailsView`)**: Натисніть на картку поїздки (наприклад, "Tokyo"). Перевірте анімоване розгортання категорій чекліста та висувну панель AI-підказок.
4. **Повернення назад**: Натисніть кнопку «Back» або виконайте свайп від лівого краю.
5. **Модальне створення поїздки (`NewTripView`)**: Натисніть круглу синю кнопку «+» у правому нижньому кутку. Введіть дестинацію, виберіть дати та теги, натисніть «Create Trip». Екран закриється, а новий запис з'явиться у списку.
6. **Перемикання вкладок**: Перейдіть на вкладку «Archive» чи «Settings», поверніться на «My Trips» — стан та позиція списку повністю зберігаються.

---

## 🧪 Building & Running Tests

To build from the command line:

```bash
xcodegen generate
xcodebuild -project ReadyRoam.xcodeproj -scheme ReadyRoam -destination 'generic/platform=iOS Simulator' build
```
