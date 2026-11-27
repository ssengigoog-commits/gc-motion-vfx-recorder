import test from 'node:test';
import assert from 'node:assert/strict';
import { assemble } from '../scripts/lib.mjs';

test('v7 retains bounded legacy v6.9 Inspector structures for GAME and old takes', async () => {
  const { source } = await assemble();
  assert.match(source, /INSPECT_FPS=10/);
  assert.match(source, /INSPECT_MAX_ACTORS=32/);
  assert.match(source, /INSPECT_MAX_FRAMES=1200/);
  assert.match(source, /INSPECT_RADIUS=60/);
  assert.match(source, /Core\.inspectRefresh\(t,ts\)/);
  assert.doesNotMatch(source, /Core\.inspectToggle\(target\)/);
  assert.match(source, /Core\.inspectEffect\(obj,now\(recording\),'add'\)/);
  assert.match(source, /Core\.inspectFinish\(t\)/);
  assert.match(source, /t\.kind=='INSPECT'/);
  assert.match(source, /F3 = Game Recorder/);
});
