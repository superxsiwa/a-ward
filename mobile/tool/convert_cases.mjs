// Converts superxsiwa's bundled cases (backend/src/services/beds/bed1.ts .. bed8.ts) into
// mobile/assets/cases/bed01.json .. bed08.json, unchanged and in his BedCasePayload shape, so the
// same parser reads his "award_ccu_cases.json" exports.
//
//   node tool/convert_cases.mjs           write the JSON files
//   node tool/convert_cases.mjs --check   exit 1 if the JSON differs from his .ts files
//
// Run from mobile/. No dependencies: each .ts file is one typed object literal, which is
// evaluated as plain JavaScript once its import line and type annotation are stripped.

import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import vm from 'node:vm';

const mobileDir = join(dirname(fileURLToPath(import.meta.url)), '..');
const bedsDir = join(mobileDir, '..', 'backend', 'src', 'services', 'beds');
const outDir = join(mobileDir, 'assets', 'cases');
const check = process.argv.includes('--check');

function readCase(n) {
  const src = readFileSync(join(bedsDir, `bed${n}.ts`), 'utf8');
  const body = src.replace(/^import \{ BedCasePayload \} from '\.\/types';\s*/, '');
  const m = body.match(/^export const BED_0(\d): BedCasePayload = (\{[\s\S]*\});\s*$/);
  if (!m || Number(m[1]) !== n) {
    throw new Error(`bed${n}.ts is no longer a single BED_0${n} object literal; update this script`);
  }
  return vm.runInNewContext(`(${m[2]})`, {}, { timeout: 1000 });
}

let stale = 0;
for (let n = 1; n <= 8; n++) {
  const json = JSON.stringify(readCase(n), null, 2) + '\n';
  const file = join(outDir, `bed0${n}.json`);
  if (check) {
    if (!existsSync(file) || readFileSync(file, 'utf8') !== json) {
      console.log(`stale: assets/cases/bed0${n}.json differs from bed${n}.ts`);
      stale++;
    }
  } else {
    writeFileSync(file, json);
    console.log(`wrote assets/cases/bed0${n}.json`);
  }
}
if (check) {
  console.log(stale === 0 ? 'cases in step with backend/src/services/beds' : `${stale} stale`);
  process.exit(stale === 0 ? 0 : 1);
}
