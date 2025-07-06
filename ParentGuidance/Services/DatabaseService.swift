//
//  DatabaseService.swift
//  ParentGuidance
//
//  Created by alex kerss on 06/07/2025.
//

import Foundation
import Supabase

// MARK: - DatabaseService
// Base database service for shared functionality (future expansion)
class DatabaseService: ObservableObject {
    static let shared = DatabaseService()
    private init() {}
    
    // Future: Add shared database utilities, connection management, etc.
    var client: SupabaseClient {
        return SupabaseManager.shared.client
    }
}
