// FakeProvider = an AiProvider for tests: no network, no cost (C.4 rule 7).
// It answers with the given replies in order and remembers every prompt.
//
//   const provider = new FakeProvider(['{"sessions":[]}']);
//   const provider = new FakeProvider([new ProviderError("down")]);

import {
  AiProvider,
  AiProviderReply,
  AiProviderRequest,
  ProviderError,
} from "./aiProvider";

export class FakeProvider implements AiProvider {
  readonly name = "fake";
  readonly requests: AiProviderRequest[] = [];

  constructor(private readonly replies: Array<string | ProviderError>) {}

  async generate(request: AiProviderRequest): Promise<AiProviderReply> {
    this.requests.push(request);
    const next = this.replies[Math.min(this.requests.length - 1, this.replies.length - 1)];
    if (next === undefined) throw new ProviderError("no fake reply");
    if (next instanceof ProviderError) throw next;
    return {text: next, inputTokens: 1, outputTokens: 1};
  }
}
