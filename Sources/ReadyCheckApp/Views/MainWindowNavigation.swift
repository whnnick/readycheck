import AppKit
import Observation
import ReadyCheckCore
import SwiftUI

enum ServiceSettingsTarget: String, CaseIterable {
    // Declaration order drives every service list. Keep raw values stable for saved settings.
    case codex, muse, deepSeek
    var title: String { switch self { case .codex: "Codex"; case .deepSeek: "DeepSeek"; case .muse: "Muse" } }
}

enum MainWindowPage: String, CaseIterable, Identifiable {
    case overview, usage, notifications, settings
    static let allCases: [MainWindowPage] = [.overview, .usage, .notifications, .settings]
    var id: String { rawValue }
    var titleKey: String { "navigation.\(rawValue)" }
    var symbol: String {
        switch self {
        case .overview: "square.grid.2x2"
        case .usage: "chart.xyaxis.line"
        case .notifications: "bell.badge"
        case .settings: "gearshape"
        }
    }
    var shortcut: String {
        switch self {
        case .overview: "1"
        case .usage: "2"
        case .notifications: "4"
        case .settings: "3"
        }
    }
}

enum MainSettingsSection: String, CaseIterable, Identifiable {
    case connection, reminders, display, general
    var id: String { rawValue }
    var titleKey: String { "navigation.\(rawValue)" }
}

struct MainWindowSidebar: View {
    @Bindable var model: ReadyCheckAppModel
    let focusAppearance: NavigationFocusAppearance
    @FocusState private var focusedPage: MainWindowPage?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 8) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable().frame(width: 30, height: 30).accessibilityHidden(true)
                Text("ReadyCheck").font(.headline)
            }
            .padding(.horizontal, 14).padding(.top, 18)
            let keyboardFocus = focusAppearance.keyboardFocus(for: focusedPage)
            VStack(spacing: 5) {
                ForEach(MainWindowPage.allCases) { page in
                    let selected = model.mainWindowPage == page
                    Button {
                        model.navigateToMainPage(page)
                        focusedPage = page
                    } label: {
                        Label(model.localization.text(page.titleKey), systemImage: page.symbol)
                            .font(.system(size: 13, weight: selected ? .semibold : .regular))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12).padding(.vertical, 10)
                            .foregroundStyle(selected ? Color.primary : Color.secondary)
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .focusable()
                    .focused($focusedPage, equals: page)
                    .navigationFocusMarker(keyboardFocus == page && !selected)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                    .glassCapsuleItem(page)
                }
            }
            .glassCapsuleSelection(model.mainWindowPage, axis: .vertical, focused: keyboardFocus == model.mainWindowPage)
            .onMoveCommand { direction in
                guard let focusedPage, let page = adjacentMenuItem(
                    to: focusedPage, in: MainWindowPage.allCases, direction: direction, axis: .vertical
                ) else { return }
                model.navigateToMainPage(page)
                self.focusedPage = page
            }
            .padding(.horizontal, 10)
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 6) {
                Text(model.selectedService.title).font(.caption.weight(.semibold))
                Text(model.selectedMuse ? model.muse.statusText(language: model.language, now: Date()) : model.selectedDeepSeek
                    ? (model.language == .zhCN ? (model.deepSeek.isConnected ? "已连接" : "未连接") : (model.deepSeek.isConnected ? "Connected" : "Not connected"))
                    : model.localization.text(model.codexOAuthStatus == .connected ? "oauth.status.connected" : "oauth.status.notConnected"))
                    .font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                Text(ReadyCheckCore.version).font(.caption2.monospacedDigit()).foregroundStyle(.tertiary)
                Button { model.showAboutWindow() } label: {
                    Label(model.localization.text("about.menuItem"), systemImage: "info.circle")
                }
                .buttonStyle(.plain)
                .font(.caption)
                .padding(.top, 6)
            }
            .padding(14)
        }
        .frame(width: 158)
        .background(.bar)
    }
}


struct MainSettingsSectionPicker: View {
    @Bindable var model: ReadyCheckAppModel
    let focusAppearance: NavigationFocusAppearance
    @FocusState private var focusedSection: MainSettingsSection?

    var body: some View {
        let keyboardFocus = focusAppearance.keyboardFocus(for: focusedSection)
        HStack(spacing: 4) {
            ForEach(MainSettingsSection.allCases) { section in
                let selected = section == model.mainSettingsSection
                Button {
                    model.mainSettingsSection = section
                    focusedSection = section
                } label: {
                    Text(model.localization.text(section.titleKey))
                        .font(.system(size: 12, weight: selected ? .semibold : .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .foregroundStyle(selected ? Color.primary : Color.secondary)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, minHeight: 30)
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .focusable()
                .focused($focusedSection, equals: section)
                .navigationFocusMarker(keyboardFocus == section && !selected)
                .accessibilityAddTraits(selected ? .isSelected : [])
                .glassCapsuleItem(section)
            }
        }
        .glassCapsuleSelection(model.mainSettingsSection, axis: .horizontal, focused: keyboardFocus == model.mainSettingsSection)
        .padding(3)
        .background(.primary.opacity(0.055), in: Capsule())
        .overlay { Capsule().strokeBorder(.primary.opacity(0.12), lineWidth: 0.75).allowsHitTesting(false) }
        .frame(maxWidth: 430)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(model.localization.text("navigation.settings"))
        .onMoveCommand { direction in
            guard let focusedSection, let section = adjacentMenuItem(
                to: focusedSection, in: MainSettingsSection.allCases, direction: direction, axis: .horizontal
            ) else { return }
            model.mainSettingsSection = section
            self.focusedSection = section
        }
    }
}

@MainActor @Observable
final class NavigationFocusAppearance {
    private var showsKeyboardFocus = false

    func record(_ event: NSEvent.EventType) {
        switch event {
        case .leftMouseDown, .rightMouseDown, .otherMouseDown:
            if showsKeyboardFocus { showsKeyboardFocus = false }
        case .keyDown:
            if !showsKeyboardFocus { showsKeyboardFocus = true }
        default:
            break
        }
    }

    func keyboardFocus<Item>(for item: Item?) -> Item? {
        showsKeyboardFocus ? item : nil
    }
}

private extension View {
    func navigationFocusMarker(_ visible: Bool) -> some View {
        focusEffectDisabled()
            .overlay(alignment: .bottom) {
                if visible {
                    Capsule().fill(Color(nsColor: .keyboardFocusIndicatorColor))
                        .frame(width: 12, height: 2)
                        .padding(.bottom, 3)
                        .accessibilityHidden(true)
                        .allowsHitTesting(false)
                }
            }
    }
}

private func adjacentMenuItem<Item: Equatable>(
    to current: Item, in items: [Item], direction: MoveCommandDirection, axis: Axis
) -> Item? {
    guard let index = items.firstIndex(of: current) else { return nil }
    switch (axis, direction) {
    case (.horizontal, .left), (.vertical, .up):
        return items[(index + items.count - 1) % items.count]
    case (.horizontal, .right), (.vertical, .down):
        return items[(index + 1) % items.count]
    default:
        return nil
    }
}
