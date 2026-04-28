# CPUC Complaint — Confirmation #226711

**Filed:** 2026-04-20
**Portal:** https://cims.cpuc.ca.gov/complaints/Home/FileComplaint
**Method:** Playwright automation (see [cpuc-complaint.js](cpuc-complaint.js))
**Status Lookup:** https://cims.cpuc.ca.gov/complaints/

## Complainant Information
| Field | Value |
|-------|-------|
| First Name | Ravi |
| Last Name | Jain |
| Street (LocationService) | 5 Caladium |
| City | Rancho Santa Margarita |
| State | CA |
| Zip | 92688 |
| Mobile Phone | 714-402-3164 |
| Email | rjain@technijian.com |

## Utility Information
| Field | Value |
|-------|-------|
| Utility Name | Sunrun, Inc. and Sunrun Installation Services, Inc. |
| Account Number | 0036 1837 1728 9 |

## Narrative Submitted

### 1. What is the situation that concerns you?
> Sunrun technicians disconnected my residential solar system (11.16 kW, two Sunrun systems at the same property: a 2012 Sunrun-owned Prepaid PPA and a 2017 customer-owned Costco solar system) during a service visit on November 7, 2025 at 5 Caladium, Rancho Santa Margarita, CA 92688. The system produced ZERO exportable power from 11/7/2025 through 4/16/2026, a period of over five months. Sunrun never notified me the system was offline. I discovered the outage only when reviewing my SDG&E bills (NEM Meter 06688420) which showed zero solar export for five consecutive months. My electric bills increased by approximately $3,600 during this period. Sunrun Service Case 18181148.

### 2. What did the utility say when you contacted them?
> Sunrun completed repairs on April 16-17, 2026 after I escalated. Their representative Katherine Wilson offered only a $450 Early Performance Guarantee credit despite over five months of zero production caused by their own technicians. I submitted a formal written warranty demand on April 17, 2026 requesting $7,500 in direct damages. Sunrun acknowledged receipt but stated I must retain an attorney to access their legal resolution team, making individual pursuit financially impractical. Their customercare inbox is unmonitored per auto-response. On April 20, 2026 Sunrun unilaterally declared the case closed with the message that my system is back to normal, without addressing reimbursement.

### 3. What action do you want the CPUC to take?
> 1. Investigate Sunruns failure to notify California customers when their solar systems are rendered non-operational by Sunruns own technicians.
> 2. Determine whether Sunrun has a pattern of disconnecting customer systems during service visits without notifying customers, which may affect many California solar customers.
> 3. Require Sunrun to provide fair reimbursement of at least $3,600 for excess electricity costs caused by their negligence.
> 4. Review Sunruns practice of requiring consumers to retain counsel before accessing internal warranty resolution, which operates as a barrier to consumer remedies.

### How did you find out about CPUC?
WEB

## Form Technical Notes (for future filings)
- The form **rejects single quotes** in narrative fields (uses them as SQL delimiters) — always write "Sunruns" not "Sunrun's"
- 1000 character limit per narrative field (~200 words each)
- reCAPTCHA must be completed manually — cannot be automated
- File attachments accepted: Word, Excel, PDF, JPEG, PNG, GIF (max 4 MB)
- Field IDs (documented by cpuc-inspect.js):
  - `#FirstName`, `#LastName`, `#BusinessName`
  - `#LocationService` (Street), `#ApartmentService`, `#CityService`, `#StateCodeService`, `#ZipService`
  - `#PhoneDayTime` (Mobile — required), `#PhoneHome`, `#EmailAddress`
  - `#UtilityName`, `#UtilityCustomerAccountNumber`
  - `#situation-concern`, `#utility-response`, `#suggested-action`
  - `#FindCode` (dropdown: UTILITY BILL / ADVERTISEMENT / WEB / FRIEND)
