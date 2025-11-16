#!/usr/bin/env node

/**
 * Test runner - compiles TypeScript and runs tests
 */

const { execSync } = require('child_process');
const path = require('path');

console.log('Building TypeScript...\n');

try {
  execSync('npx tsc --project tsconfig.json', {
    cwd: path.join(__dirname, '..'),
    stdio: 'inherit'
  });

  console.log('\nRunning fuel system tests...\n');

  // Compile test file
  execSync('npx tsc tests/fuel-system.test.ts --outDir dist --module commonjs --target es2020 --esModuleInterop --skipLibCheck', {
    cwd: path.join(__dirname, '..'),
    stdio: 'inherit'
  });

  // Run test
  execSync('node dist/tests/fuel-system.test.js', {
    cwd: path.join(__dirname, '..'),
    stdio: 'inherit'
  });

} catch (error) {
  console.error('Test execution failed');
  process.exit(1);
}
