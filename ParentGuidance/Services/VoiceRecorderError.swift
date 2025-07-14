//
//  VoiceRecorderError.swift
//  ParentGuidance
//
//  Created by alex kerss on 14/07/2025.
//

import Foundation

// MARK: - Voice Recorder Error Types

enum VoiceRecorderError: Error, Equatable {
    case permissionDenied
    case permissionUndetermined
    case audioSessionConfigurationFailed(Error)
    case recordingInitializationFailed(Error)
    case recordingFailed(Error)
    case recordingNotStarted
    case recordingAlreadyInProgress
    case fileNotFound
    case fileTooLarge(sizeInMB: Double)
    case invalidFileFormat
    case transcriptionFailed(Error)
    case noTranscriptionContent
    case apiKeyMissing
    case networkError(Error)
    case invalidResponse
    case unknown(Error)
    
    static func == (lhs: VoiceRecorderError, rhs: VoiceRecorderError) -> Bool {
        switch (lhs, rhs) {
        case (.permissionDenied, .permissionDenied),
             (.permissionUndetermined, .permissionUndetermined),
             (.recordingNotStarted, .recordingNotStarted),
             (.recordingAlreadyInProgress, .recordingAlreadyInProgress),
             (.fileNotFound, .fileNotFound),
             (.invalidFileFormat, .invalidFileFormat),
             (.noTranscriptionContent, .noTranscriptionContent),
             (.apiKeyMissing, .apiKeyMissing),
             (.invalidResponse, .invalidResponse):
            return true
        case (.fileTooLarge(let lhsSize), .fileTooLarge(let rhsSize)):
            return lhsSize == rhsSize
        case (.audioSessionConfigurationFailed, .audioSessionConfigurationFailed),
             (.recordingInitializationFailed, .recordingInitializationFailed),
             (.recordingFailed, .recordingFailed),
             (.transcriptionFailed, .transcriptionFailed),
             (.networkError, .networkError),
             (.unknown, .unknown):
            return true // For Error types, we consider them equal if they're the same case
        default:
            return false
        }
    }
}

// MARK: - Error Descriptions

extension VoiceRecorderError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission denied"
        case .permissionUndetermined:
            return "Microphone permission not requested"
        case .audioSessionConfigurationFailed(let error):
            return "Audio session configuration failed: \(error.localizedDescription)"
        case .recordingInitializationFailed(let error):
            return "Recording initialization failed: \(error.localizedDescription)"
        case .recordingFailed(let error):
            return "Recording failed: \(error.localizedDescription)"
        case .recordingNotStarted:
            return "Recording has not been started"
        case .recordingAlreadyInProgress:
            return "Recording is already in progress"
        case .fileNotFound:
            return "Audio file not found"
        case .fileTooLarge(let sizeInMB):
            return "Audio file too large: \(String(format: "%.1f", sizeInMB))MB (max 25MB)"
        case .invalidFileFormat:
            return "Invalid audio file format"
        case .transcriptionFailed(let error):
            return "Transcription failed: \(error.localizedDescription)"
        case .noTranscriptionContent:
            return "No transcription content received"
        case .apiKeyMissing:
            return "OpenAI API key missing"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from transcription service"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .permissionDenied:
            return "The app needs microphone permission to record audio"
        case .permissionUndetermined:
            return "Microphone permission has not been requested yet"
        case .audioSessionConfigurationFailed:
            return "Failed to configure the audio session for recording"
        case .recordingInitializationFailed:
            return "Failed to initialize the audio recorder"
        case .recordingFailed:
            return "An error occurred during recording"
        case .recordingNotStarted:
            return "Attempted to stop recording when no recording was active"
        case .recordingAlreadyInProgress:
            return "Cannot start recording while another recording is active"
        case .fileNotFound:
            return "The recorded audio file could not be found"
        case .fileTooLarge:
            return "The audio file exceeds the maximum size limit for transcription"
        case .invalidFileFormat:
            return "The audio file format is not supported"
        case .transcriptionFailed:
            return "Failed to transcribe the audio file"
        case .noTranscriptionContent:
            return "The transcription service returned no content"
        case .apiKeyMissing:
            return "OpenAI API key is required for transcription"
        case .networkError:
            return "Network connectivity issue"
        case .invalidResponse:
            return "Received an invalid response from the transcription service"
        case .unknown:
            return "An unexpected error occurred"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Go to Settings > Privacy & Security > Microphone to enable permission"
        case .permissionUndetermined:
            return "The app will request microphone permission when needed"
        case .audioSessionConfigurationFailed:
            return "Try restarting the app or your device"
        case .recordingInitializationFailed:
            return "Close other apps that might be using the microphone"
        case .recordingFailed:
            return "Try recording again or restart the app"
        case .recordingNotStarted:
            return "Start recording first before attempting to stop"
        case .recordingAlreadyInProgress:
            return "Stop the current recording before starting a new one"
        case .fileNotFound:
            return "Try recording again"
        case .fileTooLarge:
            return "Try recording a shorter audio clip"
        case .invalidFileFormat:
            return "Try recording again with a supported format"
        case .transcriptionFailed:
            return "Check your internet connection and try again"
        case .noTranscriptionContent:
            return "Try speaking more clearly or recording again"
        case .apiKeyMissing:
            return "Configure your OpenAI API key in Settings"
        case .networkError:
            return "Check your internet connection and try again"
        case .invalidResponse:
            return "Try again or check your API key configuration"
        case .unknown:
            return "Try again or restart the app"
        }
    }
}

// MARK: - User-Friendly Messages

extension VoiceRecorderError {
    var userFriendlyTitle: String {
        switch self {
        case .permissionDenied:
            return "Microphone Access Required"
        case .permissionUndetermined:
            return "Microphone Permission"
        case .audioSessionConfigurationFailed:
            return "Audio Setup Failed"
        case .recordingInitializationFailed:
            return "Recording Setup Failed"
        case .recordingFailed:
            return "Recording Failed"
        case .recordingNotStarted:
            return "Recording Not Started"
        case .recordingAlreadyInProgress:
            return "Recording In Progress"
        case .fileNotFound:
            return "Audio File Missing"
        case .fileTooLarge:
            return "File Too Large"
        case .invalidFileFormat:
            return "Invalid Audio Format"
        case .transcriptionFailed:
            return "Transcription Failed"
        case .noTranscriptionContent:
            return "No Text Generated"
        case .apiKeyMissing:
            return "API Key Required"
        case .networkError:
            return "Connection Error"
        case .invalidResponse:
            return "Service Error"
        case .unknown:
            return "Unexpected Error"
        }
    }
    
    var userFriendlyMessage: String {
        switch self {
        case .permissionDenied:
            return "Please enable microphone access in Settings to use voice recording."
        case .permissionUndetermined:
            return "This app needs microphone access to record your voice."
        case .audioSessionConfigurationFailed:
            return "There was a problem setting up audio recording. Please try again."
        case .recordingInitializationFailed:
            return "Could not start recording. Make sure no other app is using the microphone."
        case .recordingFailed:
            return "Recording stopped unexpectedly. Please try again."
        case .recordingNotStarted:
            return "No recording is currently active."
        case .recordingAlreadyInProgress:
            return "A recording is already in progress. Please stop it first."
        case .fileNotFound:
            return "Could not find the recorded audio. Please try recording again."
        case .fileTooLarge(let sizeInMB):
            return "Recording is too long (\(String(format: "%.1f", sizeInMB))MB). Please try a shorter recording."
        case .invalidFileFormat:
            return "The audio format is not supported. Please try recording again."
        case .transcriptionFailed:
            return "Could not convert your speech to text. Please check your connection and try again."
        case .noTranscriptionContent:
            return "No speech was detected. Please try speaking more clearly."
        case .apiKeyMissing:
            return "OpenAI API key is required for speech-to-text. Please configure it in Settings."
        case .networkError:
            return "Please check your internet connection and try again."
        case .invalidResponse:
            return "There was a problem with the transcription service. Please try again."
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }
}
