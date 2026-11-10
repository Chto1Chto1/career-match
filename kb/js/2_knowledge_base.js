// =====================================================================
// Система подбора профессий. База знаний на JavaScript: факты, правила
// ЕСЛИ → ТО, разрешение конфликтов и рейтинг. Данные скопированы из
// 1_database.sql, база данных для запуска не нужна. Установка не нужна:
//   • браузер: F12 -> вкладка Console -> вставить весь файл -> Enter;
//   • онлайн-редактор JavaScript / Node.js (например, onecompiler.com);
//   • Node.js: node 2_knowledge_base.js
// =====================================================================

// ---------- Параметры модели (CONFIG) ----------
const CONFIG = {
  BONUS_RECOMMEND: 5,   // надбавка к баллу, если победило правило recommend
  MIN_SCORE: 40,        // порог: профессия с баллом ниже не рекомендуется
  SCORE_MIN: 0,         // нижняя граница итогового балла
  SCORE_MAX: 100        // верхняя граница итогового балла
};

// ---------- Данные: копия тестовых данных из 1_database.sql ----------
const SKILLS = [
  { skl_id: 1,  name: 'Python',        aliases: 'Питон, Python3, Py' },
  { skl_id: 2,  name: 'Django',        aliases: null },
  { skl_id: 3,  name: 'PostgreSQL',    aliases: 'Postgres, PgSQL' },
  { skl_id: 4,  name: 'SQL',           aliases: null },
  { skl_id: 5,  name: 'Git',           aliases: 'Гит' },
  { skl_id: 6,  name: 'Docker',        aliases: 'Докер' },
  { skl_id: 7,  name: 'JavaScript',    aliases: 'JS, Java Script' },
  { skl_id: 8,  name: 'React',         aliases: 'ReactJS, React.js' },
  { skl_id: 9,  name: 'HTML/CSS',      aliases: 'HTML, CSS' },
  { skl_id: 10, name: 'Excel',         aliases: 'Эксель, MS Excel' },
  { skl_id: 11, name: 'Statistics',    aliases: 'Статистика' },
  { skl_id: 12, name: 'Testing',       aliases: 'Тестирование, QA' },
  { skl_id: 13, name: 'Communication', aliases: 'Общение, Коммуникабельность' },
  { skl_id: 14, name: 'Teamwork',      aliases: 'Командная работа, Работа в команде' }
];

const PROFESSIONS = [
  { prof_id: 1, title: 'Python Developer',        avg_sal: 200000 },
  { prof_id: 2, title: 'Data Analyst',            avg_sal: 160000 },
  { prof_id: 3, title: 'Frontend Developer',      avg_sal: 180000 },
  { prof_id: 4, title: 'Project Manager',         avg_sal: 190000 },
  { prof_id: 5, title: 'QA Engineer',             avg_sal: 120000 },
  { prof_id: 6, title: 'Junior Python Developer', avg_sal: 90000 }
];

// [prof_id, skl_id, weight, is_req]
const REQUIREMENTS = [
  [1, 1, 5, true], [1, 2, 4, false], [1, 3, 3, false], [1, 5, 2, false], [1, 6, 3, false], [1, 13, 1, false],
  [2, 4, 5, true], [2, 1, 3, false], [2, 11, 4, false], [2, 10, 2, false], [2, 13, 1, false],
  [3, 7, 5, true], [3, 8, 4, false], [3, 9, 4, true], [3, 5, 2, false],
  [4, 13, 5, true], [4, 14, 4, true], [4, 10, 2, false],
  [5, 12, 5, true], [5, 4, 2, false], [5, 1, 2, false], [5, 5, 1, false],
  [6, 1, 5, true], [6, 5, 2, false], [6, 4, 2, false]
].map(([prof_id, skl_id, weight, is_req]) => ({ prof_id, skl_id, weight, is_req }));

// Правила сравнения (таблица COMPARISONS)
const COMPARISONS = [
  { rul_id: 1, prof_id: 1, cond_type: 'exp_years', operator: '>=', value: '3', action: 'score += 5' },
  { rul_id: 2, prof_id: 1, cond_type: 'exp_years', operator: '<',  value: '1', action: 'score -= 10' },
  { rul_id: 3, prof_id: 6, cond_type: 'exp_years', operator: '>',  value: '2', action: 'score -= 30' }
];

// Правила «ЕСЛИ -> ТО» (таблица KNOWLEDGE)
const KNOWLEDGE = [
  { rul_id: 1, name: 'Junior Python',                   condition: 'exp_years < 1 AND has_skill = Python',  conclusion: 'recommend: Junior Python Developer', priority: 10 },
  { rul_id: 2, name: 'Опытный Python-разработчик',      condition: 'exp_years >= 3 AND has_skill = Python', conclusion: 'recommend: Python Developer',        priority: 10 },
  { rul_id: 3, name: 'Слишком опытный для Junior',      condition: 'exp_years >= 3',                        conclusion: 'exclude: Junior Python Developer',   priority: 20 },
  { rul_id: 4, name: 'Python и SQL ведут в аналитику',  condition: 'has_skill = Python AND has_skill = SQL', conclusion: 'recommend: Data Analyst',            priority: 8 },
  { rul_id: 5, name: 'Бэкенд-опыт - не аналитик',       condition: 'exp_years >= 3 AND has_skill = Django', conclusion: 'exclude: Data Analyst',              priority: 12 },
  { rul_id: 6, name: 'Django ведёт в Python Developer', condition: 'has_skill = Django',                    conclusion: 'recommend: Python Developer',        priority: 5 }
];

// Правила проверки ввода (таблица VALIDATIONS)
const VALIDATIONS = [
  { field: 'email',     condition: 'REGEXP:^[^@ ]+@[^@ ]+[.][^@ ]+$',       err: 'Некорректный email' },
  { field: 'exp_years', condition: 'RANGE:0..60',                           err: 'Опыт должен быть от 0 до 60 лет' },
  { field: 'edu_level', condition: 'IN:school,college,bachelor,master,phd', err: 'Недопустимый уровень образования' },
  { field: 'sal_min',   condition: 'RANGE:0..10000000',                     err: 'Недопустимая минимальная зарплата' }
];

// Профили (PROFILES) и цели (GOALS) пользователей
const USERS = [
  { usr_id: 1, email: 'ivan@mail.ru', exp_years: 5, edu_level: 'master',
    skills: 'Python3, Django, Postgres, SQL, Git, Общение', sal_min: 150000 },
  { usr_id: 2, email: 'anna@mail.ru', exp_years: 0, edu_level: 'bachelor',
    skills: 'python, SQL, Git, Excel, Statistics, Teamwork, Figma', sal_min: 80000 }
];

// ---------- Слой 0. R0_INPUT: проверка ввода (VALIDATIONS) ----------
function validateUser(user) {
  return VALIDATIONS.filter((v) => {
    const val = user[v.field];
    if (val === undefined || val === null) return false;
    // числовые поля: строка, NaN и бесконечность - это ошибка ввода, а не допустимое значение
    if (v.condition.startsWith('RANGE:') && (typeof val !== 'number' || !Number.isFinite(val))) return true;
    const [kind, ...rest] = v.condition.split(':');
    const spec = rest.join(':');
    if (kind === 'REGEXP') return !new RegExp(spec).test(String(val));
    if (kind === 'RANGE') { const [lo, hi] = spec.split('..').map(parseFloat); return val < lo || val > hi; }
    if (kind === 'IN') return !spec.split(',').includes(String(val));
    return false;
  }).map((v) => v.err);
}

// ---------- Слой 1. Факты ----------
// «Python3», «python», «Питон» -> один и тот же ключ: нижний регистр, без пробелов
const norm = (s) => String(s).toLowerCase().replace(/\s+/g, '');

// Навык пользователя -> каноническое название из SKILLS (по имени или синониму)
function normalizeSkills(text) {
  text = text || '';   // нет навыков -> пустой набор, а не ошибка
  const found = new Set();
  text.split(',').map(norm).filter(Boolean).forEach((token) => {
    SKILLS.forEach((s) => {
      const names = [norm(s.name)].concat(s.aliases ? s.aliases.split(',').map(norm) : []);
      if (names.includes(token)) found.add(s.skl_id);
    });
  });
  return found; // множество skl_id
}

// Навыки из профиля, которых нет в справочнике SKILLS
function unknownSkills(text) {
  return text.split(',').map((t) => t.trim()).filter(Boolean).filter((t) =>
    !SKILLS.some((s) => [norm(s.name)].concat(s.aliases ? s.aliases.split(',').map(norm) : []).includes(norm(t))));
}

function computeFacts(user) {
  const skillIds = normalizeSkills(user.skills);
  return {
    exp_years: user.exp_years,
    edu_level: user.edu_level,
    has_skill: SKILLS.filter((s) => skillIds.has(s.skl_id)).map((s) => s.name),
    skillIds
  };
}

// ---------- Слой 2. Условия правил: «A AND B AND C» ----------
function parseCondition(text) {
  return text.split(' AND ').map((atom) => {
    const m = atom.trim().match(/^(\S+)\s+(!=|<=|>=|=|<|>)\s+(.+)$/);
    if (!m) throw new Error('Не разобрано условие: ' + atom);
    return { fact: m[1], op: m[2], val: m[3].trim() };
  });
}

const isNum = (v) => /^-?\d+(\.\d+)?$/.test(v);

function testAtom(facts, { fact, op, val }) {
  const values = [].concat(facts[fact] === undefined ? [] : facts[fact]);
  return values.some((f) => {
    if (isNum(val)) {
      if (typeof f !== 'number') return false;
      const v = parseFloat(val);
      return { '=': f === v, '!=': f !== v, '<': f < v, '<=': f <= v, '>': f > v, '>=': f >= v }[op];
    }
    if (typeof f !== 'string') return false;
    const a = f.toLowerCase(), b = val.toLowerCase();
    return op === '=' ? a === b : op === '!=' ? a !== b : false;
  });
}

const allTrue = (facts, cond) => parseCondition(cond).every((a) => testAtom(facts, a));

// Контроль самих правил: ошибка эксперта видна сразу
function checkRules() {
  const errs = [];
  const titles = PROFESSIONS.map((p) => p.title);
  KNOWLEDGE.forEach((k) => {
    const target = k.conclusion.split(':').slice(1).join(':').trim();
    if (!titles.includes(target)) errs.push(`K${k.rul_id}: неизвестная профессия в выводе`);
    parseCondition(k.condition).forEach((a) => {
      if (!['exp_years', 'edu_level', 'has_skill'].includes(a.fact)) errs.push(`K${k.rul_id}: неизвестный факт ${a.fact}`);
      if (a.fact === 'has_skill' && !SKILLS.some((s) => s.name === a.val)) errs.push(`K${k.rul_id}: навык ${a.val} отсутствует в справочнике`);
    });
  });
  COMPARISONS.forEach((c) => {
    if (!/^score [+-]= \d+(\.\d+)?$/.test(c.action)) errs.push(`C${c.rul_id}: неверный формат действия`);
  });
  return errs;
}

// ---------- Слой 3. Сработавшие правила и разрешение конфликтов ----------
function firedRules(facts) {
  return KNOWLEDGE.filter((k) => allTrue(facts, k.condition)).map((k) => {
    const [kind, ...rest] = k.conclusion.split(':');
    return { ...k, kind: kind.trim(), target: rest.join(':').trim() };
  });
}

// Для каждой профессии побеждает правило с наибольшим priority;
// при равенстве приоритетов exclude сильнее recommend
function resolveConflicts(fired) {
  const winners = {};
  fired.slice()
    .sort((a, b) => (b.priority - a.priority) ||
                    ((b.kind === 'exclude') - (a.kind === 'exclude')) ||
                    (a.rul_id - b.rul_id))
    .forEach((r) => { if (!winners[r.target]) winners[r.target] = r; });
  return winners;
}

// Правила сравнения COMPARISONS: суммарная поправка к баллу профессии
function comparisonDelta(facts, prof_id) {
  return COMPARISONS.filter((c) => c.prof_id === prof_id)
    .filter((c) => testAtom(facts, { fact: c.cond_type, op: c.operator, val: c.value }))
    .reduce((sum, c) => {
      const m = c.action.match(/^score ([+-])= (\d+(?:\.\d+)?)$/);
      return m ? sum + (m[1] === '-' ? -1 : 1) * parseFloat(m[2]) : sum;
    }, 0);
}

// ---------- Слой 4-5. Баллы, фильтры, рейтинг ----------
const round4 = (x) => Math.round(x * 1e4) / 1e4;

function recommend(user) {
  const facts = computeFacts(user);
  const fired = firedRules(facts);
  const winners = resolveConflicts(fired);

  const rows = PROFESSIONS.map((p) => {
    const reqs = REQUIREMENTS.filter((r) => r.prof_id === p.prof_id);
    const totalW = reqs.reduce((s, r) => s + r.weight, 0);
    const gotW = reqs.filter((r) => facts.skillIds.has(r.skl_id)).reduce((s, r) => s + r.weight, 0);
    const reqCnt = reqs.filter((r) => r.is_req).length;
    const reqGot = reqs.filter((r) => r.is_req && facts.skillIds.has(r.skl_id)).length;

    const base = round4(totalW > 0 ? 100 * gotW / totalW : 0);       // R1_SKILLS
    const delta = comparisonDelta(facts, p.prof_id);                  // R3_COMPARE
    const w = winners[p.title];
    const bonus = w && w.kind === 'recommend' ? CONFIG.BONUS_RECOMMEND : 0; // R4_KNOWLEDGE
    const score = round4(Math.min(CONFIG.SCORE_MAX, Math.max(CONFIG.SCORE_MIN, base + delta + bonus)));
    const reqOk = reqCnt === reqGot;                                   // R2_MANDATORY
    const matched = reqOk && score >= CONFIG.MIN_SCORE;               // + порог MIN_SCORE
    const byRule = !!(w && w.kind === 'exclude');                     // R4_KNOWLEDGE (exclude)
    const bySalary = user.sal_min != null && p.avg_sal != null && p.avg_sal < user.sal_min; // R5_SALARY
    const filtered = byRule || bySalary;
    return { usr_id: user.usr_id, prof_id: p.prof_id, title: p.title, gotW, totalW,
             base, delta, bonus, score, matched, filtered, rank_pos: null,
             reqOk, byRule, bySalary, wRul: w ? w.rul_id : null };
  });

  // R7_RANK: место получают подходящие и не отсеянные, по убыванию балла
  rows.filter((r) => r.matched && !r.filtered)
      .sort((a, b) => (b.score - a.score) || (a.prof_id - b.prof_id))
      .forEach((r, i) => { r.rank_pos = i + 1; });

  // Причина результата (объяснение для пользователя)
  rows.forEach((r) => {
    r.reason = r.byRule ? 'отсеяна правилом K' + r.wRul
             : r.bySalary ? 'зарплата профессии ниже желаемой'
             : !r.reqOk ? 'нет обязательного навыка'
             : !r.matched ? 'балл ниже порога ' + CONFIG.MIN_SCORE
             : 'рекомендована, место ' + r.rank_pos;
  });

  return { facts, fired, winners, rows };
}

// ---------- Запись результата: INSERT-запросы для RECOMMENDATIONS ----------
function toSql(rows) {
  const v = rows.map((r) => `(${r.usr_id}, ${r.prof_id}, ${r.score.toFixed(4)}, ${r.matched ? 1 : 0}, ` +
                            `${r.filtered ? 1 : 0}, ${r.rank_pos === null ? 'NULL' : r.rank_pos})`);
  return 'INSERT INTO RECOMMENDATIONS (usr_id, prof_id, score, matched, filtered, rank_pos) VALUES\n ' +
         v.join(',\n ') + ';';
}

// ---------- Запуск ----------
const pad = (s, n) => String(s).padEnd(n);
const allRows = [];
const ruleErrors = checkRules();
console.log('Контроль правил: ' + (ruleErrors.length ? ruleErrors.join('; ') : 'ошибок нет'));
USERS.forEach((u) => {
  const bad = validateUser(u);
  if (bad.length) { console.log(`\n=== Пользователь ${u.usr_id}: ошибки ввода - ${bad.join('; ')}. Подбор не выполняется ===`); return; }
  const res = recommend(u);
  console.log(`\n=== Пользователь ${u.usr_id} (${u.email}): опыт ${u.exp_years}, ${u.edu_level}, ` +
              `навыки: ${res.facts.has_skill.join(', ')} ===`);
  const unk = unknownSkills(u.skills);
  if (unk.length) console.log('Нет в справочнике навыков (в выводе не участвуют): ' + unk.join(', '));
  console.log(pad('место', 7) + pad('профессия', 26) + pad('балл', 10) + pad('скоринг', 9) + pad('отсеяна', 9) + 'причина');
  res.rows.slice()
    .sort((a, b) => ((a.rank_pos === null) - (b.rank_pos === null)) || (a.rank_pos - b.rank_pos) || (b.score - a.score))
    .forEach((r) => console.log(pad(r.rank_pos === null ? '-' : r.rank_pos, 7) + pad(r.title, 26) +
                                pad(r.score.toFixed(4), 10) + pad(r.matched ? 1 : 0, 9) + pad(r.filtered ? 1 : 0, 9) + r.reason));
  console.log('Сработавшие правила (объяснение):');
  res.fired.forEach((f) => {
    const win = res.winners[f.target] === f;
    console.log(`  K${f.rul_id} «${f.name}»: ЕСЛИ ${f.condition} ТО ${f.conclusion} (приоритет ${f.priority}) - ` +
                (win ? 'применено' : 'перекрыто правилом K' + res.winners[f.target].rul_id));
  });
  allRows.push(...res.rows);
});

console.log('\n--- SQL для записи в журнал RECOMMENDATIONS ---');
console.log(toSql(allRows));
