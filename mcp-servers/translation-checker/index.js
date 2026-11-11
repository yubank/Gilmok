#!/usr/bin/env node
"use strict";

const { checkTranslation, checkTranslations, glossary } = require("./checker");

const SERVER = { name: "translation-checker", version: "1.0.0" };
const PROTOCOL = "2024-11-05";

const TOOLS = [
  {
    name: "check_translation",
    description: "영어 원문과 한국어 초안을 비교해 직역으로 어색해진 표현을 고칩니다. way가 길이나 방향이면 '방법' 대신 '길'을 쓰고, 수단이면 '길' 대신 '방법'을 씁니다. revised 문장을 최종 문구로 씁니다.",
    inputSchema: {
      type: "object",
      properties: {
        english: { type: "string", description: "영어 원문" },
        korean: { type: "string", description: "검사할 한국어 초안" },
        context: { type: "string", description: "화면이나 장르. 예: 타워디펜스 길목 방어" },
      },
      required: ["english", "korean"],
      additionalProperties: false,
    },
  },
  {
    name: "check_translations",
    description: "여러 영어·한국어 쌍을 한 번에 검사하고, 어색한 항목은 고친 문장으로 돌려줍니다.",
    inputSchema: {
      type: "object",
      properties: {
        context: { type: "string", description: "모든 항목에 공통으로 쓰는 맥락" },
        items: {
          type: "array",
          items: {
            type: "object",
            properties: {
              id: { type: "string" },
              english: { type: "string" },
              korean: { type: "string" },
              context: { type: "string" },
            },
            required: ["english", "korean"],
            additionalProperties: false,
          },
        },
      },
      required: ["items"],
      additionalProperties: false,
    },
  },
  {
    name: "translation_glossary",
    description: "길목 방어 문구를 한국어로 쓸 때 피하는 직역과 대신 쓸 말을 보여 줍니다.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false,
    },
  },
];

function send(message) {
  process.stdout.write(`${JSON.stringify(message)}\n`);
}

function toolText(value) {
  return {
    content: [{ type: "text", text: JSON.stringify(value, null, 2) }],
  };
}

function toolError(message) {
  return {
    isError: true,
    content: [{ type: "text", text: message }],
  };
}

function callTool(name, args) {
  const input = args && typeof args === "object" ? args : {};
  if (name === "translation_glossary") return toolText(glossary());
  if (name === "check_translation") {
    if (typeof input.english !== "string" || typeof input.korean !== "string") {
      return toolError("english와 korean 문자열이 필요합니다.");
    }
    return toolText(checkTranslation(input));
  }
  if (name === "check_translations") {
    if (!Array.isArray(input.items)) return toolError("items 배열이 필요합니다.");
    return toolText(checkTranslations(input.items, input.context));
  }
  return toolError(`알 수 없는 도구: ${name}`);
}

function handle(message) {
  if (!message || message.jsonrpc !== "2.0" || typeof message.method !== "string") return;
  const { id, method, params } = message;
  if (method === "notifications/initialized" || method === "notifications/cancelled") return;

  if (id === undefined) return;

  if (method === "initialize") {
    const requested = params && params.protocolVersion;
    send({
      jsonrpc: "2.0",
      id,
      result: {
        protocolVersion: typeof requested === "string" ? requested : PROTOCOL,
        capabilities: { tools: { listChanged: false } },
        serverInfo: SERVER,
      },
    });
    return;
  }

  if (method === "ping") {
    send({ jsonrpc: "2.0", id, result: {} });
    return;
  }

  if (method === "tools/list") {
    send({ jsonrpc: "2.0", id, result: { tools: TOOLS } });
    return;
  }

  if (method === "tools/call") {
    const name = params && params.name;
    const args = params && params.arguments;
    send({ jsonrpc: "2.0", id, result: callTool(name, args) });
    return;
  }

  send({
    jsonrpc: "2.0",
    id,
    error: { code: -32601, message: `Unknown method: ${method}` },
  });
}

function main() {
  let buffer = "";
  process.stdin.setEncoding("utf8");
  process.stdin.on("data", (chunk) => {
    buffer += chunk;
    buffer = drain(buffer);
  });
}

function drain(buffer) {
  while (buffer.length > 0) {
    if (buffer.startsWith("Content-Length:")) {
      const headerEnd = buffer.indexOf("\r\n\r\n");
      if (headerEnd < 0) return buffer;
      const header = buffer.slice(0, headerEnd);
      const match = header.match(/Content-Length:\s*(\d+)/i);
      if (!match) return buffer.slice(headerEnd + 4);
      const length = Number(match[1]);
      const start = headerEnd + 4;
      if (buffer.length < start + length) return buffer;
      const body = buffer.slice(start, start + length);
      buffer = buffer.slice(start + length);
      try {
        handle(JSON.parse(body));
      } catch {
        // Ignore malformed frames and keep reading.
      }
      continue;
    }

    const newline = buffer.indexOf("\n");
    if (newline < 0) return buffer;
    const line = buffer.slice(0, newline).trim();
    buffer = buffer.slice(newline + 1);
    if (!line) continue;
    try {
      handle(JSON.parse(line));
    } catch {
      // Ignore malformed lines and keep reading.
    }
  }
  return buffer;
}

if (require.main === module) main();

module.exports = { TOOLS, callTool, handle };
