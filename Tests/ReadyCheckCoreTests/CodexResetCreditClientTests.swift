import XCTest
@testable import ReadyCheckCore

final class CodexResetCreditClientTests: XCTestCase {
    func testExactRPCAndPostReadUseIsolatedExternalAuthWithoutChangingNativeLogin() async throws {
        let f = try fixture(account: "A")
        defer { try? FileManager.default.removeItem(at: f.directory) }
        let token = CodexOAuthToken(accessToken: "synthetic-access", refreshToken: "synthetic-refresh", idToken: nil,
            tokenType: "Bearer", expiresAt: Date().addingTimeInterval(600), accountID: "A", email: nil)
        let outcome = try await f.client.consume(account: "A", token: token, credit: f.card, idempotencyKey: "synthetic-attempt", authorization: ResetCreditAuthorization())
        XCTAssertEqual(outcome, .reset)
        let trace = try trace(f.directory)
        XCTAssertEqual(trace.map { $0["method"] as? String }, ["initialize", "initialized", "account/login/start", "account/read", "account/rateLimits/read", "account/rateLimitResetCredit/consume", "account/rateLimits/read"])
        let params = try XCTUnwrap(trace[5]["params"] as? [String: String])
        XCTAssertEqual(params, ["creditId": "fixture-card", "idempotencyKey": "synthetic-attempt"])
        let home = try XCTUnwrap(trace[0]["home"] as? String)
        XCTAssertTrue(home.contains("readycheck-reset-"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: home))
    }
    func testWrongAccountAndWrongCardDoNotReachConsume() async throws {
        for (account, creditID) in [("B", "fixture-card"), ("A", "another-card")] {
            let f = try fixture(account: account)
            defer { try? FileManager.default.removeItem(at: f.directory) }
            let card = CodexAppServerResetCredit(id: creditID, resetType: "codexRateLimits", status: "available", expiresAt: f.card.expiresAt)
            do {
                _ = try await f.client.consume(account: "A", token: nil, credit: card, idempotencyKey: "synthetic-attempt", authorization: ResetCreditAuthorization())
                XCTFail("Mismatched account/card must be rejected")
            } catch {}
            let methods = try trace(f.directory).compactMap { $0["method"] as? String }
            XCTAssertFalse(methods.contains("account/rateLimitResetCredit/consume"))
        }
    }
    func testNoCreditAndNothingToResetRemainDistinctAndUnsupportedServerFailsClosed() async throws {
        for name in ["noCredit", "nothingToReset", "unsupported"] {
            let f = try fixture(account: "A", outcome: name)
            defer { try? FileManager.default.removeItem(at: f.directory) }
            do {
                let value = try await f.client.consume(account: "A", token: nil, credit: f.card, idempotencyKey: "synthetic-attempt", authorization: ResetCreditAuthorization())
                XCTAssertEqual(value.rawValue, name)
                XCTAssertNotEqual(name, "unsupported")
            } catch { XCTAssertEqual(name, "unsupported") }
        }
    }
    func testRevokedAuthorizationCannotWriteConsumeEvenAfterPreflight() async throws {
        let f = try fixture(account: "A")
        defer { try? FileManager.default.removeItem(at: f.directory) }
        let authorization = ResetCreditAuthorization()
        authorization.revoke()
        do {
            _ = try await f.client.consume(account: "A", token: nil, credit: f.card, idempotencyKey: "fixture-revoked", authorization: authorization)
            XCTFail("A revoked permit must prevent the irreversible RPC")
        } catch is CancellationError {} catch { XCTFail("Unexpected error: \(error)") }
        let methods = try trace(f.directory).compactMap { $0["method"] as? String }
        XCTAssertTrue(methods.contains("account/rateLimits/read"))
        XCTAssertFalse(methods.contains("account/rateLimitResetCredit/consume"))
    }

    private func trace(_ directory: URL) throws -> [[String: Any]] {
        try String(contentsOf: directory.appendingPathComponent("trace"), encoding: .utf8).split(separator: "\n").map {
            try XCTUnwrap(JSONSerialization.jsonObject(with: Data($0.utf8)) as? [String: Any])
        }
    }
    private func fixture(account: String, outcome: String = "reset") throws -> (client: CodexResetCreditClient, card: CodexAppServerResetCredit, directory: URL) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let executable = directory.appendingPathComponent("fake-server")
        let expires = Int(Date().timeIntervalSince1970) + 1800
        let script = """
        #!/usr/bin/env python3
        import json,sys,os
        from pathlib import Path
        trace=Path(__file__).with_name('trace')
        for line in sys.stdin:
            m=json.loads(line)
            # Record methods/consume params only; never record supplied token payloads.
            row={'method':m['method'],'home':os.environ.get('CODEX_HOME','')}
            if m['method']=='account/rateLimitResetCredit/consume': row['params']=m['params']
            with trace.open('a') as f: f.write(json.dumps(row)+'\\n')
            if 'id' not in m: continue
            method=m['method']
            if method=='account/read': result={'account':{'type':'chatgpt','email':None,'planType':'plus'}}
            elif method=='account/rateLimits/read': result={'accountId':'\(account)','rateLimits':{'primary':None,'secondary':None},'rateLimitResetCredits':{'availableCount':1,'credits':[{'id':'fixture-card','resetType':'codexRateLimits','status':'available','expiresAt':\(expires)}]}}
            elif method=='account/rateLimitResetCredit/consume':
                if '\(outcome)'=='unsupported':
                    print(json.dumps({'id':m['id'],'error':{'code':-32601}}),flush=True)
                    continue
                result={'outcome':'\(outcome)'}
            else: result={}
            print(json.dumps({'id':m['id'],'result':result}),flush=True)
        """
        try script.write(to: executable, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: executable.path)
        return (CodexResetCreditClient(executableURL: executable, timeout: 5),
            CodexAppServerResetCredit(id: "fixture-card", resetType: "codexRateLimits", status: "available", expiresAt: Date(timeIntervalSince1970: TimeInterval(expires))), directory)
    }
}
