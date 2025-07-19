import SwiftUI

struct APIKeyView: View {
    @State private var apiKey: String = ""
    
    let onTestConnection: (String) -> Void
    let onSaveAndContinue: (String) -> Void
    let onGetAPIKey: () -> Void
    let onWhatsThis: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 8) {
                        Text(String(localized: "apiKey.title"))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(ColorPalette.white)
                            .multilineTextAlignment(.center)
                        
                        Text(String(localized: "apiKey.subtitle"))
                            .font(.body)
                            .foregroundColor(ColorPalette.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 80)
                    .padding(.horizontal, 24)
                    
                    VStack(spacing: 16) {
                        TextField(String(localized: "apiKey.placeholder"), text: $apiKey)
                            .font(.system(size: 16))
                            .foregroundColor(ColorPalette.navy)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(ColorPalette.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Button(action: { onTestConnection(apiKey) }) {
                            Text(String(localized: "apiKey.testConnection"))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(ColorPalette.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(ColorPalette.terracotta)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button(action: { onSaveAndContinue(apiKey) }) {
                            Text(String(localized: "apiKey.saveAndContinue"))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(ColorPalette.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(ColorPalette.terracotta)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
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
                    .foregroundColor(ColorPalette.white.opacity(0.9))
                
                HStack(spacing: 16) {
                    Button(action: onGetAPIKey) {
                        Text(String(localized: "apiKey.getKey"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ColorPalette.terracotta)
                    }
                    
                    Button(action: onWhatsThis) {
                        Text(String(localized: "apiKey.whatsThis"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ColorPalette.terracotta)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.navy)
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
