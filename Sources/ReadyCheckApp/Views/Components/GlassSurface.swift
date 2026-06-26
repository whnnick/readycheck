import SwiftUI

struct GlassSurface<Content: View>: View {
    private let cornerRadius: CGFloat
    private let content: Content

    init(cornerRadius: CGFloat = 18, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(12)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.36), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.16), lineWidth: 0.8)
            }
            .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 8)
    }
}
