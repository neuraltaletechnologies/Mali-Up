const { chromium } = require('@playwright/test');

(async () => {
  const browser = await chromium.launch({ 
    executablePath: '/usr/bin/google-chrome',
    args: ['--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage']
  });
  const page = await browser.newPage();
  const errors = [];
  const consoleMessages = [];
  page.on('console', msg => {
    if (['error', 'warning'].includes(msg.type())) {
      consoleMessages.push(`[${msg.type()}] ${msg.text()}`);
    }
  });
  page.on('pageerror', err => errors.push(err.message));
  try {
    await page.goto('http://localhost:3001/', { waitUntil: 'domcontentloaded', timeout: 15000 });
    await page.waitForTimeout(5000);
    const result = await page.evaluate(() => {
      const h1 = document.querySelector('h1');
      const nav = document.querySelector('header');
      return {
        h1text: h1?.textContent?.trim().substring(0,80),
        h1opacity: h1 ? window.getComputedStyle(h1).opacity : 'no h1',
        navOpacity: nav ? window.getComputedStyle(nav).opacity : 'no nav',
        bodyBg: window.getComputedStyle(document.body).backgroundColor,
        visibleText: document.body.innerText?.substring(0, 300),
        opacityZeroCount: Array.from(document.querySelectorAll('*')).filter(el => window.getComputedStyle(el).opacity === '0').length,
      };
    });
    console.log('RESULT:', JSON.stringify(result, null, 2));
    console.log('JS ERRORS:', errors.slice(0, 10));
    console.log('CONSOLE:', consoleMessages.slice(0, 10));
    await page.screenshot({ path: '/tmp/mali_check.png' });
    console.log('Screenshot saved: /tmp/mali_check.png');
  } catch(e) {
    console.log('ERROR:', e.message);
  }
  await browser.close();
})();
