// AiProvider = the ONE place that talks to an AI company (C.6).
// Gemini today. Switching to OpenAI = one new adapter file + one line in
// aiGateway.ts. The gateway never knows which provider it uses.

export interface AiProviderRequest {
  system: string;
  user: string;
  temperature: number;
}

export interface AiProviderReply {
  /** The raw text of the answer (the gateway parses the JSON). */
  text: string;
  /** Only logged, never sent to the app. */
  inputTokens?: number;
  outputTokens?: number;
}

export interface AiProvider {
  readonly name: string;
  generate(request: AiProviderRequest): Promise<AiProviderReply>;
}

/** The provider could not answer (down, timeout, quota, bad key...). */
export class ProviderError extends Error {
  constructor(message: string, readonly status?: number) {
    super(message);
    this.name = "ProviderError";
  }
}
