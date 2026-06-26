import Foundation
import Network

public final class OAuthLoopbackCallbackServer: @unchecked Sendable {
    private let port: UInt16
    private let callbackPath: String
    private let queue = DispatchQueue(label: "readycheck.oauth.loopback")
    private var listener: NWListener?

    public init(port: UInt16 = 1455, callbackPath: String = "/auth/callback") {
        self.port = port
        self.callbackPath = callbackPath
    }

    public func start(
        onReady: @escaping @Sendable () -> Void = {},
        onCallback: @escaping @Sendable (String) -> Void,
        onFailure: @escaping @Sendable (Error) -> Void
    ) throws {
        stop()

        guard let endpointPort = NWEndpoint.Port(rawValue: port) else {
            throw OAuthLoopbackCallbackServerError.invalidPort
        }

        let listener = try NWListener(using: .tcp, on: endpointPort)
        listener.newConnectionHandler = { [weak self] connection in
            self?.handle(connection, onCallback: onCallback)
        }
        listener.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                onReady()
            case let .failed(error):
                onFailure(error)
                self?.stop()
            default:
                break
            }
        }
        listener.start(queue: queue)
        self.listener = listener
    }

    public func stop() {
        listener?.cancel()
        listener = nil
    }

    private func handle(
        _ connection: NWConnection,
        onCallback: @escaping @Sendable (String) -> Void
    ) {
        connection.start(queue: queue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, _, _ in
            guard let self else {
                connection.cancel()
                return
            }

            let callbackURL = data.flatMap(self.callbackURL(from:))
            self.respond(to: connection, accepted: callbackURL != nil)

            if let callbackURL {
                onCallback(callbackURL)
                self.stop()
            }
        }
    }

    private func callbackURL(from data: Data) -> String? {
        guard let request = String(data: data, encoding: .utf8),
              let requestLine = request.split(separator: "\r\n").first ?? request.split(separator: "\n").first
        else {
            return nil
        }

        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2,
              parts[0] == "GET",
              parts[1].hasPrefix(Substring(callbackPath))
        else {
            return nil
        }

        return "http://localhost:\(port)\(parts[1])"
    }

    private func respond(to connection: NWConnection, accepted: Bool) {
        let title = accepted ? "ReadyCheck authorization received" : "ReadyCheck authorization failed"
        let message = accepted
            ? "You can return to ReadyCheck."
            : "ReadyCheck could not read this authorization callback."
        let body = """
        <!doctype html>
        <html>
        <head><meta charset="utf-8"><title>\(title)</title></head>
        <body style="font-family:-apple-system,BlinkMacSystemFont,sans-serif;margin:40px;">
        <h1>\(title)</h1>
        <p>\(message)</p>
        </body>
        </html>
        """
        let status = accepted ? "200 OK" : "400 Bad Request"
        let response = """
        HTTP/1.1 \(status)\r
        Content-Type: text/html; charset=utf-8\r
        Content-Length: \(body.utf8.count)\r
        Connection: close\r
        \r
        \(body)
        """

        connection.send(content: Data(response.utf8), completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}

public enum OAuthLoopbackCallbackServerError: Error {
    case invalidPort
}
