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

### Development Environment Setup
The project includes automation hooks in `settings.json` for Claude Code:
- **Post-tool hooks**: Automatic linting and testing after file modifications
- **Stop hooks**: Notification system for task completion
- **Configuration**: Uses Opus model with smart tooling integration

## Architecture Overview

### Technology Stack
- **Frontend**: SwiftUI (iOS 17.5+)
- **Backend**: Supabase (Database, Auth, Real-time)
- **AI Integration**: OpenAI GPT-4 API
- **Dependency Management**: Swift Package Manager
- **Key Dependencies**: 
  - `supabase-swift` (v2.30.0) for backend services
  - `swift-crypto` (v3.12.3) for cryptographic functionality
  - `swift-http-types` (v1.4.0) for HTTP type definitions
  - Built-in Foundation for networking and data handling

### App Architecture

#### Core Navigation Flow
1. **Entry Point**: `ParentGuidanceApp.swift` → `AppCoordinatorView` → `AppCoordinator` (service)
2. **App State Management**: Enum-based `AppState` (.loading, .onboarding(OnboardingStep), .mainApp) with sophisticated coordination
3. **Tab Structure**: 5-tab architecture managed by `Tab` enum with custom `TabButton` components and `TabNavigationManager` singleton
4. **Authentication Flow**: `AppCoordinator` handles user profile loading, onboarding progression, and fallback routing

#### Key Services (`Services/`)
- **AppCoordinator**: Central application state management, authentication flow, and user profile loading with sophisticated error handling
- **SupabaseManager**: Singleton managing database connections and authentication
- **TabNavigationManager**: Singleton service for programmatic tab navigation using Combine
- **ConversationService**: Active OpenAI integration with multiple prompt templates and data persistence
- **FrameworkGenerationService**: AI-powered generation of parenting frameworks with dedicated prompt templates
- **FrameworkStorageService**: Persistence and management of framework recommendations
- **ContextualInsightService**: Automatic context extraction and categorization from user situations using OpenAI integration
- **OnboardingManager**: Coordinates multi-step onboarding process
- **AuthService**: Authentication flow management
- **OpenAIService**: Legacy GPT-4 integration (not currently used)

#### Active OpenAI Integration
- **Primary Integration**: OpenAI Prompts API (`/v1/responses`) with multiple prompt templates
- **Prompt Templates**:
  - Main guidance: `pmpt_68515280423c8193aaa00a07235b7cf206c51d869f9526ba` (version 12)
  - Situation analysis: `pmpt_686b988bf0ac8196a69e972f08842b9a05893c8e8a5153c7` (version 1)
  - Framework generation: `pmpt_68511f82ba448193a1af0dc01215706f0d3d3fe75d5db0f1` (version 3)
  - Context extraction: `pmpt_68778827e310819792876a9f5a844c050059609da32e4637` (version 4)
- **ConversationService**: Handles situation-guidance conversation pairs and multiple OpenAI operations
- **Response Parsing**: Custom regex parsing for bracket-delimited structured guidance format
- **Framework Generation**: Separate AI workflow for analyzing situations and generating parenting frameworks
- **Contextual Insights**: Background extraction of insights from situations with 11 categories and 5 regulation tool subcategories

#### Data Models
- **Core Models** (defined in `ParentGuidanceApp.swift`):
  - `UserProfile`: User account with onboarding state and subscription details
  - `Situation`: Core situation model with JSONB context fields, category classification, and favoriting
  - `Guidance`: AI-generated guidance responses
  - `ConversationService`: Database operations and OpenAI integration
- **Child.swift**: Child profile and preferences (in `Models/` directory)
- **FrameworkRecommendation**: AI-generated parenting framework recommendations
- **ContextualInsight**: Automatic insight extraction with 11 categories (Family Context, Regulation Tools, Medical/Health, etc.)
- **OpenAI Response Models**: `PromptResponse`, `GuidanceResponse`, `FrameworkAPIResponse` for API parsing
- **Error Handling**: Custom error enums (`FrameworkGenerationError`, `FrameworkStorageError`, `OpenAIError`)
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
- **New**: Primary situation input (`NewSituationView`) with OpenAI integration and background context extraction
- **Library**: Search and browse past situations (`LibraryView`) with comprehensive filtering, selection management (`LibrarySelectionManager`), and contextual knowledge base (`YourChildsWorldCard`, `ContextualKnowledgeBaseView`)
- **Alerts**: Notification management (`AlertView`) with framework recommendations (`FrameworkRecommendationView`)
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
- **contextual_insights**: Automatically extracted insights categorized into 11 types
- **families**: Family group management
- **children**: Child profiles and characteristics
- **framework_recommendations**: AI-generated parenting frameworks

### Current Implementation Status
- ✅ Complete UI/UX implementation for all core flows
- ✅ Supabase integration and data models
- ✅ OpenAI GPT-4 integration with structured response parsing
- ✅ Multi-step onboarding with plan selection
- ✅ Tab-based navigation with situation input states
- ✅ Contextual knowledge base with automatic insight extraction and categorization
- ✅ Framework generation and recommendation system
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
- **Framework Generation Workflow**: 
  1. Situation analysis using dedicated prompt template
  2. AI-powered framework generation with structured parsing
  3. Persistent storage through `FrameworkStorageService`
  4. Integration with alerts and recommendation system

### Testing Structure
- **Unit Tests**: `ParentGuidanceTests/` (currently minimal)
- **UI Tests**: `ParentGuidanceUITests/` (currently minimal)
- **Testing Gap**: Comprehensive test coverage needed for services and data models

## Database Management

### SQL Development Files
- **User Creation**: SQL scripts in root directory for test user setup
- **Debug Queries**: Pre-written queries for common debugging scenarios
- **RLS Policies**: Row Level Security policies for data access control

### Development Database Operations
- **Test Data Setup**: Automated scripts for creating development users and sample data
- **Schema Management**: SQL files for database structure and policies
- **Local Development**: Supabase local development environment support