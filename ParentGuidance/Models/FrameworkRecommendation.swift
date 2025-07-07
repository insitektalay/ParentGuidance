//
//  FrameworkRecommendation.swift
//  ParentGuidance
//
//  Created by alex kerss on 07/07/2025.
//

import Foundation

// MARK: - Core Framework Models

/// Represents a generated framework recommendation from AI analysis
struct FrameworkRecommendation: Codable, Identifiable, Equatable {
    let id: String
    let frameworkName: String
    let notificationText: String
    let createdAt: String
    
    /// Initialize a new framework recommendation
    init(frameworkName: String, notificationText: String) {
        self.id = UUID().uuidString
        self.frameworkName = frameworkName
        self.notificationText = notificationText
        self.createdAt = ISO8601DateFormatter().string(from: Date())
    }
    
    /// Initialize from parsed API response
    init(id: String = UUID().uuidString, frameworkName: String, notificationText: String, createdAt: String) {
        self.id = id
        self.frameworkName = frameworkName
        self.notificationText = notificationText
        self.createdAt = createdAt
    }
}

// MARK: - Framework Types

/// Enumeration of available parenting framework types
enum FrameworkType: String, CaseIterable, Codable {
    case zonesOfRegulation = "Zones of Regulation"
    case focusMap = "Focus Map"
    case sensoryComfortMap = "Sensory Comfort Map"
    case worryThermometer = "Worry Thermometer"
    case powerShareChart = "Power Share Chart"
    case connectionBeforeCorrection = "Connection Before Correction"
    case collaborativeProblemSolving = "Collaborative Problem Solving"
    case emotionCoaching = "Emotion Coaching"
    
    /// Brief description of each framework
    var description: String {
        switch self {
        case .zonesOfRegulation:
            return "Helps children understand and manage their emotional states through color-coded zones"
        case .focusMap:
            return "Visual tool for improving attention and concentration in children"
        case .sensoryComfortMap:
            return "Framework for understanding and managing sensory processing needs"
        case .worryThermometer:
            return "Tool for measuring and managing anxiety levels in children"
        case .powerShareChart:
            return "System for giving children appropriate choices and control"
        case .connectionBeforeCorrection:
            return "Approach emphasizing emotional connection before addressing behavior"
        case .collaborativeProblemSolving:
            return "Method for involving children in finding solutions to challenges"
        case .emotionCoaching:
            return "Technique for helping children understand and regulate emotions"
        }
    }
    
    /// Check if a framework name matches this type
    func matches(_ name: String) -> Bool {
        return name.lowercased().contains(self.rawValue.lowercased()) ||
               self.rawValue.lowercased().contains(name.lowercased())
    }
}

// MARK: - Framework State Management

/// Represents the current state of framework activation for a user
enum FrameworkActivationState: Equatable {
    case notEstablished
    case recommended(FrameworkRecommendation)
    case active(FrameworkRecommendation)
    
    /// The framework recommendation if available
    var recommendation: FrameworkRecommendation? {
        switch self {
        case .notEstablished:
            return nil
        case .recommended(let framework), .active(let framework):
            return framework
        }
    }
    
    /// Whether a framework is currently active
    var isActive: Bool {
        switch self {
        case .active:
            return true
        default:
            return false
        }
    }
    
    /// Display text for the current state
    var displayText: String {
        switch self {
        case .notEstablished:
            return "Foundational Framework Not Yet Established"
        case .recommended(let framework):
            return "Recommended: \(framework.frameworkName)"
        case .active(let framework):
            return framework.frameworkName
        }
    }
}

// MARK: - API Response Parsing

/// Handles parsing of OpenAI API responses for framework generation
struct FrameworkAPIResponse {
    let rawContent: String
    
    /// Parse the raw API response into a structured framework recommendation
    func parseFramework() -> FrameworkRecommendation? {
        guard let frameworkName = rawContent.extractFrameworkName(),
              let notificationText = rawContent.extractNotificationText() else {
            print("❌ Failed to parse framework from response")
            return nil
        }
        
        print("✅ Parsed framework: \(frameworkName)")
        return FrameworkRecommendation(
            frameworkName: frameworkName,
            notificationText: notificationText
        )
    }
}

// MARK: - Database Integration Models

/// User's framework profile for database storage
struct UserFrameworkProfile: Codable {
    let userId: String
    let activeFrameworkName: String?
    let frameworkRecommendation: String?
    let lastUpdated: String
    
    init(userId: String, activeFrameworkName: String? = nil, frameworkRecommendation: String? = nil) {
        self.userId = userId
        self.activeFrameworkName = activeFrameworkName
        self.frameworkRecommendation = frameworkRecommendation
        self.lastUpdated = ISO8601DateFormatter().string(from: Date())
    }
}

// MARK: - String Extensions for Parsing

extension String {
    /// Extract framework name from [Foundation Tool]: Framework Name format
    func extractFrameworkName() -> String? {
        // Look for pattern: [Foundation Tool]: Framework Name
        let pattern = #"\[Foundation Tool\]:\s*(.+?)(?:\n|$)"#
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let range = NSRange(location: 0, length: self.count)
            
            if let match = regex.firstMatch(in: self, options: [], range: range) {
                let nameRange = Range(match.range(at: 1), in: self)
                if let nameRange = nameRange {
                    let frameworkName = String(self[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    return frameworkName.isEmpty ? nil : frameworkName
                }
            }
        } catch {
            print("❌ Regex error: \(error)")
        }
        
        return nil
    }
    
    /// Extract notification text from the response
    func extractNotificationText() -> String? {
        // Find everything after the framework name line
        let lines = self.components(separatedBy: .newlines)
        var foundFrameworkLine = false
        var notificationLines: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.contains("[Foundation Tool]:") {
                foundFrameworkLine = true
                continue
            }
            
            if foundFrameworkLine && !trimmedLine.isEmpty {
                notificationLines.append(trimmedLine)
            }
        }
        
        let notificationText = notificationLines.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        return notificationText.isEmpty ? nil : notificationText
    }
    
    /// Validate that a string contains a valid framework name
    func isValidFrameworkName() -> Bool {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count >= 3 && trimmed.count <= 100
    }
}

// MARK: - Validation Helpers

extension FrameworkRecommendation {
    /// Validate that the recommendation has valid data
    var isValid: Bool {
        return frameworkName.isValidFrameworkName() && 
               !notificationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               notificationText.count >= 10 && 
               notificationText.count <= 1000
    }
    
    /// Get the framework type if it matches a known type
    var frameworkType: FrameworkType? {
        return FrameworkType.allCases.first { $0.matches(frameworkName) }
    }
}