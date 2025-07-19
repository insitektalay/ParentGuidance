//
//  TranslationQueueManager.swift
//  ParentGuidance
//
//  Created by alex kerss on 19/07/2025.
//

import Foundation
import Combine
import Supabase

/// Manages background translation queue with priority and retry logic
class TranslationQueueManager: ObservableObject {
    static let shared = TranslationQueueManager()
    
    // MARK: - Published Properties
    
    @Published private(set) var activeTranslations: Set<String> = []
    @Published private(set) var queueSize: Int = 0
    @Published private(set) var completedCount: Int = 0
    @Published private(set) var failedCount: Int = 0
    
    // MARK: - Private Properties
    
    private var queue: [TranslationTask] = []
    private let maxConcurrent = 3
    private let processingQueue = DispatchQueue(label: "com.parentguidance.translationqueue", attributes: .concurrent)
    private let queueAccessQueue = DispatchQueue(label: "com.parentguidance.translationqueue.access", attributes: .concurrent)
    private var processingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Usage Pattern Tracking
    
    private var contentAccessTracker: [String: ContentAccessRecord] = [:]
    private let usageTrackingQueue = DispatchQueue(label: "com.parentguidance.usagetracking", attributes: .concurrent)
    
    // MARK: - Models
    
    struct TranslationTask: Identifiable {
        let id: String
        let guidanceId: String
        let content: String
        let targetLanguage: String
        let targetLanguageName: String
        let familyId: String
        let apiKey: String
        let priority: Priority
        var retryCount: Int = 0
        let createdAt: Date = Date()
        
        enum Priority: Int, Comparable {
            case low = 0
            case medium = 1
            case high = 2
            
            static func < (lhs: Priority, rhs: Priority) -> Bool {
                lhs.rawValue < rhs.rawValue
            }
        }
    }
    
    enum TranslationStatus: String {
        case pending = "pending"
        case inProgress = "in_progress"
        case completed = "completed"
        case failed = "failed"
        case notNeeded = "not_needed"
    }
    
    // MARK: - Usage Pattern Models
    
    struct ContentAccessRecord {
        let contentId: String
        let familyId: String
        var accessCount: Int = 0
        var lastAccessed: Date = Date()
        var languageAccesses: [String: Int] = [:]
        var userAccesses: [String: Int] = [:]
        let createdAt: Date = Date()
        
        var accessFrequency: Double {
            let daysSinceCreation = Date().timeIntervalSince(createdAt) / (24 * 60 * 60)
            return daysSinceCreation > 0 ? Double(accessCount) / daysSinceCreation : 0
        }
        
        var preferredLanguage: String? {
            return languageAccesses.max { $0.value < $1.value }?.key
        }
    }
    
    struct FamilyUsageMetrics {
        let familyId: String
        let totalContentAccesses: Int
        let uniqueContentAccessed: Int
        let averageAccessesPerContent: Double
        let languageBreakdown: [String: Int]
        let lastAnalyzed: Date = Date()
        
        var isHighUsageFamily: Bool {
            return averageAccessesPerContent > 5.0
        }
        
        var isDualLanguageActive: Bool {
            return languageBreakdown.count > 1 && languageBreakdown.values.min() ?? 0 > 2
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        startProcessingTimer()
        loadPendingTranslations()
        
        // Load usage patterns from database
        Task {
            await loadUsagePatternsFromDatabase()
        }
    }
    
    deinit {
        processingTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Enqueue a new translation task
    func enqueue(task: TranslationTask) {
        queueAccessQueue.async(flags: .barrier) {
            // Check if task already exists
            if self.queue.contains(where: { $0.id == task.id }) {
                print("⚠️ Translation task \(task.id) already in queue")
                return
            }
            
            self.queue.append(task)
            self.sortQueue()
            
            DispatchQueue.main.async {
                self.queueSize = self.queue.count
            }
            
            print("📥 Enqueued translation task \(task.id) with priority: \(task.priority)")
        }
        
        // Update database status
        Task {
            await updateTranslationStatus(guidanceId: task.guidanceId, status: .pending)
        }
    }
    
    /// Process the next task in queue
    func processNext() async {
        // Check if we can process more
        guard activeTranslations.count < maxConcurrent else {
            print("⏸️ Max concurrent translations reached (\(maxConcurrent))")
            return
        }
        
        // Get next task
        let nextTask: TranslationTask? = queueAccessQueue.sync {
            guard !queue.isEmpty else { return nil }
            return queue.removeFirst()
        }
        
        guard let task = nextTask else {
            print("📭 Translation queue is empty")
            return
        }
        
        await MainActor.run {
            self.activeTranslations.insert(task.id)
            self.queueSize = self.queue.count
        }
        
        print("🔄 Processing translation task \(task.id)")
        
        // Update status to in progress
        await updateTranslationStatus(guidanceId: task.guidanceId, status: .inProgress)
        
        do {
            // Perform translation
            let translatedContent = try await TranslationService.shared.translateContent(
                text: task.content,
                targetLanguage: task.targetLanguageName,
                apiKey: task.apiKey
            )
            
            // Validate translation
            let validation = TranslationService.shared.validateTranslation(
                original: task.content,
                translated: translatedContent
            )
            
            if !validation.isValid {
                print("⚠️ Translation validation warnings: \(validation.warnings.joined(separator: ", "))")
            }
            
            // Update guidance with translation
            try await updateGuidanceWithTranslation(
                guidanceId: task.guidanceId,
                translatedContent: translatedContent,
                targetLanguage: task.targetLanguage
            )
            
            // Update status to completed
            await updateTranslationStatus(guidanceId: task.guidanceId, status: .completed)
            
            await MainActor.run {
                self.activeTranslations.remove(task.id)
                self.completedCount += 1
            }
            
            print("✅ Translation task \(task.id) completed successfully")
            
        } catch {
            print("❌ Translation task \(task.id) failed: \(error)")
            
            // Handle retry logic
            if task.retryCount < 3 {
                var retryTask = task
                retryTask.retryCount += 1
                
                // Calculate exponential backoff delay
                let delay = pow(2.0, Double(retryTask.retryCount)) * 5.0
                
                print("🔄 Retrying task \(task.id) after \(delay) seconds (attempt \(retryTask.retryCount)/3)")
                
                // Re-enqueue with delay
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    self.enqueue(task: retryTask)
                }
                
                // Update retry count in database
                await updateTranslationRetryCount(guidanceId: task.guidanceId, retryCount: retryTask.retryCount)
                
            } else {
                // Max retries reached, mark as failed
                await updateTranslationStatus(
                    guidanceId: task.guidanceId,
                    status: .failed,
                    error: error.localizedDescription
                )
                
                await MainActor.run {
                    self.failedCount += 1
                }
            }
            
            await MainActor.run {
                self.activeTranslations.remove(task.id)
            }
        }
        
        // Process next task if available
        if !queue.isEmpty {
            await processNext()
        }
    }
    
    /// Cancel a specific translation task
    func cancelTask(taskId: String) {
        queueAccessQueue.async(flags: .barrier) {
            self.queue.removeAll { $0.id == taskId }
            
            DispatchQueue.main.async {
                self.queueSize = self.queue.count
                self.activeTranslations.remove(taskId)
            }
        }
        
        print("❌ Cancelled translation task \(taskId)")
    }
    
    /// Get current queue status
    func getQueueStatus() -> (pending: Int, active: Int, completed: Int, failed: Int) {
        return (queue.count, activeTranslations.count, completedCount, failedCount)
    }
    
    // MARK: - Usage Pattern Tracking Methods
    
    /// Track content access for usage pattern analysis
    func trackContentAccess(contentId: String, familyId: String, userId: String, language: String) {
        usageTrackingQueue.async(flags: .barrier) {
            var record = self.contentAccessTracker[contentId] ?? ContentAccessRecord(
                contentId: contentId,
                familyId: familyId
            )
            
            record.accessCount += 1
            record.lastAccessed = Date()
            record.languageAccesses[language, default: 0] += 1
            record.userAccesses[userId, default: 0] += 1
            
            self.contentAccessTracker[contentId] = record
            
            print("📊 Tracked access for content \(contentId): language=\(language), total=\(record.accessCount)")
        }
        
        // Persist to database asynchronously
        Task {
            await self.persistContentAccess(contentId: contentId, familyId: familyId, userId: userId, language: language)
        }
    }
    
    /// Get usage metrics for a specific family
    func getFamilyUsageMetrics(familyId: String) -> FamilyUsageMetrics {
        return usageTrackingQueue.sync {
            let familyRecords = contentAccessTracker.values.filter { $0.familyId == familyId }
            
            let totalAccesses = familyRecords.reduce(0) { $0 + $1.accessCount }
            let uniqueContent = familyRecords.count
            let averageAccesses = uniqueContent > 0 ? Double(totalAccesses) / Double(uniqueContent) : 0.0
            
            var languageBreakdown: [String: Int] = [:]
            for record in familyRecords {
                for (language, count) in record.languageAccesses {
                    languageBreakdown[language, default: 0] += count
                }
            }
            
            return FamilyUsageMetrics(
                familyId: familyId,
                totalContentAccesses: totalAccesses,
                uniqueContentAccessed: uniqueContent,
                averageAccessesPerContent: averageAccesses,
                languageBreakdown: languageBreakdown
            )
        }
    }
    
    /// Get content access record for specific content
    func getContentAccessRecord(contentId: String) -> ContentAccessRecord? {
        return usageTrackingQueue.sync {
            return contentAccessTracker[contentId]
        }
    }
    
    /// Analyze if content should be proactively translated based on usage patterns
    func shouldProactivelyTranslate(contentId: String, familyId: String) async -> Bool {
        // Get current usage metrics
        let metrics = getFamilyUsageMetrics(familyId: familyId)
        
        // Check if this is a high-usage family
        guard metrics.isHighUsageFamily else {
            print("📊 Family \(familyId) is low usage - no proactive translation needed")
            return false
        }
        
        // Get family's translation strategy
        do {
            let strategy = try await FamilyLanguageService.shared.getTranslationStrategy(for: familyId)
            
            switch strategy {
            case .immediate:
                return true
            case .onDemand:
                return false
            case .hybrid:
                // For hybrid, check if family actively uses dual languages
                if metrics.isDualLanguageActive {
                    print("📊 Family \(familyId) actively uses dual languages - proactive translation recommended")
                    return true
                } else {
                    return false
                }
            }
        } catch {
            print("❌ Error getting translation strategy: \(error)")
            return false
        }
    }
    
    /// Get high-priority content for proactive translation
    func getHighPriorityContentForTranslation(familyId: String, limit: Int = 5) -> [ContentAccessRecord] {
        return usageTrackingQueue.sync {
            let familyRecords = contentAccessTracker.values.filter { 
                $0.familyId == familyId && $0.accessFrequency > 2.0 
            }
            
            return Array(familyRecords.sorted { $0.accessFrequency > $1.accessFrequency }.prefix(limit))
        }
    }
    
    // MARK: - Private Methods
    
    private func startProcessingTimer() {
        processingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task {
                await self.checkAndProcessQueue()
            }
        }
    }
    
    private func checkAndProcessQueue() async {
        print("⏰ Checking translation queue...")
        
        // Process pending tasks
        while activeTranslations.count < maxConcurrent && !queue.isEmpty {
            await processNext()
        }
        
        // Load any new pending translations from database
        loadPendingTranslations()
    }
    
    private func loadPendingTranslations() {
        Task {
            do {
                // Query for pending translations
                let response = try await SupabaseManager.shared.client
                    .from("guidance")
                    .select("""
                        id,
                        situation_id,
                        content,
                        secondary_language,
                        translation_status,
                        translation_retry_count,
                        situations!inner(
                            family_id,
                            original_language
                        )
                    """)
                    .eq("translation_status", value: "pending")
                    .limit(10)
                    .execute()
                
                let pendingGuidance = response.value as? [[String: Any]] ?? []
                
                print("📋 Found \(pendingGuidance.count) pending translations")
                
                for guidance in pendingGuidance {
                    guard let guidanceId = guidance["id"] as? String,
                          let content = guidance["content"] as? String,
                          let secondaryLanguage = guidance["secondary_language"] as? String,
                          let retryCount = guidance["translation_retry_count"] as? Int,
                          let situation = guidance["situations"] as? [String: Any],
                          let familyId = situation["family_id"] as? String else {
                        continue
                    }
                    
                    // Get API key for family (would need to be implemented)
                    // For now, skip if no API key available
                    guard let apiKey = await self.getAPIKeyForFamily(familyId: familyId) else {
                        continue
                    }
                    
                    let targetLanguageName = FamilyLanguageService.shared.getLanguageName(for: secondaryLanguage)
                    
                    let task = TranslationTask(
                        id: UUID().uuidString,
                        guidanceId: guidanceId,
                        content: content,
                        targetLanguage: secondaryLanguage,
                        targetLanguageName: targetLanguageName,
                        familyId: familyId,
                        apiKey: apiKey,
                        priority: retryCount > 0 ? .low : .medium,
                        retryCount: retryCount
                    )
                    
                    enqueue(task: task)
                }
                
            } catch {
                print("❌ Error loading pending translations: \(error)")
            }
        }
    }
    
    private func sortQueue() {
        queue.sort { task1, task2 in
            // Sort by priority first (high to low)
            if task1.priority != task2.priority {
                return task1.priority > task2.priority
            }
            // Then by creation date (oldest first)
            return task1.createdAt < task2.createdAt
        }
    }
    
    // MARK: - Database Operations
    
    private func updateTranslationStatus(guidanceId: String, status: TranslationStatus, error: String? = nil) async {
        do {
            var updateData: [String: String] = [
                "translation_status": status.rawValue,
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ]
            
            if let error = error {
                updateData["translation_error"] = error
            }
            
            try await SupabaseManager.shared.client
                .from("guidance")
                .update(updateData)
                .eq("id", value: guidanceId)
                .execute()
            
            print("📊 Updated translation status for \(guidanceId): \(status.rawValue)")
            
        } catch {
            print("❌ Failed to update translation status: \(error)")
        }
    }
    
    private func updateTranslationRetryCount(guidanceId: String, retryCount: Int) async {
        do {
            try await SupabaseManager.shared.client
                .from("guidance")
                .update([
                    "translation_retry_count": String(retryCount),
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ])
                .eq("id", value: guidanceId)
                .execute()
            
        } catch {
            print("❌ Failed to update retry count: \(error)")
        }
    }
    
    private func updateGuidanceWithTranslation(guidanceId: String, translatedContent: String, targetLanguage: String) async throws {
        try await SupabaseManager.shared.client
            .from("guidance")
            .update([
                "secondary_content": translatedContent,
                "secondary_language": targetLanguage,
                "translation_status": TranslationStatus.completed.rawValue,
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: guidanceId)
            .execute()
    }
    
    private func getAPIKeyForFamily(familyId: String) async -> String? {
        // This would need to be implemented to get API key from user profile
        // For now, returning nil
        // TODO: Implement API key retrieval logic
        return nil
    }
    
    /// Persist content access tracking to database
    private func persistContentAccess(contentId: String, familyId: String, userId: String, language: String) async {
        do {
            // Insert content access record
            try await SupabaseManager.shared.client
                .from("content_access_logs")
                .insert([
                    "content_id": contentId,
                    "family_id": familyId,
                    "user_id": userId,
                    "language": language,
                    "accessed_at": ISO8601DateFormatter().string(from: Date())
                ])
                .execute()
            
        } catch {
            print("❌ Failed to persist content access: \(error)")
        }
    }
    
    /// Load usage patterns from database on startup
    private func loadUsagePatternsFromDatabase() async {
        do {
            // Get content access data from last 30 days
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            let dateFormatter = ISO8601DateFormatter()
            
            let response = try await SupabaseManager.shared.client
                .from("content_access_logs")
                .select("content_id, family_id, user_id, language, accessed_at")
                .gte("accessed_at", value: dateFormatter.string(from: thirtyDaysAgo))
                .execute()
            
            let accessLogs = response.value as? [[String: Any]] ?? []
            
            print("📊 Loading \(accessLogs.count) content access records from database")
            
            usageTrackingQueue.async(flags: .barrier) {
                for log in accessLogs {
                    guard let contentId = log["content_id"] as? String,
                          let familyId = log["family_id"] as? String,
                          let userId = log["user_id"] as? String,
                          let language = log["language"] as? String else {
                        continue
                    }
                    
                    var record = self.contentAccessTracker[contentId] ?? ContentAccessRecord(
                        contentId: contentId,
                        familyId: familyId
                    )
                    
                    record.accessCount += 1
                    record.languageAccesses[language, default: 0] += 1
                    record.userAccesses[userId, default: 0] += 1
                    
                    self.contentAccessTracker[contentId] = record
                }
                
                print("✅ Loaded usage patterns for \(self.contentAccessTracker.count) unique content items")
            }
            
        } catch {
            print("❌ Error loading usage patterns from database: \(error)")
        }
    }
}

// MARK: - Queue Analytics

extension TranslationQueueManager {
    struct QueueAnalytics {
        let averageProcessingTime: TimeInterval
        let successRate: Double
        let cacheHitRate: Double
        let dailyTranslationCount: Int
        let totalContentTracked: Int
        let familiesWithUsageData: Int
        let averageContentAccessesPerFamily: Double
        let topLanguages: [(String, Int)]
    }
    
    func getAnalytics() -> QueueAnalytics {
        let usageAnalytics = usageTrackingQueue.sync {
            let totalContent = contentAccessTracker.count
            let familyGroups = Dictionary(grouping: contentAccessTracker.values) { $0.familyId }
            let familiesCount = familyGroups.count
            
            let totalAccesses = contentAccessTracker.values.reduce(0) { $0 + $1.accessCount }
            let avgAccessesPerFamily = familiesCount > 0 ? Double(totalAccesses) / Double(familiesCount) : 0.0
            
            var languageCounts: [String: Int] = [:]
            for record in contentAccessTracker.values {
                for (language, count) in record.languageAccesses {
                    languageCounts[language, default: 0] += count
                }
            }
            
            let topLanguages = languageCounts.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
            
            return (totalContent, familiesCount, avgAccessesPerFamily, Array(topLanguages))
        }
        
        return QueueAnalytics(
            averageProcessingTime: 5.0,
            successRate: Double(completedCount) / Double(max(completedCount + failedCount, 1)),
            cacheHitRate: 0.0, // Would need to track from TranslationService
            dailyTranslationCount: completedCount,
            totalContentTracked: usageAnalytics.0,
            familiesWithUsageData: usageAnalytics.1,
            averageContentAccessesPerFamily: usageAnalytics.2,
            topLanguages: usageAnalytics.3
        )
    }
    
    /// Get comprehensive analytics for a specific family
    func getFamilyAnalytics(familyId: String) -> FamilyAnalytics {
        let usageMetrics = getFamilyUsageMetrics(familyId: familyId)
        let familyRecords = usageTrackingQueue.sync {
            contentAccessTracker.values.filter { $0.familyId == familyId }
        }
        
        let recentlyAccessedContent = familyRecords
            .sorted { $0.lastAccessed > $1.lastAccessed }
            .prefix(10)
            .map { $0.contentId }
        
        let mostAccessedContent = familyRecords
            .sorted { $0.accessCount > $1.accessCount }
            .prefix(5)
            .map { ($0.contentId, $0.accessCount) }
        
        return FamilyAnalytics(
            familyId: familyId,
            usageMetrics: usageMetrics,
            recentlyAccessedContent: Array(recentlyAccessedContent),
            mostAccessedContent: Array(mostAccessedContent),
            recommendedStrategy: usageMetrics.isHighUsageFamily ? "immediate" : "on_demand"
        )
    }
    
    struct FamilyAnalytics {
        let familyId: String
        let usageMetrics: FamilyUsageMetrics
        let recentlyAccessedContent: [String]
        let mostAccessedContent: [(String, Int)]
        let recommendedStrategy: String
    }
}