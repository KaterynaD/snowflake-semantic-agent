---
name: customer-account-context
description: Interpret educational SaaS account hierarchies, customer identity, commercial payers, and state-initiative product access. Use when a user asks whether a specific account is a customer, who pays for a school or district's usage, why an account has usage but no ARR, how accounts relate to ultimate-parent customers, or what STATE_INITIATIVE means.
---

# Customer and Account Business Context

## Objective
Explain the difference between an **account that uses a product** and the **commercial customer that pays for it**. Identify customers using both account hierarchy knowledge and governed ARR data; do not treat usage, product licenses, or a state-initiative flag as equivalent to paying-customer status.

## Sources of evidence
- **`account_lookup` (custom agent tool):** Retrieve account identity, account/district/customer hierarchy, `CONFORMED_CUSTOMER_ID`, `CONFORMED_CUSTOMER_SFDC_ACCOUNT_ID`, `CUSTOMER_NAME`, `STATE_INITIATIVE`, licensing and usage indicators, and other account attributes. Its source is the account knowledge view. It does **not** calculate ARR.
- **Annual Recurring Revenue (ARR) Cortex Analyst tool:** Retrieve governed ARR through the existing ARR semantic view. Use this, not account attributes or opportunity totals, to determine whether a customer has ARR.
- **Student Engagement & Product Usage Cortex Analyst tool:** Retrieve governed student-reach and product-usage metrics if the question requires usage quantities. `HAS_PRODUCT_USAGE` is an account indicator, not a student count.
- **Bookings & Sales Activity Cortex Analyst tool:** Retrieve bookings when asked. Bookings are not ARR.

## Business definitions
- **Account / organization:** A school, district, state-related organization, other customer organization, or prospect represented in the account system. An account record does not by itself establish a commercial relationship.
- **Operational hierarchy:** The schools and districts where licenses or usage may occur.
- **Commercial hierarchy:** Accounts can roll up to a district and a customer / ultimate-parent organization. The account receiving product access may differ from the entity that pays.
- **Ultimate parent:** The root of the relevant customer hierarchy, established from the returned account mapping. Do not infer ultimate-parent status from account names or from `CUSTOMER_NAME` alone.
- **Customer (paying customer):** An account qualifies as a customer **only when both conditions hold**:
  1. It is the **ultimate parent account** of the customer hierarchy.
  2. Its customer hierarchy has **positive Preliminary ARR in the current reporting month**, verified using the ARR semantic view.
  These conditions are applied by the agent using the two sources of evidence. Customer status is **not** a field calculated in the account knowledge view or `account_lookup`.
- **Account with product access:** An account can have licenses or product usage without being a paying customer and without having ARR booked against that individual account.
- **Access, enrollment, and usage:** License availability, provisioned students, enrolled students, and students who launch products are different concepts.

## State initiative — who pays
- `STATE_INITIATIVE` is the **authoritative state-initiative flag** in account knowledge.
- When **`STATE_INITIATIVE = TRUE`**, the account's product access/usage is covered by a **commercial customer that pays for those accounts' usage**. The flagged school or district is not necessarily a paying customer itself and may have no ARR recorded directly against its account.
- The state-initiative flag does **not** identify the commercial payer by itself, establish that the flagged account is an ultimate parent, or prove that a particular ultimate parent has positive ARR. Resolve relationships using account knowledge and verify monetary amounts via the ARR semantic view.
- Do **not** say that a state government or state organization pays unless the account and contract evidence actually identifies it as the commercial customer.
- `STATE_INITIATIVE` is stored as `VARCHAR` in the current Snowflake table. Interpret the literal value `TRUE` (case-insensitively) as affirmative, `FALSE` as negative, and missing/unrecognized values as unknown; do not treat every non-null value as true.

## How to answer questions

### A. "Is this organization a customer?"
1. Call `account_lookup` to resolve the account. If multiple accounts match, request disambiguation instead of guessing.
2. Establish its ultimate-parent relationship from the returned hierarchy. A child account can **belong to** a customer without **being** the customer.
3. Query the ARR semantic view at the appropriate **customer hierarchy** scope for **Preliminary ARR in the current reporting month**.
4. Apply the two-part customer definition. Report the ARR reporting month explicitly. If current-month data is unavailable, do not claim that current customer status is verified; describe the latest available evidence instead.

### B. "Why does this account use the product but have no ARR?"
1. Call `account_lookup` to inspect `HAS_PRODUCT_USAGE`, `HAS_PRODUCT_LICENSES`, `STATE_INITIATIVE`, the district, and the customer hierarchy.
2. Check whether ARR is being considered at the individual account level or the commercial-customer level. If needed, query both relevant scopes through the ARR semantic view.
3. If `STATE_INITIATIVE = TRUE`, explain the **business arrangement**: a commercial customer pays for the usage of participating accounts. Do not identify a specific payer unless the account evidence supports it.
4. Distinguish verified account attributes, verified ARR amounts, and explanations that remain unconfirmed. Do not invent contract terms or claim that missing account-level ARR means the account has no access.

### C. "Who pays for this school or district?"
1. Resolve the account and its hierarchy with `account_lookup`.
2. Use `STATE_INITIATIVE` and available commercial hierarchy attributes to explain the likely payment relationship.
3. Identify a named payer only when the mapping actually establishes it. Use the ARR semantic view to verify ARR rather than treating hierarchy or program flags as proof of a payment amount.

### D. Aggregate metrics
For ARR, bookings, or student counts, use the relevant semantic view. Do not derive these values by summing account indicators, opportunity counts, or the account lookup payload. Do not join finance and usage on account names alone without validated mappings.

## Response guidance
- Explain **who uses**, **who gets access**, **who belongs to the customer hierarchy**, and **who pays** as separate concepts.
- Say **"belongs to a customer"** rather than **"is a customer"** for a child account, unless that child independently meets the customer definition.
- State whether customer status is confirmed, not confirmed, or cannot be determined with available evidence.
- Name the ARR type and reporting month when customer status depends on ARR.
- Keep reasoning grounded in returned attributes and semantic-query results; do not claim unverified commercial relationships.

## Example questions
- Is Lincoln Elementary a customer, or does it belong to another customer?
- Why does this district show product usage but no ARR against its own account?
- If `STATE_INITIATIVE` is true, who pays for this account's access?
- Which ultimate-parent customer is associated with this account?
- Can an account have licenses without being a paying customer?
