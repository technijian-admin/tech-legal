const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.goto('https://cims.cpuc.ca.gov/complaints/Home/FileComplaint', { waitUntil: 'networkidle' });
  await page.waitForTimeout(2000);

  const fields = await page.evaluate(() => {
    const els = [...document.querySelectorAll('input, textarea, select')];
    return els.map(el => ({
      tag: el.tagName,
      type: el.type || '',
      id: el.id || '',
      name: el.name || '',
      placeholder: el.placeholder || '',
      label: (() => {
        if (el.id) {
          const lbl = document.querySelector(`label[for="${el.id}"]`);
          if (lbl) return lbl.innerText.trim();
        }
        const parent = el.closest('label');
        if (parent) return parent.innerText.trim();
        let sib = el.previousElementSibling;
        if (sib && sib.tagName === 'LABEL') return sib.innerText.trim();
        return '';
      })()
    }));
  });

  fields.forEach(f => console.log(JSON.stringify(f)));
  await browser.close();
})();
