import SwiftUI

enum GlassSurfaceRenderingMode {
    case material
    case staticSurface
}

struct GlassSurface<Content: View>: View {
    private let cornerRadius: CGFloat
    private let renderingMode: GlassSurfaceRenderingMode
    private let content: Content

    init(
        cornerRadius: CGFloat = 18,
        renderingMode: GlassSurfaceRenderingMode = .material,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.renderingMode = renderingMode
        self.content = content()
    }

    var body: some View {
        content
            .padding(12)
            .background {
                surfaceBackground
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.16), lineWidth: 0.8)
            }
            .shadow(
                color: .black.opacity(renderingMode == .material ? 0.12 : 0.08),
                radius: renderingMode == .material ? 14 : 7,
                x: 0,
                y: renderingMode == .material ? 8 : 3
            )
    }

    @ViewBuilder
    private var surfaceBackground: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        switch renderingMode {
        case .material:
            shape
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.36))
                .background(.regularMaterial, in: shape)
        case .staticSurface:
            shape
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.92))
        }
    }
}
