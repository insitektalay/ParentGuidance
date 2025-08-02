import SwiftUI

struct APIKeyView: View {
    @State private var apiKey: String = ""
    
    let onTestConnection: (String) -> Void
    let onSaveAndContinue: (String) -> Void
    let onGetAPIKey: () -> Void
    let onWhatsThis: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 8) {
                        Text(String(localized: "apiKey.title"))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(SemanticColors.primaryText)
                            .multilineTextAlignment(.center)
                        
                        Text(String(localized: "apiKey.subtitle"))
                            .font(.body)
                            .foregroundColor(SemanticColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 80)
                    .padding(.horizontal, 24)
                    
                    VStack(spacing: 16) {
                        TextField(String(localized: "apiKey.placeholder"), text: $apiKey)
                            .font(.system(size: 16))
                            .foregroundColor(SemanticColors.primaryBackground)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(SemanticColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .if(colorScheme == .light) { view in view.cardShadow() }
                        
                        Button(action: { onTestConnection(apiKey) }) {
                            Text(String(localized: "apiKey.testConnection"))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(SemanticColors.primaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(SemanticColors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .if(colorScheme == .light) { view in view.cardShadow() }
                        }
                        
                        Button(action: { onSaveAndContinue(apiKey) }) {
                            Text(String(localized: "apiKey.saveAndContinue"))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(SemanticColors.primaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(SemanticColors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .if(colorScheme == .light) { view in view.cardShadow() }
                        }
                    }
                    .padding(.top, 32)
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 150)
                }
            }
            
            VStack(spacing: 8) {
                Text(String(localized: "apiKey.needKey"))
                    .font(.system(size: 14))
                    .foregroundColor(SemanticColors.secondaryText)
                
                HStack(spacing: 16) {
                    Button(action: onGetAPIKey) {
                        Text(String(localized: "apiKey.getKey"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(SemanticColors.accent)
                    }
                    
                    Button(action: onWhatsThis) {
                        Text(String(localized: "apiKey.whatsThis"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(SemanticColors.accent)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SemanticColors.primaryBackground)
        .ignoresSafeArea()
    }
}

#Preview {
    APIKeyView(
        onTestConnection: { _ in },
        onSaveAndContinue: { _ in },
        onGetAPIKey: {},
        onWhatsThis: {}
    )
}
