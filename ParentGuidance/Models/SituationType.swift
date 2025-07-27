//
//  SituationType.swift
//  ParentGuidance
//
//  Created by alex kerss on 24/07/2025.
//

import Foundation

enum SituationType: String, CaseIterable {
    case justLetMeType = "just_let_me_type"
    case crisisNow = "crisis_now"
    case whatJustHappened = "what_just_happened"
    case foundationalWork = "foundational_work"
    case teachMeATactic = "teach_me_a_tactic"
    case knowMyChild = "know_my_child"
    case rebuildConnection = "rebuild_connection"
    case imJustWondering = "im_just_wondering"
    
    var emoji: String {
        switch self {
        case .justLetMeType: return "📝"
        case .crisisNow: return "🔥"
        case .whatJustHappened: return "🌪️"
        case .foundationalWork: return "🧱"
        case .teachMeATactic: return "🪥"
        case .knowMyChild: return "👧"
        case .rebuildConnection: return "🤝"
        case .imJustWondering: return "🤔"
        }
    }
    
    var titleKey: String {
        switch self {
        case .justLetMeType: return "situation.type.justLetMeType.title"
        case .crisisNow: return "situation.type.crisisNow.title"
        case .whatJustHappened: return "situation.type.whatJustHappened.title"
        case .foundationalWork: return "situation.type.foundationalWork.title"
        case .teachMeATactic: return "situation.type.teachMeATactic.title"
        case .knowMyChild: return "situation.type.knowMyChild.title"
        case .rebuildConnection: return "situation.type.rebuildConnection.title"
        case .imJustWondering: return "situation.type.imJustWondering.title"
        }
    }
    
    var subtitleKey: String {
        switch self {
        case .justLetMeType: return "situation.type.justLetMeType.subtitle"
        case .crisisNow: return "situation.type.crisisNow.subtitle"
        case .whatJustHappened: return "situation.type.whatJustHappened.subtitle"
        case .foundationalWork: return "situation.type.foundationalWork.subtitle"
        case .teachMeATactic: return "situation.type.teachMeATactic.subtitle"
        case .knowMyChild: return "situation.type.knowMyChild.subtitle"
        case .rebuildConnection: return "situation.type.rebuildConnection.subtitle"
        case .imJustWondering: return "situation.type.imJustWondering.subtitle"
        }
    }
    
    /// Get the guidance note for this situation type to provide context to the AI
    var guidanceNote: String {
        switch self {
        case .justLetMeType: return "Respond naturally based on the situation text. No assumptions about urgency, tone, or structure."
        case .crisisNow: return "This is an urgent, emotionally intense moment. Provide fast, calming, practical guidance with empathy."
        case .whatJustHappened: return "Reflect on the recent moment with insight. Help the parent understand what might have happened internally for the child and offer suggestions for next time."
        case .foundationalWork: return "Address a deeper trait or pattern. Focus on long-term development, emotional growth, and internal change."
        case .teachMeATactic: return "Give step-by-step, practical suggestions to resolve everyday struggles with warmth and realism."
        case .knowMyChild: return "The user is offering background info. Focus on understanding the child better to inform future guidance."
        case .rebuildConnection: return "Help the parent repair emotional connection. Emphasize empathy, trust-building, and emotional safety."
        case .imJustWondering: return "This is a non-urgent question. Offer thoughtful, curious, and informative guidance that supports reflective parenting."
        }
    }
}