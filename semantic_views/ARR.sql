
CREATE OR REPLACE SEMANTIC VIEW DW.REVENUE.ARR

-- =========================================================
-- 1. LOGICAL TABLES
-- =========================================================
TABLES (
    DW.REVENUE.VW_FACT_ARR
        WITH SYNONYMS (
            'ARR facts',
            'monthly ARR records',
            'recurring revenue snapshots'
        )
        COMMENT = 'Monthly Annual Recurring Revenue (ARR) fact records by account, reporting month, ARR_TYPE, and RECORD_TYPE. The source contains three ARR types: Preliminary, True, and Backdated. Each is reported as a separate semi-additive snapshot metric. The default ARR metric is exactly Preliminary ARR, not the sum of the three types. Values can be summed across compatible nonoverlapping accounts or organizational groups at one snapshot but not across months. All three types share the same monthly reporting periods. The source must contain the intended nonduplicated records for each type; the semantic view does not independently reconstruct balances from record movements.',

    DW.COMMON.DIM_ACCOUNT
        PRIMARY KEY (ACCOUNT_ID)
        WITH SYNONYMS (
            'customers',
            'districts',
            'customer accounts',
            'organizations',
            'account master'
        )
        COMMENT = 'Flattened organizational hierarchy with three reporting levels: Customer, District, and Account. Each row represents one ACCOUNT_ID and contains NAME, DISTRICT_NAME, and CUSTOMER_NAME. These values may be identical when the account itself represents a district or customer. Multiple accounts may belong to the same district, and multiple districts may belong to the same customer. Use CUSTOMER_NAME for customer-level aggregation, DISTRICT_NAME for district-level aggregation, and NAME for individual account-level reporting.',

    DW.COMMON.DIM_MONTH
        PRIMARY KEY (MON_LASTDAY)
        WITH SYNONYMS (
            'calendar table',
            'fiscal calendar',
            'month dimension'
        )
        COMMENT = 'Calendar and fiscal reporting dimension with one row per month-end date. The fiscal year begins July 1 and ends June 30. Fiscal month 1 represents July, fiscal month 2 represents August, and fiscal month 12 represents June. Fiscal years are labeled with both calendar years, for example 2024/2025 covers July 2024 through June 2025. Fiscal month 0 exists in the source and requires business clarification.'
)

-- =========================================================
-- 2. RELATIONSHIPS
-- =========================================================
RELATIONSHIPS (
    ARR_TO_ACCOUNT AS
        VW_FACT_ARR (ACCOUNT_ID)
        REFERENCES DIM_ACCOUNT (ACCOUNT_ID),

    ARR_TO_MONTH AS
        VW_FACT_ARR (MON_LASTDAY)
        REFERENCES DIM_MONTH (MON_LASTDAY)
)

-- =========================================================
-- 3. FACTS
-- =========================================================
FACTS (
    VW_FACT_ARR.ARR_AMOUNT
        AS ARR_AMOUNT
        WITH SYNONYMS (
            'ARR fact amount',
            'annual recurring revenue amount',
            'recurring revenue contribution'
        )
        COMMENT = 'Numeric ARR_AMOUNT from an individual monthly ARR fact record. This fact is used in three conditional semi-additive metrics, filtered by source ARR_TYPE: Preliminary, True, and Backdated. ARR is defined as Preliminary ARR by default. The three type balances are alternatives or separate views of ARR and must not be added together. Preserve signed source amounts. Never sum monthly ARR snapshots across time.'
        SAMPLE_VALUES (
            '3594.5400000000',
            '4035.7200000000',
            '314.4900000000'
        )
)

-- =========================================================
-- 4. DIMENSIONS
-- =========================================================
DIMENSIONS (

    -- ARR_TYPE is intentionally not a reporting dimension: use the three
    -- separate semi-additive metrics Preliminary, True, or Backdated ARR.



    -- Account identifier
    DIM_ACCOUNT.ACCOUNT_ID AS ACCOUNT_ID
        WITH SYNONYMS (
            'account identifier',
            'organization ID'
        )
        COMMENT = 'Unique identifier of the account joined to the ARR fact. Use ACCOUNT_ID when identifying or grouping individual accounts. The identifier is not itself a count or metric.'
        SAMPLE_VALUES (
            '0014100000v3N4wAAE',
            '0014100000wXBowAAG',
            '05081ca7-d9cb-4b2b-b538-16c0bcd87c62'
        ),

    -- Account display name
    DIM_ACCOUNT.NAME AS NAME
    WITH SYNONYMS = (
        'account name',
        'organization display name'
    )
    COMMENT = 'Individual account or organization name. An account may represent a school, district, or customer. This is the lowest reporting level in the flattened organizational hierarchy. Use NAME for account-level reporting, not for customer or district rollups.'
    WITH CORTEX SEARCH SERVICE
        DW.SERVICE.ACCOUNT_NAME_SEARCH,        

    -- District display name
    DIM_ACCOUNT.DISTRICT_NAME AS DISTRICT_NAME
        WITH SYNONYMS (
            'district',
            'district name',
            'district organization'
        )
        COMMENT = 'District-level organization name. Multiple accounts may belong to the same district. DISTRICT_NAME may equal NAME when the account itself represents the district. Use DISTRICT_NAME to aggregate ARR across all accounts belonging to a district for a compatible snapshot.'
       WITH CORTEX SEARCH SERVICE
        DW.SERVICE.DISTRICT_NAME_SEARCH,

    -- Customer display name
    DIM_ACCOUNT.CUSTOMER_NAME AS CUSTOMER_NAME
        WITH SYNONYMS (
            'customer name',
            'customer organization'
        )
        COMMENT = 'Customer-level organization name. A customer may contain multiple districts and accounts. CUSTOMER_NAME may equal DISTRICT_NAME or NAME when the customer and account represent the same organization. Use CUSTOMER_NAME to aggregate ARR across associated accounts and districts for a compatible snapshot.'
    WITH CORTEX SEARCH SERVICE
        DW.SERVICE.CUSTOMER_NAME_SEARCH,
        
    -- Account ownership
    DIM_ACCOUNT.OWNER AS OWNER
        WITH SYNONYMS (
            'account owner',
            'assigned owner',
            'sales owner',
            'CSM'
        )
        COMMENT = 'Owner assigned to an account in DIM_ACCOUNT. Use for ARR by account owner. This reflects the account master attribute, not necessarily the historical owner at the time of each ARR snapshot. Do not infer that OWNER is the contract, opportunity, or billing owner.'
        SAMPLE_VALUES (
            'A***** L*****',
            'B**** H******',
            'B****** F****',
            'D**** T***',
            'F*** A****',
            'H****** I**********',
            'K** v** P*******',
            'K**** C****',
            'K**** M********',
            'K***** W*****',
            'M**** P****',
            'M***** R*****',
            'N****** C*****',
            'P******* C******',
            'R*** D******',
            'R***** M******',
            'S**** R*******',
            'S**** T********',
            'S********* S*****',
            'T****** K*****',
            'U*** I**********',
            'U******'
        ),

    -- Geographic attribute
    DIM_ACCOUNT.STATE_CODE AS STATE_CODE
        WITH SYNONYMS (
            'state abbreviation',
            'US state code',
            'account state',
            'territory code',
            'state'
        )
        COMMENT = 'US state or territory code associated with an account. For example, CA means California, NY means New York, and TX means Texas. Unknown represents missing or unclassified geography. Use for ARR by state or territory. Geographic attribution is based on the account dimension, not necessarily on the location of contract execution or the end user.'
        SAMPLE_VALUES (
            'AK', 'AL', 'AR', 'AS', 'AZ',
            'CA', 'CO', 'CT', 'DC', 'DE',
            'FL', 'GA', 'HI', 'IA', 'ID',
            'IL', 'IN', 'KS', 'KY', 'LA',
            'MA', 'MD', 'ME', 'MI', 'MN',
            'MO', 'MP', 'MS', 'MT', 'NC',
            'ND', 'NE', 'NH', 'NJ', 'NM',
            'NV', 'NY', 'OH', 'OK', 'OR',
            'PA', 'PR', 'RI', 'SC', 'SD',
            'TN', 'TX', 'UT', 'Unknown',
            'VA', 'VI', 'VT', 'WA', 'WI',
            'WV', 'WY'
        ),

    -- Calendar month end
    DIM_MONTH.MON_LASTDAY AS MON_LASTDAY
        WITH SYNONYMS (
            'month end date',
            'last day of month',
            'snapshot month end',
            'reporting month end'
        )
        COMMENT = 'Last calendar date of the reporting month, joined to VW_FACT_ARR by MON_LASTDAY. Use for chronological reporting and date-range filters. This is the snapshot reporting month-end date and not necessarily the transaction effective date.',

    -- Calendar month YYYYMM
    DIM_MONTH.MON_YEAR AS MON_YEAR
        WITH SYNONYMS (
            'calendar month',
            'year month',
            'YYYYMM'
        )
        COMMENT = 'Calendar year and month represented numerically as YYYYMM. For example 202307 means July 2023 and 202504 means April 2025. Use this dimension for calendar-month reporting. It is not a fiscal month index.'
        SAMPLE_VALUES (
            '202307',
            '202308',
            '202504'
        ),

    -- Fiscal year
    DIM_MONTH.FISCALYEAR AS FISCALYEAR
        WITH SYNONYMS (
            'fiscal year',
            'financial year',
            'FY'
        )
        COMMENT = 'Fiscal year in YYYY/YYYY format, beginning July 1 of the first year and ending June 30 of the second year. For example 2024/2025 covers July 2024 through June 2025. For annual ARR, report the latest available monthly snapshot within each fiscal year rather than the sum of monthly ARR. When displaying months within a fiscal year, order by FISCALYEAR_MON.'
        SAMPLE_VALUES (
            '2015/2016',
            '2016/2017',
            '2017/2018',
            '2018/2019',
            '2019/2020',
            '2020/2021',
            '2021/2022',
            '2022/2023',
            '2023/2024',
            '2024/2025',
            '2025/2026'
        ),

    -- Fiscal month
    DIM_MONTH.FISCALYEAR_MON AS FISCALYEAR_MON
        WITH SYNONYMS (
            'fiscal month',
            'fiscal month number',
            'month within fiscal year'
        )
        COMMENT = 'Fiscal month in the July-June fiscal calendar: 1=July, 2=August, 3=September, 4=October, 5=November, 6=December, 7=January, 8=February, 9=March, 10=April, 11=May, 12=June, 0=Unknown. Fiscal month 0 also occurs in the source and its business meaning has not yet been confirmed. Order months within a fiscal year by FISCALYEAR_MON ascending.'
        SAMPLE_VALUES (
            '0', '1', '2', '3', '4', '5', '6',
            '7', '8', '9', '10', '11', '12'
        )
)

-- =========================================================
-- 5. THREE SEMI-ADDITIVE METRICS + DEFAULT ARR METRIC
-- =========================================================
METRICS (
    -- Preliminary is the default business definition of ARR.
    VW_FACT_ARR.PRELIMINARY_ARR
        NON ADDITIVE BY (DIM_MONTH.MON_LASTDAY ASC)
        AS SUM(
            CASE
                WHEN VW_FACT_ARR.ARR_TYPE = 'Preliminary'
                THEN VW_FACT_ARR.ARR_AMOUNT
                ELSE 0
            END
        )
        WITH SYNONYMS (
            'preliminary annual recurring revenue',
            'preliminary recurring revenue',
            'preliminary ARR balance'
        )
        COMMENT = 'Semi-additive Preliminary Annual Recurring Revenue. Includes only source records where ARR_TYPE = Preliminary. Calculated using SUM(ARR_AMOUNT) for those records at the latest available reporting month of the result group. This is the default ARR business measure. Do not add Preliminary, True, and Backdated together; the three are separate ARR types.',

    VW_FACT_ARR.TRUE_ARR
        NON ADDITIVE BY (DIM_MONTH.MON_LASTDAY ASC)
        AS SUM(
            CASE
                WHEN VW_FACT_ARR.ARR_TYPE = 'True'
                THEN VW_FACT_ARR.ARR_AMOUNT
                ELSE 0
            END
        )
        WITH SYNONYMS (
            'true annual recurring revenue',
            'true recurring revenue',
            'true ARR balance'
        )
        COMMENT = 'Semi-additive True Annual Recurring Revenue. Includes only source records where ARR_TYPE = True. Uses the latest monthly snapshot within the requested period. Choose this metric only when the question explicitly requests True ARR or compares ARR types. This is not the default ARR metric.',

    VW_FACT_ARR.BACKDATED_ARR
        NON ADDITIVE BY (DIM_MONTH.MON_LASTDAY ASC)
        AS SUM(
            CASE
                WHEN VW_FACT_ARR.ARR_TYPE = 'Backdated'
                THEN VW_FACT_ARR.ARR_AMOUNT
                ELSE 0
            END
        )
        WITH SYNONYMS (
            'backdated annual recurring revenue',
            'backdated recurring revenue',
            'backdated ARR balance'
        )
        COMMENT = 'Semi-additive Backdated Annual Recurring Revenue. Includes only source records where ARR_TYPE = Backdated. Uses the latest monthly snapshot within the requested period. Choose this metric only when the question explicitly requests Backdated ARR or compares ARR types. This is not the default ARR metric.',

    -- View-level derived metric; intentionally unqualified, not VW_FACT_ARR.ARR.
    -- Inherits the semi-additive behavior of PRELIMINARY_ARR.
    ARR AS VW_FACT_ARR.PRELIMINARY_ARR
        WITH SYNONYMS (
            'annual recurring revenue',
            'total ARR',
            'ARR balance',
            'recurring revenue balance',
            'default ARR',
            'ending ARR'
        )
        COMMENT = 'DEFAULT ARR METRIC. ARR is exactly PRELIMINARY_ARR and therefore includes only ARR_TYPE = Preliminary. This is a view-level derived metric referencing the semi-additive Preliminary ARR metric. Whenever a question simply asks for ARR, annual recurring revenue, total ARR, ending ARR, or ARR by a dimension without naming an ARR type, use ARR. Use TRUE_ARR or BACKDATED_ARR only on explicit request, and never add the three types together.'
)

-- =========================================================
-- 6. SEMANTIC VIEW DESCRIPTION
-- =========================================================
COMMENT = 'Monthly Account Annual Recurring Revenue semantic view for reporting and Cortex Analyst. Provides three separate semi-additive monthly snapshot metrics: PRELIMINARY_ARR for Preliminary records, TRUE_ARR for True records, and BACKDATED_ARR for Backdated records. The default metric ARR is exactly PRELIMINARY_ARR. If a user asks simply for ARR, total ARR, or annual recurring revenue without specifying a type, use ARR (Preliminary). Show True or Backdated only when explicitly requested, or show all three when comparison is requested. Never sum the three ARR types together. All ARR types share the same month periods. The view also provides calendar reporting, a July-June fiscal calendar, account ownership and state geography, RECORD_TYPE classification, and the flattened Customer -> District -> Account reporting hierarchy. ARR is a semi-additive month-end balance, not additive bookings: fiscal-year and period queries use the latest available month, never a sum of monthly balances.'

-- =========================================================
-- 7. CORTEX ANALYST SQL GENERATION INSTRUCTIONS
-- =========================================================
AI_SQL_GENERATION '
DEFAULT ARR TYPE -- MANDATORY:
When the user asks for ARR, total ARR, annual recurring revenue, ending ARR, ARR balance, or ARR by any dimension and does not name a type, ALWAYS use the derived metric ARR. ARR is exactly VW_FACT_ARR.PRELIMINARY_ARR (ARR_TYPE = Preliminary). Do not ask which type if the question does not specify one; Preliminary is the business default.

THREE AVAILABLE TYPES:
1. VW_FACT_ARR.PRELIMINARY_ARR = records of ARR_TYPE Preliminary.
2. VW_FACT_ARR.TRUE_ARR = records of ARR_TYPE True.
3. VW_FACT_ARR.BACKDATED_ARR = records of ARR_TYPE Backdated.
ARR is a fourth semantic metric name, but not a fourth source type: ARR aliases Preliminary ARR.
For explicitly requested Preliminary ARR, use VW_FACT_ARR.PRELIMINARY_ARR or the equivalent ARR metric.
For explicitly requested True ARR, use VW_FACT_ARR.TRUE_ARR.
For explicitly requested Backdated ARR, use VW_FACT_ARR.BACKDATED_ARR.
If the user requests a comparison of ARR types, select all three metrics together. You may also include ARR to make the default alias visible. NEVER add the three types together and NEVER define an all-types total.
ARR_TYPE is intentionally not exposed as a dimension: use the three type-specific metrics instead of grouping by type or adding raw filters.
All three source types cover the same reporting months. When comparing types, use the same requested reporting month, fiscal period, and other dimensions for each metric.

SEMI-ADDITIVE SNAPSHOT RULES:
ARR, PRELIMINARY_ARR, TRUE_ARR, and BACKDATED_ARR are semi-additive recurring revenue snapshot balances. NEVER sum monthly ARR snapshots across months or fiscal years.
NON ADDITIVE BY (MON_LASTDAY ASC) uses the latest available reporting month within the requested result period. Use semantic metrics, not manual SUM across historical monthly ARR.
For calendar-month reporting, use DIM_MONTH.MON_YEAR or DIM_MONTH.MON_LASTDAY. For period-end balances, use the latest available month within the period.
For fiscal-year ARR, group by DIM_MONTH.FISCALYEAR and use the requested metric; each fiscal year returns its latest available monthly snapshot, NOT the sum of monthly balances.
For monthly ARR within a fiscal year, group by DIM_MONTH.FISCALYEAR, DIM_MONTH.FISCALYEAR_MON, and DIM_MONTH.MON_YEAR. Display in ascending fiscal month order.
The fiscal year starts July 1 and ends June 30. Fiscal month 1 is July and fiscal month 12 is June.
Fiscal month 0 represents an unknown month in source data and is not a regular thirteenth fiscal month.
If a user explicitly requests ARR as of June 30, use June month data; do not label the latest earlier month as June 30 ARR.
For reporting groups such as customer, district, account, state, or owner, an explicitly specified common month is preferred for apples-to-apples comparisons.
When filtering to a specific month, put the month dimension condition inside SEMANTIC_VIEW, before the metric is calculated.

DIMENSIONS AND BUSINESS CONTEXT:
Use DIM_ACCOUNT.STATE_CODE for state and territory reporting. Translate full state names to stored codes, e.g. California = CA, New York = NY, Texas = TX.
Use VW_FACT_ARR.RECORD_TYPE for record classifications such as ARR-Starting, ARR-MonthlyAdded, and ARR-MonthlyReduced. Interpret these as source classification values, NOT separate ARR type metrics or independently defined new ARR, churn, or expansion measures.
Do not invent Net Revenue Retention, Gross Revenue Retention, churn rates, or booking metrics from ARR balances.
For ARR rankings, use ARR descending unless the question explicitly requests True or Backdated ARR, in which case rank by the requested type metric.
Use DIM_ACCOUNT.ACCOUNT_ID to identify individual accounts and DIM_ACCOUNT.NAME for display.
DIM_ACCOUNT.OWNER is the account master owner, not necessarily the historical owner at the snapshot month.
For SEMANTIC_VIEW SQL, qualify table-level metric names inside the function (e.g. VW_FACT_ARR.TRUE_ARR); reference default ARR as ARR without a table prefix. Use the returned metric and dimension names in the outer SELECT and ORDER BY.

ORGANIZATIONAL HIERARCHY:
DIM_ACCOUNT is a flattened Customer -> District -> Account hierarchy, not three separate tables.
NAME is an individual account, DISTRICT_NAME is the associated district, and CUSTOMER_NAME is the associated customer.
The values may be equal when an organization occupies multiple levels.
For ARR by customer, group by DIM_ACCOUNT.CUSTOMER_NAME.
For ARR by district, group by DIM_ACCOUNT.DISTRICT_NAME.
For ARR by account, group by DIM_ACCOUNT.ACCOUNT_ID and DIM_ACCOUNT.NAME.
For a specific customer, filter on DIM_ACCOUNT.CUSTOMER_NAME.
For a specific district, filter on DIM_ACCOUNT.DISTRICT_NAME.
For a specific account, filter on DIM_ACCOUNT.ACCOUNT_ID or DIM_ACCOUNT.NAME.
For customer-to-district drill-down, group by CUSTOMER_NAME and DISTRICT_NAME.
For district-to-account drill-down, group by DISTRICT_NAME, ACCOUNT_ID, and NAME.
For compatible month-end snapshots, ARR of a customer or district is the rollup of the underlying nonoverlapping accounts. Never add together customer, district, and account subtotals since they overlap, and never add ARR across different months.
'

-- =========================================================
-- 8. CORTEX ANALYST QUESTION CATEGORIZATION
-- =========================================================
AI_QUESTION_CATEGORIZATION '
This semantic view answers questions about monthly and fiscal ARR snapshots, Preliminary ARR, True ARR, Backdated ARR, account/customer/district hierarchy, geographic state, owner, record type, and month-end revenue balance comparisons.

DEFAULT TYPE RULE: A question that asks for ARR, total ARR, annual recurring revenue, ending ARR, ARR balance, or ARR by state, month, fiscal year, customer, district, account, or owner WITHOUT naming one of the three types is CLEAR, not ambiguous. Answer using ARR, which by business definition equals Preliminary ARR.

Explicit True ARR questions use TRUE_ARR; explicit Backdated ARR questions use BACKDATED_ARR; explicit Preliminary ARR questions use PRELIMINARY_ARR (or ARR). Requests to compare types use the three separate metrics. There is no fourth raw ARR type, and the three types must not be added.

ARR is a semi-additive snapshot metric. If a user requests a sum of ARR over multiple reporting months, respond with month-by-month snapshots or a latest end-of-period snapshot as appropriate rather than adding monthly balances.

The view supports fiscal-year, fiscal-month, calendar-month, month-end, and organizational rollup reporting. Interpret by customer as CUSTOMER_NAME, by district as DISTRICT_NAME, and by account as ACCOUNT_ID/NAME.
If the requested organizational level is genuinely ambiguous, ask for clarification. Do not ask which ARR type is meant when none is specified; use the default Preliminary ARR.

RECORD_TYPE is distinct from ARR_TYPE. Do not interpret ARR-Starting, ARR-MonthlyAdded, and ARR-MonthlyReduced as the three types. Do not invent NRR, GRR, churn rate, or booking flow metrics; route these concepts to other semantic models if available.
'

-- =========================================================
-- 9. CORTEX ANALYST EMBEDDED EXAMPLE QUERIES
-- =========================================================
AI_VERIFIED_QUERIES (

    arr_by_fiscal_year AS (
        QUESTION 'What was ARR by fiscal year?'
        VERIFIED_AT 1794590880
        ONBOARDING_QUESTION TRUE
        VERIFIED_BY '(STEWARD = KaterynaD)'
        SQL '
            SELECT FISCALYEAR, ARR
            FROM SEMANTIC_VIEW(
                DW.REVENUE.ARR
                DIMENSIONS DIM_MONTH.FISCALYEAR
                METRICS ARR
            )
            ORDER BY FISCALYEAR DESC
        '
    ),

    monthly_arr AS (
        QUESTION 'Show monthly ARR in fiscal year order.'
        VERIFIED_AT 1794590880
        ONBOARDING_QUESTION TRUE
        VERIFIED_BY '(STEWARD = KaterynaD)'
        SQL '
            SELECT FISCALYEAR, FISCALYEAR_MON, MON_YEAR, ARR
            FROM SEMANTIC_VIEW(
                DW.REVENUE.ARR
                DIMENSIONS
                    DIM_MONTH.FISCALYEAR,
                    DIM_MONTH.FISCALYEAR_MON,
                    DIM_MONTH.MON_YEAR
                METRICS ARR
            )
            ORDER BY FISCALYEAR DESC, FISCALYEAR_MON ASC
        '
    ),

    arr_by_state AS (
        QUESTION 'What are the top 10 states by ARR?'
        VERIFIED_AT 1794590880
        ONBOARDING_QUESTION TRUE
        VERIFIED_BY '(STEWARD = KaterynaD)'
        SQL '
            SELECT STATE_CODE, ARR
            FROM SEMANTIC_VIEW(
                DW.REVENUE.ARR
                DIMENSIONS DIM_ACCOUNT.STATE_CODE
                METRICS ARR
            )
            ORDER BY ARR DESC
            LIMIT 10
        '
    ),

    arr_by_customer AS (
        QUESTION 'Show ARR by customer.'
        VERIFIED_AT 1794590880
        ONBOARDING_QUESTION FALSE
        VERIFIED_BY '(STEWARD = KaterynaD)'
        SQL '
            SELECT CUSTOMER_NAME, ARR
            FROM SEMANTIC_VIEW(
                DW.REVENUE.ARR
                DIMENSIONS DIM_ACCOUNT.CUSTOMER_NAME
                METRICS ARR
            )
            ORDER BY ARR DESC
        '
    ),

    district_drill_down AS (
        QUESTION 'Show ARR by customer and district.'
        VERIFIED_AT 1794590880
        ONBOARDING_QUESTION FALSE
        VERIFIED_BY '(STEWARD = KaterynaD)'
        SQL '
            SELECT CUSTOMER_NAME, DISTRICT_NAME, ARR
            FROM SEMANTIC_VIEW(
                DW.REVENUE.ARR
                DIMENSIONS
                    DIM_ACCOUNT.CUSTOMER_NAME,
                    DIM_ACCOUNT.DISTRICT_NAME
                METRICS ARR
            )
            ORDER BY CUSTOMER_NAME, ARR DESC
        '
    ),

    california_arr_by_month AS (
        QUESTION 'Show California ARR for each month in chronological order.'
        VERIFIED_AT 1794590880
        ONBOARDING_QUESTION FALSE
        VERIFIED_BY '(STEWARD = KaterynaD)'
        SQL '
            SELECT MON_YEAR, ARR
            FROM SEMANTIC_VIEW(
                DW.REVENUE.ARR
                DIMENSIONS DIM_MONTH.MON_YEAR
                METRICS ARR
                WHERE DIM_ACCOUNT.STATE_CODE = ''CA''
            )
            ORDER BY MON_YEAR ASC
        '
    ),

    arr_by_account AS (
        QUESTION 'What are the top 10 accounts by ARR?'
        VERIFIED_AT 1794590880
        ONBOARDING_QUESTION FALSE
        VERIFIED_BY '(STEWARD = KaterynaD)'
        SQL '
            SELECT ACCOUNT_ID, NAME, ARR
            FROM SEMANTIC_VIEW(
                DW.REVENUE.ARR
                DIMENSIONS
                    DIM_ACCOUNT.ACCOUNT_ID,
                    DIM_ACCOUNT.NAME
                METRICS ARR
            )
            ORDER BY ARR DESC
            LIMIT 10
        '
    ),


    compare_arr_types AS (
        QUESTION 'Compare Preliminary ARR, True ARR, and Backdated ARR.'
        VERIFIED_AT 1794590880
        ONBOARDING_QUESTION TRUE
        VERIFIED_BY '(STEWARD = KaterynaD)'
        SQL '
            SELECT PRELIMINARY_ARR, TRUE_ARR, BACKDATED_ARR
            FROM SEMANTIC_VIEW(
                DW.REVENUE.ARR
                METRICS
                    VW_FACT_ARR.PRELIMINARY_ARR,
                    VW_FACT_ARR.TRUE_ARR,
                    VW_FACT_ARR.BACKDATED_ARR
            )
        '
    ),

    monthly_comparison_arr_types AS (
        QUESTION 'Compare all three ARR types by month.'
        VERIFIED_AT 1794590880
        ONBOARDING_QUESTION FALSE
        VERIFIED_BY '(STEWARD = KaterynaD)'
        SQL '
            SELECT
                MON_YEAR,
                PRELIMINARY_ARR,
                TRUE_ARR,
                BACKDATED_ARR
            FROM SEMANTIC_VIEW(
                DW.REVENUE.ARR
                DIMENSIONS DIM_MONTH.MON_YEAR
                METRICS
                    VW_FACT_ARR.PRELIMINARY_ARR,
                    VW_FACT_ARR.TRUE_ARR,
                    VW_FACT_ARR.BACKDATED_ARR
            )
            ORDER BY MON_YEAR ASC
        '
    ),

    true_arr_by_fiscal_year AS (
        QUESTION 'What was True ARR by fiscal year?'
        VERIFIED_AT 1794590880
        ONBOARDING_QUESTION FALSE
        VERIFIED_BY '(STEWARD = KaterynaD)'
        SQL '
            SELECT FISCALYEAR, TRUE_ARR
            FROM SEMANTIC_VIEW(
                DW.REVENUE.ARR
                DIMENSIONS DIM_MONTH.FISCALYEAR
                METRICS VW_FACT_ARR.TRUE_ARR
            )
            ORDER BY FISCALYEAR DESC
        '
    ),

    backdated_arr_by_state AS (
        QUESTION 'What are the top 10 states by Backdated ARR?'
        VERIFIED_AT 1794590880
        ONBOARDING_QUESTION FALSE
        VERIFIED_BY '(STEWARD = KaterynaD)'
        SQL '
            SELECT STATE_CODE, BACKDATED_ARR
            FROM SEMANTIC_VIEW(
                DW.REVENUE.ARR
                DIMENSIONS DIM_ACCOUNT.STATE_CODE
                METRICS VW_FACT_ARR.BACKDATED_ARR
            )
            ORDER BY BACKDATED_ARR DESC
            LIMIT 10
        '
    ),

    default_arr_equals_preliminary AS (
        QUESTION 'Show that the default ARR metric equals Preliminary ARR.'
        VERIFIED_AT 1794590880
        ONBOARDING_QUESTION FALSE
        VERIFIED_BY '(STEWARD = KaterynaD)'
        SQL '
            SELECT
                ARR,
                PRELIMINARY_ARR,
                TRUE_ARR,
                BACKDATED_ARR
            FROM SEMANTIC_VIEW(
                DW.REVENUE.ARR
                METRICS
                    ARR,
                    VW_FACT_ARR.PRELIMINARY_ARR,
                    VW_FACT_ARR.TRUE_ARR,
                    VW_FACT_ARR.BACKDATED_ARR
            )
        '
    )

);


DESCRIBE SEMANTIC VIEW DW.REVENUE.ARR;

SELECT GET_DDL(
    'SEMANTIC_VIEW',
    'DW.REVENUE.ARR'
);


-- Semantic ARR metrics vs original source
-- Compare all metrics at the latest available monthly snapshot.

WITH latest_month AS (
    SELECT MAX(MON_LASTDAY) AS MON_LASTDAY
    FROM DW.REVENUE.VW_FACT_ARR
),

source_total AS (
    SELECT
        f.MON_LASTDAY,
        SUM(CASE WHEN ARR_TYPE = 'Preliminary'
                 THEN ARR_AMOUNT ELSE 0 END) AS PRELIMINARY_ARR,
        SUM(CASE WHEN ARR_TYPE = 'True'
                 THEN ARR_AMOUNT ELSE 0 END) AS TRUE_ARR,
        SUM(CASE WHEN ARR_TYPE = 'Backdated'
                 THEN ARR_AMOUNT ELSE 0 END) AS BACKDATED_ARR
    FROM DW.REVENUE.VW_FACT_ARR f
    JOIN latest_month m
        ON f.MON_LASTDAY = m.MON_LASTDAY
    GROUP BY f.MON_LASTDAY
),

semantic_total AS (
    SELECT
        MON_LASTDAY,
        ARR,
        PRELIMINARY_ARR,
        TRUE_ARR,
        BACKDATED_ARR
    FROM SEMANTIC_VIEW(
        DW.REVENUE.ARR
        DIMENSIONS DIM_MONTH.MON_LASTDAY
        METRICS
            ARR,
            VW_FACT_ARR.PRELIMINARY_ARR,
            VW_FACT_ARR.TRUE_ARR,
            VW_FACT_ARR.BACKDATED_ARR
    )
),

comparison AS (
    SELECT
        s.MON_LASTDAY,
        s.PRELIMINARY_ARR AS SOURCE_PRELIMINARY,
        s.TRUE_ARR AS SOURCE_TRUE,
        s.BACKDATED_ARR AS SOURCE_BACKDATED,
        v.ARR AS SEMANTIC_ARR,
        v.PRELIMINARY_ARR AS SEMANTIC_PRELIMINARY,
        v.TRUE_ARR AS SEMANTIC_TRUE,
        v.BACKDATED_ARR AS SEMANTIC_BACKDATED
    FROM source_total s
    JOIN semantic_total v
        ON s.MON_LASTDAY = v.MON_LASTDAY
)

SELECT
    MON_LASTDAY,
    'ARR (default)' AS METRIC,
    SOURCE_PRELIMINARY AS SOURCE_TOTAL,
    SEMANTIC_ARR AS SEMANTIC_TOTAL,
    SOURCE_PRELIMINARY - SEMANTIC_ARR AS DIFFERENCE
FROM comparison

UNION ALL

SELECT
    MON_LASTDAY,
    'PRELIMINARY_ARR',
    SOURCE_PRELIMINARY,
    SEMANTIC_PRELIMINARY,
    SOURCE_PRELIMINARY - SEMANTIC_PRELIMINARY
FROM comparison

UNION ALL

SELECT
    MON_LASTDAY,
    'TRUE_ARR',
    SOURCE_TRUE,
    SEMANTIC_TRUE,
    SOURCE_TRUE - SEMANTIC_TRUE
FROM comparison

UNION ALL

SELECT
    MON_LASTDAY,
    'BACKDATED_ARR',
    SOURCE_BACKDATED,
    SEMANTIC_BACKDATED,
    SOURCE_BACKDATED - SEMANTIC_BACKDATED
FROM comparison

ORDER BY METRIC;

SELECT *
FROM SEMANTIC_VIEW(
    DW.REVENUE.ARR

    METRICS
        ARR

    DIMENSIONS
        DIM_ACCOUNT.NAME

    WHERE DIM_MONTH.MON_YEAR = 202609
      AND DIM_ACCOUNT.ACCOUNT_ID =
          '61109bbc-09eb-43d4-802c-c50a64c98129'

);

