-- Business Analytics Assistant evaluation — 15 questions from user-verified results.
-- Generated from agent_eval_questions(1).csv. Does not execute the questions
-- against the underlying data; results are supplied by the user.
--
-- ASSUMPTION: Your Cortex Agent and evaluation objects are in DW.SERVICE.
-- If your Agent is in a different schema, change DW.SERVICE below accordingly.
--
-- Run the CREATE/INSERT/SELECT blocks in a Snowsight SQL worksheet.
-- The CREATE DATASET call at the end is optional if you prefer using
-- Agent > Evaluations > Create new dataset from this source table.
--
-- This CREATE OR REPLACE statement overwrites only the named evaluation source table.

CREATE OR REPLACE TABLE DW.SERVICE.BUSINESS_AGENT_EVAL_SOURCE (
    INPUT_QUERY VARCHAR,
    GROUND_TRUTH VARIANT
);

INSERT INTO DW.SERVICE.BUSINESS_AGENT_EVAL_SOURCE
    (INPUT_QUERY, GROUND_TRUTH)
SELECT COLUMN1, PARSE_JSON(COLUMN2)
FROM VALUES
    -- Q01 | ARR | DW.REVENUE.ARR
    ('What was our ARR in September 2026?',
     '{"ground_truth_output":"Expected results: 14535765.98. Evaluation requirements: Default to Preliminary ARR; September 2026 month-end snapshot; no sum over months. The response may use commas, currency symbols or compact notation if numerically equivalent; do not invent missing results. Financial values are in USD.","test_id":"Q01","domain":"ARR","expected_semantic_view":"DW.REVENUE.ARR"}'),
    -- Q02 | ARR | DW.REVENUE.ARR
    ('Compare Preliminary, True, and Backdated ARR in September 2026.',
     '{"ground_truth_output":"Expected results: PRELIMINARY_ARR = 14535765.9800000000; TRUE_ARR = 11244962.8900000000; BACKDATED_ARR = 11244869.0600000000. Evaluation requirements: Three separate values; never sum them; compare at the same snapshot. The response may use commas, currency symbols or compact notation if numerically equivalent; do not invent missing results. Financial values are in USD.","test_id":"Q02","domain":"ARR","expected_semantic_view":"DW.REVENUE.ARR"}'),
    -- Q03 | ARR | DW.REVENUE.ARR
    ('What was ARR at the end of fiscal year 2025/2026?',
     '{"ground_truth_output":"Expected results: 17692031.24. Evaluation requirements: June 2026 snapshot; July-June fiscal calendar; default to Preliminary ARR. The response may use commas, currency symbols or compact notation if numerically equivalent; do not invent missing results. Financial values are in USD.","test_id":"Q03","domain":"ARR","expected_semantic_view":"DW.REVENUE.ARR"}'),
    -- Q04 | ARR | DW.REVENUE.ARR
    ('Which 10 US states had the highest ARR in September 2026?',
     '{"ground_truth_output":"Expected results: TX: 6226517.99; NC: 2308979.37; WV: 927856.89; AZ: 725102.81; NY: 500868.60; NJ: 332588.66; AL: 310184.29; CA: 294702.64; MI: 261250.50; OH: 245467.84. Evaluation requirements: Top ten state codes and values, descending, September snapshot. The response may use commas, currency symbols or compact notation if numerically equivalent; do not invent missing results. Financial values are in USD.","test_id":"Q04","domain":"ARR","expected_semantic_view":"DW.REVENUE.ARR"}'),
    -- Q05 | ARR | DW.REVENUE.ARR
    ('Which 10 customers had the highest ARR in September 2026?',
     '{"ground_truth_output":"Expected results: M******* S***** E********** S******* C********** - 907524.96; H****** P***** Schools - 503448.40; K*** I********** School District - 364616.48; W************ /F****** C***** Schools - 244869.63; G******* C***** Schools - 240451.44; C****** I********** School District - 230558.26; N******* H******* Academies - 225414.33; M****** I********** School District - 208811.25; U****** I********** School District - 192255.99; C********* C***** Schools - 184788.18. Evaluation requirements: Group by CUSTOMER_NAME and rank September Preliminary ARR. The response may use commas, currency symbols or compact notation if numerically equivalent; do not invent missing results. Financial values are in USD.","test_id":"Q05","domain":"ARR","expected_semantic_view":"DW.REVENUE.ARR"}'),
    -- Q06 | BOOKING | DW.REVENUE.BOOKING
    ('What were total bookings in fiscal year 2025/2026?',
     '{"ground_truth_output":"Expected results: 15212183.95. Evaluation requirements: Sum booking flows for July 2025-June 2026, all categories. The response may use commas, currency symbols or compact notation if numerically equivalent; do not invent missing results. Financial values are in USD.","test_id":"Q06","domain":"BOOKING","expected_semantic_view":"DW.REVENUE.BOOKING"}'),
    -- Q07 | BOOKING | DW.REVENUE.BOOKING
    ('Show monthly bookings for fiscal year 2025/2026.',
     '{"ground_truth_output":"Expected results: 202507: 3228160.29; 202508: 2008980.59; 202509: 3294200.83; 202510: 357399.54; 202511: 1974364.21; 202512: 1058781.46; 202601: 576981.37; 202602: 128036.73; 202603: 273305.59; 202604: 152026.94; 202605: 484357.36; 202606: 1675589.04. Evaluation requirements: Twelve months in fiscal order July-June; individual monthly sums. The response may use commas, currency symbols or compact notation if numerically equivalent; do not invent missing results. Financial values are in USD.","test_id":"Q07","domain":"BOOKING","expected_semantic_view":"DW.REVENUE.BOOKING"}'),
    -- Q08 | BOOKING | DW.REVENUE.BOOKING
    ('Break down bookings by booking category for fiscal year 2025/2026.',
     '{"ground_truth_output":"Expected results: Renewal: ARR - 8490990.17; Renewal: Biz Dev - 4454909.80; New Business: ARR - 457730.86; Renewal: Upfront Yr 2&3 - 442575.03; Upsell: ARR - 361999.98; New Business: Upfront yr 2&3 - 271959.23; Upsell: Biz Dev - 163940.18; New Business: Biz Dev - 140404.92; New Business: Upfront Yrs>3 - 125966.75; New Business: NRR - 105666.55; Upsell: Upfront Yr 2&3 - 94404.34; Renewal: Upfront Yrs>3 - 80179.71; Renewal: NRR - 21178.62; Upsell: Upfront Yrs>3 - 199.43; Upsell: NRR - 78.38. Evaluation requirements: Use stored BUCKET categories; no invented classifications. The response may use commas, currency symbols or compact notation if numerically equivalent; do not invent missing results. Financial values are in USD.","test_id":"Q08","domain":"BOOKING","expected_semantic_view":"DW.REVENUE.BOOKING"}'),
    -- Q09 | BOOKING | DW.REVENUE.BOOKING
    ('Which 10 US states had the highest bookings in fiscal year 2025/2026?',
     '{"ground_truth_output":"Expected results: TX - 5342877.77; NC - 2352713.31; SC - 1572026.15; FL - 1247889.44; AZ - 688833.67; NY - 579317.87; AL - 462777.08; NJ - 418678.37; CA - 291556.64; GA - 256767.14. Evaluation requirements: Top ten states, booking flow for full fiscal year. The response may use commas, currency symbols or compact notation if numerically equivalent; do not invent missing results. Financial values are in USD.","test_id":"Q09","domain":"BOOKING","expected_semantic_view":"DW.REVENUE.BOOKING"}'),
    -- Q10 | BOOKING | DW.REVENUE.BOOKING
    ('Which 10 customers had the highest bookings in September 2026?',
     '{"ground_truth_output":"Expected results: P*********** I********** School District - 113709.96; J****** P****** School District 86 - 79904.80; U***** C**** School District - 56156.37; F****** C******* School District - 53417.86; A******** C**** School District - 44164.29; P********* Elementary District - 43632.84; P***** School District - 39385.89; S****** I********** School District - 36717.12; W***** U***** Elementary School District - 26686.23; D******* C****** School District - 24788.45. Evaluation requirements: Group by CUSTOMER_NAME and sum bookings for September. The response may use commas, currency symbols or compact notation if numerically equivalent; do not invent missing results. Financial values are in USD.","test_id":"Q10","domain":"BOOKING","expected_semantic_view":"DW.REVENUE.BOOKING"}'),
    -- Q11 | USAGE | DW.USAGE.PRODUCT_USAGE
    ('How many distinct students had used our products by September 2026 in the current school year?',
     '{"ground_truth_output":"Expected results: 782876. Evaluation requirements: COMPANY_STUDENTS; cumulative school-year-to-date through September; not monthly-only count. The response may use commas, currency symbols or compact notation if numerically equivalent; do not invent missing results. Student counts and launches are counts, not currency.","test_id":"Q11","domain":"USAGE","expected_semantic_view":"DW.USAGE.PRODUCT_USAGE"}'),
    -- Q12 | USAGE | DW.USAGE.PRODUCT_USAGE
    ('How many student launch events occurred as of September 2026 in the current school year?',
     '{"ground_truth_output":"Expected results: 11510219. Evaluation requirements: STUDENTS_LAUNCHES cumulative through September; events, not unique students. The response may use commas, currency symbols or compact notation if numerically equivalent; do not invent missing results. Student counts and launches are counts, not currency.","test_id":"Q12","domain":"USAGE","expected_semantic_view":"DW.USAGE.PRODUCT_USAGE"}'),
    -- Q13 | USAGE | DW.USAGE.PRODUCT_USAGE
    ('Which 10 US states had the most distinct students as of September 2026?',
     '{"ground_truth_output":"Expected results: TX - 378226; NC - 86152; SC - 46753; AZ - 38159; WV - 28557; CA - 26010; GA - 19224; FL - 18594; MS - 15746; AL - 14820. Evaluation requirements: STATE_STUDENTS for each US state; do not sum district figures. The response may use commas, currency symbols or compact notation if numerically equivalent; do not invent missing results. Student counts and launches are counts, not currency.","test_id":"Q13","domain":"USAGE","expected_semantic_view":"DW.USAGE.PRODUCT_USAGE"}'),
    -- Q14 | USAGE | DW.USAGE.PRODUCT_USAGE
    ('Which 10 districts had the most distinct students as of September 2026?',
     '{"ground_truth_output":"Expected results: U***** I********** School District - 22527; P******** J********* I********** School District - 21147; F******* U******* School District - 17280; H****** I********** School District - 15061; A***** C****** School District - 14944; E******* C*********** I********** School District - 14037; K*** I********** School District - 13541; C****** C******* I********** School District - 13140; C****** I********** School District - 12355; C********* C***** Schools - 12139. Evaluation requirements: DISTRICT_STUDENTS grouped by unique district ID and name. The response may use commas, currency symbols or compact notation if numerically equivalent; do not invent missing results. Student counts and launches are counts, not currency.","test_id":"Q14","domain":"USAGE","expected_semantic_view":"DW.USAGE.PRODUCT_USAGE"}'),
    -- Q15 | USAGE | DW.USAGE.PRODUCT_USAGE
    ('How many distinct students had we reached by June 2026 (school year 2025/2026)?',
     '{"ground_truth_output":"Expected results: 1674685. Evaluation requirements: COMPANY_STUDENTS; June 2026 cumulative snapshot; no sum of monthly snapshots. The response may use commas, currency symbols or compact notation if numerically equivalent; do not invent missing results. Student counts and launches are counts, not currency.","test_id":"Q15","domain":"USAGE","expected_semantic_view":"DW.USAGE.PRODUCT_USAGE"}');

-- Validate count, ground-truth JSON and source routing labels.
SELECT
    COUNT(*) AS EVALUATION_QUESTION_COUNT,
    COUNT_IF(GROUND_TRUTH:ground_truth_output IS NULL) AS MISSING_EXPECTED_ANSWERS
FROM DW.SERVICE.BUSINESS_AGENT_EVAL_SOURCE;

SELECT
    GROUND_TRUTH:test_id::VARCHAR AS TEST_ID,
    GROUND_TRUTH:expected_semantic_view::VARCHAR AS EXPECTED_VIEW,
    INPUT_QUERY,
    GROUND_TRUTH:ground_truth_output::VARCHAR AS EXPECTED_ANSWER
FROM DW.SERVICE.BUSINESS_AGENT_EVAL_SOURCE
ORDER BY TEST_ID;

-- Optional: create a Snowflake Dataset for the agent Evaluations tab.
-- Requires CREATE DATASET privilege in DW.SERVICE.
-- IMPORTANT: the SQL mapping key is 'expected_tools' for the VARIANT column,
-- even when using Answer Correctness. This is Snowflake's documented syntax.
-- If a dataset with this name already exists, use a new dataset name.

CALL SYSTEM$CREATE_EVALUATION_DATASET(
    'Cortex Agent',
    'DW.SERVICE.BUSINESS_AGENT_EVAL_SOURCE',
    'DW.SERVICE.BUSINESS_AGENT_EVAL_V1',
    OBJECT_CONSTRUCT(
        'query_text', 'INPUT_QUERY',
        'expected_tools', 'GROUND_TRUTH'
    )
);

SHOW DATASETS IN SCHEMA DW.SERVICE;
