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
    
    private init() {}
    
    // MARK: - Permission Status
    
    var permissionStatus: AVAudioSession.RecordPermission {
        return AVAudioSession.sharedInstance().recordPermission
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
                } else {
                    print("❌ Microphone permission denied by user")
                }
                continuation.resume(returning: granted)
            }
        }
    }
    
    // MARK: - Permission Check with Request
    
    func checkAndRequestPermission() async -> Bool {
        print("🔍 Checking microphone permission status...")
        
        switch permissionStatus {
        case .granted:
            print("✅ Microphone permission already granted")
            return true
            
        case .denied:
            print("❌ Microphone permission denied - user needs to enable in Settings")
            return false
            
        case .undetermined:
            print("❓ Microphone permission undetermined - requesting...")
            return await requestMicrophonePermission()
            
        @unknown default:
            print("⚠️ Unknown microphone permission status")
            return false
        }
    }
    
    // MARK: - Audio Session Configuration
    
    func configureAudioSession() throws {
        print("🎵 Configuring audio session for recording...")
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
            print("✅ Audio session configured successfully")
        } catch {
            print("❌ Failed to configure audio session: \(error)")
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
