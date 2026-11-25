// Tests for the AI gateway with fakes: no emulator, no network, no AI cost.
// Master Document B.1 task 21: unauthenticated call, over-limit call,
// invalid feature, invalid JSON from the provider (and the other codes).
//
// Run: npm test -- gateway

import assert from "node:assert/strict";
import {describe, it} from "node:test";

import type {Firestore} from "firebase-admin/firestore";
import {z} from "zod";

import {AI_LIMITS} from "../../src/ai/config";
import {
  ERROR_MESSAGES,
  GatewayDeps,
  GatewayLog,
  handleAiRequest,
} from "../../src/ai/gateway";
import {ProviderError} from "../../src/ai/providers/aiProvider";
import {FakeProvider} from "../../src/ai/providers/fakeProvider";
import {buildRegistry, registry as realRegistry} from "../../src/ai/registry";
import {FeatureModule} from "../../src/ai/types";
import {MemoryUsageStore, dateKeyIn} from "../../src/ai/usageStore";

// A tiny feature, so these tests do not depend on another member's module.
const echo: FeatureModule<{text: string}, {answer: string}> = {
  feature: "dailyTip",
  dailyLimit: 2,
  temperature: 0.7,
  payloadSchema: z.object({text: z.string().max(50)}).strict(),
  responseSchema: z.object({answer: z.string().min(1)}),
  buildPrompt: (payload) => ({system: "You give tips.", user: payload.text}),
  validateAgainstPayload: (_payload, response) =>
    response.answer === "forbidden" ? ["not allowed"] : [],
};

const GOOD = JSON.stringify({answer: "Study 25 minutes, rest 5."});

function setup(replies: Array<string | ProviderError>, module = echo) {
  const provider = new FakeProvider(replies);
  const usage = new MemoryUsageStore();
  const logs: GatewayLog[] = [];
  const persisted: unknown[] = [];
  const withPersist: FeatureModule = {
    ...module,
    persist: async (_ctx, data) => {
      persisted.push(data);
    },
  };
  const deps: GatewayDeps = {
    registry: buildRegistry([withPersist]),
    provider: () => provider,
    usage,
    db: {} as Firestore,
    now: () => new Date("2026-11-24T10:00:00Z"),
    log: (entry) => logs.push(entry),
  };
  return {deps, provider, usage, logs, persisted};
}

const request = (payload: unknown = {text: "tip please"}) => ({
  feature: "dailyTip",
  payload,
});

describe("aiGateway", () => {
  it("success: validated data and the calls left today", async () => {
    const {deps, provider, persisted} = setup([GOOD]);

    const result = await handleAiRequest("u1", request(), deps);

    assert.deepEqual(result, {
      ok: true,
      data: {answer: "Study 25 minutes, rest 5."},
      usage: {remainingToday: 1, feature: "dailyTip"},
    });
    assert.equal(provider.requests.length, 1);
    assert.equal(provider.requests[0].temperature, 0.7);
    assert.equal(persisted.length, 1, "the persist hook ran");
  });

  it("unauthenticated: rejected before anything else", async () => {
    const {deps, provider} = setup([GOOD]);

    const result = await handleAiRequest(undefined, request(), deps);

    assert.deepEqual(result, {
      ok: false,
      error: {code: "unauthenticated", message: ERROR_MESSAGES.unauthenticated},
    });
    assert.equal(provider.requests.length, 0);
  });

  it("invalid feature: unknown name, bad shape or bad payload", async () => {
    const {deps, provider} = setup([GOOD]);
    const bad = [
      {feature: "hackTheServer", payload: {}},
      {feature: "dailyTip"}, // no payload
      {feature: "dailyTip", payload: []}, // not an object
      null,
      request({text: "x", extra: "smuggled"}), // strict payload
    ];

    for (const data of bad) {
      const result = await handleAiRequest("u1", data, deps);
      assert.equal(result.ok, false);
      if (!result.ok) assert.equal(result.error.code, "invalid_feature");
    }
    assert.equal(provider.requests.length, 0, "the AI is never called");
  });

  it("payload too large: over 20 KB is refused", async () => {
    const {deps, provider} = setup([GOOD]);
    const big = {text: "x".repeat(AI_LIMITS.maxPayloadBytes + 1)};

    const result = await handleAiRequest("u1", request(big), deps);

    assert.equal(result.ok, false);
    if (!result.ok) assert.equal(result.error.code, "payload_too_large");
    assert.equal(provider.requests.length, 0);
  });

  it("over the daily limit: rate_limited with 0 left", async () => {
    const {deps, provider} = setup([GOOD]);

    await handleAiRequest("u1", request(), deps);
    await handleAiRequest("u1", request(), deps); // limit is 2
    const third = await handleAiRequest("u1", request(), deps);

    assert.equal(third.ok, false);
    if (!third.ok) {
      assert.equal(third.error.code, "rate_limited");
      assert.deepEqual(third.usage, {remainingToday: 0, feature: "dailyTip"});
    }
    assert.equal(provider.requests.length, 2);
  });

  it("the limit is per user", async () => {
    const {deps} = setup([GOOD]);

    await handleAiRequest("u1", request(), deps);
    await handleAiRequest("u1", request(), deps);
    const other = await handleAiRequest("u2", request(), deps);

    assert.equal(other.ok, true);
  });

  it("invalid JSON once: one repair retry, then success", async () => {
    const {deps, provider, logs} = setup(["```json\n{}\n```", GOOD]);

    const result = await handleAiRequest("u1", request(), deps);

    assert.equal(result.ok, true);
    assert.equal(provider.requests.length, 2);
    assert.match(provider.requests[1].user, /valid JSON/);
    assert.equal(logs.at(-1)?.attempts, 2);
  });

  it("invalid JSON twice: invalid_response, the call still counts", async () => {
    const {deps, provider} = setup(["HACKED", "still not json"]);

    const result = await handleAiRequest("u1", request(), deps);

    assert.equal(result.ok, false);
    if (!result.ok) {
      assert.equal(result.error.code, "invalid_response");
      assert.equal(result.usage?.remainingToday, 1);
    }
    assert.equal(provider.requests.length, 2, "only ONE retry");
  });

  it("wrong shape or failed cross-check counts as invalid", async () => {
    for (const reply of [
      JSON.stringify({answer: ""}),
      JSON.stringify({answer: "forbidden"}),
    ]) {
      const {deps} = setup([reply]);
      const result = await handleAiRequest("u1", request(), deps);
      assert.equal(result.ok, false);
      if (!result.ok) assert.equal(result.error.code, "invalid_response");
    }
  });

  it("provider down: provider_unavailable and the call is given back", async () => {
    const {deps, usage} = setup([new ProviderError("Gemini HTTP 503", 503)]);

    const result = await handleAiRequest("u1", request(), deps);

    assert.equal(result.ok, false);
    if (!result.ok) {
      assert.equal(result.error.code, "provider_unavailable");
      assert.equal(result.usage?.remainingToday, 2);
    }
    const day = usage.counts.get(`u1/${dateKeyIn(deps.now(), "UTC")}`);
    assert.equal(day?.total, 0);
  });

  it("a crash inside a module becomes internal", async () => {
    const broken: FeatureModule = {
      ...echo,
      buildPrompt: () => {
        throw new Error("bug");
      },
    };
    const {deps} = setup([GOOD], broken);

    const result = await handleAiRequest("u1", request(), deps);

    assert.equal(result.ok, false);
    if (!result.ok) assert.equal(result.error.code, "internal");
  });

  it("logs never contain the payload, the prompt or the answer", async () => {
    const {deps, logs} = setup([GOOD]);

    await handleAiRequest("u1", request({text: "my secret note"}), deps);

    const text = JSON.stringify(logs);
    assert.doesNotMatch(text, /secret note|Study 25|u1/);
    assert.deepEqual(Object.keys(logs[0]).sort(), [
      "attempts",
      "durationMs",
      "feature",
      "inputTokens",
      "outputTokens",
      "status",
    ]);
  });
});

describe("registry", () => {
  it("contains studyPlan (M2)", () => {
    assert.ok(realRegistry.has("studyPlan"));
  });

  it("refuses unknown and repeated features", () => {
    assert.throws(() => buildRegistry([{...echo, feature: "nope"}]));
    assert.throws(() => buildRegistry([echo, echo]));
  });
});

describe("dateKeyIn", () => {
  it("uses the user's time zone", () => {
    // 23:30 UTC on the 24th is already the 25th in Cairo (UTC+2).
    const late = new Date("2026-11-24T23:30:00Z");
    assert.equal(dateKeyIn(late, "UTC"), "2026-11-24");
    assert.equal(dateKeyIn(late, "Africa/Cairo"), "2026-11-25");
  });

  it("a wrong time zone falls back to UTC", () => {
    assert.equal(dateKeyIn(new Date("2026-11-24T10:00:00Z"), "Mars/Base"),
      "2026-11-24");
  });
});
