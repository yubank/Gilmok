"use strict";

const assert = require("node:assert/strict");
const { spawn } = require("node:child_process");
const path = require("node:path");
const test = require("node:test");
const { checkTranslation, checkTranslations, replaceStem } = require("./checker");

test("way가 방향이면 방법을 길로 고친다", () => {
  const result = checkTranslation({
    english: "Go this way.",
    korean: "이 방법으로 가세요.",
  });
  assert.equal(result.ok, false);
  assert.equal(result.revised, "이 길로 가세요.");
  assert.equal(result.issues[0].found, "방법");
  assert.equal(result.issues[0].expected, "길");
});

test("출구로 이어진 way는 길이다", () => {
  const result = checkTranslation({
    english: "This is the way to the exit.",
    korean: "이것이 출구로 가는 방법입니다.",
  });
  assert.equal(result.revised, "이것이 출구로 가는 길입니다.");
});

test("수단인 way는 방법이다", () => {
  const result = checkTranslation({
    english: "There is a way to upgrade the tower.",
    korean: "포탑을 강화하는 길이 있습니다.",
  });
  assert.equal(result.revised, "포탑을 강화하는 방법이 있습니다.");
  assert.equal(result.issues[0].sense, "method");
});

test("길목 안의 길은 건드리지 않고 수단만 방법으로 고친다", () => {
  const result = checkTranslation({
    english: "There is a way to guard the chokepoint.",
    korean: "길목을 지킬 길이 있습니다.",
  });
  assert.equal(result.revised, "길목을 지킬 방법이 있습니다.");
});

test("굽은 way와 모든 way는 길이다", () => {
  assert.equal(
    checkTranslation({ english: "Learn the winding way.", korean: "굽은 방법을 익히십시오." }).revised,
    "굽은 길을 익히십시오.",
  );
  assert.equal(
    checkTranslation({ english: "Watch every way.", korean: "모든 방법을 살피십시오." }).revised,
    "모든 길을 살피십시오.",
  );
});

test("이미 자연스러운 길 표현은 그대로 둔다", () => {
  const samples = [
    ["A bonus craft follows the path quickly. Shoot it down for a large gold reward.", "보너스 우주선이 길을 빠르게 따라옵니다. 맞추면 골드를 많이 받습니다."],
    ["Place towers off the path. Place mines on the path.", "포탑은 길 밖에, 지뢰는 길 위에 설치합니다."],
    ["Tap the mine count to upgrade mines. When the gauge finishes, mines already on the path get stronger too.", "지뢰 개수를 누르면 지뢰를 강화합니다. 게이지가 끝나면 길에 깔린 지뢰도 함께 강해집니다."],
    ["Boss. Very high health. A leak costs 5 lives.", "보스. 체력이 매우 높습니다. 출구로 새면 라이프를 5 잃습니다."],
    ["All 30 stages cleared.", "30개 스테이지를 모두 클리어했습니다."],
    ["Gold is reset. Stage %d starts with a new fund.", "자금이 초기화되었습니다. 스테이지 %d는 새 자금으로 시작합니다."],
    ["The way to upgrade is simple.", "강화하는 방법은 간단합니다."],
    ["Find a way to place mines on the path.", "길에 지뢰를 놓는 방법을 찾으세요."],
    ["Drag the lock icon left or right to unlock", "잠금 아이콘을 좌우로 밀면 해제됩니다"],
    ["Saved game found", "저장된 게임이 있습니다"],
  ];
  for (const [english, korean] of samples) {
    const result = checkTranslation({ english, korean });
    assert.equal(result.ok, true, `${english} => ${result.revised}`);
    assert.equal(result.revised, korean);
  }
});

test("거절의 no way는 길로 바꾸지 않는다", () => {
  const result = checkTranslation({ english: "No way.", korean: "방법이 없습니다." });
  assert.equal(result.revised, "방법이 없습니다.");
  assert.equal(result.issues[0].sense, "refusal");
});

test("루트와 차선과 패스는 길로 고친다", () => {
  assert.equal(
    checkTranslation({ english: "Follow the route.", korean: "루트를 따라가세요." }).revised,
    "길을 따라가세요.",
  );
  assert.equal(
    checkTranslation({ english: "Watch every lane.", korean: "모든 차선을 살피십시오." }).revised,
    "모든 길을 살피십시오.",
  );
  assert.equal(
    checkTranslation({ english: "Stay on the path.", korean: "패스에 머무르세요." }).revised,
    "길에 머무르세요.",
  );
});

test("수단인 way가 있으면 경로 단어 때문에 방법을 길로 바꾸지 않는다", () => {
  const result = checkTranslation({
    english: "Find a way to defend the route.",
    korean: "그 루트를 지킬 방법을 찾으세요.",
  });
  assert.equal(result.revised, "그 길을 지킬 방법을 찾으세요.");
});

test("게임 용어 직역을 고친다", () => {
  assert.equal(
    checkTranslation({ english: "A bonus craft follows the path.", korean: "보너스 공예가 패스를 따라옵니다." }).revised,
    "보너스 우주선이 길을 따라옵니다.",
  );
  assert.equal(
    checkTranslation({ english: "Drag a tower onto the field.", korean: "타워를 들판으로 드래그합니다." }).revised,
    "포탑을 필드로 드래그합니다.",
  );
  assert.equal(
    checkTranslation({ english: "The next wave brings a boss.", korean: "다음 파도에 사장이 옵니다." }).revised,
    "다음 웨이브에 보스가 옵니다.",
  );
  assert.equal(
    checkTranslation({ english: "Upgrade mines with gold.", korean: "황금으로 광산을 업그레이드합니다." }).revised,
    "골드로 지뢰를 강화합니다.",
  );
  assert.equal(
    checkTranslation({ english: "Low health costs lives.", korean: "건강이 낮으면 인생을 잃습니다." }).revised,
    "체력이 낮으면 라이프를 잃습니다.",
  );
  assert.equal(
    checkTranslation({ english: "Stage 1 starts with a new fund.", korean: "무대 1은 새 펀드로 시작합니다." }).revised,
    "스테이지 1은 새 자금으로 시작합니다.",
  );
  assert.equal(
    checkTranslation({ english: "Recall the tower.", korean: "타워를 회상합니다." }).revised,
    "포탑을 회수합니다.",
  );
  assert.equal(
    checkTranslation({ english: "Defend every approach.", korean: "모든 접근법을 지키십시오." }).revised,
    "모든 접근로를 지키십시오.",
  );
});

test("조사 받침에 맞춰 방법과 길을 바꾼다", () => {
  assert.deepEqual(replaceStem("방법은 방법을 방법이 방법에 방법과 방법으로", "방법", "길"), {
    text: "길은 길을 길이 길에 길과 길로",
    count: 6,
  });
  assert.deepEqual(replaceStem("길은 길을 길이 길에 길과 길로", "길", "방법"), {
    text: "방법은 방법을 방법이 방법에 방법과 방법으로",
    count: 6,
  });
  assert.equal(replaceStem("길목을 막은 방법", "방법", "길").text, "길목을 막은 길");
});

test("여러 줄을 줄마다 검사한다", () => {
  const result = checkTranslations([
    { id: "move", english: "Go this way.", korean: "이 방법으로 가세요." },
    { id: "keep", english: "Follow the path.", korean: "길을 따라가세요." },
  ]);
  assert.equal(result.ok, false);
  assert.equal(result.results[0].revised, "이 길로 가세요.");
  assert.equal(result.results[1].ok, true);
});

test("MCP 도구가 way 직역을 고친다", async () => {
  const serverPath = path.join(__dirname, "index.js");
  const child = spawn(process.execPath, [serverPath], { stdio: ["pipe", "pipe", "pipe"] });
  let buffer = "";
  const pending = new Map();
  let nextId = 1;

  child.stdout.on("data", (chunk) => {
    buffer += chunk.toString("utf8");
    let newline = buffer.indexOf("\n");
    while (newline >= 0) {
      const line = buffer.slice(0, newline).trim();
      buffer = buffer.slice(newline + 1);
      newline = buffer.indexOf("\n");
      if (!line) continue;
      const message = JSON.parse(line);
      const waiter = pending.get(message.id);
      if (waiter) {
        pending.delete(message.id);
        waiter(message);
      }
    }
  });

  function request(method, params) {
    const id = nextId;
    nextId += 1;
    const response = new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error(`${method} timed out`)), 5000);
      pending.set(id, (message) => {
        clearTimeout(timer);
        resolve(message);
      });
    });
    child.stdin.write(`${JSON.stringify({ jsonrpc: "2.0", id, method, params })}\n`);
    return response;
  }

  try {
    const init = await request("initialize", {
      protocolVersion: "2024-11-05",
      capabilities: {},
      clientInfo: { name: "test", version: "0" },
    });
    assert.equal(init.result.serverInfo.name, "translation-checker");
    child.stdin.write(`${JSON.stringify({ jsonrpc: "2.0", method: "notifications/initialized" })}\n`);

    const listed = await request("tools/list", {});
    const names = listed.result.tools.map((tool) => tool.name);
    assert.deepEqual(names, ["check_translation", "check_translations", "translation_glossary"]);

    const called = await request("tools/call", {
      name: "check_translation",
      arguments: { english: "Go this way.", korean: "이 방법으로 가세요." },
    });
    const body = JSON.parse(called.result.content[0].text);
    assert.equal(body.revised, "이 길로 가세요.");
  } finally {
    child.kill();
  }
});
