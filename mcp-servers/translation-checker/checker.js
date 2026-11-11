"use strict";

const PATH_WORDS = new Set([
  "path", "paths", "road", "roads", "route", "routes", "lane", "lanes",
  "corridor", "corridors", "entrance", "entrances", "exit", "exits",
  "trail", "trails", "street", "streets", "alley", "bridge", "crossing",
  "detour", "perimeter", "crossings", "detours",
]);

const PLACES = new Set([
  ...PATH_WORDS,
  "center", "centre", "side", "left", "right", "back", "front", "base",
  "gate", "home", "end", "start", "middle", "inside", "outside", "tower",
  "field", "line", "corner", "edge", "stage", "chokepoint",
]);

const VERBS = new Set([
  "do", "make", "get", "go", "use", "place", "put", "move", "upgrade",
  "defend", "attack", "build", "shoot", "repair", "start", "stop", "keep",
  "take", "find", "clear", "beat", "defeat", "hold", "watch", "cover",
  "block", "slow", "hit", "reach", "follow", "enter", "leave", "turn",
  "cross", "merge", "split", "overlap", "drag", "tap", "press", "learn",
  "prepare", "secure", "balance", "spread", "stack", "choose", "fix",
  "install", "fire", "aim", "guard", "protect", "win", "lose", "save",
  "load", "play", "open", "close", "raise", "lower", "add", "remove",
  "avoid", "prevent", "kill", "damage", "need", "want", "try", "help",
  "continue", "begin", "end", "unlock", "lock", "spend", "buy", "sell",
  "pass", "escape", "survive", "destroy", "break", "charge", "wait",
]);

const PARTICLES = [
  "으로써", "으로서", "으로부터", "로부터", "이라고", "라도",
  "까지", "부터", "마다", "밖에", "처럼", "보다", "조차", "이나마",
  "이라도", "대로", "하고", "이나", "에서", "에게", "한테", "으로",
  "은", "는", "을", "를", "과", "와", "이", "가", "의", "에", "도",
  "만", "로", "라고",
];

const GLOSSARY = [
  {
    term: "path",
    sense: "path",
    message: "path는 길이므로 '길'로 씁니다.",
    test: (tokens) => tokens.includes("path") || tokens.includes("paths"),
    swaps: [["패스", "길"], ["방법", "길"]],
  },
  {
    term: "route",
    sense: "path",
    message: "route는 길이므로 '길'로 씁니다.",
    test: (tokens) => tokens.includes("route") || tokens.includes("routes"),
    swaps: [["루트", "길"], ["방법", "길"]],
  },
  {
    term: "lane",
    sense: "path",
    message: "lane은 길이므로 '길'로 씁니다.",
    test: (tokens) => tokens.includes("lane") || tokens.includes("lanes"),
    swaps: [["차선", "길"], ["레인", "길"], ["방법", "길"]],
  },
  {
    term: "road",
    sense: "path",
    message: "road는 길이므로 '길'로 씁니다.",
    test: (tokens) => tokens.includes("road") || tokens.includes("roads"),
    swaps: [["로드", "길"], ["방법", "길"]],
  },
  {
    term: "corridor",
    sense: "path",
    message: "corridor는 '통로'로 씁니다.",
    test: (tokens) => tokens.includes("corridor") || tokens.includes("corridors"),
    swaps: [["코리도", "통로"]],
  },
  {
    term: "approach",
    sense: "path",
    message: "길로 들어오는 approach는 '접근로'로 씁니다.",
    test: approachIsPath,
    swaps: [["접근법", "접근로"], ["어프로치", "접근로"]],
  },
  {
    term: "craft",
    sense: "vehicle",
    message: "하늘로 지나가는 craft는 '우주선'으로 씁니다.",
    test: craftIsVehicle,
    swaps: [["공예품", "우주선"], ["공예", "우주선"], ["크래프트", "우주선"]],
  },
  {
    term: "tower",
    sense: "tower",
    message: "tower는 '포탑'으로 씁니다.",
    test: (tokens) => tokens.includes("tower") || tokens.includes("towers"),
    swaps: [["타워", "포탑"]],
  },
  {
    term: "mine",
    sense: "mine",
    message: "길에 설치하는 mine은 '지뢰'로 씁니다.",
    test: mineIsWeapon,
    swaps: [["광산", "지뢰"], ["마인", "지뢰"]],
  },
  {
    term: "wave",
    sense: "wave",
    message: "몰려오는 wave는 '웨이브'로 씁니다.",
    test: waveIsRound,
    swaps: [["파도", "웨이브"], ["물결", "웨이브"]],
  },
  {
    term: "lives",
    sense: "lives",
    message: "남은 기회인 lives는 '라이프'로 씁니다.",
    test: livesAreHearts,
    swaps: [["인생", "라이프"], ["삶", "라이프"]],
  },
  {
    term: "boss",
    sense: "boss",
    message: "boss는 '보스'로 씁니다.",
    test: (tokens) => tokens.includes("boss") || tokens.includes("bosses"),
    swaps: [["상사", "보스"], ["사장", "보스"]],
  },
  {
    term: "stage",
    sense: "stage",
    message: "stage는 '스테이지'로 씁니다.",
    test: (tokens) => tokens.includes("stage") || tokens.includes("stages"),
    swaps: [["무대", "스테이지"]],
  },
  {
    term: "gold",
    sense: "gold",
    message: "gold는 '골드'로 씁니다.",
    test: (tokens) => tokens.includes("gold"),
    swaps: [["황금", "골드"], ["금화", "골드"]],
  },
  {
    term: "upgrade",
    sense: "upgrade",
    message: "upgrade는 '강화'로 씁니다.",
    test: (tokens) => tokens.some((token) => token === "upgrade" || token === "upgrades" || token === "upgraded" || token === "upgrading"),
    swaps: [["업그레이드", "강화"]],
  },
  {
    term: "health",
    sense: "health",
    message: "health는 '체력'으로 씁니다.",
    test: (tokens) => tokens.includes("health"),
    swaps: [["건강", "체력"]],
  },
  {
    term: "field",
    sense: "field",
    message: "전투가 벌어지는 field는 '필드'로 씁니다.",
    test: (tokens) => tokens.includes("field") || tokens.includes("fields"),
    swaps: [["들판", "필드"]],
  },
  {
    term: "fund",
    sense: "fund",
    message: "fund는 '자금'으로 씁니다.",
    test: (tokens) => tokens.includes("fund") || tokens.includes("funds"),
    swaps: [["펀드", "자금"], ["기금", "자금"]],
  },
  {
    term: "recall",
    sense: "recall",
    message: "설치물을 거두는 recall은 '회수'로 씁니다.",
    test: (tokens) => tokens.some((token) => token === "recall" || token === "recalls" || token === "recalled"),
    swaps: [["회상", "회수"], ["상기", "회수"]],
  },
];

function tokenize(english) {
  return [...String(english).matchAll(/[A-Za-z]+(?:'[A-Za-z]+)?/g)].map((match) => match[0].toLowerCase());
}

function looksLikeVerb(word) {
  if (!word) return false;
  if (VERBS.has(word)) return true;
  if (word.endsWith("ing") && word.length > 5 && !["thing", "something", "nothing", "everything", "morning", "evening", "during"].includes(word)) {
    return true;
  }
  if (word.endsWith("ed") && word.length > 4) return true;
  return false;
}

function looksLikePlace(word) {
  return PLACES.has(word);
}

function approachIsPath(tokens) {
  const hits = [];
  tokens.forEach((token, index) => {
    if (token !== "approach" && token !== "approaches") return;
    const next1 = tokens[index + 1] || "";
    const next2 = tokens[index + 2] || "";
    hits.push(!(next1 === "to" && looksLikeVerb(next2)));
  });
  return hits.length > 0 && hits.every(Boolean);
}

function craftIsVehicle(tokens) {
  const cues = new Set(["bonus", "ship", "aircraft", "shoot", "flew", "flies", "flying"]);
  const hasCraft = tokens.includes("craft") || tokens.includes("crafts");
  return hasCraft && tokens.some((token) => cues.has(token));
}

function mineIsWeapon(tokens) {
  return tokens.some((token, index) => {
    if (token !== "mine" && token !== "mines") return false;
    const prev = tokens[index - 1] || "";
    return prev !== "of" && prev !== "gold";
  });
}

function waveIsRound(tokens) {
  return tokens.some((token, index) => {
    if (token !== "wave" && token !== "waves") return false;
    const prev = tokens[index - 1] || "";
    return !["sound", "radio", "shock", "heat", "light", "brain", "new"].includes(prev);
  });
}

function livesAreHearts(tokens) {
  return tokens.some((token, index) => {
    if (token !== "lives") return false;
    const prev = tokens[index - 1] || "";
    return !["he", "she", "it", "who", "that", "someone", "everybody", "everyone"].includes(prev);
  });
}

function classifyWay(tokens, index) {
  const prev1 = tokens[index - 1] || "";
  const prev2 = tokens[index - 2] || "";
  const prev3 = tokens[index - 3] || "";
  const next1 = tokens[index + 1] || "";
  const next2 = tokens[index + 2] || "";
  const next3 = tokens[index + 3] || "";
  const possessive = new Set(["the", "your", "his", "her", "their", "our", "its", "my"]);

  if (prev1 === "either") return { sense: "idiom", strong: true };
  if (prev1 === "any" && !["through", "around", "ahead", "back", "forward"].includes(next1)) {
    return { sense: "idiom", strong: true };
  }
  if ((prev3 === "out" && prev2 === "of" && prev1 === "the") || (prev2 === "out" && prev1 === "of")) {
    return { sense: "path", strong: true };
  }
  if (prev1 === "no" && next1 === "to" && looksLikeVerb(next2)) return { sense: "method", strong: true };
  if (prev1 === "no") return { sense: "refusal", strong: true };
  if ((prev2 === "in" || prev2 === "on" || prev2 === "along") && possessive.has(prev1)) {
    return { sense: "path", strong: true };
  }
  if (prev2 === "all" && prev1 === "the") return { sense: "path", strong: true };
  if (["give", "make", "block", "clear", "follow", "along", "down", "up"].includes(prev1)) {
    return { sense: "path", strong: true };
  }
  if (next1 === "to" && next2 === "the" && looksLikePlace(next3)) return { sense: "path", strong: true };
  if (next1 === "to" && looksLikePlace(next2)) return { sense: "path", strong: true };
  if (next1 === "to" && looksLikeVerb(next2)) return { sense: "method", strong: true };
  if (next1 === "of" && (looksLikeVerb(next2) || (next2.endsWith("ing") && next2.length > 5))) {
    return { sense: "method", strong: true };
  }
  if (["through", "around", "ahead", "back", "forward", "across", "along", "past", "toward", "towards", "into"].includes(next1)) {
    return { sense: "direction", strong: true };
  }
  if (["this", "that", "which", "every", "each"].includes(prev1)) return { sense: "direction", strong: true };
  if (["long", "winding", "narrow", "main", "same", "other", "whole", "blocked"].includes(prev1)) {
    return { sense: "path", strong: true };
  }
  if (["best", "only", "right", "wrong", "proper", "possible", "effective", "sure", "easy", "another"].includes(prev1)) {
    return { sense: "method", strong: true };
  }
  return { sense: "path", strong: false };
}

function waySenses(tokens, context) {
  const senses = [];
  tokens.forEach((token, index) => {
    if (token !== "way" && token !== "ways") return;
    senses.push(classifyWay(tokens, index));
  });
  const methodContext = typeof context === "string" && /사용법|설명서|how-?to|method/i.test(context);
  if (methodContext && senses.length > 0 && senses.every((item) => item.sense === "path" && !item.strong)) {
    return senses.map(() => ({ sense: "method", strong: true }));
  }
  return senses;
}

function jongseong(word) {
  const code = word.charCodeAt(word.length - 1);
  if (code < 0xac00 || code > 0xd7a3) return -1;
  return (code - 0xac00) % 28;
}

function adjustParticle(stem, particle) {
  const jong = jongseong(stem);
  const batchim = jong > 0;
  const rieul = jong === 8;
  switch (particle) {
    case "은":
    case "는":
      return batchim ? "은" : "는";
    case "을":
    case "를":
      return batchim ? "을" : "를";
    case "이":
    case "가":
      return batchim ? "이" : "가";
    case "과":
    case "와":
      return batchim ? "과" : "와";
    case "으로":
    case "로":
      return !batchim || rieul ? "로" : "으로";
    case "으로써":
    case "로서":
      return !batchim || rieul ? "로써" : "으로써";
    case "으로부터":
    case "로부터":
      return !batchim || rieul ? "로부터" : "으로부터";
    case "이나":
    case "나":
      return batchim ? "이나" : "나";
    case "이라도":
    case "라도":
      return batchim ? "이라도" : "라도";
    case "이라고":
    case "라고":
      return batchim ? "이라고" : "라고";
    default:
      return particle;
  }
}

function isWordStart(text, index) {
  if (index === 0) return true;
  return /[\s.,!?;:…"~"'“”(\[\{「『]/.test(text[index - 1]);
}

const KEEPING_ENDINGS = [
  "이었습니다", "이었어요", "였습니다", "했습니다", "하였습니다", "하겠습니다",
  "입니다", "입니까", "인가요", "이었다", "이에요", "합니다", "합니까", "합시다",
  "하세요", "하였다", "한다", "했다", "하고", "하면", "하며", "하여",
  "하니", "하는", "하던", "하지", "하자", "해도", "해서", "해야", "해요", "이다",
  "인가", "함", "하다",
].sort((left, right) => right.length - left.length);

function boundaryAfter(rest, particle) {
  if (rest === "" || /^[\s.,!?;:…"~"'“”)\]\}」』]/.test(rest)) return true;
  if (rest.startsWith("요")) return boundaryAfter(rest.slice(1), "");
  if (particle === "이" || particle === "가") {
    const copulas = ["습니다", "었습니다", "었어요", "었다", "에요", "예요", "다", "며", "면", "고"];
    for (const ending of copulas) {
      if (!rest.startsWith(ending)) continue;
      const tail = rest.slice(ending.length);
      if (tail === "" || /^[\s.,!?;:…"~"'“”)\]\}」』]/.test(tail) || tail.startsWith("요")) return true;
    }
  }
  if (particle === "" && hasKeepingEnding(rest)) return true;
  return false;
}

function hasKeepingEnding(rest) {
  for (const ending of KEEPING_ENDINGS) {
    if (!rest.startsWith(ending)) continue;
    const tail = rest.slice(ending.length);
    if (tail === "" || /^[\s.,!?;:…"~"'“”)\]\}」』]/.test(tail) || tail.startsWith("요")) return true;
  }
  return false;
}

function longestParticle(after) {
  for (const particle of PARTICLES) {
    if (after.startsWith(particle) && boundaryAfter(after.slice(particle.length), particle)) return particle;
  }
  if (boundaryAfter(after, "")) return "";
  return null;
}

function replaceStem(text, from, to) {
  let result = "";
  let count = 0;
  let index = 0;
  while (index < text.length) {
    if (text.startsWith(from, index) && isWordStart(text, index)) {
      const after = text.slice(index + from.length);
      const particle = longestParticle(after);
      if (particle !== null) {
        result += to + adjustParticle(to, particle);
        count += 1;
        index += from.length + particle.length;
        continue;
      }
    }
    result += text[index];
    index += 1;
  }
  return { text: result, count };
}

function containsStem(text, stem) {
  return replaceStem(text, stem, stem).count > 0;
}

function issue(term, sense, found, expected, message) {
  return { term, sense, found, expected, message };
}

function applyWay(tokens, korean, senses) {
  const issues = [];
  let revised = korean;
  const names = senses.map((item) => item.sense);
  const pathLike = names.includes("path") || names.includes("direction");
  const method = names.includes("method");
  const refusal = names.includes("refusal");
  const idiom = names.includes("idiom");
  const pathNoun = tokens.some((token) => PATH_WORDS.has(token));

  if (pathLike && !method && containsStem(revised, "방법")) {
    const sense = names.includes("path") ? "path" : "direction";
    const message = sense === "direction"
      ? "way가 방향을 가리키면 '방법'이 아니라 '길'로 씁니다."
      : "way가 길을 가리키면 '방법'이 아니라 '길'로 씁니다.";
    const replaced = replaceStem(revised, "방법", "길");
    if (replaced.count > 0) {
      issues.push(issue("way", sense, "방법", "길", message));
      revised = replaced.text;
    }
  } else if (method && !pathLike && !pathNoun && containsStem(revised, "길") && !containsStem(revised, "방법")) {
    const replaced = replaceStem(revised, "길", "방법");
    if (replaced.count > 0) {
      issues.push(issue("way", "method", "길", "방법", "way가 수단을 가리키면 '길'이 아니라 '방법'으로 씁니다."));
      revised = replaced.text;
    }
  } else if (method && pathLike && (containsStem(revised, "방법") || containsStem(revised, "길"))) {
    issues.push(issue(
      "way",
      "mixed",
      "방법",
      "길",
      "한 문장에 길의 way와 수단의 way가 함께 있습니다. 경로를 가리키는 쪽만 '길'로 두고, 수단은 '방법'으로 둡니다.",
    ));
  }

  if (refusal && containsStem(revised, "방법")) {
    issues.push(issue("way", "refusal", "방법", "그럴 수 없습니다", "거절의 no way는 '방법'보다 '그럴 수 없습니다'에 가깝습니다."));
  }
  if (idiom && /어느\s*방법|어떤\s*방법|아무\s*방법/.test(revised)) {
    issues.push(issue("way", "idiom", "방법", "어느 쪽이든", "either way와 any way는 '어느 쪽이든'처럼 씁니다."));
  }
  return { issues, korean: revised, method };
}

function applyGlossary(tokens, korean, protectMethod) {
  const issues = [];
  let revised = korean;
  for (const rule of GLOSSARY) {
    if (!rule.test(tokens)) continue;
    for (const [from, to] of rule.swaps) {
      if (from === "방법" && protectMethod) continue;
      if (!containsStem(revised, from)) continue;
      const replaced = replaceStem(revised, from, to);
      if (replaced.count === 0) continue;
      issues.push(issue(rule.term, rule.sense, from, to, rule.message));
      revised = replaced.text;
    }
  }
  return { issues, korean: revised };
}

function checkLine(english, korean, context) {
  const tokens = tokenize(english);
  const senses = waySenses(tokens, context);
  const way = applyWay(tokens, korean, senses);
  const glossary = applyGlossary(tokens, way.korean, way.method);
  const issues = [...way.issues, ...glossary.issues];
  return {
    ok: issues.length === 0,
    issues,
    revised: glossary.korean,
    original: korean,
  };
}

function checkTranslation({ english, korean, context } = {}) {
  if (typeof english !== "string" || typeof korean !== "string") {
    throw new TypeError("english와 korean은 문자열이어야 합니다.");
  }
  const englishLines = english.split(/\r?\n/);
  const koreanLines = korean.split(/\r?\n/);
  const newline = korean.includes("\r\n") ? "\r\n" : "\n";
  if (englishLines.length > 1 && englishLines.length === koreanLines.length) {
    const checked = englishLines.map((line, index) => checkLine(line, koreanLines[index], context));
    return {
      ok: checked.every((item) => item.ok),
      issues: checked.flatMap((item, index) => item.issues.map((entry) => ({ ...entry, line: index + 1 }))),
      revised: checked.map((item) => item.revised).join(newline),
      original: korean,
    };
  }
  return checkLine(english, korean, context);
}

function checkTranslations(items, context) {
  if (!Array.isArray(items)) throw new TypeError("items는 배열이어야 합니다.");
  const results = items.map((item, index) => {
    const result = checkTranslation({
      english: item && item.english,
      korean: item && item.korean,
      context: item && item.context ? item.context : context,
    });
    return { id: item && item.id ? item.id : String(index + 1), ...result };
  });
  return { ok: results.every((item) => item.ok), results };
}

function glossary() {
  return {
    principles: [
      "way가 길, 경로, 방향이면 길이다. 수단이면 방법이다.",
      "path, route, lane, road는 길이다.",
      "거절의 no way는 '그럴 수 없습니다'에 가깝다.",
    ],
    terms: GLOSSARY.map((rule) => ({
      term: rule.term,
      sense: rule.sense,
      message: rule.message,
      prefer: rule.swaps.map((pair) => pair[1]),
      avoid: rule.swaps.map((pair) => pair[0]),
    })),
  };
}

module.exports = {
  adjustParticle,
  checkTranslation,
  checkTranslations,
  glossary,
  replaceStem,
  tokenize,
};
