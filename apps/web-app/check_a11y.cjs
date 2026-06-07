const { chromium } = require('@playwright/test');

(async () => {
  const browser = await chromium.launch({
    executablePath: '/usr/bin/google-chrome',
    args: ['--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage']
  });
  const page = await browser.newPage();
  await page.goto('http://localhost:3001/', { waitUntil: 'domcontentloaded', timeout: 20000 });
  await page.waitForTimeout(4000);

  // Inject axe-core
  await page.addScriptTag({
    url: 'https://cdnjs.cloudflare.com/ajax/libs/axe-core/4.10.3/axe.min.js'
  });

  const violations = await page.evaluate(async () => {
    const results = await axe.run(document, {
      runOnly: ['wcag2a', 'wcag2aa', 'best-practice'],
    });
    return results.violations.map(v => ({
      id: v.id,
      impact: v.impact,
      description: v.description,
      nodes: v.nodes.length,
      help: v.help,
      example: v.nodes[0]?.html?.substring(0, 150),
    }));
  });

  console.log('\nAXE ACCESSIBILITY AUDIT — ' + violations.length + ' violation(s)\n');
  violations.forEach((v, i) => {
    console.log((i+1) + '. [' + (v.impact||'').toUpperCase() + '] ' + v.id);
    console.log('   ' + v.help);
    console.log('   Affected nodes: ' + v.nodes);
    console.log('   Example: ' + v.example);
    console.log();
  });
  if (violations.length === 0) console.log('No violations found!');

  // Also take a full-page screenshot
  await page.screenshot({ path: '/tmp/mali_full.png', fullPage: false });
  console.log('Screenshot: /tmp/mali_full.png');
  await browser.close();
})();
