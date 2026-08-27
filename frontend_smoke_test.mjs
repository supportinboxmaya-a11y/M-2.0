// Frontend smoke test: execute every ES module under frontend/js with a
// minimal browser shim. Catches import-time crashes, bad template literals
// in class bodies, and broken cross-module contracts.
import fs from 'fs';
import path from 'path';
import { pathToFileURL } from 'url';

const root = path.resolve('frontend/js');

// ── Browser shims ──────────────────────────────────────────────
const el = () => ({
  innerHTML: '', textContent: '', value: '', style: {}, dataset: {},
  classList: { add(){}, remove(){}, toggle(){}, contains(){ return false; } },
  addEventListener(){}, removeEventListener(){},
  appendChild(){ return el(); }, removeChild(){}, querySelector(){ return null; },
  querySelectorAll(){ return []; }, setAttribute(){}, getAttribute(){ return null; },
  closest(){ return null; }, scrollTop: 0, scrollHeight: 0,
});
globalThis.document = {
  addEventListener(){}, getElementById(){ return null; },
  createElement(){ return el(); }, createTextNode(){ return {}; },
  querySelector(){ return null; }, querySelectorAll(){ return []; },
  body: Object.assign(el(), { style: {} }),
  head: el(),
  documentElement: Object.assign(el(), { dataset: {} }),
};
globalThis.window = {
  location: { hash: '', protocol: 'https:', host: 'localhost' },
  addEventListener(){}, dispatchEvent(){}, matchMedia(){ return { matches: false }; },
  innerWidth: 1024,
};
globalThis.localStorage = {
  _s: {},
  getItem(k){ return this._s[k] ?? null; },
  setItem(k, v){ this._s[k] = String(v); },
  removeItem(k){ delete this._s[k]; },
};
globalThis.navigator = {};
globalThis.fetch = async () => ({ ok: true, status: 200, json: async () => ({}), text: async () => '' });
globalThis.EventSource = class { close(){} };
globalThis.WebSocket = class { close(){} send(){} };
globalThis.indexedDB = { open(){ return {}; } };
globalThis.location = window.location;
globalThis.confirm = async () => true;

const files = [];
(function walk(dir){
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) {
      // legacy/ holds the archived plain-script screens + router that
      // index.html never loads; they are not part of the ES-module app.
      if (e.name === 'legacy') continue;
      walk(p);
    }
    else if (e.name.endsWith('.js')) files.push(p);
  }
})(root);

let fail = 0;
for (const f of files) {
  try {
    await import(pathToFileURL(f).href);
    console.log(`OK    ${path.relative(root, f)}`);
  } catch (err) {
    console.log(`CRASH ${path.relative(root, f)} :: ${err.message}`);
    fail = 1;
  }
}

// ── Contract check: every view exposes the view lifecycle the app uses ──
const lifecycle = ['show', 'hide'];
const modDir = path.join(root, 'views');
for (const f of fs.readdirSync(modDir)) {
  if (!f.endsWith('.js') || f === 'GenericViews.js' || f === 'BaseView.js') continue;
  const mod = await import(pathToFileURL(path.join(modDir, f)).href);
  for (const [name, Ctor] of Object.entries(mod)) {
    if (typeof Ctor !== 'function') continue;
    const proto = Ctor.prototype;
    // LoginView is rendered by app directly but still needs show/hide
    const missing = lifecycle.filter(m => typeof proto[m] !== 'function');
    if (missing.length) {
      console.log(`CONTRACT ${f}:${name} missing ${missing.join(',')}`);
      fail = 1;
    }
  }
}

// ── ApiClient surface sanity ───────────────────────────────────
const { api } = await import(pathToFileURL(path.join(root, 'api.js')).href);
const required = [
  'getKernelStatus','processGoal','resumeIncompleteGoals','getKernelGoals','getGoal',
  'createGoal','decomposeGoal','updateGoal','getIncompleteGoals','resumeGoal',
  'knowledgeQuery','getKnowledgeStats','learnKnowledge','queryBeliefs','addBelief',
  'simulateAction','getCapabilities','searchCapabilities','verifyCapability',
  'synthesizeTool','getSynthesisJob','createPlan','replanPlan',
  'getMetacognitiveStatus','runMetacognitiveMonitor','getMetacognitiveEvents',
  'getSocietyStatus','spawnSocietyAgent','tenderSocietyTask','awardSocietyTask',
  'writeBlackboard','queryBlackboard',
  'getEpisodes','searchEpisodes','getSkillsProcedural','composeSkills','distillSkills','replayExperience',
  'getMCPStatus','connectMCPServer','callMCPTool',
  'getSelfProfile','assessSelf','setSelfTrait',
  'getSelfImproveStatus','proposeImprovement','decideProposal','executeProposal',
  'getCoreStatus','coreLoopControl','switchCoreModel','invokeCoreModel','restoreCoreCheckpoint','getCoreAudit',
  'streamChat','streamTaskEvents','cancelTask','pauseTask','resumeTask','getTaskStatus',
  'updateMemory','analyzeResearch','getResearchReports','publishSite','getPublishHistory',
  'executePlan','listWorkspaces','getWorkspaceMemory','addWorkspaceMemory',
  'deleteWorkspaceMemory','getWorkspaceStats','getLearningPrompts','getToolFramework',
];
const missingApi = required.filter(m => typeof api[m] !== 'function');
if (missingApi.length) { console.log('API MISSING: ' + missingApi.join(', ')); fail = 1; }

console.log(fail ? '\nSMOKE TEST FAILED' : `\nSMOKE TEST PASSED (${files.length} modules executed)`);
process.exit(fail);
