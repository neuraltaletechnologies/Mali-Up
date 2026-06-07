const { chromium } = require('@playwright/test');
(async () => {
  const browser = await chromium.launch({ 
    executablePath: '/usr/bin/google-chrome',
    args: ['--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage']
  });
  const page = await browser.newPage();
  const failed = [];
  page.on('requestfailed', req => failed.push({ url: req.url(), reason: req.failure()?.errorText }));
  page.on('response', resp => { if (resp.status() >= 400) failed.push({ url: resp.url(), status: resp.status() }); });
  await page.goto('http://localhost:3001/', { waitUntil: 'networkidle', timeout: 20000 });
  console.log('FAILED RESOURCES:', JSON.stringify(failed, null, 2));
  
  // Also run accessibility audit
  const a11y = await page.evaluate(() => {
    const issues = [];
    // Check for images without alt
    document.querySelectorAll('img:not([alt])').forEach(img => issues.push('IMG missing alt: ' + img.src));
    // Check for buttons without labels
    document.querySelectorAll('button:not([aria-label])').forEach(btn => {
      if (!btn.textContent?.trim()) issues.push('BUTTON missing label: ' + btn.outerHTML.substring(0, 80));
    });
    // Check color contrast (basic - just check if text colors are set)
    return issues;
  });
  console.log('A11Y ISSUES:', a11y);
  await browser.close();
})();
