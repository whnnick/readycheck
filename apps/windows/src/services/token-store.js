"use strict";

const fs = require("node:fs");
const path = require("node:path");
const { safeStorage } = require("electron");

class EncryptedTokenStore {
  constructor(userDataPath) {
    this.filePath = path.join(userDataPath, "codex-oauth-token.bin");
  }

  async loadToken() {
    if (!fs.existsSync(this.filePath)) {
      return null;
    }
    this.ensureEncryptionAvailable();

    const encrypted = fs.readFileSync(this.filePath);
    const decrypted = safeStorage.decryptString(encrypted);
    return JSON.parse(decrypted);
  }

  async saveToken(token) {
    this.ensureEncryptionAvailable();
    fs.mkdirSync(path.dirname(this.filePath), { recursive: true });
    const encrypted = safeStorage.encryptString(JSON.stringify(token));
    fs.writeFileSync(this.filePath, encrypted, { mode: 0o600 });
  }

  async removeToken() {
    if (fs.existsSync(this.filePath)) {
      fs.unlinkSync(this.filePath);
    }
  }

  ensureEncryptionAvailable() {
    if (!safeStorage.isEncryptionAvailable()) {
      throw new Error("Electron safeStorage encryption is not available.");
    }
  }
}

module.exports = {
  EncryptedTokenStore
};
