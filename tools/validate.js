/**
 * 工程静态校验：在没有 DevEco Studio 的环境下，
 * 尽量把「能提前发现的错误」都提前发现。
 *
 * 覆盖：
 *  1. 所有 JSON / JSON5 配置能否解析
 *  2. $r('app.media.x') / $r('app.string.x') 引用的资源是否存在
 *  3. .ets 之间的 import 路径能否解析，导入的符号是否真的被导出
 *  4. 是否存在重复 import、未使用的 import
 *  5. 主题令牌引用是否存在（Space./FontSize./Color./Radius./Font./Weight.）
 *  6. module.json5 / main_pages.json 中声明的文件是否存在
 */
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const ENTRY = path.join(ROOT, 'entry');
const MAIN = path.join(ENTRY, 'src', 'main');
const ETS = path.join(MAIN, 'ets');

let errors = 0;
let warns = 0;
const fail = (m) => { errors++; console.log('  [ERR ] ' + m); };
const warn = (m) => { warns++; console.log('  [WARN] ' + m); };
const ok = (m) => console.log('  [ ok ] ' + m);

// ── 1. JSON5 解析（去掉注释与尾逗号后交给 JSON.parse） ──
function parseJson5(src) {
  let s = src.replace(/\/\*[\s\S]*?\*\//g, '');
  s = s.replace(/(^|[^:"'\\])\/\/.*$/gm, '$1');
  s = s.replace(/,(\s*[}\]])/g, '$1');
  return JSON.parse(s);
}

function walk(dir, exts, out = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) {
      if (e.name === 'build' || e.name === 'oh_modules' || e.name === 'node_modules') continue;
      walk(p, exts, out);
    } else if (exts.some((x) => e.name.endsWith(x))) {
      out.push(p);
    }
  }
  return out;
}

console.log('\n=== 1. JSON / JSON5 配置 ===');
for (const f of walk(ROOT, ['.json', '.json5'])) {
  const rel = path.relative(ROOT, f).replace(/\\/g, '/');
  try {
    parseJson5(fs.readFileSync(f, 'utf8'));
    ok(rel);
  } catch (e) {
    fail(rel + ' → ' + e.message);
  }
}

// ── 2. 资源引用 ──
console.log('\n=== 2. $r() 资源引用 ===');
// main 与 ohosTest 是两个独立模块，各自有独立的资源命名空间。
const mediaDirs = [
  path.join(MAIN, 'resources', 'base', 'media'),
  path.join(ENTRY, 'src', 'ohosTest', 'resources', 'base', 'media')
];
const mediaFiles = new Set();
for (const d of mediaDirs) {
  if (!fs.existsSync(d)) continue;
  for (const n of fs.readdirSync(d)) mediaFiles.add(n.replace(/\.[^.]+$/, ''));
}

const stringFiles = [
  path.join(MAIN, 'resources', 'base', 'element', 'string.json'),
  path.join(ENTRY, 'src', 'ohosTest', 'resources', 'base', 'element', 'string.json'),
  path.join(ROOT, 'AppScope', 'resources', 'base', 'element', 'string.json')
];
const strings = new Set();
for (const f of stringFiles) {
  if (!fs.existsSync(f)) continue;
  const j = JSON.parse(fs.readFileSync(f, 'utf8'));
  for (const it of j.string || []) strings.add(it.name);
}

const etsFiles = walk(path.join(ENTRY, 'src'), ['.ets']);
const usedMedia = new Set();
for (const f of etsFiles) {
  const src = fs.readFileSync(f, 'utf8');
  const rel = path.relative(ROOT, f).replace(/\\/g, '/');
  for (const m of src.matchAll(/\$r\(\s*'app\.media\.([A-Za-z0-9_]+)'\s*\)/g)) {
    usedMedia.add(m[1]);
    if (!mediaFiles.has(m[1])) fail(rel + ' → 缺失 media 资源 app.media.' + m[1]);
  }
  for (const m of src.matchAll(/\$r\(\s*'app\.string\.([A-Za-z0-9_]+)'\s*\)/g)) {
    if (!strings.has(m[1])) fail(rel + ' → 缺失 string 资源 app.string.' + m[1]);
  }
}
// module.json5 / AppScope / media 描述文件里的 $media: 与 $string:
const declarers = [
  path.join(MAIN, 'module.json5'),
  path.join(ENTRY, 'src', 'ohosTest', 'module.json5'),
  path.join(ROOT, 'AppScope', 'app.json5'),
  path.join(MAIN, 'resources', 'base', 'media', 'layered_image.json'),
  path.join(ENTRY, 'src', 'ohosTest', 'resources', 'base', 'media', 'layered_image.json')
];
for (const f of declarers) {
  if (!fs.existsSync(f)) continue;
  const rel = path.relative(ROOT, f).replace(/\\/g, '/');
  const src = fs.readFileSync(f, 'utf8');
  for (const m of src.matchAll(/\$media:([A-Za-z0-9_]+)/g)) {
    usedMedia.add(m[1]);
    if (!mediaFiles.has(m[1])) fail(rel + ' → 缺失 media 资源 ' + m[1]);
  }
  for (const m of src.matchAll(/\$string:([A-Za-z0-9_]+)/g)) {
    if (!strings.has(m[1])) fail(rel + ' → 缺失 string 资源 ' + m[1]);
  }
}
const unusedMedia = [...mediaFiles].filter((n) => !usedMedia.has(n) && n !== 'layered_image');
ok('引用的 media 资源数 ' + usedMedia.size + '，实际存在 ' + mediaFiles.size);
if (unusedMedia.length) warn('未被引用的 media（冗余资源）：' + unusedMedia.join(', '));

// ── 3/4. import 解析 + 重复/未使用检查 ──
console.log('\n=== 3. import 解析与导出符号 ===');
function exportsOf(src) {
  const set = new Set();
  for (const m of src.matchAll(/export\s+(?:default\s+)?(?:declare\s+)?(class|struct|enum|interface|function|const|let|type)\s+([A-Za-z0-9_]+)/g)) {
    set.add(m[2]);
  }
  // export { a, b }
  for (const m of src.matchAll(/export\s*\{([^}]*)\}/g)) {
    for (const part of m[1].split(',')) {
      const n = part.trim().split(/\s+as\s+/).pop().trim();
      if (n) set.add(n);
    }
  }
  return set;
}

for (const f of etsFiles) {
  const rel = path.relative(ROOT, f).replace(/\\/g, '/');
  const src = fs.readFileSync(f, 'utf8');
  const seen = new Set();
  const importRe = /import\s*\{([^}]*)\}\s*from\s*'([^']+)'/g;
  let m;
  while ((m = importRe.exec(src)) !== null) {
    const names = m[1].split(',').map((s) => s.trim()).filter(Boolean);
    const spec = m[2];
    if (seen.has(spec)) warn(rel + ' → 重复 import 同一模块 ' + spec);
    seen.add(spec);

    if (!spec.startsWith('.')) continue; // @kit.* / @ohos.* 交给编译器
    const target = path.resolve(path.dirname(f), spec);
    let file = null;
    for (const cand of [target + '.ets', target + '.ts', path.join(target, 'index.ets')]) {
      if (fs.existsSync(cand)) { file = cand; break; }
    }
    if (!file) { fail(rel + ' → import 路径无法解析: ' + spec); continue; }

    const ex = exportsOf(fs.readFileSync(file, 'utf8'));
    for (const raw of names) {
      const name = raw.split(/\s+as\s+/)[0].trim();
      if (!ex.has(name)) {
        fail(rel + ' → 从 ' + spec + ' 导入了未导出的符号: ' + name);
      }
      // 未使用检查（排除只用于类型的场景由编译器处理）
      const body = src.slice(m.index + m[0].length);
      const useRe = new RegExp('\\b' + name.replace(/[$]/g, '\\$') + '\\b');
      if (!useRe.test(body)) warn(rel + ' → 导入但未使用: ' + name);
    }
  }
}
ok('已检查 ' + etsFiles.length + ' 个 .ets 文件');

// ── 5. 主题令牌引用 ──
console.log('\n=== 4. 主题令牌引用 ===');
const themeSrc = fs.readFileSync(path.join(ETS, 'common', 'Theme.ets'), 'utf8');
const tokens = { Color: new Set(), FontSize: new Set(), Space: new Set(), Radius: new Set(), Font: new Set(), Motion: new Set(), Layout: new Set(), Weight: new Set() };
for (const cls of Object.keys(tokens)) {
  const re = new RegExp('class\\s+' + cls + '\\s*\\{([\\s\\S]*?)\\n\\}', 'g');
  const mm = re.exec(themeSrc);
  if (!mm) { fail('Theme.ets 中找不到 class ' + cls); continue; }
  for (const t of mm[1].matchAll(/static\s+readonly\s+([A-Za-z0-9_]+)/g)) tokens[cls].add(t[1]);
}
for (const f of etsFiles) {
  if (f.endsWith('Theme.ets')) continue;
  const rel = path.relative(ROOT, f).replace(/\\/g, '/');
  const src = fs.readFileSync(f, 'utf8');
  for (const cls of Object.keys(tokens)) {
    const re = new RegExp('\\b' + cls + '\\.([A-Za-z0-9_]+)', 'g');
    for (const mm of src.matchAll(re)) {
      if (!tokens[cls].has(mm[1])) fail(rel + ' → 未定义的主题令牌 ' + cls + '.' + mm[1]);
    }
  }
}
ok('令牌类：' + Object.keys(tokens).map((k) => k + '(' + tokens[k].size + ')').join(' '));

// ── 6. 声明文件存在性 ──
// ── 5. 静态成员调用一致性（防止「删了定义但别处还在调」） ──
console.log('\n=== 5. 静态成员调用一致性 ===');
/** 用花括号配对切出每个类的真实类体，避免把整个文件的成员都算到同一个类上。 */
function classBodies(src) {
  const out = [];
  const re = /export\s+(?:class|struct)\s+([A-Za-z0-9_]+)[^{]*\{/g;
  let m;
  while ((m = re.exec(src)) !== null) {
    let depth = 1;
    let i = re.lastIndex;
    while (i < src.length && depth > 0) {
      if (src[i] === '{') depth++;
      else if (src[i] === '}') depth--;
      i++;
    }
    out.push({ name: m[1], body: src.slice(re.lastIndex, i - 1) });
  }
  return out;
}

const knownClasses = new Set();
const classMembers = new Map(); // 'Class.member' → 声明文件
for (const f of etsFiles) {
  for (const cb of classBodies(fs.readFileSync(f, 'utf8'))) {
    knownClasses.add(cb.name);
    for (const mm of cb.body.matchAll(/^\s*(?:private\s+|public\s+|protected\s+)?static\s+(?:async\s+)?(?:readonly\s+)?([A-Za-z0-9_]+)/gm)) {
      classMembers.set(cb.name + '.' + mm[1], f);
    }
  }
}

for (const f of etsFiles) {
  const rel = path.relative(ROOT, f).replace(/\\/g, '/');
  const src = fs.readFileSync(f, 'utf8');
  // 只关心「工程内自定义类」上的静态访问，跳过 AppStorage / Math / JSON 等内置对象
  for (const mm of src.matchAll(/\b([A-Z][A-Za-z0-9_]*)\.([A-Za-z0-9_]+)\b/g)) {
    const owner = mm[1];
    const member = mm[2];
    if (!knownClasses.has(owner)) continue;
    if (member === 'length' || member === 'name') continue;
    if (!classMembers.has(owner + '.' + member)) {
      fail(rel + ' → 调用了不存在的静态成员 ' + owner + '.' + member);
    }
  }
}
ok('导出类 ' + knownClasses.size + ' 个，静态成员 ' + classMembers.size + ' 个，交叉调用已校验');

// ── 6. 声明文件存在性 ──
console.log('\n=== 6. 声明的文件 ===');
function checkModule(label, moduleJsonPath, pagesProfilePath, etsRoot) {
  if (!fs.existsSync(moduleJsonPath)) return;
  const moduleJson = fs.readFileSync(moduleJsonPath, 'utf8');
  const rel = path.relative(ROOT, pagesProfilePath).replace(/\\/g, '/');
  if (fs.existsSync(pagesProfilePath)) {
    const pages = JSON.parse(fs.readFileSync(pagesProfilePath, 'utf8'));
    for (const p of pages.src) {
      const f = path.join(etsRoot, p + '.ets');
      if (fs.existsSync(f)) ok(label + ' 页面 ' + p);
      else fail(rel + ' 声明的页面不存在: ' + p);
    }
  } else {
    fail('缺少页面清单: ' + rel);
  }
  const m = /"srcEntry"\s*:\s*"([^"]+)"/.exec(moduleJson);
  if (m) {
    const f = path.join(path.dirname(moduleJsonPath), m[1].replace(/^\.\//, ''));
    if (fs.existsSync(f)) ok(label + ' Ability ' + m[1]);
    else fail(path.relative(ROOT, moduleJsonPath).replace(/\\/g, '/') + ' srcEntry 不存在: ' + m[1]);
  }
}

checkModule(
  'main',
  path.join(MAIN, 'module.json5'),
  path.join(MAIN, 'resources', 'base', 'profile', 'main_pages.json'),
  path.join(MAIN, 'ets')
);
checkModule(
  'ohosTest',
  path.join(ENTRY, 'src', 'ohosTest', 'module.json5'),
  path.join(ENTRY, 'src', 'ohosTest', 'resources', 'base', 'profile', 'test_pages.json'),
  path.join(ENTRY, 'src', 'ohosTest', 'ets')
);

console.log('\n=== 结果 ===');
console.log('错误 ' + errors + ' 个，警告 ' + warns + ' 个');
process.exit(errors > 0 ? 1 : 0);
