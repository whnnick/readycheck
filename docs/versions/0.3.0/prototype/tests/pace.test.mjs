import test from 'node:test';
import assert from 'node:assert/strict';
import { scenarios, evaluatePace } from '../src/pace.mjs';

test('risk compares time to the chosen threshold with reset', () => {
 const p=evaluatePace(scenarios.risk,10);
 assert.equal(p.kind,'risk'); assert.equal(p.minutesToThreshold,60); assert.equal(p.rate,24);
 assert.equal(evaluatePace(scenarios.risk,5).minutesToThreshold,72.5);
});
test('safe is conditional on current observed pace', () => {
 const p=evaluatePace(scenarios.safe,10);
 assert.equal(p.kind,'safe'); assert.equal(p.remainingAtReset,30);
});
test('missing, old, new-cycle and volatile data never show a countdown', () => {
 for(const id of ['short','stale','reset','volatile']) {
  const p=evaluatePace(scenarios[id],10);
  assert.equal(p.kind,id==='reset'?'short':id);
  assert.equal(p.minutesToThreshold,null);
 }
});
test('idle readings do not imply unlimited time', () => {
 assert.equal(evaluatePace(scenarios.idle,10).kind,'idle');
 assert.equal(evaluatePace(scenarios.idle,10).minutesToThreshold,null);
});
test('actual threshold reached is distinct from a future estimate', () => {
 assert.equal(evaluatePace({...scenarios.risk,remaining:8},10).kind,'low');
});
test('reset increases and long gaps cannot produce an optimistic estimate', () => {
 const reset=scenarios.risk.points.map((p,i)=>({...p,remaining:i>5?p.remaining+40:p.remaining}));
 assert.equal(evaluatePace({...scenarios.risk,points:reset},10).kind,'short');
 const gaps=scenarios.risk.points.map((p,i)=>({...p,minute:i*15}));
 assert.equal(evaluatePace({...scenarios.risk,points:gaps},10).kind,'short');
});
