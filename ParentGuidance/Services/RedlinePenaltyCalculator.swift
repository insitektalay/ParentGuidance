import Foundation

class RedlinePenaltyCalculator {
    
    // MARK: - Configuration
    
    private struct PenaltyWeights {
        static let semantic: Double = 0.5
        static let keyword: Double = 0.3
        static let section: Double = 0.2
    }
    
    // MARK: - Main Calculation Method
    
    func calculateRedlinePenalty(
        output: String,
        redline: RedlineResponse
    ) -> RedlinePenalty {
        // 1. Semantic proximity (would use embeddings in production)
        let semanticScore = calculateSemanticProximity(output, redline.fullResponse)
        
        // 2. Keyword/phrase detection
        let keywordHits = detectRedlineKeywords(output, redline.responseSections?.keywords ?? [])
        
        // 3. Section-specific checks
        let sectionPenalties = checkSectionViolations(output, redline.responseSections)
        
        // 4. Compute weighted penalty
        let totalPenalty = (semanticScore * PenaltyWeights.semantic) +
                          (Double(keywordHits) * PenaltyWeights.keyword * 0.1) + // Scale keyword hits
                          (sectionPenalties * PenaltyWeights.section)
        
        return RedlinePenalty(
            semanticProximity: semanticScore,
            keywordHits: keywordHits,
            sectionPenalties: sectionPenalties,
            totalPenalty: min(1.0, totalPenalty) // Cap at 1.0
        )
    }
    
    // MARK: - Semantic Proximity
    
    private func calculateSemanticProximity(_ output: String, _ redlineText: String) -> Double {
        // Simple implementation using text similarity
        // In production, this would use embedding-based cosine similarity
        let similarity = calculateJaccardSimilarity(output, redlineText)
        return similarity
    }
    
    private func calculateJaccardSimilarity(_ text1: String, _ text2: String) -> Double {
        let words1 = Set(tokenize(text1))
        let words2 = Set(tokenize(text2))
        
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        guard !union.isEmpty else { return 0.0 }
        
        return Double(intersection.count) / Double(union.count)
    }
    
    // MARK: - Keyword Detection
    
    private func detectRedlineKeywords(_ output: String, _ keywords: [String]) -> Int {
        let outputLower = output.lowercased()
        var hitCount = 0
        
        for keyword in keywords {
            if outputLower.contains(keyword.lowercased()) {
                hitCount += 1
            }
        }
        
        // Also check for phrase matches
        hitCount += detectPhrasesInText(output, keywords)
        
        return hitCount
    }
    
    private func detectPhrasesInText(_ text: String, _ phrases: [String]) -> Int {
        let textLower = text.lowercased()
        var hitCount = 0
        
        for phrase in phrases {
            let phraseLower = phrase.lowercased()
            if phraseLower.count > 10 && textLower.contains(phraseLower) {
                hitCount += 2 // Phrase matches are weighted higher
            }
        }
        
        return hitCount
    }
    
    // MARK: - Section Violations
    
    private func checkSectionViolations(_ output: String, _ redlineSections: ResponseSections?) -> Double {
        guard let sections = redlineSections else { return 0.0 }
        
        var penalties: Double = 0.0
        
        // Check tone violations
        if let tone = sections.tone {
            penalties += checkToneViolations(output, tone)
        }
        
        // Check step violations
        if let steps = sections.steps {
            penalties += checkStepViolations(output, steps)
        }
        
        // Check key point violations
        if let keyPoints = sections.keyPoints {
            penalties += checkKeyPointViolations(output, keyPoints)
        }
        
        return min(1.0, penalties)
    }
    
    private func checkToneViolations(_ output: String, _ avoidTone: String) -> Double {
        // Simple tone detection based on keywords
        let toneKeywords = extractToneKeywords(avoidTone)
        let outputLower = output.lowercased()
        
        var violations: Double = 0.0
        for keyword in toneKeywords {
            if outputLower.contains(keyword.lowercased()) {
                violations += 0.1
            }
        }
        
        return violations
    }
    
    private func checkStepViolations(_ output: String, _ avoidSteps: [String]) -> Double {
        var violations: Double = 0.0
        
        for step in avoidSteps {
            let stepSimilarity = calculateJaccardSimilarity(output, step)
            if stepSimilarity > 0.3 { // Threshold for step similarity
                violations += stepSimilarity * 0.2
            }
        }
        
        return violations
    }
    
    private func checkKeyPointViolations(_ output: String, _ avoidKeyPoints: [String]) -> Double {
        var violations: Double = 0.0
        
        for keyPoint in avoidKeyPoints {
            if output.lowercased().contains(keyPoint.lowercased()) {
                violations += 0.15
            }
        }
        
        return violations
    }
    
    // MARK: - Utility Methods
    
    private func tokenize(_ text: String) -> [String] {
        return text.components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
            .filter { !$0.isEmpty && $0.count > 2 }
            .map { $0.lowercased() }
    }
    
    private func extractToneKeywords(_ toneDescription: String) -> [String] {
        // Extract tone-related keywords from description
        let commonToneWords = [
            "harsh", "gentle", "firm", "soft", "strict", "lenient",
            "authoritarian", "permissive", "demanding", "understanding",
            "critical", "supportive", "judgmental", "accepting"
        ]
        
        let descriptionLower = toneDescription.lowercased()
        return commonToneWords.filter { descriptionLower.contains($0) }
    }
    
    // MARK: - Batch Processing
    
    func calculatePenaltiesForBatch(
        outputs: [String],
        redlines: [RedlineResponse]
    ) -> [String: RedlinePenalty] {
        var results: [String: RedlinePenalty] = [:]
        
        for (index, output) in outputs.enumerated() {
            if index < redlines.count {
                let penalty = calculateRedlinePenalty(output: output, redline: redlines[index])
                results[redlines[index].id.uuidString] = penalty
            }
        }
        
        return results
    }
    
    // MARK: - Analysis Methods
    
    func analyzeRedlineEffectiveness(
        penalties: [RedlinePenalty],
        threshold: Double = 0.3
    ) -> RedlineAnalysis {
        let totalPenalties = penalties.count
        let highPenalties = penalties.filter { $0.totalPenalty > threshold }.count
        let averagePenalty = penalties.isEmpty ? 0.0 : penalties.map { $0.totalPenalty }.reduce(0, +) / Double(penalties.count)
        
        let effectivenessScore = Double(highPenalties) / Double(totalPenalties)
        
        return RedlineAnalysis(
            totalEvaluations: totalPenalties,
            highPenaltyCount: highPenalties,
            averagePenalty: averagePenalty,
            effectivenessScore: effectivenessScore,
            recommendations: generateRecommendations(penalties)
        )
    }
    
    private func generateRecommendations(_ penalties: [RedlinePenalty]) -> [String] {
        var recommendations: [String] = []
        
        let avgSemantic = penalties.map { $0.semanticProximity }.reduce(0, +) / Double(penalties.count)
        let avgKeyword = Double(penalties.map { $0.keywordHits }.reduce(0, +)) / Double(penalties.count)
        
        if avgSemantic < 0.2 {
            recommendations.append("Consider adding more specific examples to redline content")
        }
        
        if avgKeyword < 2 {
            recommendations.append("Add more specific keywords and phrases to avoid")
        }
        
        if penalties.filter({ $0.totalPenalty < 0.1 }).count > penalties.count / 2 {
            recommendations.append("Redline content may be too restrictive or not specific enough")
        }
        
        return recommendations
    }
}

// MARK: - Supporting Data Structures

struct RedlinePenalty {
    let semanticProximity: Double
    let keywordHits: Int
    let sectionPenalties: Double
    let totalPenalty: Double
}

struct RedlineAnalysis {
    let totalEvaluations: Int
    let highPenaltyCount: Int
    let averagePenalty: Double
    let effectivenessScore: Double
    let recommendations: [String]
}

// MARK: - Error Types

enum RedlinePenaltyError: LocalizedError {
    case invalidRedlineContent
    case calculationFailed(String)
    case embeddingServiceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidRedlineContent:
            return "Invalid or empty redline content"
        case .calculationFailed(let message):
            return "Penalty calculation failed: \(message)"
        case .embeddingServiceUnavailable:
            return "Embedding service required for semantic analysis is unavailable"
        }
    }
}