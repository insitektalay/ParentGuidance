import SwiftUI

struct ApiKeyManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = ""
    @State private var isTestingConnection: Bool = false
    @State private var isSaving: Bool = false
    @State private var testResult: TestResult?
    @State private var showingError: Bool = false
    @State private var errorMessage: String?
    
    let userProfile: UserProfile
    let onApiKeySaved: () -> Void
    
    enum TestResult {
        case success
        case failure(String)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header section
                    VStack(spacing: 8) {
                        Text("API Key Management")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(ColorPalette.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Manage your OpenAI API key for personalized AI responses")
                            .font(.body)
                            .foregroundColor(ColorPalette.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, 24)
                    
                    // Current API Key Status
                    VStack(spacing: 16) {
                        HStack {
                            Text("Current Status")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(ColorPalette.white)
                            
                            Spacer()
                        }
                        
                        HStack {
                            Text("API Key")
                                .font(.system(size: 14))
                                .foregroundColor(ColorPalette.white.opacity(0.9))
                            
                            Spacer()
                            
                            Text(formatCurrentApiKey())
                                .font(.system(size: 14, family: .monospaced))
                                .foregroundColor(ColorPalette.white.opacity(0.7))
                        }
                        
                        if let testResult = testResult {
                            HStack {
                                Text("Connection")
                                    .font(.system(size: 14))
                                    .foregroundColor(ColorPalette.white.opacity(0.9))
                                
                                Spacer()
                                
                                switch testResult {
                                case .success:
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Connected")
                                            .foregroundColor(.green)
                                    }
                                    .font(.system(size: 14))
                                    
                                case .failure(let error):
                                    HStack(spacing: 4) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                        Text("Failed")
                                            .foregroundColor(.red)
                                    }
                                    .font(.system(size: 14))
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(ColorPalette.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)
                    
                    // API Key Input
                    VStack(spacing: 16) {
                        HStack {
                            Text("Update API Key")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(ColorPalette.white)
                            
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("OpenAI API Key")
                                .font(.system(size: 14))
                                .foregroundColor(ColorPalette.white.opacity(0.9))
                            
                            SecureField("sk-...", text: $apiKey)
                                .font(.system(size: 14, family: .monospaced))
                                .foregroundColor(ColorPalette.navy)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(ColorPalette.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(ColorPalette.terracotta.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        HStack(spacing: 12) {
                            Button(isTestingConnection ? "Testing..." : "Test Connection") {
                                Task {
                                    await testApiKey()
                                }
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ColorPalette.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(isValidApiKey && !isTestingConnection ? ColorPalette.brightBlue : ColorPalette.white.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .disabled(!isValidApiKey || isTestingConnection)
                            
                            Spacer()
                        }
                    }
                    .padding(16)
                    .background(ColorPalette.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 100)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ColorPalette.navy)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(ColorPalette.white.opacity(0.8))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isSaving ? "Saving..." : "Save") {
                        Task {
                            await saveApiKey()
                        }
                    }
                    .foregroundColor(isValidApiKey && !isSaving ? ColorPalette.terracotta : ColorPalette.white.opacity(0.5))
                    .disabled(!isValidApiKey || isSaving)
                }
            }
        }
        .onAppear {
            loadCurrentApiKey()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {
                showingError = false
            }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
    }
    
    // MARK: - API Key Validation
    
    private var isValidApiKey: Bool {
        apiKey.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("sk-") &&
        apiKey.trimmingCharacters(in: .whitespacesAndNewlines).count >= 20
    }
    
    // MARK: - Data Loading
    
    private func loadCurrentApiKey() {
        if let currentKey = userProfile.userApiKey, !currentKey.isEmpty {
            // Don't load the actual key for security, just show it exists
            apiKey = ""
        }
    }
    
    private func formatCurrentApiKey() -> String {
        if let currentKey = userProfile.userApiKey, !currentKey.isEmpty {
            // Show only first and last few characters for security
            let prefix = String(currentKey.prefix(7)) // "sk-" + 4 chars
            let suffix = String(currentKey.suffix(4))
            return "\(prefix)...\(suffix)"
        } else {
            return "Not configured"
        }
    }
    
    // MARK: - API Key Testing
    
    private func testApiKey() async {
        guard isValidApiKey else { return }
        
        await MainActor.run {
            isTestingConnection = true
            testResult = nil
        }
        
        // Simple test: try to make a basic request to OpenAI API
        do {
            let url = URL(string: "https://api.openai.com/v1/models")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))", forHTTPHeaderField: "Authorization")
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            await MainActor.run {
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        testResult = .success
                    } else {
                        testResult = .failure("HTTP \(httpResponse.statusCode)")
                    }
                } else {
                    testResult = .failure("Invalid response")
                }
                isTestingConnection = false
            }
            
        } catch {
            await MainActor.run {
                testResult = .failure(error.localizedDescription)
                isTestingConnection = false
            }
        }
    }
    
    // MARK: - API Key Saving
    
    private func saveApiKey() async {
        guard isValidApiKey else { return }
        
        await MainActor.run {
            isSaving = true
            errorMessage = nil
        }
        
        do {
            let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            try await AuthService.shared.saveApiKey(trimmedKey, userId: userProfile.id)
            
            await MainActor.run {
                isSaving = false
                onApiKeySaved()
                dismiss()
            }
            
        } catch {
            await MainActor.run {
                isSaving = false
                errorMessage = "Failed to save API key: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
}

#Preview {
    ApiKeyManagementView(
        userProfile: UserProfile(from: try! JSONDecoder().decode(UserProfile.self, from: """
        {
            "id": "test-id",
            "email": "test@example.com",
            "selected_plan": "api",
            "user_api_key": "sk-test12345678901234567890abcdef",
            "api_key_provider": "openai",
            "plan_setup_complete": "true",
            "child_details_complete": "true",
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!)),
        onApiKeySaved: {}
    )
}