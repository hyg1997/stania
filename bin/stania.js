#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const VERSION = '3.0.0';
const COMMANDS_DIR = path.join(__dirname, '..', 'commands');
const SKILLS_DIR = path.join(__dirname, '..', 'skills');
const TEMPLATES_DIR = path.join(__dirname, '..', 'templates');

const RED = '\x1b[31m';
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const BLUE = '\x1b[34m';
const BOLD = '\x1b[1m';
const DIM = '\x1b[2m';
const NC = '\x1b[0m';

const args = process.argv.slice(2);
const command = args[0] || 'install';

function log(msg) { console.log(`  ${msg}`); }

function header() {
  console.log('');
  log(`${BOLD}Stania v${VERSION}${NC}`);
  log(`${DIM}AI engineering workflow for Claude Code${NC}`);
  console.log('');
}

function install(projectDir) {
  const claudeDir = path.join(projectDir, '.claude');
  const cmdDir = path.join(claudeDir, 'commands');
  const skillDir = path.join(claudeDir, 'skills', 'st');
  const settingsFile = path.join(claudeDir, 'settings.json');

  fs.mkdirSync(cmdDir, { recursive: true });
  fs.mkdirSync(skillDir, { recursive: true });

  // Install commands
  let installed = 0;
  let updated = 0;
  const cmdFiles = fs.readdirSync(COMMANDS_DIR).filter(f => f.endsWith('.md'));
  for (const file of cmdFiles) {
    const src = path.join(COMMANDS_DIR, file);
    const dest = path.join(cmdDir, file);
    const srcContent = fs.readFileSync(src, 'utf8');

    if (fs.existsSync(dest)) {
      const destContent = fs.readFileSync(dest, 'utf8');
      if (srcContent !== destContent) {
        fs.writeFileSync(dest, srcContent);
        updated++;
        log(`${BLUE}↻${NC} Updated: /${file.replace('.md', '')}`);
      }
    } else {
      fs.writeFileSync(dest, srcContent);
      installed++;
      log(`${GREEN}+${NC} Installed: /${file.replace('.md', '')}`);
    }
  }

  // Install skill
  const skillSrc = path.join(SKILLS_DIR, 'st', 'SKILL.md');
  const skillDest = path.join(skillDir, 'SKILL.md');
  fs.copyFileSync(skillSrc, skillDest);
  log(`${GREEN}+${NC} Skill: st`);

  // Install settings (only if not exists)
  if (!fs.existsSync(settingsFile)) {
    const templateSrc = path.join(TEMPLATES_DIR, 'settings.json');
    fs.copyFileSync(templateSrc, settingsFile);
    log(`${GREEN}+${NC} Settings: .claude/settings.json`);
  }

  console.log('');
  log(`${BOLD}${GREEN}Done.${NC} ${installed} new, ${updated} updated`);
  console.log('');
  log(`${BOLD}Start here:${NC}`);
  log(`  /st-next        ${DIM}What should I do now? (role-aware)${NC}`);
  log(`  /st-onboard     ${DIM}Onboard a new team member${NC}`);
  console.log('');
  log(`${BOLD}Pipeline:${NC}`);
  log(`  /st-spec        Define feature spec`);
  log(`  /st-contract    Define API contract → mocks + types`);
  log(`  /st-agent       Launch autonomous implementation`);
  log(`  /st-build       Layer-by-layer generation`);
  log(`  /st-check       Validate + harden`);
  log(`  /st-review      Code review with domain context`);
  log(`  /st-ship        Pre-deploy audit`);
  log(`  /st-deploy      Build + push + deploy (Cloud Run)`);
  log(`  /st-retro       Session close`);
  console.log('');
  log(`${BOLD}Team:${NC}`);
  log(`  /st-onboard     Onboard partner/intern`);
  log(`  /st-decision    Record architecture decision (ADR)`);
  log(`  /st-board       GitHub status board`);
  log(`  /st-trace       Trace feature across all layers`);
  console.log('');
  log(`${BOLD}Quality:${NC}`);
  log(`  /st-e2e         Generate Playwright E2E tests`);
  log(`  /st-env         Compare env vars with Cloud Run`);
  log(`  /st-test-prompt Test AI endpoint responses`);
  log(`  /st-deps        Dependency health audit`);
  console.log('');
}

function uninstall(projectDir) {
  const claudeDir = path.join(projectDir, '.claude');
  const cmdDir = path.join(claudeDir, 'commands');
  const skillDir = path.join(claudeDir, 'skills', 'st');

  let removed = 0;
  if (fs.existsSync(cmdDir)) {
    const files = fs.readdirSync(cmdDir).filter(f => f.startsWith('st-'));
    for (const file of files) {
      fs.unlinkSync(path.join(cmdDir, file));
      removed++;
    }
  }
  if (fs.existsSync(skillDir)) {
    fs.rmSync(skillDir, { recursive: true });
    removed++;
  }

  log(`${GREEN}Uninstalled.${NC} ${removed} items removed.`);
  console.log('');
}

function showVersion() {
  log(`stania v${VERSION}`);
}

function showHelp() {
  log(`${BOLD}Usage:${NC} npx stania [command]`);
  console.log('');
  log(`${BOLD}Commands:${NC}`);
  log(`  install      Install Stania in current project (default)`);
  log(`  update       Update Stania to latest version`);
  log(`  uninstall    Remove Stania from current project`);
  log(`  version      Show version`);
  log(`  help         Show this help`);
  console.log('');
  log(`${BOLD}Examples:${NC}`);
  log(`  npx stania              Install in current project`);
  log(`  npx stania@latest       Update to latest`);
  log(`  npx stania uninstall    Remove from project`);
  console.log('');
}

// Main
header();

const projectDir = process.cwd();

switch (command) {
  case 'install':
  case 'init':
    log(`${DIM}Installing to: ${projectDir}/.claude/${NC}`);
    console.log('');
    install(projectDir);
    break;
  case 'update':
    log(`${DIM}Updating in: ${projectDir}/.claude/${NC}`);
    console.log('');
    install(projectDir); // Same as install (idempotent)
    break;
  case 'uninstall':
  case 'remove':
    uninstall(projectDir);
    break;
  case 'version':
  case '-v':
  case '--version':
    showVersion();
    break;
  case 'help':
  case '-h':
  case '--help':
    showHelp();
    break;
  default:
    log(`${RED}Unknown command: ${command}${NC}`);
    showHelp();
    process.exit(1);
}
