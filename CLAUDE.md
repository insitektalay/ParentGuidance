# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ParentGuidance is a SwiftUI iOS application designed as a "parenting co-pilot" to provide AI-powered guidance for parenting situations. The app integrates OpenAI's GPT-4 API and Supabase for backend services, featuring a tab-based navigation structure focused on situation input and guidance delivery.

## Build and Development Commands

### Building the Project
```bash
# Build the project (debug)
xcodebuild -project ParentGuidance.xcodeproj -scheme ParentGuidance -configuration Debug build

# Build for release
xcodebuild -project ParentGuidance.xcodeproj -scheme ParentGuidance -configuration Release build

# Build for specific iOS Simulator
xcodebuild -project ParentGuidance.xcodeproj -scheme ParentGuidance -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
```

### Running Tests
```bash
# Run all tests
xcodebuild test -project ParentGuidance.xcodeproj -scheme ParentGuidance -destination 'platform=iOS Simulator,name=iPhone 15'

# Run unit tests only
xcodebuild test -project ParentGuidance.xcodeproj -scheme ParentGuidance -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:ParentGuidanceTests

# Run UI tests only
xcodebuild test -project ParentGuidance.xcodeproj -scheme ParentGuidance -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:ParentGuidanceUITests
```

### Linting and Code Quality
The project uses standard Xcode warnings and built-in Swift compiler checks. No additional linting tools are currently configured.

### Quick Test Build
```bash
# Quick test build using the provided script
./test_build.sh
```

## Architecture Overview

### Technology Stack
- **Frontend**: SwiftUI (iOS 17.5+)
- **Backend**: Supabase (Database, Auth, Real-time)
- **AI Integration**: OpenAI GPT-4 API
- **Dependency Management**: Swift Package Manager
- **Key Dependencies**: 
  - `supabase-swift` (v2.29.3) for backend services
  - Built-in Foundation for networking and data handling

### App Architecture

#### Core Navigation Flow
1. **Entry Point**: `ParentGuidanceApp.swift` → `OnboardingFlow` → `MainTabView.swift`
2. **Tab Structure**: 5-tab architecture managed by `Tab` enum with custom `TabButton` components
3. **State Management**: Enum-based coordinators for onboarding (`OnboardingStep`) and situation flows
4. **Authentication Flow**: Checks user profile to determine onboarding state and navigation path

#### Key Services (`Services/`)
- **SupabaseManager**: Singleton managing database connections and authentication
- **OpenAIService**: Legacy GPT-4 integration (not currently used)
- **AuthService**: Authentication flow management
- **OnboardingManager**: Coordinates multi-step onboarding process
- **AppCoordinator**: Application-level navigation coordination

#### Active OpenAI Integration (`Views/Core/NewSituationView.swift`)
- **Primary Integration**: OpenAI Prompts API (`/v1/responses`) with prompt templates
- **ConversationService**: Embedded service for situation-guidance conversation pairs
- **Response Parsing**: Custom regex parsing for bracket-delimited structured guidance format
- **Prompt ID**: Uses specific prompt template ID for parenting guidance generation

#### Data Models
- **Core Models** (defined in `ParentGuidanceApp.swift`):
  - `UserProfile`: User account with onboarding state and subscription details
  - `Situation`: Core situation model with JSONB context fields
  - `Guidance`: AI-generated guidance responses
  - `ConversationService`: Database operations and OpenAI integration
- **Child.swift**: Child profile and preferences (in `Models/` directory)
- **Additional Models**: Various view-specific models throughout the app

#### Onboarding Flow (`Views/Onboarding/`)
Enum-driven coordinator pattern through these steps:
1. Welcome → Authentication → Plan Selection → Payment/API Key → Child Setup
2. Supports both subscription plans and bring-your-own OpenAI API key
3. Complete flow managed by `OnboardingCoordinator.swift`

#### Situation Input System (`Views/Core/Situations/`)
Multi-state input system for parenting situations:
- **SituationInputIdleView**: Default state with text/voice input
- **SituationTypingView**: Active text input state  
- **SituationVoiceView**: Voice recording state
- **SituationFollowUpView**: Follow-up questions state
- **SituationOrganizingView**: AI processing state
- **Components**: `MicButton`, `SendButton`, `InputGuidanceFooter`

#### Main Tab Views (`Views/Core/`)
- **Today**: Timeline view with empty state (`TodayViewController`, `TodayTimelineView`, `TodayEmptyView`)
- **New**: Primary situation input (`NewSituationView`) with OpenAI integration
- **Library**: Search and browse past situations (`LibraryView`) with comprehensive filtering
- **Alerts**: Notification management (`AlertView`)
- **Settings**: User preferences and account management (`SettingsView`)

### Design System (`Constants/ColorPalette.swift`)
- **Primary Colors**: Navy (#2B2D42), Terracotta (#C4816C), Cream (#F7F3E9)
- **Accent**: Bright Blue (#4285F4)
- **Custom Color Extension**: Hex string support for SwiftUI Colors
- **Consistent Theming**: All views use ColorPalette constants

### Database Schema
The app uses Supabase with these core tables:
- **situations**: User-submitted parenting scenarios with JSONB context fields
- **guidance**: AI-generated responses linked to situations
- **families**: Family group management
- **children**: Child profiles and characteristics

### Current Implementation Status
- ✅ Complete UI/UX implementation for all core flows
- ✅ Supabase integration and data models
- ✅ OpenAI GPT-4 integration with structured response parsing
- ✅ Multi-step onboarding with plan selection
- ✅ Tab-based navigation with situation input states
- ⚠️ Testing implementation is minimal (placeholder tests only)
- ⚠️ Error handling and edge cases need enhancement

## Development Notes

### Code Conventions
- **SwiftUI Patterns**: Declarative UI throughout, consistent use of `@State` and `@StateObject`
- **Navigation**: Enum-based state management for complex flows (onboarding, situation input)
- **Naming**: Descriptive component names (e.g., `SituationInputIdleView`, `OnboardingCoordinator`)
- **Theming**: All colors via `ColorPalette` constants, avoid hardcoded hex values
- **Preview Providers**: Include for all major views for design iteration

### API Integration Patterns
- **OpenAI Integration**: 
  - **Active**: Prompts API (`/v1/responses`) in `NewSituationView.swift` with template-based requests
  - **Legacy**: Chat Completions API (`/v1/chat/completions`) in `OpenAIService.swift` (unused)
  - **Prompt Structure**: Uses bracket-delimited sections `[TITLE]`, `[SITUATION]`, etc.
  - **Response Format**: Structured guidance with 7 sections: Title, Situation, Analysis, Action Steps, Phrases to Try, Quick Comebacks, Support
- **Supabase**: Singleton manager pattern with centralized client configuration
- **Database Operations**: `ConversationService` handles all data persistence for situations and guidance

### Testing Structure
- **Unit Tests**: `ParentGuidanceTests/` (currently minimal)
- **UI Tests**: `ParentGuidanceUITests/` (currently minimal)
- **Testing Gap**: Comprehensive test coverage needed for services and data models