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
- **ConversationService**: AI-powered conversation management with feature flag for EdgeFunction vs direct API
- **FrameworkGenerationService**: AI-powered generation of parenting frameworks with EdgeFunction integration
- **FrameworkStorageService**: Persistence and management of framework recommendations
- **ContextualInsightService**: Automatic context extraction and categorization with EdgeFunction support
- **EdgeFunctionService**: Unified service for all AI operations via Supabase Edge Functions
- **TranslationService**: Content translation with EdgeFunction vs direct API feature flag
- **OnboardingManager**: Coordinates multi-step onboarding process
- **AuthService**: Authentication flow management
- **OpenAIService**: Legacy GPT-4 integration (not currently used)

#### AI Integration Architecture
- **Primary Integration**: Supabase Edge Functions (`/functions/v1/guidance`) with fallback to direct OpenAI API
- **Feature Flag System**: All AI services support EdgeFunction vs Direct API modes via UserDefaults
- **Unified Edge Function**: Single function handling 4 operations: guidance, analyze, context, framework
- **Prompt Templates**: Centralized in `supabase/prompts/promptTemplates.ts` with variable interpolation
  - Main guidance: 4 style/mode combinations (Warm Practical, Analytical Scientific × Fixed, Dynamic)
  - Situation analysis: Category classification and incident detection
  - Framework generation: AI-powered parenting framework recommendations
  - Context extraction: General (11 categories) and regulation-specific insights
- **Response Parsing**: Maintained bracket-delimited format compatibility with existing parsers
- **Streaming Support**: EdgeFunction provides streaming for guidance and translation operations
- **Legacy Support**: Direct OpenAI Prompts API maintained as fallback option

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
- ✅ Supabase Edge Functions integration with OpenAI GPT-4 API
- ✅ Feature flag system for EdgeFunction vs Direct API switching
- ✅ Multi-step onboarding with plan selection
- ✅ Tab-based navigation with situation input states
- ✅ Contextual knowledge base with automatic insight extraction and categorization
- ✅ Framework generation and recommendation system
- ✅ EdgeFunction migration completed for all AI operations
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
- **EdgeFunction Integration** (Primary):
  - **Unified Endpoint**: `/functions/v1/guidance` handles all AI operations
  - **Operations**: guidance, analyze, context (general/regulation), framework, translate
  - **Authentication**: Uses Supabase session tokens for secure access
  - **Prompt Templates**: Server-side interpolation from `promptTemplates.ts`
  - **Streaming**: SSE format for real-time guidance and translation
- **Direct OpenAI Integration** (Fallback):
  - **Prompts API**: `ConversationService`, `FrameworkGenerationService`, `ContextualInsightService`
  - **Chat Completions API**: `TranslationService` (legacy mode)
  - **Template-based**: Uses OpenAI prompt template IDs with variable interpolation
- **Feature Flag System**: UserDefaults-based switching between EdgeFunction and Direct API
- **Response Format Compatibility**: Maintained bracket-delimited structure across both modes
- **Database Operations**: All services persist data identically regardless of API mode
- **Error Handling**: Graceful fallback and consistent error messaging

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