const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  console.log('Navigating to CSLB license check...');
  await page.goto('https://www.cslb.ca.gov/OnlineServices/CheckLicenseII/CheckLicense.aspx', { waitUntil: 'networkidle' });
  await page.waitForTimeout(1500);

  // The form has tabs for different search types — click Business Name tab first
  // The tabs are likely triggered by clicking a heading or link. Try clicking text "Business Name"
  console.log('Looking for Business Name tab...');
  try {
    await page.getByText('Business Name', { exact: false }).first().click({ timeout: 5000 });
    await page.waitForTimeout(500);
  } catch (e) {
    console.log('No Business Name tab click needed:', e.message.substring(0, 80));
  }

  // Force-fill the field using page.evaluate to bypass visibility check
  console.log('Filling business name...');
  await page.evaluate(() => {
    const el = document.querySelector('#MainContent_NextName');
    if (el) { el.value = 'Sunrun'; el.dispatchEvent(new Event('change', { bubbles: true })); }
  });

  console.log('Submitting search...');
  await page.evaluate(() => {
    const btn = document.querySelector('#MainContent_Contractor_Business_Name_Button');
    if (btn) btn.click();
  });

  await page.waitForLoadState('networkidle');
  await page.waitForTimeout(2500);

  console.log(`\nCurrent URL: ${page.url()}`);
  const title = await page.title();
  console.log(`Title: ${title}`);

  const text = await page.evaluate(() => document.body.innerText);
  console.log('\n--- RESULT PAGE TEXT (trimmed) ---');
  console.log(text.substring(0, 4000));

  // Extract table rows
  const rows = await page.$$eval('table tr', trs => trs.map(tr => [...tr.querySelectorAll('td,th')].map(td => td.innerText.trim().replace(/\s+/g, ' '))));
  console.log('\n--- SUNRUN-RELATED TABLE ROWS ---');
  rows.forEach(r => {
    const joined = r.join(' | ');
    if (joined.toLowerCase().includes('sunrun')) console.log(joined);
  });

  // Extract license detail links
  const detailLinks = await page.$$eval('a', as => as.map(a => ({ text: a.innerText.trim(), href: a.href })).filter(l => l.href.includes('LicenseDetail')));
  console.log('\n--- LICENSE DETAIL LINKS ---');
  detailLinks.forEach(l => console.log(JSON.stringify(l)));

  // Visit each detail link and grab key fields
  for (const l of detailLinks.slice(0, 5)) {
    try {
      console.log(`\n=== VISITING: ${l.href} ===`);
      await page.goto(l.href, { waitUntil: 'networkidle', timeout: 20000 });
      await page.waitForTimeout(1500);
      const body = await page.evaluate(() => document.body.innerText);
      // Show relevant chunk
      const idx = body.toLowerCase().indexOf('license number');
      if (idx >= 0) {
        console.log(body.substring(idx, idx + 1500));
      } else {
        console.log(body.substring(0, 1500));
      }
    } catch (e) {
      console.log('ERROR:', e.message);
    }
  }

  await browser.close();
})();
