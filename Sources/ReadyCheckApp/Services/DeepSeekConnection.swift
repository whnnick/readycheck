import Foundation
import Observation
import ReadyCheckCore

@MainActor @Observable
final class DeepSeekConnection {
    enum RefreshOutcome: Equatable { case updated, unchanged, failed }
    static let credentialKey = CredentialKey(providerId: "deepseek", name: "api-key")
    private let store: any CredentialStore
    private let client: DeepSeekBalanceClient
    private let historyStore: DeepSeekBalanceHistoryStore
    @ObservationIgnored
    var onReading: (@MainActor (UUID, DeepSeekBalanceSnapshot) async -> Void)?
    private(set) var connectionID: UUID?
    private(set) var isConnected = false
    private(set) var isBusy = false
    private(set) var snapshot: DeepSeekBalanceSnapshot?
    private(set) var observedAt: Date?
    private(set) var history: [DeepSeekBalanceObservation] = []
    private(set) var historyError = false
    private(set) var error: DeepSeekBalanceError?
    private(set) var connectError: DeepSeekBalanceError?
    private(set) var credentialError = false
    private(set) var refreshOutcome: RefreshOutcome?

    init(store: any CredentialStore = KeychainCredentialStore(), client: DeepSeekBalanceClient = DeepSeekBalanceClient(),
         historyStore: DeepSeekBalanceHistoryStore? = nil) {
        self.store = store
        self.client = client
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.historyStore = historyStore ?? DeepSeekBalanceHistoryStore(fileURL: base.appendingPathComponent("ReadyCheck/deepseek-balance-history.json"))
    }

    struct Credential: Codable {
        let key: String
        let connectionID: UUID
        static func parse(_ raw: String) throws -> Credential? {
            guard raw.hasPrefix("{") else { return nil }
            return try JSONDecoder().decode(Credential.self, from: Data(raw.utf8))
        }
        func encode() throws -> String { String(decoding: try JSONEncoder().encode(self), as: UTF8.self) }
    }

    func connect(key: String) async {
        let key = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        connectError = nil
        credentialError = false
        do {
            let result = try await client.fetch(apiKey: key)
            try Task.checkCancellation()
            let credential: Credential
            do {
                let existing = try await store.loadCredential(for: Self.credentialKey)
                let parsed = try existing.flatMap { try Credential.parse($0) }
                credential = parsed?.key == key ? parsed! : Credential(key: key, connectionID: UUID())
                try await store.saveCredential(try credential.encode(), for: Self.credentialKey)
            } catch { credentialError = true; return }
            error = nil
            connectionID = credential.connectionID
            isConnected = true
            snapshot = result
            let date = Date()
            observedAt = date
            history = []
            await updateHistory(credential: credential, snapshot: result, date: date)
            await onReading?(credential.connectionID, result)
        } catch is CancellationError { return }
        catch let failure as DeepSeekBalanceError { connectError = failure }
        catch { connectError = .network }
    }

    func retryCredentialRead() async {
        let retryStore: any CredentialStore = (store as? KeychainCredentialStore)?.allowingInteraction() ?? store
        await refresh(using: retryStore)
    }

    func refresh() async { await refresh(using: store) }

    private func refresh(using readStore: any CredentialStore) async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        error = nil
        refreshOutcome = nil
        credentialError = false
        let raw: String
        let parsed: Credential?
        do {
            guard let saved = try await readStore.loadCredential(for: Self.credentialKey) else {
                isConnected = false; connectionID = nil; snapshot = nil; observedAt = nil; history = []
                refreshOutcome = .failed
                return
            }
            raw = saved
            parsed = try Credential.parse(saved)
            if connectionID != parsed?.connectionID {
                snapshot = nil
                observedAt = nil
                history = []
            }
            isConnected = true
            connectionID = parsed?.connectionID
            if let parsed {
                do { history = try await historyStore.load(connectionID: parsed.connectionID); historyError = false }
                catch { history = []; historyError = true }
            }
        } catch {
            credentialError = true
            refreshOutcome = .failed
            connectionID = nil
            snapshot = nil
            observedAt = nil
            history = []
            return
        }
        do {
            let result = try await client.fetch(apiKey: parsed?.key ?? raw)
            try Task.checkCancellation()
            let credential = parsed ?? Credential(key: raw, connectionID: UUID())
            if parsed == nil {
                do { try await store.saveCredential(try credential.encode(), for: Self.credentialKey) }
                catch { credentialError = true; refreshOutcome = .failed; return }
            }
            connectionID = credential.connectionID
            refreshOutcome = snapshot == result ? .unchanged : .updated
            snapshot = result
            let date = Date()
            observedAt = date
            await updateHistory(credential: credential, snapshot: result, date: date)
            await onReading?(credential.connectionID, result)
        } catch is CancellationError { return }
        catch let failure as DeepSeekBalanceError { error = failure; refreshOutcome = .failed }
        catch { self.error = .network; refreshOutcome = .failed }
    }

    private func updateHistory(credential: Credential, snapshot: DeepSeekBalanceSnapshot, date: Date) async {
        do {
            try await historyStore.record(connectionID: credential.connectionID, observedAt: date, balances: snapshot.balances)
            history = try await historyStore.load(connectionID: credential.connectionID, now: date)
            historyError = false
        } catch { historyError = true }
    }

    func disconnect() async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            try await store.removeCredential(for: Self.credentialKey)
            isConnected = false; connectionID = nil; snapshot = nil; observedAt = nil; history = []; historyError = false
            error = nil; connectError = nil; credentialError = false
            refreshOutcome = nil
        } catch { credentialError = true }
    }
}
