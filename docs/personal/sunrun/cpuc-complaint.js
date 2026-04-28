const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false, slowMo: 100 });
  const page = await browser.newPage();

  console.log('Navigating to CPUC complaint form...');
  await page.goto('https://cims.cpuc.ca.gov/complaints/Home/FileComplaint', { waitUntil: 'networkidle' });
  await page.waitForTimeout(2000);

  console.log('Filling personal information...');
  await page.locator('#FirstName').fill('Ravi');
  await page.locator('#LastName').fill('Jain');
  await page.locator('#LocationService').fill('5 Caladium');
  await page.locator('#CityService').fill('Rancho Santa Margarita');
  await page.locator('#StateCodeService').selectOption('CA');
  await page.locator('#ZipService').fill('92688');
  await page.locator('#PhoneDayTime').fill('7144023164');
  await page.locator('#EmailAddress').fill('rjain@technijian.com');

  console.log('Filling utility information...');
  await page.locator('#UtilityName').fill('Sunrun, Inc. and Sunrun Installation Services, Inc.');
  await page.locator('#UtilityCustomerAccountNumber').fill('0036 1837 1728 9');

  console.log('Filling complaint narrative...');
  const situation = `Sunrun technicians disconnected my residential solar system (11.16 kW, two Sunrun systems at the same property: a 2012 Sunrun-owned Prepaid PPA and a 2017 customer-owned Costco solar system) during a service visit on November 7, 2025 at 5 Caladium, Rancho Santa Margarita, CA 92688. The system produced ZERO exportable power from 11/7/2025 through 4/16/2026, a period of over five months. Sunrun never notified me the system was offline. I discovered the outage only when reviewing my SDG&E bills (NEM Meter 06688420) which showed zero solar export for five consecutive months. My electric bills increased by approximately $3,600 during this period. Sunrun Service Case 18181148.`;

  const utilityResponse = `Sunrun completed repairs on April 16-17, 2026 after I escalated. Their representative Katherine Wilson offered only a $450 Early Performance Guarantee credit despite over five months of zero production caused by their own technicians. I submitted a formal written warranty demand on April 17, 2026 requesting $7,500 in direct damages. Sunrun acknowledged receipt but stated I must retain an attorney to access their legal resolution team, making individual pursuit financially impractical. Their customercare inbox is unmonitored per auto-response. On April 20, 2026 Sunrun unilaterally declared the case closed with the message that my system is back to normal, without addressing reimbursement.`;

  const suggestedAction = `1. Investigate Sunruns failure to notify California customers when their solar systems are rendered non-operational by Sunruns own technicians. 2. Determine whether Sunrun has a pattern of disconnecting customer systems during service visits without notifying customers, which may affect many California solar customers. 3. Require Sunrun to provide fair reimbursement of at least $3,600 for excess electricity costs caused by their negligence. 4. Review Sunruns practice of requiring consumers to retain counsel before accessing internal warranty resolution, which operates as a barrier to consumer remedies.`;

  await page.locator('#situation-concern').fill(situation);
  await page.locator('#utility-response').fill(utilityResponse);
  await page.locator('#suggested-action').fill(suggestedAction);

  try {
    await page.locator('#FindCode').selectOption({ label: 'WEB' });
  } catch (e) {
    console.log('FindCode dropdown selection skipped:', e.message);
  }

  console.log('');
  console.log('====================================================');
  console.log('FORM FILLED. Please do the following manually:');
  console.log('  1. Review every field in the browser');
  console.log('  2. Complete the reCAPTCHA');
  console.log('  3. Click Submit Complaint when ready');
  console.log('====================================================');
  console.log('Browser stays open for 15 minutes.');

  await page.waitForTimeout(15 * 60 * 1000);
  await browser.close();
})();
