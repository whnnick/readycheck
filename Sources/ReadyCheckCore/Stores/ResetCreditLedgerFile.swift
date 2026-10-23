import Foundation
import Darwin

/// Keeps the protected ledger open while the app runs; never falls back to cached consent.
final class ResetCreditLedgerFile {
    private let url: URL
    private var handle: FileHandle?
    private let protection: FileProtectionType?
    private let openExisting: (URL) throws -> FileHandle

    init(url: URL, protection: FileProtectionType? = .completeUnlessOpen, openExisting: @escaping (URL) throws -> FileHandle = { url in
        let fd = Darwin.open(url.path, O_RDONLY | O_NOFOLLOW | O_CLOEXEC)
        guard fd >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        return FileHandle(fileDescriptor: fd, closeOnDealloc: true)
    }) {
        self.url = url; self.protection = protection; self.openExisting = openExisting
    }
    deinit { try? handle?.close() }

    func read() throws -> Data? {
        var pathInfo = stat()
        guard lstat(url.path, &pathInfo) == 0 else {
            guard errno == ENOENT else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
            try? handle?.close(); handle = nil
            return nil
        }
        guard pathInfo.st_mode & S_IFMT == S_IFREG else { throw CocoaError(.fileReadUnknown) }
        var openInfo = stat()
        if let handle, fstat(handle.fileDescriptor, &openInfo) == 0,
           pathInfo.st_ino == openInfo.st_ino, pathInfo.st_dev == openInfo.st_dev {
            try handle.seek(toOffset: 0)
            return try handle.readToEnd() ?? Data()
        }
        try? handle?.close(); handle = nil
        let opened = try openExisting(url)
        guard fstat(opened.fileDescriptor, &openInfo) == 0,
              pathInfo.st_ino == openInfo.st_ino, pathInfo.st_dev == openInfo.st_dev else {
            try? opened.close(); throw CocoaError(.fileReadUnknown)
        }
        handle = opened
        return try opened.readToEnd() ?? Data()
    }

    func write(_ data: Data) throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let temporary = directory.appendingPathComponent(".reset-ledger-" + UUID().uuidString)
        let fd = Darwin.open(temporary.path, O_RDWR | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard fd >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        let opened = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        var committed = false
        defer {
            if !committed { try? opened.close(); try? FileManager.default.removeItem(at: temporary) }
        }
        // Same protection class as before. Keep this descriptor open across the atomic replacement.
        if let protection {
            try FileManager.default.setAttributes([.protectionKey: protection], ofItemAtPath: temporary.path)
        }
        try opened.write(contentsOf: data)
        try opened.synchronize()
        guard rename(temporary.path, url.path) == 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        try? handle?.close(); handle = opened; committed = true
    }
}
