const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  const dumpFields = async () => {
    const fields = await page.evaluate(() => {
      const els = [...document.querySelectorAll('input, textarea, select, button')];
      return els.map(el => ({
        tag: el.tagName,
        type: el.type || '',
        id: el.id || '',
        name: el.name || '',
        placeholder: el.placeholder || '',
        value: el.value ? el.value.substring(0, 40) : '',
        label: (() => {
          if (el.id) { const lbl = document.querySelector(`label[for="${el.id}"]`); if (lbl) return lbl.innerText.trim(); }
          const parent = el.closest('label'); if (parent) return parent.innerText.trim();
          return '';
        })()
      })).filter(f => f.type !== 'hidden' && !f.id.startsWith('goog-gt'));
    });
    console.log(`URL: ${page.url()}`);
    console.log(`TITLE: ${await page.title()}`);
    console.log(`FIELDS (${fields.length}):`);
    fields.forEach(f => console.log('  ' + JSON.stringify(f)));
  };

  console.log('\n=== Step 1: Solar Complaint Form Entry ===');
  await page.goto('https://www.cslb.ca.gov/OnlineServices/SolarComplaint/SolarComplaintFormProcess.aspx', { waitUntil: 'networkidle', timeout: 30000 });
  await page.waitForTimeout(2000);
  await dumpFields();

  console.log('\n=== Body text ===');
  const body = await page.evaluate(() => document.body.innerText);
  console.log(body.substring(0, 3000));

  // Also check the general construction complaint form as backup
  console.log('\n\n=== Step 2: General Construction Complaint Form ===');
  try {
    await page.goto('https://www.cslb.ca.gov/OnlineServices/ConstructionComplaint/ComplaintFormProcess.aspx', { waitUntil: 'networkidle', timeout: 30000 });
    await page.waitForTimeout(2000);
    await dumpFields();
  } catch (e) { console.log('ERROR:', e.message); }

  await browser.close();
})();
