#!/usr/bin/env node
import { readFileSync } from 'node:fs';

const pkg = JSON.parse(readFileSync(new URL('../package.json', import.meta.url), 'utf8'));

if (pkg.name !== '@capgo/capacitor-persona') {
  console.error(`Expected package name @capgo/capacitor-persona, got ${pkg.name}`);
  process.exit(1);
}

const repoUrl = pkg.repository?.url ?? '';
if (!repoUrl.includes('capacitor-persona')) {
  console.error('package.json repository.url must reference Cap-go/capacitor-persona');
  process.exit(1);
}

console.log('Package identity OK:', pkg.name);
