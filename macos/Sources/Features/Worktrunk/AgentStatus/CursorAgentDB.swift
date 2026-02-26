import CryptoKit
import Foundation
import SQLite3

/// Lightweight read-only accessor for Cursor Agent chat store.db files.
/// The DB has two tables: `meta` (key TEXT, value TEXT) and `blobs` (id TEXT, data BLOB).
/// The meta row with key "0" holds hex-encoded JSON with session metadata.
final class CursorAgentDB {
    struct Meta {
        var agentId: String?
        var name: String?
        var createdAt: Double?
        var lastUsedModel: String?
    }

    private var db: OpaquePointer?

    init?(path: String) {
        var handle: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX
        guard sqlite3_open_v2(path, &handle, flags, nil) == SQLITE_OK else {
            if let handle { sqlite3_close(handle) }
            return nil
        }
        self.db = handle
    }

    func close() {
        if let db {
            sqlite3_close(db)
            self.db = nil
        }
    }

    deinit {
        close()
    }

    func readMeta() -> Meta? {
        guard let db else { return nil }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "SELECT value FROM meta WHERE key = '0' LIMIT 1", -1, &stmt, nil) == SQLITE_OK else {
            return nil
        }
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_step(stmt) == SQLITE_ROW else { return nil }
        guard let cstr = sqlite3_column_text(stmt, 0) else { return nil }
        let hexString = String(cString: cstr)

        guard let jsonData = dataFromHex(hexString) else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else { return nil }

        var meta = Meta()
        meta.agentId = json["agentId"] as? String
        meta.name = json["name"] as? String
        meta.createdAt = json["createdAt"] as? Double
        meta.lastUsedModel = json["lastUsedModel"] as? String
        return meta
    }

    /// Cursor Agent uses MD5(workspace_path) as the project directory hash.
    static func projectHash(for workspacePath: String) -> String {
        let digest = Insecure.MD5.hash(data: Data(workspacePath.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func dataFromHex(_ hex: String) -> Data? {
        let chars = Array(hex)
        guard chars.count % 2 == 0 else { return nil }
        var data = Data(capacity: chars.count / 2)
        var i = 0
        while i < chars.count {
            guard let byte = UInt8(String(chars[i..<i+2]), radix: 16) else { return nil }
            data.append(byte)
            i += 2
        }
        return data
    }
}
