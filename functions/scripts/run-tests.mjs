// Runs every test/**/*.test.ts file with Node's test runner (through tsx),
// on Windows, macOS and Linux alike (npm scripts cannot expand ** on
// Windows). No real AI is called: tests use fake providers.
//
//   npm test                      -> all tests
//   npm test -- gateway           -> only files whose path contains "gateway"

import {spawnSync} from "node:child_process";
import {readdirSync, statSync} from "node:fs";
import {join, relative} from "node:path";

function findTests(dir) {
  const files = [];
  for (const name of readdirSync(dir)) {
    const path = join(dir, name);
    if (statSync(path).isDirectory()) files.push(...findTests(path));
    else if (name.endsWith(".test.ts")) files.push(path);
  }
  return files;
}

const filter = process.argv[2];
const files = findTests("test")
  .map((file) => relative(".", file))
  .filter((file) => !filter || file.includes(filter))
  .sort();

if (files.length === 0) {
  console.error("No test files found.");
  process.exit(1);
}

const result = spawnSync(
  process.execPath,
  ["--import", "tsx", "--test", ...files],
  {stdio: "inherit"},
);
process.exit(result.status ?? 1);
