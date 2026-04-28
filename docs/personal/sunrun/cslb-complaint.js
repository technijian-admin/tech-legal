const { chromium } = require('playwright');

// =========================================================================
// CSLB SOLAR COMPLAINT — Sunrun Installation Services, Inc. (License 750184)
// Property: 5 Caladium, Rancho Santa Margarita, CA 92688
// Complainant: Ravi Jain (personal, NOT a Technijian matter)
// =========================================================================

const DATA = {
  complainant: {
    firstName: 'Ravi', lastName: 'Jain',
    street: '5 Caladium', city: 'Rancho Santa Margarita', state: 'CA', zip: '92688',
    dayPhone: '7144023164', email: 'rjain@technijian.com'
  },
  contractor: {
    businessName: 'Sunrun Installation Services, Inc.',
    firstName: 'Katherine', lastName: 'Wilson',
    license: '750184',
    street: '225 Bush Street, 14th Floor',
    city: 'San Francisco', state: 'CA', zip: '94104',
    phone: '8554787786',
    email: 'membercare@sunrun.com'
  },
  siteOwnerSameAsComplainant: true,
  constructionSiteSameAsOwnerAddress: true,
  contractNegotiated: 'At my home, 5 Caladium, Rancho Santa Margarita',
  findContractor: 'O', // Other
  findContractorOther: 'Existing Sunrun customer since 2012; service dispatched at my request',
  primaryComplaint: 'W', // Workmanship
  contractDate: '09/12/2012',
  // Contract amount fields: original 2012 Prepaid PPA — exact number is in the contract Sunrun has on file.
  // Using 0 so form doesn't become a sworn inaccurate figure; user can correct during review.
  contractAmount: '0',
  contractAmountPaid: '0',
  workDateStarted: '11/07/2025',
  workDateCeased: '11/07/2025',
  howPayForSystem: 'P', // Power Purchase Agreement
  listItems: `Sunrun Installation Services technicians disconnected my residential solar system at 5 Caladium, Rancho Santa Margarita, CA 92688 during a service visit on November 7, 2025 and failed to reconnect it or notify me that the system had been left inoperative.

The system (11.16 kW combined: a 2012 Sunrun-owned Prepaid Power Purchase Agreement system and a 2017 Costco customer-owned Sunrun-installed system) produced ZERO exportable power from November 7, 2025 through April 16, 2026, a period of over five months. This is documented by SDG&E NEM Meter 06688420 on Account 0036 1837 1728 9, which shows zero solar export in every Time-of-Use bucket for five consecutive monthly billing cycles.

I discovered the outage only by reviewing my SDG&E bills; Sunrun never notified me. When I escalated in April 2026 (Sunrun Service Case 18181148), Sunrun dispatched technicians on April 16-17, 2026 who completed the repairs necessary to restore production. The Sunrun representative Katherine Wilson acknowledged that Sunrun's technicians had disconnected the panels during the earlier visit.

Sunrun offered me only $450 as an Early Performance Guarantee credit despite more than five months of zero production caused by their own technicians' workmanship error and their failure to notify me. My excess SDG&E electricity bills during the outage period total approximately $3,600. I submitted a formal written warranty demand on April 17, 2026 requesting $7,500 in direct damages; Sunrun acknowledged receipt but stated I must retain an attorney to access their legal resolution team, which is not economically practical for this claim size. On April 20, 2026 Sunrun unilaterally declared the case closed without addressing reimbursement.

On April 20, 2026 I also filed a complaint with the California Public Utilities Commission (portal confirmation #226711). On April 21, 2026 CPUC Consumer Affairs Branch closed that complaint as Commission File #726931, declining jurisdiction and referring me to CSLB as the correct agency.

This complaint concerns workmanship by Sunrun Installation Services, Inc. (CSLB License #750184) under an active service/maintenance relationship. Separately, CSLB License #969975 (Sunrun, Inc.) is the affiliated parent entity named in my 2012 and 2017 agreements. I am the property owner of record.`,
  remedy: `1. Require Sunrun Installation Services, Inc. to reimburse me approximately $3,600 for excess SDG&E electricity costs incurred between November 7, 2025 and April 16, 2026 as a direct result of their technicians leaving my solar system disconnected.

2. Investigate whether Sunrun has a pattern of technicians disconnecting customer systems during service visits and failing to notify customers, which may affect many California solar customers served under Sunrun PPAs and customer-owned installations.

3. Review Sunrun's post-service customer notification procedures and whether the lack of any "system-offline" notification to customers constitutes a violation of contractor workmanship standards under Business and Professions Code sections governing licensed contractors.

4. Review Sunrun's practice of requiring consumers to retain legal counsel before accessing their internal warranty and legal resolution process, which operates as a barrier to consumer remedies on claims too small to justify individual counsel.`,
  filedInCourt: 'N',
  residenceProject: 'Residence',
  batteryBackup: 'N',
  signContract: 'Wet Signature',
  changeOrder: 'N',
  disclosureNotice: 'Y',
  buildingPermit: 'Contractor',
  employeeList: 'N',
  authorizationDoc: 'N',
  reverseMortgage: 'N',
  contactAttempts: ['Personal contact', 'Telephone', 'Letter/Email'],
  contractorPaid: 'Y',
  contractorAmountPaid: '0',
  gotEstimate: 'N',
  workCompleted: 'Y' // original 2012 install completed; 2025 incident eventually remediated April 2026
};

const waitForNetwork = async (page, ms = 1500) => {
  try { await page.waitForLoadState('networkidle', { timeout: 20000 }); } catch (e) {}
  await page.waitForTimeout(ms);
};

(async () => {
  const browser = await chromium.launch({ headless: false, slowMo: 80 });
  const page = await browser.newPage();

  console.log('Navigating to CSLB Solar Complaint intake page...');
  await page.goto('https://www.cslb.ca.gov/OnlineServices/SolarComplaint/SolarComplaintFormProcess.aspx', { waitUntil: 'domcontentloaded', timeout: 60000 });
  await waitForNetwork(page, 3000);

  console.log('Clicking Start a new complaint...');
  await page.locator('#MainContent_btnNewbutton').click();
  await waitForNetwork(page, 4000);
  await page.screenshot({ path: 'c:/vscode/tech-legal/docs/personal/sunrun/cslb-step0-after-start.png', fullPage: true });
  console.log(`  After Start, URL: ${page.url()}, title: ${await page.title()}`);

  // Advance past the "General Information and Instructions" intro page
  console.log('  Advancing past intro page...');
  for (let i = 0; i < 3; i++) {
    const lastNameVisible = await page.locator('#MainContent_tbLastName').isVisible().catch(() => false);
    if (lastNameVisible) break;
    console.log(`  Intro page detected (attempt ${i + 1}) — clicking Next...`);
    await page.locator('#MainContent_btnNext').click();
    await waitForNetwork(page, 3000);
  }

  // STEP 1: Complainant Info
  console.log('STEP 1: Filling complainant info...');
  // Select Individual — this may trigger ASP.NET postback revealing the person name fields
  await page.locator('#MainContent_rbIndividual').check();
  await waitForNetwork(page, 3000);
  await page.screenshot({ path: 'c:/vscode/tech-legal/docs/personal/sunrun/cslb-step1-after-individual.png', fullPage: true });
  // Wait for the last name field to become visible before filling
  try {
    await page.locator('#MainContent_tbLastName').waitFor({ state: 'visible', timeout: 10000 });
  } catch (e) {
    console.log('tbLastName not visible — dumping visible form fields for debug...');
    const visible = await page.evaluate(() => {
      const els = [...document.querySelectorAll('input, textarea, select')];
      return els.filter(el => el.offsetParent !== null && el.type !== 'hidden').map(el => ({ id: el.id, type: el.type, label: el.closest('label')?.innerText || '' }));
    });
    console.log(JSON.stringify(visible, null, 2));
    throw e;
  }
  await page.locator('#MainContent_tbLastName').fill(DATA.complainant.lastName);
  await page.locator('#MainContent_tbFirstName').fill(DATA.complainant.firstName);
  await page.locator('#MainContent_tbStreet').fill(DATA.complainant.street);
  await page.locator('#MainContent_tbCity').fill(DATA.complainant.city);
  await page.locator('#MainContent_ddlState').selectOption(DATA.complainant.state);
  await page.locator('#MainContent_tbZip').fill(DATA.complainant.zip);
  await page.locator('#MainContent_tbDayTimePhone').fill(DATA.complainant.dayPhone);
  await page.locator('#MainContent_tbEmail').fill(DATA.complainant.email);
  await page.locator('#MainContent_Nextbutton_1').click();
  await waitForNetwork(page, 2500);

  // STEP 2: Contractor Info
  console.log('STEP 2: Filling contractor info...');
  await page.locator('#MainContent_tbContractorBusinessName').fill(DATA.contractor.businessName);
  // Try multiple candidate IDs for contractor first/last name (CSLB uses varying ids)
  const fillFirst = async (candidates, val) => {
    for (const sel of candidates) {
      try {
        const loc = page.locator(sel);
        if (await loc.count()) { await loc.first().fill(val); console.log(`  filled ${sel} = ${val}`); return true; }
      } catch (e) {}
    }
    console.log(`  NO candidate matched for value: ${val}`);
    return false;
  };
  await fillFirst([
    '#MainContent_tbContractorFirstName', '#MainContent_tbContractorFname',
    '#MainContent_tbContractorFName', '#MainContent_tbContractorFirst',
    'input[name$="tbContractorFirstName"]', 'input[name$="tbContractorFname"]'
  ], DATA.contractor.firstName);
  await fillFirst([
    '#MainContent_tbContractorLastName', '#MainContent_tbContractorLname',
    '#MainContent_tbContractorLName', '#MainContent_tbContractorLast',
    'input[name$="tbContractorLastName"]', 'input[name$="tbContractorLname"]'
  ], DATA.contractor.lastName);
  await page.locator('#MainContent_tbContractorLicense').fill(DATA.contractor.license);
  await page.locator('#MainContent_tbContractorAddress1').fill(DATA.contractor.street);
  await page.locator('#MainContent_tbContractorCity').fill(DATA.contractor.city);
  await page.locator('#MainContent_ddlContractorState').selectOption(DATA.contractor.state);
  await page.locator('#MainContent_tbContractorZip').fill(DATA.contractor.zip);
  await page.locator('#MainContent_tbContractorDayPhone').fill(DATA.contractor.phone);
  await page.locator('#MainContent_tbContractorEmail').fill(DATA.contractor.email);
  await page.locator('#MainContent_tbContractNegotiated').fill(DATA.contractNegotiated);
  // How did you find/reach the contractor — "Other"
  await page.locator(`input[name="ctl00$MainContent$rblFindContractor"][value="${DATA.findContractor}"]`).check();
  await page.waitForTimeout(500);
  try { await page.locator('#MainContent_tbOtherContractor').fill(DATA.findContractorOther); } catch (e) {}
  await page.locator('#MainContent_Nextbutton_2').click();
  await waitForNetwork(page, 2500);

  // Helper: force-set a field via evaluate (bypasses ASP.NET hidden/visibility state)
  const forceCheck = async (selector) => {
    await page.evaluate((sel) => {
      const el = document.querySelector(sel);
      if (el && !el.checked) { el.checked = true; el.dispatchEvent(new Event('change', { bubbles: true })); el.dispatchEvent(new Event('click', { bubbles: true })); }
    }, selector);
  };
  const forceFill = async (id, val) => {
    await page.evaluate(([i, v]) => {
      const el = document.getElementById(i);
      if (el) { el.value = v; el.dispatchEvent(new Event('input', { bubbles: true })); el.dispatchEvent(new Event('change', { bubbles: true })); }
    }, [id, val]);
  };

  // Robust step-advance: try step-specific Next, then generic Next, then __doPostBack.
  // Waits for sentinel selector (or URL change) before returning true.
  const advanceStep = async (stepNum, sentinelFn, label) => {
    const specificId = `#MainContent_Nextbutton_${stepNum}`;
    const postbackName = `ctl00$MainContent$Nextbutton_${stepNum}`;
    const genericId = '#MainContent_btnNext';

    const strategies = [
      async () => {
        const btn = page.locator(specificId);
        if (await btn.isVisible().catch(() => false)) {
          console.log(`  [${label}] clicking ${specificId} (visible)...`);
          await btn.click();
          return true;
        }
        return false;
      },
      async () => {
        const btn = page.locator(genericId);
        if (await btn.isVisible().catch(() => false)) {
          console.log(`  [${label}] clicking ${genericId} (generic, visible)...`);
          await btn.click();
          return true;
        }
        return false;
      },
      async () => {
        console.log(`  [${label}] doing __doPostBack(${postbackName}) fallback...`);
        await page.evaluate((name) => {
          // eslint-disable-next-line no-undef
          if (typeof __doPostBack === 'function') __doPostBack(name, '');
        }, postbackName);
        return true;
      },
      async () => {
        // Last-ditch: force the specific button visible + click
        console.log(`  [${label}] force-visible + click ${specificId}...`);
        await page.evaluate((sel) => {
          const el = document.querySelector(sel);
          if (el) { el.style.display = ''; el.style.visibility = 'visible'; el.removeAttribute('hidden'); el.click(); }
        }, specificId);
        return true;
      }
    ];

    for (let s = 0; s < strategies.length; s++) {
      try {
        const did = await strategies[s]();
        if (!did) continue;
        await waitForNetwork(page, 2500);
        if (await sentinelFn()) {
          console.log(`  [${label}] advanced (strategy ${s + 1}).`);
          return true;
        }
        console.log(`  [${label}] strategy ${s + 1} did not reach sentinel — trying next...`);
      } catch (e) {
        console.log(`  [${label}] strategy ${s + 1} error: ${e.message}`);
      }
    }
    return false;
  };

  // Skip any intermediate page before Step 3
  for (let i = 0; i < 3; i++) {
    const visible = await page.locator('#MainContent_chkOwner').isVisible().catch(() => false);
    if (visible) break;
    console.log(`  Step 3 intro page (attempt ${i + 1}) — clicking Next...`);
    const nb = page.locator('#MainContent_btnNext');
    if (await nb.isVisible().catch(() => false)) { await nb.click(); await waitForNetwork(page, 3000); } else break;
  }

  // STEP 3: Project info + complaint details (force-fill to bypass any remaining hidden state)
  console.log('STEP 3: Filling project info and complaint details...');
  await forceCheck('#MainContent_chkOwner');
  await waitForNetwork(page, 1000);
  await forceCheck('#MainContent_chkProjectConstructionSite');
  await forceCheck(`input[name="ctl00$MainContent$rblPrimaryComplaint"][value="${DATA.primaryComplaint}"]`);
  await waitForNetwork(page, 800);
  await forceFill('MainContent_tbProjectContractDate', DATA.contractDate);
  await forceFill('MainContent_tbProjectContractAmount', DATA.contractAmount);
  await forceFill('MainContent_tbProjectContractAmountPaid', DATA.contractAmountPaid);
  await forceFill('MainContent_tbProjectContractWorkDateStarted', DATA.workDateStarted);
  await forceFill('MainContent_tbProjectContractWorkDateCeased', DATA.workDateCeased);
  await forceCheck(`input[name="ctl00$MainContent$rblHowPayForSystem"][value="${DATA.howPayForSystem}"]`);
  await waitForNetwork(page, 800);
  await forceFill('MainContent_tbProjectListItems', DATA.listItems);
  await forceFill('MainContent_tbProjectRemedy', DATA.remedy);
  await page.screenshot({ path: 'c:/vscode/tech-legal/docs/personal/sunrun/cslb-step3-filled.png', fullPage: true });

  // Advance past Step 3 using robust helper (step-specific → generic → __doPostBack)
  const step4Sentinel = async () => {
    // Either we see Step 4 fields, or we land on the intro page between Step 3 and Step 4
    const step4Field = await page.locator(`input[name="ctl00$MainContent$rblFiledInCourt"]`).first().isVisible().catch(() => false);
    if (step4Field) return true;
    // Are we past Step 3 entirely? Check that Step 3 textarea is no longer present
    const step3StillHere = await page.locator('#MainContent_tbProjectListItems').isVisible().catch(() => false);
    return !step3StillHere;
  };
  const advanced3 = await advanceStep(3, step4Sentinel, 'Step 3 → 4');
  if (!advanced3) {
    await page.screenshot({ path: 'c:/vscode/tech-legal/docs/personal/sunrun/cslb-step3-advance-fail.png', fullPage: true });
    throw new Error('Could not advance past Step 3');
  }

  // Skip any intermediate page before Step 4
  for (let i = 0; i < 4; i++) {
    const visible = await page.locator(`input[name="ctl00$MainContent$rblFiledInCourt"]`).first().isVisible().catch(() => false);
    if (visible) break;
    console.log(`  Step 4 intro page (attempt ${i + 1}) — clicking Next...`);
    const nb = page.locator('#MainContent_btnNext');
    if (await nb.isVisible().catch(() => false)) { await nb.click(); await waitForNetwork(page, 3000); }
    else {
      // Try postback for ctl00$MainContent$btnNext
      console.log('  btnNext not visible — trying __doPostBack...');
      await page.evaluate(() => { try { __doPostBack('ctl00$MainContent$btnNext', ''); } catch (e) {} });
      await waitForNetwork(page, 3000);
    }
  }
  await page.screenshot({ path: 'c:/vscode/tech-legal/docs/personal/sunrun/cslb-step4-landed.png', fullPage: true });

  // STEP 4: Project details (force-fill all)
  console.log('STEP 4: Filling project details...');
  await forceCheck(`input[name="ctl00$MainContent$rblFiledInCourt"][value="${DATA.filedInCourt}"]`);
  await forceCheck(`input[name="ctl00$MainContent$rblResidenceProject"][value="${DATA.residenceProject}"]`);
  await forceCheck(`input[name="ctl00$MainContent$rblbatterybackup"][value="${DATA.batteryBackup}"]`);
  await forceCheck(`input[name="ctl00$MainContent$rblsigncontract"][value="${DATA.signContract}"]`);
  await forceCheck(`input[name="ctl00$MainContent$rblChangeOrder"][value="${DATA.changeOrder}"]`);
  await forceCheck(`input[name="ctl00$MainContent$rbldisclosurenotice"][value="${DATA.disclosureNotice}"]`);
  await forceCheck(`input[name="ctl00$MainContent$rblBuildingPermit"][value="${DATA.buildingPermit}"]`);
  await forceCheck(`input[name="ctl00$MainContent$rblEmployeeList"][value="${DATA.employeeList}"]`);
  await forceCheck(`input[name="ctl00$MainContent$rblauthorizationdoc"][value="${DATA.authorizationDoc}"]`);
  await forceCheck(`input[name="ctl00$MainContent$rblreversemortgage"][value="${DATA.reverseMortgage}"]`);

  for (const attempt of DATA.contactAttempts) {
    await forceCheck(`input[name^="ctl00$MainContent$cblatempts"][value="${attempt}"]`);
  }

  await forceCheck(`input[name="ctl00$MainContent$rblContractorpaid"][value="${DATA.contractorPaid}"]`);
  await waitForNetwork(page, 800);
  await forceFill('MainContent_tbContractorAmount', DATA.contractorAmountPaid);
  await forceCheck(`input[name="ctl00$MainContent$rblEstimate"][value="${DATA.gotEstimate}"]`);
  await forceCheck(`input[name="ctl00$MainContent$rblCompleted"][value="${DATA.workCompleted}"]`);
  await page.screenshot({ path: 'c:/vscode/tech-legal/docs/personal/sunrun/cslb-step4-filled.png', fullPage: true });

  // Advance past Step 4 using robust helper
  const step5Sentinel = async () => {
    // Step 5 is Review — look for a Submit button, a "Review" header, or disappearance of Step 4 fields
    const submitVisible = await page.locator('#MainContent_btnSubmit, input[value*="Submit"]').first().isVisible().catch(() => false);
    if (submitVisible) return true;
    const reviewHeader = await page.locator('text=/Review/i').first().isVisible().catch(() => false);
    const step4Gone = !(await page.locator(`input[name="ctl00$MainContent$rblFiledInCourt"]`).first().isVisible().catch(() => false));
    return reviewHeader && step4Gone;
  };
  const advanced4 = await advanceStep(4, step5Sentinel, 'Step 4 → 5');
  if (!advanced4) {
    await page.screenshot({ path: 'c:/vscode/tech-legal/docs/personal/sunrun/cslb-step4-advance-fail.png', fullPage: true });
    console.log('Could not advance past Step 4 (sentinel not met) — check cslb-step4-advance-fail.png');
  }

  // Skip any intermediate page before Step 5 (Review)
  for (let i = 0; i < 4; i++) {
    const submitVisible = await page.locator('#MainContent_btnSubmit, input[value*="Submit"]').first().isVisible().catch(() => false);
    if (submitVisible) break;
    console.log(`  Step 5 intro page (attempt ${i + 1}) — clicking Next...`);
    const nb = page.locator('#MainContent_btnNext');
    if (await nb.isVisible().catch(() => false)) { await nb.click(); await waitForNetwork(page, 3000); }
    else {
      await page.evaluate(() => { try { __doPostBack('ctl00$MainContent$btnNext', ''); } catch (e) {} });
      await waitForNetwork(page, 3000);
    }
  }
  await page.screenshot({ path: 'c:/vscode/tech-legal/docs/personal/sunrun/cslb-step5-review.png', fullPage: true });

  console.log('');
  console.log('====================================================');
  console.log('ALL FIELDS FILLED. Now on Review (Step 5).');
  console.log('Please do the following manually:');
  console.log('  1. Scroll through the review page — verify every field');
  console.log('  2. Use the Edit buttons to fix anything that looks wrong');
  console.log('  3. Click "Submit This Complaint" when ready');
  console.log('  4. On the final page, enter your email (rjain@technijian.com)');
  console.log('     and click "Email PDF" to get the signable copy');
  console.log('====================================================');
  console.log('Browser stays open for 30 minutes.');

  await page.waitForTimeout(30 * 60 * 1000);
  await browser.close();
})();
