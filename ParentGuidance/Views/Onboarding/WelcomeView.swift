import SwiftUI

struct PhoneIllustration: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(ColorPalette.white)
                .frame(width: 128, height: 192)
                .shadow(radius: 8)
            
            Circle()
                .fill(Color(hex: "FF8A65"))
                .frame(width: 96, height: 96)
                .overlay(
                    ZStack {
                        HStack(spacing: 18) {
                            Circle()
                                .fill(ColorPalette.navy)
                                .frame(width: 12, height: 12)
                            Circle()
                                .fill(ColorPalette.navy)
                                .frame(width: 12, height: 12)
                        }
                        .offset(y: -12)
                        
                        Capsule()
                            .stroke(ColorPalette.navy, lineWidth: 2)
                            .frame(width: 48, height: 24)
                            .offset(y: 12)
                            .clipShape(
                                Rectangle()
                                    .offset(y: -12)
                            )
                    }
                )
            
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 32, height: 4)
                .offset(y: -84)
        }
    }
}

struct FloatingElement: View {
    let systemName: String
    let size: CGFloat
    let position: CGPoint
    
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size))
            .foregroundColor(ColorPalette.cream)
            .position(position)
    }
}

struct FloatingShape: View {
    let shape: AnyView
    let position: CGPoint
    
    var body: some View {
        shape
            .position(position)
    }
}

struct WelcomeView: View {
    let onGetStarted: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: [ColorPalette.terracotta, Color(hex: "D9A292")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                GeometryReader { geometry in
                    let screenWidth = geometry.size.width
                    let upperHeight = geometry.size.height
                    
                    ZStack {
                        FloatingElement(
                            systemName: "star.fill",
                            size: 20,
                            position: CGPoint(x: 40, y: 40)
                        )
                        
                        FloatingElement(
                            systemName: "heart.fill",
                            size: 16,
                            position: CGPoint(x: screenWidth - 48, y: 80)
                        )
                        
                        FloatingElement(
                            systemName: "music.note",
                            size: 18,
                            position: CGPoint(x: 64, y: 144)
                        )
                        
                        FloatingElement(
                            systemName: "cloud.fill",
                            size: 22,
                            position: CGPoint(x: screenWidth - 56, y: upperHeight - 96)
                        )
                        
                        FloatingElement(
                            systemName: "star.fill",
                            size: 14,
                            position: CGPoint(x: screenWidth * 0.45, y: 112)
                        )
                        
                        FloatingShape(
                            shape: AnyView(
                                Circle()
                                    .fill(ColorPalette.cream.opacity(0.7))
                                    .frame(width: 20, height: 20)
                            ),
                            position: CGPoint(x: 48, y: upperHeight - 128)
                        )
                        
                        FloatingShape(
                            shape: AnyView(
                                Capsule()
                                    .fill(ColorPalette.cream.opacity(0.7))
                                    .frame(width: 64, height: 8)
                                    .rotationEffect(.degrees(12))
                            ),
                            position: CGPoint(x: screenWidth - 96, y: 96)
                        )
                        
                        FloatingShape(
                            shape: AnyView(
                                Circle()
                                    .stroke(ColorPalette.cream.opacity(0.7), lineWidth: 2)
                                    .frame(width: 48, height: 48)
                            ),
                            position: CGPoint(x: screenWidth - 24, y: upperHeight - 64)
                        )
                        
                        FloatingShape(
                            shape: AnyView(
                                Path { path in
                                    let width: CGFloat = 64
                                    let height: CGFloat = 32
                                    path.addArc(
                                        center: CGPoint(x: width/2, y: height),
                                        radius: width/2,
                                        startAngle: .degrees(180),
                                        endAngle: .degrees(0),
                                        clockwise: false
                                    )
                                }
                                .stroke(ColorPalette.cream.opacity(0.7), lineWidth: 4)
                                .frame(width: 64, height: 32)
                            ),
                            position: CGPoint(x: 32, y: upperHeight - 80)
                        )
                        
                        PhoneIllustration()
                            .position(x: screenWidth/2, y: upperHeight/2)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: UIScreen.main.bounds.height * 0.6)
            
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("ParentPal")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(ColorPalette.white)
                    
                    Text("Great parenting happens when you stay present and engaged with your child. Enhance your intuition—understand more, respond better.")
                        .font(.body)
                        .italic()
                        .foregroundColor(ColorPalette.white)
                        .multilineTextAlignment(.leading)
                }
                .padding(.top, 32)
                .padding(.horizontal, 32)
                
                Spacer()
                
                Button(action: onGetStarted) {
                    Text("GET STARTED")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ColorPalette.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(ColorPalette.brightBlue)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ColorPalette.navy)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    WelcomeView(onGetStarted: {})
}
