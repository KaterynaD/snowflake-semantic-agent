---
name: student-usage-interpretation
description: Interpret student reach, unique students, learning-product launches, school-year snapshots and overlapping product or grade categories. Use when a user compares usage across schools, districts, states, products, grades or months, or asks why summed student counts differ from a company total.
---

# Student Engagement and Product Usage Interpretation

## Objective
Explain learning-product adoption accurately without double counting students or cumulative usage snapshots.

## Business concepts
- **Distinct students reached:** Number of unique students with usage in the relevant cumulative school-year snapshot. It is not school enrollment or license provisioning.
- **Launch events:** A count of student activity launches. A student may launch more than once. Launches are not distinct students.
- **School-year-to-date:** Usage metrics accumulate since July, with snapshots at the end of reporting months. Do not add successive cumulative snapshots.
- **Product and grade categories:** May overlap. An explicit `(All)` row represents the precomputed total; do not add category breakdowns or substitute a differently named category such as `All Students`.

## Workflow
1. Use **Student Engagement & Product Usage** (`DW.USAGE.PRODUCT_USAGE`) to retrieve governed metrics.
2. For unique students, use the metric matching the reporting level: `SCHOOL_STUDENTS`, `DISTRICT_STUDENTS`, `STATE_STUDENTS`, `COUNTRY_STUDENTS`, or `COMPANY_STUDENTS`.
3. Do not derive a parent-level unique-student count by summing lower-level distinct-student counts. The view has separately pre-aggregated counts at each geographic level.
4. Use `STUDENTS_LAUNCHES` for launch events. It can be rolled up across nonoverlapping schools at one snapshot, but not across cumulative months or overlapping product/grade categories.
5. For a calendar-month question, apply `MON_YEAR` (`YYYYMM`). For school-year reporting, use `SCHOOLYEAR` (`YYYY/YYYY`); September 2026 belongs to school year 2026/2027.
6. For unfiltered product and grade questions, use the view's precomputed `(All)` totals; for an explicit product or grade, filter to the exact available label.
7. Use school and district IDs for identity because names can repeat. Do not assume that a school or district is a paying customer on the basis of usage.
8. If a user asks about enrollment, licenses, student success, completion rates or reasons for a usage change, state when current semantic views lack evidence for the requested claim.

## Example prompts
- "How many unique students used our products in California in September 2026?"
- "Why doesn't the sum of school student counts equal the state count?"
- "Compare student launches and unique students in FY 2025/2026."
- "Why don't student counts across product categories add up to the total?"

## Response guidance
Label "unique students" and "launch events" clearly. State the school year and as-of snapshot where relevant. Do not invent data or causal explanations.
