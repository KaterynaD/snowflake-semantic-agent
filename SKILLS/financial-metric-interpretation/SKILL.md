---
name: financial-metric-interpretation
description: Interpret business questions about ARR and choose the right view—Preliminary for the current ARR position and near-term outlook, True for operationally confirmed ARR, and Backdated for retrospective contractual-period reporting. Also explain ARR versus bookings, fiscal periods, renewals, and why monthly ARR snapshots cannot be summed. Use even when the user does not explicitly mention an ARR type, such as "Where do we stand now?", "What is confirmed?", or "What did prior months look like after corrections?"
---

# Financial Metric Interpretation

## Objective
Answer business questions using the ARR view that matches the **reporting purpose**, not just the words in the question. Explain the choice in business language. Use governed Snowflake semantic metrics for numerical answers; explain concepts directly when no numbers are requested.

## The central business distinction: what question is being answered?

The three ARR views are alternative ways of reporting recurring contractual value from the same underlying business. **They are not separate revenue streams and must never be added together.**

### Preliminary ARR — where do we stand, and what is our near-term outlook?
- **Purpose:** The best available **expected operational ARR** for current or recent business reporting when some renewal or payment outcomes remain unresolved.
- **Business perspective:** Favors a useful view of ongoing recurring business rather than dropping ARR immediately at a contract end while the renewal outcome is still pending.
- **How it works:** Applies True ARR's operational start-date logic, but can temporarily continue expected ARR through a limited renewal grace period. Standard grace periods: **6 months for State/Biz Dev; 90 days for Texas accounts; 60 days for other District accounts**. A confirmed renewal invoice or close event can end the extension earlier.
- **Use for:** Current ARR position, recent business performance, near-term planning and expectations, and general ARR questions with no stronger reporting intent.
- **Interpretation:** Estimated/expected, **not fully confirmed actuals**. A near-term outlook is **not** a complete sales forecast; do not fabricate ARR for future months not represented in the available data.

### True ARR — what has been operationally confirmed?
- **Purpose:** **Actuals-based, operationally confirmed ARR**, without an assumption that an unresolved renewal will continue.
- **Business perspective:** Favors evidence of invoicing or confirmed loss over expected renewal continuity.
- **How it works:** A Closed Won contract becomes reportable only after its Invoiced Date; a Closed Lost renewal is reduced upon its confirming Close Date. Effective starts can shift later than contractual starts. **No grace period.**
- **Use for:** Confirmed ARR, actuals-oriented operational reporting, or questions that explicitly exclude expectations and grace-period assumptions.
- **Interpretation:** Operational confirmation is **not the same as recognized accounting revenue or cash received**.

### Backdated ARR — what belongs to earlier contractual periods after we know more?
- **Purpose:** **Adjusted historical ARR** allocated to the contractual period after subsequent operational confirmation.
- **Business perspective:** Favors retrospective accuracy of *which period the confirmed business belongs to*, rather than the best current operational estimate.
- **How it works:** Retains the contract start period (subject to parent/renewal continuity rules), but does not make ARR reportable before the required Invoiced Date or Close Date confirmation. A later confirmed event may correct a prior reporting month. **No grace period.** Standard historical recalculation uses a **rolling 12-month window**.
- **Use for:** Looking back over previous months, explaining restated or corrected historical ARR, retrospective period analysis, and contract-period alignment.
- **Interpretation:** **Not the default for a current ARR position or near-term outlook.** The rolling window also means older periods are not necessarily restated automatically.

## Choose ARR based on reporting intent

1. **Explicit type wins.** If the user says Preliminary, True, or Backdated, query that type and describe it accurately.
2. **Current position / latest ARR / how much recurring business do we expect to maintain / near-term outlook** → **Preliminary ARR** (`ARR`, the default semantic metric).
3. **Confirmed / invoiced / actuals / excluding pending renewals / no assumptions** → **True ARR** (`TRUE_ARR`).
4. **Retrospective / restated history / after later confirmations / revised prior months / aligned to original contract periods** → **Backdated ARR** (`BACKDATED_ARR`).
5. **General ARR questions with no clear reporting intent** → **Preliminary ARR** (`ARR`), because it is the business default. State the type in the answer.
6. **Historical date alone does not automatically mean Backdated.** "What was ARR in June?" is different from "After later corrections, what ARR belongs to June?" The latter calls for Backdated; the former uses Preliminary by default unless context implies otherwise.
7. **When the distinction affects the answer**, briefly explain why the selected view fits and mention the other view if it could materially change interpretation. Ask a clarification only when the user's objective cannot reasonably be inferred.
8. **Forecasting boundary:** Use Preliminary to describe a near-term outlook only to the extent supported by available snapshots or explicit documented grace-period rules. Do not extrapolate a numerical future ARR forecast, assume renewals will close, or call a current snapshot a forecast. If future data or a forecast model is unavailable, say so.

## Intent-based examples

| User question | Preferred view | Reason |
| --- | --- | --- |
| "What's our ARR right now?" | `ARR` — Preliminary | Best available current operational estimate |
| "What ARR are we carrying into the next few months?" | `ARR` — Preliminary, subject to data availability | Includes limited expected continuity for unresolved renewals; not a predictive forecast |
| "How much ARR has actually been confirmed?" | `TRUE_ARR` — True | Requires operational confirmation; no grace period |
| "What was our ARR last quarter after the late renewals were processed?" | `BACKDATED_ARR` — Backdated | Historical contractual-period corrections |
| "Recalculate March ARR using what we know now." | `BACKDATED_ARR` — Backdated | Retrospective alignment, subject to the available historical window |
| "What was June ARR?" | `ARR` — Preliminary | A past date by itself does not ask for a restatement |
| "Compare expected ARR to confirmed ARR this month." | `ARR` and `TRUE_ARR` | Preliminary versus operational confirmation |
| "Why do True and Backdated ARR differ in earlier months?" | Both | Timing of operational confirmation versus contractual allocation |

## Shared metric and reporting rules

- **ARR:** Annualized recurring contractual value active in a reporting-month snapshot; **semi-additive**. It can be rolled up across nonoverlapping organizations at one snapshot, but **never summed across months**. For fiscal-year-end ARR, select the applicable period-end snapshot rather than adding months.
- **Bookings:** Value sold in completed deals, potentially including recurring, non-recurring, or multi-year portions. The `DW.REVENUE.BOOKING` metric is additive across compatible periods; bookings are a **flow over a period**, unlike ARR's **snapshot balance**.
- **Recognized revenue:** Earned revenue, different from bookings or ARR. It is not provided by the currently described semantic views.
- **Fiscal year:** July 1–June 30; labeled `YYYY/YYYY`; July is fiscal month 1.
- **Sources of numbers:** Use the governed **Annual Recurring Revenue (ARR)** semantic view / `DW.REVENUE.ARR` for ARR and **Bookings & Sales Activity** / `DW.REVENUE.BOOKING` for bookings. Use available semantic dimensions and metrics rather than deriving ARR independently from raw contracts.
- **Organizational comparisons:** Align the reporting period. Customer is `CUSTOMER_NAME`, district is `DISTRICT_NAME`, and an individual account requires its identifier/name.
- **Changes and causes:** Quantify observed differences, but do not claim that they were caused by churn, invoice delays, renewals, or pricing without supporting data. A difference between ARR types is not automatically a reconciliation error.
- **Unexposed measures:** Do not invent recognized revenue, retention rates, contract-level explanations, or numeric forecasts that the accessible models do not support.

## Answer style

Use an ordinary business explanation before technical details. For reported numbers, always identify the **ARR type** and **snapshot/period**. For questions about differences between views, explain **expected continuity vs operational confirmation vs retrospective historical alignment** before discussing date mechanics. Avoid showing SQL unless requested.

## Detailed-rule boundary

This skill provides **interpretation and metric-selection guidance**, not a complete contract-processing specification. For a specific contract's eligibility, renewal overlap, activation/deactivation, or historical exception, consult the full business knowledge document (`knowledge/annual_recurring_revenue_arr_knowledge.md`) if it is available to the agent. Do not assume that a repository file is automatically accessible, and do not improvise missing business rules.
