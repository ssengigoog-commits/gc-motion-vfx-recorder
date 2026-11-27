import test from 'node:test';
import assert from 'node:assert/strict';
import { assemble } from '../scripts/lib.mjs';

test('F3 records actual Highlight visual properties, target identity and lifecycle', async () => {
  const {source,manifest}=await assemble();
  assert.equal(manifest.output,'dist/GC_MotionVFX_Baker_v7_1_4.luau');
  for(const marker of [
    "obj:IsA('Highlight')", 'function Core.gameHighlightObserve(t,obj,action)',
    'function Core.gameObserveInstance(t,obj,action,area)',
    "Core.gameHighlightObserve(t,obj,action)",
    'primeHighlights(t)', 'gameHighlightTracked', 'gameHighlightConns',
    'GAME_HIGHLIGHT_', 'highlights={}', 'highlightEventCount',
    'CFG.GAME_MAX_HIGHLIGHTS', 'CFG.GAME_MAX_HIGHLIGHT_EVENTS',
    'highlightData(t,obj,state.id)', 'highlightTarget(obj)',
    'adorneePath=', 'adorneeClass=', 'adorneeExplicit=',
    'obj.FillColor', 'obj.OutlineColor', 'obj.FillTransparency',
    'obj.OutlineTransparency', 'obj.DepthMode', 'obj.Enabled',
    'GAME_MAX_HIGHLIGHT_EVENTS=2400', 'GAME_MAX_HIGHLIGHTS=160',
    "recordHighlight(t,obj,current,'changed',prop)",
    "recordHighlight(t,obj,state,'remove')",
    'watch(playerGui.DescendantAdded:Connect(function(obj)',
    'watch(playerGui.DescendantRemoving:Connect(function(obj)',
  ]) assert.ok(source.includes(marker), `missing Highlight feature: ${marker}`);
  assert.match(source,/for _,conn in ipairs\(t\.gameHighlightConns or \{\}\)/);
  assert.match(source,/combinedStreams=t\.kind=='GAME'.*'highlights'/);
  assert.match(source,/MAX_SECONDS=120/);
  assert.doesNotMatch(source, /getscriptbytecode|debug\.getupvalue|fireserver\s*\(/i);
});

test('current short loader targets7.1.4', async () => {
 const {readFile}=await import('node:fs/promises');
 const loader=await readFile(new URL('../LOADER.txt',import.meta.url),'utf8');
 assert.ok(loader.includes('GC_MotionVFX_Baker_v7_1_4.luau'));
});
