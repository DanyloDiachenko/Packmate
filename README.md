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
