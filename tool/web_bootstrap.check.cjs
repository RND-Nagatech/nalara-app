// Source-only JS/asset checks: fake loader/DOM, no Flutter app or browser/server.
const {test} = require('node:test');
const assert = require('node:assert/strict');
const {readFileSync} = require('node:fs');
const {resolve} = require('node:path');
const {runInNewContext} = require('node:vm');
const root = resolve(__dirname, '..');
const read = path => readFileSync(resolve(root, path), 'utf8');
const bootstrap = read('web/flutter_bootstrap.js').replace('{{flutter_js}}', '').replace('{{flutter_build_config}}', '');
function environment({failLoad=false}={}) {
  const elements=new Map(), events=new Map();let options, reloads=0;
  for(const id of ['nalara-app','nalara-loading','nalara-loading-message','nalara-loading-spinner','nalara-reload']) {
    elements.set(id,{id,hidden:false,removed:false,attributes:{},listeners:{},textContent:'',
      setAttribute(key,value){this.attributes[key]=value;}, remove(){this.removed=true;}, addEventListener(key,listener){this.listeners[key]=listener;}});
  }
  elements.get('nalara-reload').hidden=true;
  const window={location:{reload(){reloads++;}},addEventListener(name,listener,config){events.set(name,{listener,config});},removeEventListener(name){events.delete(name);}};
  runInNewContext(bootstrap,{
    document:{getElementById:id=>elements.get(id)},window,
    _flutter:{loader:{load(value){options=value;return failLoad?Promise.reject(new Error('loader unavailable')):Promise.resolve();}}},
  });
  return {elements,events,get options(){return options;},get reloads(){return reloads;}};
}

test('engine receives the bounded host, including overlays/MediaQuery, then starts once',async()=>{
  const env=environment();let starts=0;
  assert.equal(env.options.config.hostElement,env.elements.get('nalara-app'));
  await env.options.onEntrypointLoaded({initializeEngine:async config=>{
    assert.equal(config.hostElement,env.elements.get('nalara-app'));
    return {runApp:async()=>{starts++;}};
  }});
  assert.equal(starts,1);assert.equal(env.elements.get('nalara-loading').removed,false);
});

test('NALARA loading overlay is removed on the first Flutter frame only',()=>{
  const env=environment(), event=env.events.get('flutter-first-frame');
  assert.equal(event.config.once,true);event.listener();
  assert.equal(env.elements.get('nalara-loading').removed,true);
  assert.equal(env.events.has('error'),false);assert.equal(env.events.has('unhandledrejection'),false);
});

test('early Dart/unhandled startup errors show retry, without taking over runtime errors after first frame',()=>{
  for(const type of ['error','unhandledrejection']) {
    const env=environment();env.events.get(type).listener();
    assert.equal(env.elements.get('nalara-reload').hidden,false);
    env.events.get('flutter-first-frame').listener();
    assert.equal(env.events.has(type),false);
  }
});

test('loader failure exposes a safe retry action instead of an endless spinner',async()=>{
  const env=environment({failLoad:true});await new Promise(resolve=>setImmediate(resolve));
  assert.equal(env.elements.get('nalara-loading').attributes['aria-busy'],'false');
  assert.equal(env.elements.get('nalara-loading-spinner').hidden,true);
  assert.equal(env.elements.get('nalara-reload').hidden,false);
  assert.match(env.elements.get('nalara-loading-message').textContent,/NALARA belum dapat dibuka/);
  env.elements.get('nalara-reload').listeners.click();assert.equal(env.reloads,1);
});

test('engine and app runner failures use the same branded retry state',async()=>{
  for(const phase of ['engine','app']) {
    const env=environment();
    await env.options.onEntrypointLoaded({initializeEngine:async()=>{
      if(phase==='engine')throw new Error('private diagnostic');
      return {runApp:async()=>{throw new Error('private diagnostic');}};
    }});
    assert.equal(env.elements.get('nalara-reload').hidden,false);
    assert.doesNotMatch(env.elements.get('nalara-loading-message').textContent,/private diagnostic/);
  }
});

test('HTML/CSS use phone-sized portrait host, Nalara loading assets and cache-busted favicon',()=>{
  const html=read('web/index.html'),css=read('web/nalara.css');
  assert.match(html,/id="nalara-app"/);assert.match(html,/alt="Logo NALARA"/);
  assert.match(html,/favicon\.png\?v=nalara-1/);assert.match(html,/name="viewport"/);
  assert.match(css,/max-width:\s*430px/);assert.match(css,/width:\s*clamp\(320px,\s*56\.25svh,\s*430px\)/);
  assert.match(css,/height:\s*100dvh/);assert.match(css,/prefers-reduced-motion/);
});

test('favicon and all install icons are correctly-sized PNGs from the local Nalara pipeline',()=>{
  const manifest=JSON.parse(read('web/manifest.json'));
  assert.equal(manifest.name,'NALARA');assert.equal(manifest.orientation,'portrait-primary');
  const files=[['favicon.png',32],...manifest.icons.map(icon=>[icon.src.split('?')[0],Number(icon.sizes.split('x')[0])])];
  for(const [name,size] of files) {
    const png=readFileSync(resolve(root,'web',name));
    assert.equal(png.subarray(1,4).toString(),'PNG');
    assert.equal(png.readUInt32BE(16),size);assert.equal(png.readUInt32BE(20),size);
  }
  assert.match(read('tool/generate_web_icons.cjs'),/assets\/Logo\/LOGO_SQUARE\.png/);
});

test('Google auth is lazy at construction and Web guards initialization before popup use',()=>{
  const service=read('lib/features/auth/data/services/google_auth_service.dart');
  const constructor=service.slice(service.indexOf('GoogleAuthService({'),service.indexOf('Future<String> signIn'));
  assert.doesNotMatch(constructor,/FirebaseAuth\.instance|GoogleSignIn\.instance/);
  assert.match(service,/GOOGLE_WEB_NOT_CONFIGURED/);assert.match(service,/signInWithPopup/);
  const main=read('lib/main.dart');
  assert.ok(main.indexOf('FirebaseWebConfig().options')<main.indexOf('await configureDependencies()'));
  assert.match(main,/if \(webOptions != null\)/);
});
