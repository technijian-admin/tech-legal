# MegaIT — Douglas McGaugh (Referral / Channel Partner)

## Status (as of 2026-05-01)

**Relationship:** Independent IT-services business owner (MegaIT). Doug brought his existing IT clients to Technijian as he transitioned toward retirement (he is over 70 and wanted to keep helping his clients without running the full back-office). Technijian carries those clients on Technijian contracts, performs the bulk of the service stack, and **passes the Systems Architect line item through to Doug at 100%** (Doug performs the Systems Architect work for those clients himself). No written referral / channel-partner agreement exists; the arrangement is by course of dealing.

**Doug is not a Technijian employee, contractor, subcontractor, or worker.** He performs no work *for* Technijian; he performs Systems Architect work *for his own clients*, with Technijian as the prime contractor and billing intermediary on the overall service contract. Indicators that confirm independence:

- No set tasks at Technijian, no schedule, no defined work product.
- Does not work from Technijian's office. Used to come in casually when he felt like it to talk to techs about his own clients.
- Owns and operates a separate IT services company (MegaIT, `megait.us`).
- Sets his own hours, methods, tools.
- Multi-decade independent business; semi-retired.

This is a **referral / channel-partner relationship between two businesses** — outside the ABC test framework (Lab. Code § 2775) because Doug provides no labor or services for remuneration *to Technijian*. Misclassification exposure under AB 5 is not a meaningful concern on these facts.

## Contact

| Field | Value |
|---|---|
| Name | Douglas (Doug) McGaugh |
| Company | MegaIT |
| Authorized email | `doug@megait.us` |
| Technijian mailbox | **Disabled** (per Ravi 2026-03-23) |

## Communication Protocol (Effective 2026-03-23 / 2026-03-30)

1. All Technijian-related communication goes through **Ravi only** (`rjain@technijian.com`), in writing, by email.
2. Doug is **not authorized** to contact Technijian admin or technical staff directly.
3. Doug is **not authorized** to request or obtain client credentials, passwords, or system access from anyone other than Ravi (specifically called out historically: BWH server / ESXi credentials, AOC firewall password). All such requests come to Ravi in writing; Technijian releases credentials only via expressly authorized process.

These restrictions stand because Technijian must control client-credentials handling under its own contractual and security obligations to its clients — not because of any open dispute with Doug.

## Compensation Structure (Pass-Through, Not Commission)

| Element | Detail |
|---|---|
| Mechanism | Doug's compensation is the **full Systems Architect line item** on each Technijian contract for a Doug-referred client, passed through at 100%. |
| Not a commission | This is *not* a percentage of contract revenue. It is the price of the Systems Architect service line specifically. Doug performs that work. |
| Triggered by | Client payment to Technijian on the invoice containing the Systems Architect line. |
| Cycle | Monthly, aligned with Technijian's billing cycle for the underlying client contract. |

## BST (Boston Group) — Resolved 2026-03

Doug initially asserted a $2,800 commission on the BST account was due (per 2026-03-24 email). The trigger he relied on (client payment) had not fully occurred because BST had paid principal but **not the late fees**. Once Technijian made the business decision to **waive BST's late fees** (closing the BST relationship out cleanly, given BST's cancellation), the holdup was removed. Technijian then paid Doug the proper $2,800 as the Systems Architect line for BST. **Doug accepted; matter resolved.** No active dispute on BST.

The 2026-03-24 Ravi reply that initially "disputed" the $2,800 reflected the pre-waiver state where the trigger had not yet occurred. After the late-fee waiver, the trigger was satisfied and the amount was paid as proper.

## BWH (Brandywine Homes) — Active, Rate Reduction Effective 2026-05-01

BWH is on Doug's referred-client roster. Schedule A of the new MSA (DocuSign envelope `26cf808f`, dispatched 2026-04-29) provides 5 hrs/mo of Systems Architect.

**Rate reduction (15% across all Virtual Staff lines):**

| Line | Hours/mo | Old rate | Old monthly | New rate (eff. 5/1/2026) | New monthly | Δ |
|---|---:|---:|---:|---:|---:|---:|
| **Systems Architect** | 5.00 | $200/hr | **$1,000/mo** | $170/hr | **$850/mo** | **−$150/mo** |
| USA Tech Normal | 15.26 | $125/hr | $1,907.50 | $106.25/hr | $1,621.38 | −$286.13 |
| India Tech Normal | 58.13 | $15/hr | $871.95 | $12.75/hr | $741.16 | −$130.79 |
| India Tech After Hours | 42.82 | $30/hr | $1,284.60 | $25.50/hr | $1,091.91 | −$192.69 |

**For Doug specifically:** the Systems Architect monthly pass-through drops from $1,000 to $850, a $150/mo reduction beginning with the May 2026 invoice. The rate cut was a concession negotiated to retain the BWH account (Dave Barisic accepted the package 2026-04-28).

## Email Pull (2026-04-30)

Pulled with `scripts/pull-doug-emails.ps1`. 5 messages total in `emails/`, plus index at `emails/_index.csv`.

| # | Date | Direction | Subject |
|---|---|---|---|
| 1 | 2026-03-23 | Sent | BST Late fees (initial position + comms restriction) |
| 2 | 2026-03-24 | Received | Re: BST Late fees (Doug's $2,800 ask) |
| 3 | 2026-03-24 | Sent | Re: BST Late fees (pre-waiver position; later resolved by waiver + payment) |
| 4 | 2026-03-30 | Sent | Client Credentials and Communication Protocol (formal) |
| 5 | 2026-04-02 | Received | Family time (Easter pleasantries — relationship amicable) |

## Folder Layout

```
referral-partners/MegaIT/
├── README.md                         # this file
├── agreements/                       # for any future signed referral agreement
├── emails/
│   ├── _index.csv                    # CSV index
│   ├── inbox/                        # from Doug
│   └── sent/                         # from Ravi to Doug
└── scripts/
    ├── pull-doug-emails.ps1          # Graph email puller (re-runnable)
    └── draft-doug-bwh-rate-change.ps1 # courtesy notice script (default = draft only)
```

## Notes

- Treat correspondence as potentially evidentiary; preserve `.eml` originals.
- Doug is over 70 and semi-retired. Communications should reflect the long-standing professional relationship — clear, concise, courteous.
- Future client references from Doug, if any, follow the same model: Technijian carries the contract, Doug performs the Systems Architect line at full pass-through.
- A written referral / channel-partner agreement formalizing the pass-through structure would tighten things up but is not currently in place. Worth considering for next quiet period.
