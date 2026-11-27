import test from 'node:test';
import assert from 'node:assert/strict';
import { assemble } from '../scripts/lib.mjs';

// Structural regression checks. These are NOT a Roblox Player runtime test.
test('F3 GAME coordinates three old capture paths and adds client observations', async () => {
  const {source, manifest}=await assemble();
  assert.equal(manifest.output,'dist/GC_MotionVFX_Baker_v7_1_5.luau');
  assert.match(source,/Core\.startRecord\('GAME'\)/);
  assert.match(source,/key=='F3'and not processed then Core\.startRecord\('GAME'\)/);
  assert.doesNotMatch(source,/key=='F9'and not processed then Core\.startRecord\('GAME'\)/);
  assert.match(source,/if mode=='ANIM' or mode=='GAME' then/);
  assert.match(source,/if mode=='VFX' or mode=='GAME' then/);
  assert.match(source,/if mode=='INSPECT' or mode=='GAME' then/);
  assert.match(source,/Core\.inspectBegin\(t\)/);
  assert.match(source,/Group\.seed\(t\)/);
  assert.match(source,/Core\.gameBegin\(t\)/);
  assert.match(source,/Core\.gamePrime\(t\)/);
  assert.match(source,/Core\.inspectSample\(t,ts\)/);
  assert.match(source,/Core\.sampleMotion\(t,ts\)/);
  assert.match(source,/Core\.vfxRefresh\(t,ts\)/);
  assert.match(source,/Core\.gameSample\(t,ts\)/);
  assert.match(source,/Core\.gameFinish\(t\)/);
  assert.match(source,/combinedStreams=t\.kind=='GAME'/);
  assert.match(source,/frames=t\.frames/);
  assert.match(source,/vfx=t\.vfx/);
  assert.match(source,/inspector=t\.inspector,game=t\.game/);
  assert.match(source,/GAME_SAMPLE_HZ=5/);
  assert.match(source,/GAME_MAX_EVENTS=12000/);
  assert.match(source,/GAME_MAX_VFX_EVENTS=6000/);
  assert.match(source,/GAME_VFX_FPS=15/);
  assert.match(source,/math\.min\(CFG\.FPS,30\)/);
  assert.match(source,/MAX_SECONDS=120/);
  assert.match(source,/GAME_SOUND_PLAY/);
  assert.match(source,/GAME_VALUE_CHANGED/);
  assert.match(source,/GAME_INSTANCE_ADDED/);
  assert.match(source,/GAME_ATTRIBUTE_CHANGED/);
  assert.match(source,/GAME_ACTOR_HUMANOID_STATE/);
});

test('existing F6/F8, ghost, VFX importer and storage remain available', async () => {
  const {source}=await assemble();
  for(const marker of [
    "Core.startRecord('ANIM')", "Core.startRecord('VFX')",
    "Core.playSelected(loopOn)",
    'Core.studioImporter', 'Core.studioVfxImporter',
    'Core.safeWrite', 'Core.safeDelete', 'Core.saveHistory',
    "for _,version in ipairs({7,6,5,4})do",
    "MANIFEST='GC_BAKER_HISTORY_v7.json'",
    "return frame~=nil and (frame.Position-t.rigObj.root.Position).Magnitude<=(t.kind=='GAME'",
  ]) assert.ok(source.includes(marker), `missing ${marker}`);
  assert.doesNotMatch(source, /getscriptbytecode|debug\.getupvalue|fireserver\s*\(/i);
});
