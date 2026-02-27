#!/usr/bin/env node
/**
 * TikTok Carousel Marketing — Onboarding Config Validator
 *
 * The onboarding is CONVERSATIONAL — the agent talks to the user naturally,
 * not through this script. This script validates the resulting config is complete.
 *
 * Usage:
 *   node onboarding.js --validate --config tiktok-marketing/config.json
 *   node onboarding.js --init --dir tiktok-marketing/
 *
 * --validate: Check config completeness, show what's missing
 * --init: Create the directory structure and empty config files
 */

const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);
const configPath = args.includes('--config') ? args[args.indexOf('--config') + 1] : null;
const validate = args.includes('--validate');
const init = args.includes('--init');
const dir = args.includes('--dir') ? args[args.indexOf('--dir') + 1] : 'tiktok-marketing';

if (init) {
  // Create directory structure
  const dirs = [dir, `${dir}/posts`, `${dir}/hooks`];
  dirs.forEach(d => {
    if (!fs.existsSync(d)) {
      fs.mkdirSync(d, { recursive: true });
      console.log(`📁 Created ${d}/`);
    }
  });

  // Empty config template
  const configTemplate = {
    app: {
      name: '',
      description: '',
      audience: '',
      problem: '',
      differentiator: '',
      url: '',
      category: ''
    },
    imageGen: {
      provider: '',
      apiKey: '',
      model: '',
      basePrompt: ''
    },
    postiz: {
      apiKey: '',
      integrationId: ''
    },
    posting: {
      privacyLevel: 'SELF_ONLY',
      schedule: ['07:30', '16:30', '21:00']
    }
  };

  const cfgPath = `${dir}/config.json`;
  if (!fs.existsSync(cfgPath)) {
    fs.writeFileSync(cfgPath, JSON.stringify(configTemplate, null, 2));
    console.log(`📝 Created ${cfgPath}`);
  }

  // Empty competitor research template
  const compPath = `${dir}/competitor-research.json`;
  if (!fs.existsSync(compPath)) {
    fs.writeFileSync(compPath, JSON.stringify({
      researchDate: '',
      competitors: [],
      nicheInsights: {
        trendingSounds: [],
        commonFormats: [],
        gapOpportunities: '',
        avoidPatterns: ''
      }
    }, null, 2));
    console.log(`📝 Created ${compPath}`);
  }

  // Empty strategy template
  const stratPath = `${dir}/strategy.json`;
  if (!fs.existsSync(stratPath)) {
    fs.writeFileSync(stratPath, JSON.stringify({
      hooks: [],
      postingSchedule: ['07:30', '16:30', '21:00'],
      hookCategories: { testing: [], proven: [], dropped: [] },
      notes: ''
    }, null, 2));
    console.log(`📝 Created ${stratPath}`);
  }

  // Empty hook performance tracker
  const hookPath = `${dir}/hook-performance.json`;
  if (!fs.existsSync(hookPath)) {
    fs.writeFileSync(hookPath, JSON.stringify({
      posts: [],
      rules: { doubleDown: [], testing: [], dropped: [] }
    }, null, 2));
    console.log(`📝 Created ${hookPath}`);
  }

  console.log('\n✅ Directory structure ready. Start the conversational onboarding to fill in config.');
  process.exit(0);
}

if (validate && configPath) {
  if (!fs.existsSync(configPath)) {
    console.error(`❌ Config not found: ${configPath}`);
    process.exit(1);
  }

  const config = JSON.parse(fs.readFileSync(configPath, 'utf-8'));
  const required = [];
  const optional = [];

  // App profile (required)
  if (!config.app?.name) required.push('app.name — What is the product called?');
  if (!config.app?.description) required.push('app.description — What does it do?');
  if (!config.app?.audience) required.push('app.audience — Who is it for?');
  if (!config.app?.problem) required.push('app.problem — What problem does it solve?');
  if (!config.app?.category) required.push('app.category — What category?');

  // Image generation (required)
  if (!config.imageGen?.provider) required.push('imageGen.provider — Which image tool?');
  if (config.imageGen?.provider && config.imageGen.provider !== 'local' && !config.imageGen?.apiKey) {
    required.push('imageGen.apiKey — API key for image generation');
  }

  // Postiz (required)
  if (!config.postiz?.apiKey) required.push('postiz.apiKey — Postiz API key');
  if (!config.postiz?.integrationId) required.push('postiz.integrationId — TikTok integration ID');

  // Competitor research (important but not blocking)
  const compDir = path.dirname(configPath);
  const compPath = path.join(compDir, 'competitor-research.json');
  if (fs.existsSync(compPath)) {
    const comp = JSON.parse(fs.readFileSync(compPath, 'utf-8'));
    if (!comp.competitors || comp.competitors.length === 0) {
      optional.push('Competitor research — no competitors analyzed yet (run browser research)');
    }
  } else {
    optional.push('Competitor research — file not created yet');
  }

  // Strategy
  const stratPath = path.join(compDir, 'strategy.json');
  if (fs.existsSync(stratPath)) {
    const strat = JSON.parse(fs.readFileSync(stratPath, 'utf-8'));
    if (!strat.hooks || strat.hooks.length === 0) {
      optional.push('Content strategy — no hooks planned yet');
    }
  } else {
    optional.push('Content strategy — file not created yet');
  }

  // URL
  if (!config.app?.url) optional.push('Product URL — helpful for competitor research');

  // Base prompt
  if (!config.imageGen?.basePrompt) optional.push('imageGen.basePrompt — base prompt for image generation');

  // Results
  if (required.length === 0) {
    console.log('✅ Core config complete! Ready to start posting.\n');
  } else {
    console.log('❌ Missing required config:\n');
    required.forEach(r => console.log(`   ⬚ ${r}`));
    console.log('');
  }

  if (optional.length > 0) {
    console.log('💡 Recommended (not blocking):\n');
    optional.forEach(o => console.log(`   ○ ${o}`));
    console.log('');
  }

  // Summary
  console.log('📋 Setup Summary:');
  console.log(`   Product: ${config.app?.name || '(not set)'}`);
  console.log(`   Category: ${config.app?.category || '(not set)'}`);
  console.log(`   Image Gen: ${config.imageGen?.provider || '(not set)'}${config.imageGen?.model ? ` (${config.imageGen.model})` : ''}`);
  console.log(`   TikTok: ${config.postiz?.integrationId ? 'Connected' : 'Not connected'}`);
  console.log(`   Privacy: ${config.posting?.privacyLevel || 'SELF_ONLY'}`);
  console.log(`   Schedule: ${(config.posting?.schedule || []).join(', ')}`);

  process.exit(required.length > 0 ? 1 : 0);
} else {
  console.log('Usage:');
  console.log('  node onboarding.js --init --dir tiktok-marketing/    Create directory structure');
  console.log('  node onboarding.js --validate --config config.json    Validate config completeness');
}
