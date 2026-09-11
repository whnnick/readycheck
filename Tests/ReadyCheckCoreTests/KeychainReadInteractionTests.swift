import XCTest
import Security
@testable import ReadyCheckCore

final class KeychainReadInteractionTests: XCTestCase {
    func testRestoresInteractionAfterSuccessAndFailure() throws {
        for initial in [true, false] {
            for fails in [true, false] {
                var changes: [Bool] = []
                let operation = {
                    try KeychainReadInteraction.withoutPrompt(
                        get: { $0.pointee = DarwinBoolean(initial); return errSecSuccess },
                        set: { changes.append($0); return errSecSuccess }
                    ) {
                        if fails { throw KeychainCredentialStoreError.unexpectedStatus(errSecInteractionNotAllowed) }
                        return "synthetic"
                    }
                }
                if fails { XCTAssertThrowsError(try operation()) }
                else { XCTAssertEqual(try operation(), "synthetic") }
                XCTAssertEqual(changes, [false, initial])
            }
        }
    }

    func testDoesNotReadWhenInteractionCannotBeDisabled() {
        var read = false
        XCTAssertThrowsError(try KeychainReadInteraction.withoutPrompt(
            get: { $0.pointee = true; return errSecSuccess },
            set: { _ in errSecInteractionNotAllowed }
        ) { read = true })
        XCTAssertFalse(read)
    }
}
