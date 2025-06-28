# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ParentGuidance is a SwiftUI iOS application designed as a "parenting co-pilot" to provide guidance for parenting situations. The app features a tab-based navigation structure and focuses on situation input through text and voice with an AI-powered guidance system.

## Build and Development Commands

### Building the Project
```bash
# Build the project
xcodebuild -project ParentGuidance.xcodeproj -scheme ParentGuidance -configuration Debug build

# Build for release
xcodebuild -project ParentGuidance.xcodeproj -scheme ParentGuidance -configuration Release build
```

### Running Tests
```bash
# Run unit tests
xcodebuild test -project ParentGuidance.xcodeproj -scheme ParentGuidance -destination 'platform=iOS Simulator,name=iPhone 15'

# Run UI tests specifically
xcodebuild test -project ParentGuidance.xcodeproj -scheme ParentGuidance -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:ParentGuidanceUITests
```

### Linting and Code Quality
The project uses standard Xcode warnings and built-in Swift compiler checks. No additional linting tools are currently configured.

## Architecture Overview

### App Structure
- **Entry Point**: `ParentGuidanceApp.swift` - Main app entry that displays `MainTabView`
- **Navigation**: Tab-based architecture with 5 main sections (Today, New, Library, Alerts, Settings)
- **Design System**: Centralized color palette in `ColorPalette.swift` with navy, terracotta, and cream theme

### Key Components

#### Main Navigation (`MainTabView.swift`)
- Custom tab bar implementation with enum-based tab management
- Each tab has an associated icon, title, and view
- Currently defaults to "New" tab (situation input)

#### Onboarding Flow (`Views/Onboarding/`)
- Multi-step onboarding coordinator using enum-based state management
- Steps: Welcome → Authentication → Plan Selection → Payment/API Key → Child Setup
- `OnboardingCoordinator.swift` manages the flow state

#### Situation Input System (`Views/Core/Situations/`)
- **Primary View**: `SituationInputIdleView` - Main text/voice input interface
- **Components**: Reusable UI components in `Components/` folder
  - `ChildBadge.swift` - Child identifier badge
  - `MicButton.swift` - Voice recording button
  - `SendButton.swift` - Message send button  
  - `InputGuidanceFooter.swift` - Help text footer
- **State Views**: Different states (Typing, Voice, FollowUp, Organizing)

### Directory Structure
```
ParentGuidance/
├── Assets.xcassets/          # App icons and image assets
├── Components/               # Reusable components (currently empty)
├── Constants/               # App-wide constants and theming
├── Models/Core/             # Data models (currently empty)
├── Services/                # External service integrations (currently empty)
├── Utilities/               # Helper functions and extensions (currently empty)
├── ViewModels/              # MVVM view models (currently empty)
└── Views/
    ├── Core/                # Main app screens
    │   ├── Situations/      # Situation input flow
    │   └── [Tab Views]      # Today, Library, Alerts, Settings
    ├── Components/          # Shared UI components (currently empty)
    └── Onboarding/          # Onboarding flow screens
```

### Design System
- **Color Palette**: Navy primary, terracotta accent, cream background, bright blue highlights
- **Custom Color Extension**: Hex color support for SwiftUI Color type
- **Typography**: System fonts with consistent sizing
- **Layout**: Consistent padding (16px horizontal, varying vertical spacing)

### Current Development Status
- Basic app structure and navigation implemented
- Onboarding flow structure complete (UI flows but no backend integration)
- Situation input UI implemented with placeholder actions
- Core tab views are placeholder implementations
- No data persistence, networking, or AI integration yet implemented

## Development Notes

### Testing Structure
- Unit tests: `ParentGuidanceTests/` (basic XCTest setup)
- UI tests: `ParentGuidanceUITests/` (basic XCTest setup)
- Tests are currently minimal - main test files contain only example test methods

### Code Conventions
- SwiftUI declarative UI throughout
- Enum-based state management for navigation flows
- Consistent use of ColorPalette for theming
- Preview providers for all major views
- Descriptive component naming (e.g., `SituationInputIdleView`, `ChildBadge`)