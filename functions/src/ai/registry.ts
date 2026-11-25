// The feature registry (C.3). Each owner adds ONE import and ONE line.
// M1 does not write other members' prompts.
//
// To add your feature (see functions/README.md):
//   1. write src/ai/features/<yourFeature>.ts matching FeatureModule
//   2. import it below and add it to `modules`
//   3. npm test

import {KNOWN_FEATURES} from "./config";
import * as chat from "./features/chat";
import * as dailyTip from "./features/dailyTip";
import * as habitSuggest from "./features/habitSuggest";
import * as studyPlan from "./features/studyPlan";
import * as weeklyInsight from "./features/weeklyInsight";
import {FeatureModule} from "./types";

const modules: FeatureModule[] = [
  studyPlan, // M2
  habitSuggest, // M4
  chat, // M5
  dailyTip, // M5
  weeklyInsight, // M5
];

/** Builds the lookup table and refuses unknown or repeated names. */
export function buildRegistry(
  list: FeatureModule[],
  known: readonly string[] = KNOWN_FEATURES,
): ReadonlyMap<string, FeatureModule> {
  const map = new Map<string, FeatureModule>();
  for (const module of list) {
    if (!known.includes(module.feature)) {
      throw new Error(`Unknown AI feature "${module.feature}" (config.ts)`);
    }
    if (map.has(module.feature)) {
      throw new Error(`AI feature "${module.feature}" is registered twice`);
    }
    map.set(module.feature, module);
  }
  return map;
}

export const registry = buildRegistry(modules);
