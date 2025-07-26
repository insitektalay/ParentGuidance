//
//  AudioPermissionManager.swift
//  ParentGuidance
//
//  Created by alex kerss on 14/07/2025.
//

import Foundation
import AVFoundation

class AudioPermissionManager {
    static let shared = AudioPermissionManager()
    
    private var cachedPermissionStatus: AVAudioSession.RecordPermission?
    
    private init() {}
    
    // MARK: - Permission Status
    
    var permissionStatus: AVAudioSession.RecordPermission {
        // Use cached value if available for performance
        if let cached = cachedPermissionStatus {
            return cached
        }
        let status = AVAudioSession.sharedInstance().recordPermission
        cachedPermissionStatus = status
        return status
    }
    
    var isPermissionGranted: Bool {
        return permissionStatus == .granted
    }
    
    var isPermissionDenied: Bool {
        return permissionStatus == .denied
    }
    
    var isPermissionUndetermined: Bool {
        return permissionStatus == .undetermined
    }
    
    // MARK: - Permission Request
    
    func requestMicrophonePermission() async -> Bool {
        print("🎙️ Requesting microphone permission...")
        print("🔍 Current permission status: \(permissionStatus.rawValue)")
        
        // If already granted, return true
        if isPermissionGranted {
            print("✅ Microphone permission already granted")
            return true
        }
        
        // If denied, return false (user needs to go to Settings)
        if isPermissionDenied {
            print("❌ Microphone permission previously denied")
            return false
        }
        
        // Request permission
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                print("📝 Permission request result: \(granted)")
                if granted {
                    print("✅ Microphone permission granted")
                    self.cachedPermissionStatus = .granted
                } else {
                    print("❌ Microphone permission denied by user")
                    self.cachedPermissionStatus = .denied
                }
                continuation.resume(returning: granted)
            }
        }
    }
    
    // MARK: - Permission Check with Request
    
    func checkAndRequestPermission() async -> Bool {
        print("🔍 Checking microphone permission status...")
        
        // Quick check with cached value first
        if cachedPermissionStatus == .granted {
            print("✅ Microphone permission already granted (cached)")
            return true
        }
        
        // Refresh cache and check again
        cachedPermissionStatus = nil
        
        switch permissionStatus {
        case .granted:
            print("✅ Microphone permission already granted")
            return true
            
        case .denied:
            print("❌ Microphone permission denied - user needs to enable in Settings")
            return false
            
        case .undetermined:
            print("❓ Microphone permission undetermined - requesting...")
            let granted = await requestMicrophonePermission()
            if granted {
                cachedPermissionStatus = .granted
            }
            return granted
            
        @unknown default:
            print("⚠️ Unknown microphone permission status")
            return false
        }
    }
    
    // MARK: - Audio Session Configuration
    
    private var isAudioSessionConfigured = false
    
    func configureAudioSession() throws {
        print("🎵 Configuring audio session for recording...")
        
        let audioSession = AVAudioSession.sharedInstance()
        
        // Only configure if not already configured
        if !isAudioSessionConfigured {
            do {
                try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
                isAudioSessionConfigured = true
                print("✅ Audio session category configured")
            } catch {
                print("❌ Failed to configure audio session category: \(error)")
                throw error
            }
        }
        
        // Always activate (fast operation)
        do {
            try audioSession.setActive(true)
            print("✅ Audio session activated")
        } catch {
            print("❌ Failed to activate audio session: \(error)")
            throw error
        }
    }
    
    func deactivateAudioSession() {
        print("🔇 Deactivating audio session...")
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            print("✅ Audio session deactivated successfully")
        } catch {
            print("❌ Failed to deactivate audio session: \(error)")
        }
    }
    
    // MARK: - User-Friendly Status Messages
    
    func getPermissionStatusMessage() -> String {
        switch permissionStatus {
        case .granted:
            return "Microphone access granted"
        case .denied:
            return "Microphone access denied. Please enable in Settings > Privacy & Security > Microphone"
        case .undetermined:
            return "Microphone access not yet requested"
        @unknown default:
            return "Unknown microphone permission status"
        }
    }
    
    func getPermissionStatusTitle() -> String {
        switch permissionStatus {
        case .granted:
            return "Ready to Record"
        case .denied:
            return "Microphone Access Required"
        case .undetermined:
            return "Microphone Permission"
        @unknown default:
            return "Permission Status Unknown"
        }
    }
}
