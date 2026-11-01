import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
const catalog = JSON.parse(readFileSync(new URL('../src/catalog.json', import.meta.url)));
const expected = ['codex','claude','gemini','deepseek','cursor','copilot','alibaba-coding-plan','zai','kimi','minimax'];
test('release target is exactly the ten agreed services, in batch order', () => {
  assert.deepEqual(catalog.map(p => p.id), expected);
});
test('both implementation batches contain five targets', () => {
  assert.equal(catalog.filter(p => p.batch === 1).length, 5);
  assert.equal(catalog.filter(p => p.batch === 2).length, 5);
});
test('every target retains a source and an explicit implementation boundary', () => {
  assert.equal(new Set(catalog.map(p => p.id)).size, 10);
  for (const item of catalog) {
    assert.match(item.reference, /^https:\/\/github\.com\/steipete\/CodexBar\/blob\/main\/docs\//);
    assert.ok(item.note.length > 15);
  }
});
test('domestic service aliases remain discoverable without merging separate products', () => {
  assert.match(catalog.find(p => p.id === 'alibaba-coding-plan').aliases, /通义/);
  assert.match(catalog.find(p => p.id === 'zai').aliases, /GLM/);
  assert.match(catalog.find(p => p.id === 'kimi').name, /Code/);
});
