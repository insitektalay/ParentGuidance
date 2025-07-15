//
//  VoiceRecorderDelegate.swift
//  ParentGuidance
//
//  Created by alex kerss on 14/07/2025.
//

import Foundation

// MARK: - Voice Recorder Delegate Protocol

protocol VoiceRecorderDelegate: AnyObject {
    
    // MARK: - Recording Lifecycle Events
    
    /// Called when recording is about to start
    /// - Parameter recorder: The voice recorder service instance
    func voiceRecorderWillStartRecording(_ recorder: VoiceRecorderService)
    
    /// Called when recording has successfully started
    /// - Parameters:
    ///   - recorder: The voice recorder service instance
    ///   - fileURL: The URL where the recording is being saved
    func voiceRecorderDidStartRecording(_ recorder: VoiceRecorderService, fileURL: URL)
    
    /// Called when recording has been stopped successfully
    /// - Parameters:
    ///   - recorder: The voice recorder service instance
    ///   - fileURL: The URL of the completed recording file
    ///   - duration: The total duration of the recording in seconds
    func voiceRecorderDidStopRecording(_ recorder: VoiceRecorderService, fileURL: URL, duration: TimeInterval)
    
    /// Called when recording has been canceled
    /// - Parameter recorder: The voice recorder service instance
    func voiceRecorderDidCancelRecording(_ recorder: VoiceRecorderService)
    
    // MARK: - Transcription Events
    
    /// Called when transcription is about to start
    /// - Parameters:
    ///   - recorder: The voice recorder service instance
    ///   - fileURL: The URL of the file being transcribed
    func voiceRecorderWillStartTranscription(_ recorder: VoiceRecorderService, fileURL: URL)
    
    /// Called when transcription has completed successfully
    /// - Parameters:
    ///   - recorder: The voice recorder service instance
    ///   - transcription: The transcribed text from the audio
    ///   - fileURL: The URL of the original audio file
    func voiceRecorderDidCompleteTranscription(_ recorder: VoiceRecorderService, transcription: String, fileURL: URL)
    
    /// Called when the complete record-and-transcribe flow has finished
    /// - Parameters:
    ///   - recorder: The voice recorder service instance
    ///   - transcription: The final transcribed text
    ///   - fileURL: The URL of the recording file
    ///   - duration: The total recording duration in seconds
    func voiceRecorderDidCompleteRecordingAndTranscription(_ recorder: VoiceRecorderService, transcription: String, fileURL: URL, duration: TimeInterval)
    
    // MARK: - Error Handling
    
    /// Called when any error occurs during recording or transcription
    /// - Parameters:
    ///   - recorder: The voice recorder service instance
    ///   - error: The specific error that occurred
    func voiceRecorderDidEncounterError(_ recorder: VoiceRecorderService, error: VoiceRecorderError)
    
    // MARK: - Progress Updates
    
    /// Called periodically during recording to provide duration updates
    /// - Parameters:
    ///   - recorder: The voice recorder service instance
    ///   - duration: The current recording duration in seconds
    func voiceRecorderDidUpdateRecordingDuration(_ recorder: VoiceRecorderService, duration: TimeInterval)
    
    /// Called to provide progress updates during transcription (if available)
    /// - Parameters:
    ///   - recorder: The voice recorder service instance
    ///   - progress: Progress value between 0.0 and 1.0 (optional, may not be available for all operations)
    func voiceRecorderDidUpdateTranscriptionProgress(_ recorder: VoiceRecorderService, progress: Float?)
}

// MARK: - Default Protocol Implementation

extension VoiceRecorderDelegate {
    
    // Provide default empty implementations for optional delegate methods
    // This allows conforming classes to only implement the methods they need
    
    func voiceRecorderWillStartRecording(_ recorder: VoiceRecorderService) {
        // Default implementation - override if needed
    }
    
    func voiceRecorderDidUpdateRecordingDuration(_ recorder: VoiceRecorderService, duration: TimeInterval) {
        // Default implementation - override if needed
    }
    
    func voiceRecorderDidUpdateTranscriptionProgress(_ recorder: VoiceRecorderService, progress: Float?) {
        // Default implementation - override if needed
    }
    
    func voiceRecorderWillStartTranscription(_ recorder: VoiceRecorderService, fileURL: URL) {
        // Default implementation - override if needed
    }
    
    func voiceRecorderDidCancelRecording(_ recorder: VoiceRecorderService) {
        // Default implementation - override if needed
    }
}

// MARK: - Convenience Protocol for Simple Use Cases

/// Simplified delegate protocol for basic voice-to-text functionality
/// Use this when you only need the final transcription result
protocol SimpleVoiceRecorderDelegate: AnyObject {
    
    /// Called when voice recording and transcription is complete
    /// - Parameters:
    ///   - transcription: The final transcribed text
    ///   - success: Whether the operation completed successfully
    func voiceRecorderDidFinish(transcription: String?, success: Bool)
    
    /// Called when an error occurs
    /// - Parameter error: The error that occurred
    func voiceRecorderDidFail(with error: VoiceRecorderError)
}

// MARK: - Bridge Between Full and Simple Delegate

extension VoiceRecorderService {
    
    /// Convenience method to set a simple delegate that will receive basic callbacks
    /// This creates a bridge to the full delegate protocol
    func setSimpleDelegate(_ simpleDelegate: SimpleVoiceRecorderDelegate) {
        // This would be implemented in the service to bridge between protocols
        // For now, this is a placeholder for the pattern
    }
}
