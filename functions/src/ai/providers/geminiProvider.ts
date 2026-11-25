// GeminiProvider = AiProvider for Google Gemini, through its REST API
// (Node 22 has fetch, so no extra library).
//
// JSON mode is always on (responseMimeType: application/json), as every
// feature answers with JSON (C.4 rule 3).
// The key comes from Secret Manager (defineSecret in aiGateway.ts). It is
// sent in a header, never in the URL, so it does not end up in logs.

import {GEMINI_MODEL, PROVIDER_TIMEOUT_MS} from "../config";
import {
  AiProvider,
  AiProviderReply,
  AiProviderRequest,
  ProviderError,
} from "./aiProvider";

interface GeminiResponse {
  candidates?: Array<{content?: {parts?: Array<{text?: string}>}}>;
  usageMetadata?: {promptTokenCount?: number; candidatesTokenCount?: number};
}

export class GeminiProvider implements AiProvider {
  readonly name = "gemini";

  constructor(
    private readonly apiKey: string,
    private readonly model: string = GEMINI_MODEL,
    private readonly timeoutMs: number = PROVIDER_TIMEOUT_MS,
    private readonly fetchFn: typeof fetch = fetch,
  ) {}

  async generate(request: AiProviderRequest): Promise<AiProviderReply> {
    if (!this.apiKey) throw new ProviderError("GEMINI_API_KEY is missing");

    const url = "https://generativelanguage.googleapis.com/v1beta/models/" +
      `${encodeURIComponent(this.model)}:generateContent`;

    let response: Response;
    try {
      response = await this.fetchFn(url, {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "x-goog-api-key": this.apiKey,
        },
        body: JSON.stringify({
          systemInstruction: {parts: [{text: request.system}]},
          contents: [{role: "user", parts: [{text: request.user}]}],
          generationConfig: {
            temperature: request.temperature,
            responseMimeType: "application/json",
          },
        }),
        signal: AbortSignal.timeout(this.timeoutMs),
      });
    } catch (error) {
      // Network error or timeout.
      throw new ProviderError(`Gemini request failed: ${errorName(error)}`);
    }

    if (!response.ok) {
      // 400 bad key/request, 429 quota, 5xx Gemini is down.
      throw new ProviderError(`Gemini HTTP ${response.status}`, response.status);
    }

    const body = (await response.json()) as GeminiResponse;
    const text = (body.candidates?.[0]?.content?.parts ?? [])
      .map((part) => part.text ?? "")
      .join("");

    return {
      text,
      inputTokens: body.usageMetadata?.promptTokenCount,
      outputTokens: body.usageMetadata?.candidatesTokenCount,
    };
  }
}

function errorName(error: unknown): string {
  return error instanceof Error ? error.name : "unknown";
}
