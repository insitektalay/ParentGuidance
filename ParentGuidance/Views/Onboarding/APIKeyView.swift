import SwiftUI

struct APIKeyView: View {
    @State private var apiKey: String = ""
    
    let onTestConnection: () -> Void
    let onSaveAndContinue: () -> Void
    let onGetAPIKey: () -> Void
    let onWhatsThis: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 8) {
                        Text("Enter Your OpenAI API Key")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(ColorPalette.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Your key is stored securely and only used for your guidance")
                            .font(.body)
                            .foregroundColor(ColorPalette.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 80)
                    .padding(.horizontal, 24)
                    
                    VStack(spacing: 16) {
                        TextField("sk-...", text: $apiKey)
                            .font(.system(size: 16))
                            .foregroundColor(ColorPalette.navy)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(ColorPalette.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Button(action: onTestConnection) {
                            Text("Test Connection")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(ColorPalette.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(ColorPalette.terracotta)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button(action: onSaveAndContinue) {
                            Text("Save and Continue")
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
                Text("Need an API key?")
                    .font(.system(size: 14))
                    .foregroundColor(ColorPalette.white.opacity(0.9))
                
                HStack(spacing: 16) {
                    Button(action: onGetAPIKey) {
                        Text("Get OpenAI API Key")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ColorPalette.terracotta)
                    }
                    
                    Button(action: onWhatsThis) {
                        Text("What's this?")
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
        onTestConnection: {},
        onSaveAndContinue: {},
        onGetAPIKey: {},
        onWhatsThis: {}
    )
}
