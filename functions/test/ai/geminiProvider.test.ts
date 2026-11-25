// Tests for GeminiProvider with a fake fetch (no network, no key needed).
// Run: npm test -- gemini

import assert from "node:assert/strict";
import {describe, it} from "node:test";

import {ProviderError} from "../../src/ai/providers/aiProvider";
import {GeminiProvider} from "../../src/ai/providers/geminiProvider";

type Call = {url: string; init: RequestInit};

function fakeFetch(status: number, body: unknown, calls: Call[] = []) {
  return (async (url: string, init: RequestInit) => {
    calls.push({url, init});
    return new Response(JSON.stringify(body), {status});
  }) as unknown as typeof fetch;
}

const request = {system: "sys", user: "hello", temperature: 0.3};

describe("GeminiProvider", () => {
  it("sends JSON mode, the key in a header, and returns the text", async () => {
    const calls: Call[] = [];
    const provider = new GeminiProvider("KEY123", "gemini-test", 1000,
      fakeFetch(200, {
        candidates: [{content: {parts: [{text: "{\"a\":"}, {text: "1}"}]}}],
        usageMetadata: {promptTokenCount: 10, candidatesTokenCount: 3},
      }, calls));

    const reply = await provider.generate(request);

    assert.deepEqual(reply, {text: "{\"a\":1}", inputTokens: 10, outputTokens: 3});
    assert.match(calls[0].url, /models\/gemini-test:generateContent$/);
    assert.doesNotMatch(calls[0].url, /KEY123/, "the key is not in the URL");
    const headers = calls[0].init.headers as Record<string, string>;
    assert.equal(headers["x-goog-api-key"], "KEY123");
    const body = JSON.parse(calls[0].init.body as string);
    assert.equal(body.generationConfig.responseMimeType, "application/json");
    assert.equal(body.generationConfig.temperature, 0.3);
    assert.equal(body.systemInstruction.parts[0].text, "sys");
  });

  it("an HTTP error becomes a ProviderError", async () => {
    const provider = new GeminiProvider("KEY", "m", 1000, fakeFetch(429, {}));
    await assert.rejects(provider.generate(request), ProviderError);
  });

  it("a network error becomes a ProviderError", async () => {
    const failing = (async () => {
      throw new TypeError("fetch failed");
    }) as unknown as typeof fetch;
    const provider = new GeminiProvider("KEY", "m", 1000, failing);
    await assert.rejects(provider.generate(request), ProviderError);
  });

  it("a missing key is a ProviderError (no call made)", async () => {
    const calls: Call[] = [];
    const provider = new GeminiProvider("", "m", 1000, fakeFetch(200, {}, calls));
    await assert.rejects(provider.generate(request), ProviderError);
    assert.equal(calls.length, 0);
  });
});
