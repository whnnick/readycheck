import AppKit
import XCTest
@testable import ReadyCheckApp
@testable import ReadyCheckCore

@MainActor
final class MainMenuTests: XCTestCase {
    func testBothLanguagesRetainLocalizedNavigationAndNativeFullScreenShortcut() throws {
        _ = NSApplication.shared
        let target = NSObject()
        for language in [AppLanguage.zhCN, .enUS] {
            let localization = LocalizationService(language: language)
            let menu = ReadyCheckApplication.makeMainMenu(localization: localization, target: target)
            XCTAssertEqual(menu.items[1].submenu?.title, localization.text("menu.file"))
            let view = try XCTUnwrap(menu.items[2].submenu)
            XCTAssertEqual(view.title, localization.text("menu.view"))
            let navigation = view.items.filter { $0.action == NSSelectorFromString("showPage:") }
            XCTAssertEqual(navigation.map(\.title), MainWindowPage.allCases.map { localization.text($0.titleKey) })
            XCTAssertEqual(navigation.map(\.keyEquivalent), ["1", "2", "4", "3"])
            XCTAssertEqual(navigation.map(\.title), language == .zhCN ? ["总览", "Token 用量", "通知记录", "设置"] : ["Overview", "Token usage", "Notification history", "Settings"])
            XCTAssertTrue(navigation.allSatisfy { $0.keyEquivalentModifierMask == .command })
            let fullscreen = try XCTUnwrap(view.items.first { $0.action == NSSelectorFromString("toggleFullScreen:") })
            XCTAssertEqual(fullscreen.title, localization.text("menu.fullscreen"))
            XCTAssertEqual(fullscreen.keyEquivalent, "f")
            XCTAssertEqual(fullscreen.keyEquivalentModifierMask, [.command, .control])
            let quit = try XCTUnwrap(menu.items[0].submenu?.items.first { $0.action == NSSelectorFromString("terminate:") })
            let about = try XCTUnwrap(menu.items[0].submenu?.items.first { $0.action == NSSelectorFromString("showAboutWindow") })
            XCTAssertEqual(about.title, localization.text("about.menuItem"))
            XCTAssertEqual(quit.title, localization.text("action.quit"))
        }
    }
}
