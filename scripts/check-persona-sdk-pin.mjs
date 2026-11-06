#!/usr/bin/env node
/**
 * Persona SDK pin guard.
 *
 * Fails when Package.swift and the podspec disagree on the PersonaInquirySDK2 version,
 * which happens when a dependency bot updates one manifest but not the other.
 *
 * Usage:
 *   node scripts/check-persona-sdk-pin.mjs
 *   node scripts/check-persona-sdk-pin.mjs --dir path/to/plugin
 */

import { readFileSync } from 'node:fs';
import path from 'node:path';

function parseArgs(argv) {
  const out = { dir: process.cwd() };
  for (let i = 2; i < argv.length; i++) {
    if (argv[i] === '--dir') out.dir = path.resolve(argv[++i] || '.');
  }
  return out;
}

const { dir } = parseArgs(process.argv);

const packageSwift = readFileSync(path.join(dir, 'Package.swift'), 'utf8');
const podspec = readFileSync(path.join(dir, 'CapgoCapacitorPersona.podspec'), 'utf8');
const gradle = readFileSync(path.join(dir, 'android', 'build.gradle'), 'utf8');

const spmVersion = /inquiry-ios-2\.git"\s*,\s*exact:\s*"([^"]+)"/.exec(packageSwift)?.[1];
const podVersion = /s\.dependency\s+'PersonaInquirySDK2'\s*,\s*'([^']+)'/.exec(podspec)?.[1];
const androidDefault = /personaInquiryVersion\s*=\s*project\.findProperty\('personaInquiryVersion'\)\s*\?:\s*'([^']+)'/.exec(gradle)?.[1];

const errors = [];
if (!spmVersion) errors.push('Package.swift: could not find an exact: pin for inquiry-ios-2');
if (!podVersion) errors.push("podspec: could not find s.dependency 'PersonaInquirySDK2', '<version>'");
if (!androidDefault) errors.push('android/build.gradle: could not find the personaInquiryVersion default');
if (spmVersion && podVersion && spmVersion !== podVersion) {
  errors.push(`iOS pins differ: Package.swift=${spmVersion} podspec=${podVersion}`);
}

if (errors.length) {
  console.error('[persona-pin] FAIL');
  for (const e of errors) console.error(`- ${e}`);
  process.exit(1);
}

console.log(`[persona-pin] OK iOS PersonaInquirySDK2 ${spmVersion}, Android com.withpersona.sdk2:inquiry default ${androidDefault}`);
