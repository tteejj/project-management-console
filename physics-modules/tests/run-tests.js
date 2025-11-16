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

  console.log('\n' + '='.repeat(60) + '\n');
  console.log('Running electrical system tests...\n');

  // Compile electrical test file
  execSync('npx tsc tests/electrical-system.test.ts --outDir dist --module commonjs --target es2020 --esModuleInterop --skipLibCheck', {
    cwd: path.join(__dirname, '..'),
    stdio: 'inherit'
  });

  // Run test
  execSync('node dist/tests/electrical-system.test.js', {
    cwd: path.join(__dirname, '..'),
    stdio: 'inherit'
  });

  console.log('\n' + '='.repeat(60) + '\n');
  console.log('Running compressed gas system tests...\n');

  // Compile compressed gas test file
  execSync('npx tsc tests/compressed-gas-system.test.ts --outDir dist --module commonjs --target es2020 --esModuleInterop --skipLibCheck', {
    cwd: path.join(__dirname, '..'),
    stdio: 'inherit'
  });

  // Run test
  execSync('node dist/tests/compressed-gas-system.test.js', {
    cwd: path.join(__dirname, '..'),
    stdio: 'inherit'
  });

  console.log('\n' + '='.repeat(60) + '\n');
  console.log('Running thermal system tests...\n');

  // Compile thermal test file
  execSync('npx tsc tests/thermal-system.test.ts --outDir dist --module commonjs --target es2020 --esModuleInterop --skipLibCheck', {
    cwd: path.join(__dirname, '..'),
    stdio: 'inherit'
  });

  // Run test
  execSync('node dist/tests/thermal-system.test.js', {
    cwd: path.join(__dirname, '..'),
    stdio: 'inherit'
  });

  console.log('\n' + '='.repeat(60) + '\n');
  console.log('Running coolant system tests...\n');

  // Compile coolant test file
  execSync('npx tsc tests/coolant-system.test.ts --outDir dist --module commonjs --target es2020 --esModuleInterop --skipLibCheck', {
    cwd: path.join(__dirname, '..'),
    stdio: 'inherit'
  });

  // Run test
  execSync('node dist/tests/coolant-system.test.js', {
    cwd: path.join(__dirname, '..'),
    stdio: 'inherit'
  });

  console.log('\n' + '='.repeat(60) + '\n');
  console.log('Running main engine tests...\n');

  // Compile main engine test file
  execSync('npx tsc tests/main-engine.test.ts --outDir dist --module commonjs --target es2020 --esModuleInterop --skipLibCheck', {
    cwd: path.join(__dirname, '..'),
    stdio: 'inherit'
  });

  // Run test
  execSync('node dist/tests/main-engine.test.js', {
    cwd: path.join(__dirname, '..'),
    stdio: 'inherit'
  });

  console.log('\n' + '='.repeat(60) + '\n');
  console.log('Running RCS system tests...\n');

  // Compile RCS test file
  execSync('npx tsc tests/rcs-system.test.ts --outDir dist --module commonjs --target es2020 --esModuleInterop --skipLibCheck', {
    cwd: path.join(__dirname, '..'),
    stdio: 'inherit'
  });

  // Run test
  execSync('node dist/tests/rcs-system.test.js', {
    cwd: path.join(__dirname, '..'),
    stdio: 'inherit'
  });

  console.log('\n' + '='.repeat(60) + '\n');
  console.log('Running ship physics tests...\n');

  // Compile ship physics test file
  execSync('npx tsc tests/ship-physics.test.ts --outDir dist --module commonjs --target es2020 --esModuleInterop --skipLibCheck', {
    cwd: path.join(__dirname, '..'),
    stdio: 'inherit'
  });

  // Run test
  execSync('node dist/tests/ship-physics.test.js', {
    cwd: path.join(__dirname, '..'),
    stdio: 'inherit'
  });

  console.log('\n' + '='.repeat(60) + '\n');
  console.log('✓ All test suites completed!\n');

} catch (error) {
  console.error('Test execution failed');
  process.exit(1);
}
