//
//  TranslationQueueManager.swift
//  ParentGuidance
//
//  Created by alex kerss on 19/07/2025.
//

import Foundation
import Combine

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
    
    // MARK: - Initialization
    
    private init() {
        startProcessingTimer()
        loadPendingTranslations()
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
        let nextTask = queueAccessQueue.sync {
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
        await loadPendingTranslations()
    }
    
    private func loadPendingTranslations() {
        Task {
            do {
                // Query for pending translations
                let pendingGuidance: [[String: Any]] = try await SupabaseManager.shared.client
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
                    .value
                
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
                    guard let apiKey = await getAPIKeyForFamily(familyId: familyId) else {
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
                    "translation_retry_count": retryCount,
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
}

// MARK: - Queue Analytics

extension TranslationQueueManager {
    struct QueueAnalytics {
        let averageProcessingTime: TimeInterval
        let successRate: Double
        let cacheHitRate: Double
        let dailyTranslationCount: Int
    }
    
    func getAnalytics() -> QueueAnalytics {
        // Placeholder implementation
        return QueueAnalytics(
            averageProcessingTime: 5.0,
            successRate: Double(completedCount) / Double(completedCount + failedCount),
            cacheHitRate: 0.0, // Would need to track from TranslationService
            dailyTranslationCount: completedCount
        )
    }
}