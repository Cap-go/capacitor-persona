#!/usr/bin/env node
import { readFileSync, existsSync } from 'node:fs';

const root = new URL('..', import.meta.url);
const pkg = JSON.parse(readFileSync(new URL('../package.json', import.meta.url), 'utf8'));

const expectedName = '@capgo/capacitor-persona';
const expectedRepo = 'git+https://github.com/Cap-go/capacitor-persona.git';
const expectedHomepage = 'https://capgo.app/docs/plugins/persona/';

if (pkg.name !== expectedName) {
  console.error(`Expected package name ${expectedName}, got ${pkg.name}`);
  process.exit(1);
}

const repoUrl = pkg.repository?.url ?? '';
if (repoUrl !== expectedRepo) {
  console.error(`package.json repository.url must be exactly ${expectedRepo}`);
  process.exit(1);
}

if (pkg.homepage !== expectedHomepage) {
  console.error(`package.json homepage must be ${expectedHomepage}`);
  process.exit(1);
}

const description = String(pkg.description ?? '');
if (/intune|msal|microsoft intune/i.test(description)) {
  console.error('package.json description must not reference Intune or MSAL.');
  process.exit(1);
}

/** @param {string} rel */
function read(rel) {
  return readFileSync(new URL(rel, root), 'utf8');
}

const forbiddenSnippets = [
  { label: 'IntuneMAM plugin id', pattern: /IntuneMAM|IntuneMAMPlugin/ },
  { label: 'Intune Android package', pattern: /app\.capgo\.intune|app\/capgo\/intune/ },
  { label: 'Intune podspec', pattern: /CapgoCapacitorIntune/ },
  { label: 'Intune MAM SDK path', pattern: /ms-intune-app-sdk-android|IntuneMAMSwift/ },
];

const scanPaths = [
  'package.json',
  'src/index.ts',
  'src/definitions.ts',
  'android/build.gradle',
  'android/src/main/java/app/capgo/persona/PersonaPlugin.java',
  'ios/Sources/PersonaPlugin/PersonaPlugin.swift',
  'CapgoCapacitorPersona.podspec',
];

for (const rel of scanPaths) {
  if (!existsSync(new URL(rel, root))) {
    console.error(`Missing expected Persona artifact: ${rel}`);
    process.exit(1);
  }
  const text = read(rel);
  for (const { label, pattern } of forbiddenSnippets) {
    if (pattern.test(text)) {
      console.error(`Intune implementation marker (${label}) found in ${rel}`);
      process.exit(1);
    }
  }
}

if (!read('src/index.ts').includes("'Persona'")) {
  console.error('src/index.ts must register the Persona Capacitor plugin.');
  process.exit(1);
}

if (existsSync(new URL('CapgoCapacitorIntune.podspec', root))) {
  console.error('CapgoCapacitorIntune.podspec must not be present in the Persona repository.');
  process.exit(1);
}

const intuneJavaDir = new URL('android/src/main/java/app/capgo/intune', root);
if (existsSync(intuneJavaDir)) {
  console.error('android/src/main/java/app/capgo/intune must not exist in the Persona repository.');
  process.exit(1);
}

console.log('Package identity OK:', pkg.name);
