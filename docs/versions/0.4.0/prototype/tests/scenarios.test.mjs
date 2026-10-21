import test from 'node:test';
import assert from 'node:assert/strict';
import { SCENARIOS, buildScenario } from '../src/scenarios.mjs';

const ids = ['normal', 'off', 'authorized', 'unknown', 'notificationPending'];

test('five distinct scenarios are available with bounded, shared next events', () => {
  assert.deepEqual(SCENARIOS.map(x => x.id).sort(), [...ids].sort());
  for (const language of ['zh', 'en']) for (const id of ids) {
    const view = buildScenario(id, { language });
    assert.equal(view.id, id);
    assert.ok(view.events.length <= 2, `${id} must stay concise`);
    assert.equal(new Set(view.events.map(x => x.id)).size, view.events.length);
    assert.ok(view.events.every(x => x.title && x.detail && x.action));
  }
});

test('disabled automation remains disabled and never claims successful redemption', () => {
  const view = buildScenario('off');
  assert.equal(view.autoEnabled, false);
  assert.notEqual(view.redemptionState, 'used');
  assert.doesNotMatch(view.events.map(x => x.title + x.detail).join(' '), /已成功使用|将自动使用|必定|guaranteed/i);
});

test('authorized card waits for a conditional window, not a guaranteed execution appointment', () => {
  const view = buildScenario('authorized');
  assert.equal(view.autoEnabled, true);
  assert.equal(view.isFresh, true);
  assert.notEqual(view.redemptionState, 'used');
  assert.doesNotMatch(view.events.map(x => x.title + x.detail).join(' '), /将自动使用|自动使用成功|必定|guaranteed/i);
  assert.equal(view.availableCards.length, 2);
  assert.equal(new Set(view.availableCards.map(x => x.id)).size, 2);
});

test('unverified readings cannot carry a definite use-window promise', () => {
  const view = buildScenario('unknown');
  assert.equal(view.isFresh, false);
  assert.notEqual(view.redemptionState, 'used');
  assert.doesNotMatch(view.events.map(x => x.title + x.detail).join(' '), /12:00.*进入|将自动使用|已恢复|guaranteed/i);
});

test('confirmed redemption and pending notification stay separate even if future automation is disabled', () => {
  for (const autoEnabled of [true, false]) {
    const view = buildScenario('notificationPending', { autoEnabled });
    assert.equal(view.redemptionState, 'used');
    assert.equal(view.notificationState, 'pending');
    assert.doesNotMatch(view.events.map(x => x.title + x.detail).join(' '), /正在重试|retrying now|用卡失败/i);
  }
});

test('changing primary window is retained without silently falling back', () => {
  for (const primaryWindow of ['5h', '7d']) {
    assert.equal(buildScenario('authorized', { primaryWindow }).primaryWindow, primaryWindow);
  }
});

test('same input produces the same synthetic state without clock drift', () => {
  for (const id of ids) assert.deepEqual(buildScenario(id), buildScenario(id));
});
