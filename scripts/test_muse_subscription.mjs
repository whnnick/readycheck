import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import test from 'node:test';

const source = await readFile(new URL('../Sources/ReadyCheckApp/Resources/MuseSubscription.js', import.meta.url), 'utf8');
const run = new (Object.getPrototypeOf(async function(){}).constructor)(
  'cachedActionID', 'location', 'document', 'fetch', source);
const id = 'a'.repeat(40);
const flight = '0:{"a":"$@1"}\n1:' + JSON.stringify({success: true, subscription: {
  tier: {name:'Power'}, usage:{percentUsed:27,resetsAt:2000000000},
  usageRowValueLabel:'27% used (400M tokens left)', payment_method:'must-not-escape'}});

async function execute({cached = '', status = 200, stale = false, staleStatus = 404, chunks = 1, payload = flight, lazy = false, immutable = false, homeStatus = 200, staleDOM = false, separatedSettings = false} = {}) {
  const calls = [];
  const chunkDirectory = immutable ? 'static/immutable/chunks' : 'static/chunks';
  const scripts = Array.from({length:chunks},(_,i)=>({src:`https://muse.ai/_next/${chunkDirectory}/chunk${i}.js`}));
  scripts.push({src:'https://unrelated.example/private.js'});
  const fetch = async (path, options) => {
    calls.push({path, options});
    if (options.method === 'GET') return {ok:homeStatus===200,status:homeStatus,type:homeStatus===0?'opaqueredirect':'basic',text:async()=>scripts.map(s=>`<script src="${s.src}"></script>`).join('')};
    if (options.method === 'POST') {
      const firstPost = calls.filter(x=>x.options.method==='POST').length===1;
      const code = stale && firstPost ? staleStatus : status;
      return {ok:code===200,status:code,text:async()=>payload};
    }
    const moduleReference = 'e.A(123).then(({preloadHatchSettingsData:x})=>x({}));';
    const loader = `},123,s=>{s.v(t=>Promise.all(["${chunkDirectory}/settings.js"].map(t=>s.l(t))))}`;
    if (separatedSettings) {
      const content = path.endsWith('/settings.js') ? `createServerReference("${id}",x,"fetchSubscriptionAction")`
        : path.endsWith('/chunk90.js') ? moduleReference
        : path.endsWith('/chunk59.js') ? loader
        : 'x'.repeat(300000);
      return {ok:true,status:200,text:async()=>content};
    }
    const content = lazy ? (path.includes('settings.js') ? `createServerReference("${id}",x,"fetchSubscriptionAction")`
      : moduleReference + loader)
      : chunks===1 ? `createServerReference("${id}",x,"fetchSubscriptionAction")` : 'no-action';
    return {ok:true,status:200,text:async()=>content};
  };
  const output = JSON.parse(await run(cached,{origin:'https://muse.ai',href:'https://muse.ai/'},{scripts:staleDOM?[]:scripts},fetch));
  return {output,calls};
}

test('reads only the subscription action; static chunks carry no credentials; unrelated fields do not escape',async()=>{
  const {output,calls}=await execute();
  assert.equal(output.actionID,id);
  assert.ok(output.flight.includes('400M tokens left'));
  assert.ok(!output.flight.includes('payment_method'));
  for(const call of calls){
    assert.ok(call.path.startsWith('/'));
    assert.equal(call.options.redirect,call.options.method==='GET'?'manual':'error');
    assert.equal(call.options.credentials,call.options.method?'same-origin':'omit');
    if(call.options.method==='GET') assert.equal(call.options.cache,'no-store');
    if(call.options.method==='POST') assert.deepEqual(JSON.parse(call.options.body),[{includeAgreement:true}]);
  }
  assert.equal(calls.filter(x=>x.options.method==='POST').length,1);
});

test('cached action avoids discovery and stale action gets one bounded rediscovery',async()=>{
  const cached=await execute({cached:id});
  assert.equal(cached.calls.length,1);
  const stale=await execute({cached:id,stale:true});
  assert.equal(stale.output.actionID,id);
  assert.equal(stale.calls.filter(x=>x.options.method==='POST').length,2);
});

test('a cached action rejected with a server error is rediscovered once and recovers',async()=>{
  const cachedID = 'b'.repeat(40);
  const {output,calls}=await execute({cached:cachedID,stale:true,staleStatus:500});
  assert.equal(output.actionID,id);
  assert.ok(output.flight.includes('400M tokens left'));
  const posts=calls.filter(x=>x.options.method==='POST');
  assert.equal(posts.length,2);
  assert.equal(posts[0].options.headers['Next-Action'],cachedID);
  assert.equal(posts[1].options.headers['Next-Action'],id);
});

test('persistent server failure is bounded and authentication failure does not rediscover',async()=>{
  const failed=await execute({cached:id,status:502});
  assert.equal(failed.output.error,'network');
  assert.equal(failed.calls.filter(x=>x.options.method==='POST').length,2);
  const fresh=await execute({status:502});
  assert.equal(fresh.calls.filter(x=>x.options.method==='POST').length,1);
  for(const status of [401,403]) {
    const signedOut=await execute({cached:id,status});
    assert.equal(signedOut.output.error,'loginRequired');
    assert.equal(signedOut.calls.length,1);
  }
});

test('finds the lazy settings action without invoking unrelated server actions',async()=>{
  const {output,calls}=await execute({lazy:true});
  assert.equal(output.actionID,id);
  assert.ok(calls.some(x=>x.path==='/_next/static/chunks/settings.js'));
  assert.equal(calls.filter(x=>x.options.method==='POST').length,1);
});

test('discovers the subscription action in immutable page and settings chunks',async()=>{
  const {output,calls}=await execute({lazy:true,immutable:true});
  assert.equal(output.actionID,id);
  const chunks = calls.filter(call => call.path.includes('/chunks/'));
  assert.deepEqual(chunks.map(call => call.path), [
    '/_next/static/immutable/chunks/chunk0.js',
    '/_next/static/immutable/chunks/settings.js',
  ]);
  assert.ok(chunks.every(call => call.options.credentials === 'omit'));
});

test('discovers settings near the end of a large page with the loader in an earlier chunk',async()=>{
  const {output,calls}=await execute({chunks:107,immutable:true,separatedSettings:true});
  assert.equal(output.actionID,id);
  const paths = calls.map(call => call.path);
  assert.ok(paths.indexOf('/_next/static/immutable/chunks/chunk90.js') <
    paths.indexOf('/_next/static/immutable/chunks/chunk59.js'));
  assert.ok(paths.includes('/_next/static/immutable/chunks/settings.js'));
  assert.ok(!paths.includes('/_next/static/immutable/chunks/chunk0.js'));
  assert.equal(calls.filter(call => call.options.method === 'POST').length,1);
});

test('rediscovers once when a cached action receives a conflict',async()=>{
  const {output,calls}=await execute({cached:'b'.repeat(40),stale:true,staleStatus:409,lazy:true,immutable:true});
  assert.equal(output.actionID,id);
  assert.equal(calls.filter(call => call.options.method === 'POST').length,2);
});

test('expired session, malformed response and repeated stale action remain unavailable',async()=>{
  assert.equal((await execute({cached:id,status:403})).output.error,'loginRequired');
  assert.equal((await execute({cached:id,payload:'unexpected'})).output.error,'responseChanged');
  const stale=await execute({cached:id,status:404});
  assert.equal(stale.output.error,'responseChanged');
  assert.equal(stale.calls.filter(x=>x.options.method==='POST').length,2);
});

test('discovery has a hard request cap and makes no POST without a discovered read action',async()=>{
  const result=await execute({chunks:150});
  assert.equal(result.output.error,'responseChanged');
  assert.equal(result.calls.length,129);
  assert.equal(result.calls.filter(x=>x.options.method==='POST').length,0);
});

test('another origin cannot read a session or issue any requests',async()=>{
  const value=JSON.parse(await run('',{origin:'https://unrelated.example'}, {},()=>{throw Error('must not fetch');}));
  assert.equal(value.error,'loginRequired');
});


test('discovers from fresh same-origin HTML after client-side sign-in, not stale login DOM',async()=>{
  const {output,calls}=await execute({staleDOM:true});
  assert.equal(output.actionID,id);
  assert.equal(calls[0].path,'/');
  assert.equal(calls[0].options.method,'GET');
  assert.equal(calls[0].options.cache,'no-store');
});

test('signed-out homepage redirects and authentication failures stop before action discovery',async()=>{
  for(const homeStatus of [0,401,403]) {
    const {output,calls}=await execute({homeStatus});
    assert.equal(output.error,'loginRequired');
    assert.equal(calls.length,1);
  }
});

test('failed discovery reports only its fixed stage, never page content',async()=>{
  const {output}=await execute({chunks:150});
  assert.deepEqual(output,{error:'responseChanged',stage:'discovery'});
});
