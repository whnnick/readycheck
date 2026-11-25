import AppKit
import SwiftUI

enum GlassCapsuleKind {
    case selection, insetSelection, rail
}

struct GlassCapsuleSurface: View {
    var kind: GlassCapsuleKind = .selection
    var focused = false

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        material
            .overlay {
                Capsule().strokeBorder(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [.white.opacity(0.49), .white.opacity(0.13), .white.opacity(0.25)]
                            : [.white.opacity(0.95), .primary.opacity(0.12), .white.opacity(0.68)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.75
                )
            }
            .overlay {
                if focused {
                    Capsule().strokeBorder(Color(nsColor: .keyboardFocusIndicatorColor), lineWidth: 1.25)
                }
            }
            .accessibilityHidden(true)
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private var material: some View {
        let shape = Capsule()
        if reduceTransparency {
            let background = NSColor.windowBackgroundColor
            let color = kind == .rail ? background
                : background.blended(withFraction: 0.17, of: .controlAccentColor) ?? .controlBackgroundColor
            shape.fill(Color(nsColor: color))
        } else if kind == .rail {
            // Keep quota readings legible over desktop wallpapers and other app windows.
            shape.fill(.regularMaterial)
                .overlay {
                    shape.fill(colorScheme == .dark ? Color(white: 0.09).opacity(0.46) : .white.opacity(0.28))
                }
        } else if kind == .insetSelection {
            // The rail already provides the backdrop material.
            shape.fill(.primary.opacity(colorScheme == .dark ? 0.17 : 0.10))
        } else {
            Group {
                if #available(macOS 26, *) {
                    shape.fill(.clear).glassEffect(.regular, in: shape)
                } else {
                    shape.fill(.regularMaterial)
                }
            }
            .overlay { shape.fill(.primary.opacity(0.08)) }
        }
    }
}

private struct GlassCapsuleAnchors<ID: Hashable>: PreferenceKey {
    static var defaultValue: [ID: Anchor<CGRect>] { [:] }

    static func reduce(value: inout [ID: Anchor<CGRect>], nextValue: () -> [ID: Anchor<CGRect>]) {
        value.merge(nextValue()) { _, newest in newest }
    }
}

extension View {
    func glassCapsuleItem<ID: Hashable>(_ id: ID) -> some View {
        anchorPreference(key: GlassCapsuleAnchors<ID>.self, value: .bounds) { [id: $0] }
    }

    func glassCapsuleSelection<ID: Hashable>(
        _ selection: ID?, axis: Axis, kind: GlassCapsuleKind = .selection, focused: Bool = false
    ) -> some View {
        backgroundPreferenceValue(GlassCapsuleAnchors<ID>.self) { anchors in
            GeometryReader { geometry in
                let destination = selection.flatMap { id in
                    anchors[id].map { GlassCapsuleDestination(id: id, frame: geometry[$0]) }
                }
                GlassCapsuleIndicator(
                    destination: destination,
                    axis: axis,
                    kind: kind,
                    focused: focused
                )
            }
            .accessibilityHidden(true)
            .allowsHitTesting(false)
        }
    }
}

private struct GlassCapsuleDestination<ID: Hashable>: Equatable {
    let id: ID
    let frame: CGRect
}

private struct GlassCapsuleTransition<ID: Hashable>: Equatable {
    let destination: GlassCapsuleDestination<ID>?
    let reduceMotion: Bool
}

private struct GlassCapsuleIndicator<ID: Hashable>: View {
    let destination: GlassCapsuleDestination<ID>?
    let axis: Axis
    let kind: GlassCapsuleKind
    let focused: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var motion: GlassCapsuleMotion?
    @State private var previousID: ID?

    var body: some View {
        Group {
            if let destination {
                let target = destination.frame
                let frame = reduceMotion ? target : motion?.frame(fitting: target, axis: axis) ?? target
                GlassCapsuleSurface(kind: kind, focused: focused)
                    .frame(width: frame.width, height: frame.height)
                    .position(x: frame.midX, y: frame.midY)
            }
        }
        .transaction { $0.animation = nil }
        .task(id: GlassCapsuleTransition(destination: destination, reduceMotion: reduceMotion)) {
            await move()
        }
    }

    private func move() async {
        guard !Task.isCancelled else { return }
        let lastID = previousID
        previousID = destination?.id
        guard let destination else {
            motion = nil
            return
        }
        let target = destination.frame
        guard var state = motion, !reduceMotion, lastID != destination.id else {
            motion = GlassCapsuleMotion(frame: target, axis: axis)
            return
        }
        let clock = ContinuousClock()
        var last = clock.now
        while !state.isAtRest(at: target, axis: axis) {
            do { try await clock.sleep(until: last + .milliseconds(16)) }
            catch { return }
            guard !Task.isCancelled, !reduceMotion else { return }
            let timestamp = clock.now
            let duration = (timestamp - last).components
            last = timestamp
            state.advance(
                toward: target, axis: axis,
                seconds: CGFloat(duration.seconds) + CGFloat(duration.attoseconds) / 1e18
            )
            motion = state
        }
        motion = GlassCapsuleMotion(frame: target, axis: axis)
    }
}

struct GlassCapsuleMotion {
    private(set) var position: CGFloat
    private(set) var velocity: CGFloat = 0
    private(set) var stretch: CGFloat = 0
    private var stretchVelocity: CGFloat = 0

    init(frame: CGRect, axis: Axis) {
        position = Self.center(of: frame, axis: axis)
    }

    mutating func advance(toward target: CGRect, axis: Axis, seconds: CGFloat) {
        let duration = min(max(0, seconds), 0.04)
        let count = max(1, Int(ceil(duration * 180)))
        let step = duration / CGFloat(count)
        let center = Self.center(of: target, axis: axis)
        let limit: CGFloat = axis == .horizontal ? 17 : 13
        let stretchResistance: CGFloat = axis == .horizontal ? 66 : 58

        for _ in 0..<count {
            velocity += (390 * (center - position) - 29.5 * velocity) * step
            position += velocity * step

            let desiredStretch = min(limit, max(-limit, velocity / stretchResistance))
            stretchVelocity += (560 * (desiredStretch - stretch) - 35 * stretchVelocity) * step
            stretch += stretchVelocity * step
        }
    }

    func frame(fitting target: CGRect, axis: Axis) -> CGRect {
        let length = (axis == .horizontal ? target.width : target.height) + abs(stretch)
        let origin = position - length / 2 + stretch * 0.23
        if axis == .horizontal {
            return CGRect(x: origin, y: target.minY, width: length, height: target.height)
        }
        return CGRect(x: target.minX, y: origin, width: target.width, height: length)
    }

    func isAtRest(at target: CGRect, axis: Axis) -> Bool {
        abs(position - Self.center(of: target, axis: axis)) < 0.10 && abs(velocity) < 3
            && abs(stretch) < 0.14 && abs(stretchVelocity) < 3
    }

    private static func center(of frame: CGRect, axis: Axis) -> CGFloat {
        axis == .horizontal ? frame.midX : frame.midY
    }
}
