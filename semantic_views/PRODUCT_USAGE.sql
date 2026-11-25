CREATE OR REPLACE SEMANTIC VIEW DW.USAGE.PRODUCT_USAGE

-- ============================================================
-- 1. LOGICAL TABLE
-- ============================================================
TABLES (
    u AS DW.USAGE.VW_FACT_PRODUCT_USAGE
        WITH SYNONYMS (
            'monthly product usage snapshots',
            'student product usage',
            'student activity by school',
            'school-year usage facts'
        )
        COMMENT = 'One logical source for cumulative school-year-to-date product usage by reporting month, school, district, state, country, grade level, and product category. Each snapshot has already-computed distinct student counts at five geographic levels: school, district, state, country, and company for each product category and grade level.  School launch counts are cumulative school-year-to-date events at school grain. The table also includes precomputed (All) values for grade and product. Multiple grade bands and product categories may overlap. A student may attend more than one school or district and counted only once at each level.'
)

-- ============================================================
-- 2. DIMENSIONS
-- ============================================================
DIMENSIONS (
    u.MON_LASTDAY AS u.MON_LASTDAY
        WITH SYNONYMS ('snapshot date', 'month end date', 'as of date')
        COMMENT = 'Actual calendar month-end date of a cumulative school-year-to-date snapshot. NON ADDITIVE BY (MON_LASTDAY ASC) selects the latest available monthly snapshot within the selected period. Do not sum cumulative snapshots across months.',

    u.MON_YEAR AS u.MON_YEAR
        WITH SYNONYMS ('reporting month', 'calendar year month', 'YYYYMM')
        COMMENT = 'Calendar reporting month as numeric YYYYMM, for example 202609 is September 2026. This is NOT a school-year number. Use MON_YEAR for an explicitly specified calendar month; never combine September 2026 with school year 2025/2026.'
        SAMPLE_VALUES ('202606', '202609'),

    u.SCHOOLYEAR AS u.SCHOOLYEAR
        WITH SYNONYMS ('school year', 'academic year', 'SY')
        COMMENT = 'July-through-June academic reporting year. For example 2025/2026 means July 2025 through June 2026. When asked for a school-year ending balance, filter by SCHOOLYEAR and let the non-additive snapshot logic select the latest available month within that school year.'
        SAMPLE_VALUES ('2025/2026', '2026/2027'),

    u.SCHOOLYEAR_MON AS u.SCHOOLYEAR_MON
        WITH SYNONYMS ('school year month', 'academic month number', 'month in school year')
        COMMENT = 'School-year month number: 1=July, 2=August, 3=September, 4=October, 5=November, 6=December, 7=January, 8=February, 9=March, 10=April, 11=May, 12=June. Use ascending order to display monthly snapshots within a school year; 12 is June, the school-year ending month.'
        SAMPLE_VALUES ('1','2','3','4','5','6','7','8','9','10','11','12'),

    u.COUNTRY AS u.COUNTRY
        WITH SYNONYMS ('country', 'nation', 'country name')
        COMMENT = 'Country of the district. Country is a geographic aggregation level, not a measure. Use COUNTRY_STUDENTS, not a sum of state or district distinct-student counts, for country-level student numbers. Unknown is a legitimate stored value.'
        SAMPLE_VALUES (
            'Bahamas', 'Egypt', 'Guatemala', 'Panama',
            'Philippines', 'Saudi Arabia', 'United Arab Emirates',
            'United States of America', 'Unknown'
        ),

    u.STATE_CODE AS u.STATE_CODE
        WITH SYNONYMS ('state', 'state abbreviation', 'province code', 'US state')
        COMMENT = 'Geographic state, territory, or province code, sometimes Unknown. When a US state name is specified, translate it to the exact stored abbreviation (California=CA, Florida=FL, New York=NY, Texas=TX). Use COUNTRY together with STATE_CODE for unambiguous geographic groupings, especially Unknown. Use STATE_STUDENTS for distinct counts at this level.'
        SAMPLE_VALUES (
            'AK','AL','AR','AZ','CA','CO','CT','DC','FL','GA',
            'HI','IA','ID','IL','IN','KS','KY','LA','MA','MD',
            'ME','MI','MN','MO','MS','MT','NC','ND','NE','NH',
            'NJ','NM','NV','NY','OH','OK','OR','PA','RI','SC',
            'SD','TN','TX','UT','Unknown','VA','VI','WA','WI',
            'WV','WY'
        ),

    u.ORGANIZATION_DISTRICT_ID AS u.ORGANIZATION_DISTRICT_ID
        WITH SYNONYMS ('district ID', 'district identifier')
        COMMENT = 'Identifier of the district containing a school. Use as the grouping key when a question is about districts; name alone is not guaranteed to be unique. This is not an individual school identifier.',

    u.DISTRICT_NAME AS u.DISTRICT_NAME
        WITH SYNONYMS ('district name', 'school district')
        COMMENT = 'Display name of the associated district, obtained from DIM_ACCOUNT through the source SQL view. Pair with ORGANIZATION_DISTRICT_ID when grouping or identifying a particular district; district names need not be unique.'
        WITH CORTEX SEARCH SERVICE
        DW.SERVICE.DISTRICT_NAME_SEARCH,

    u.DISTRICT_OWNER AS u.DISTRICT_OWNER
        WITH SYNONYMS ('district owner', 'district account owner')
        COMMENT = 'Owner associated with the district account in the account dimension. This is the present account-master owner, not necessarily the historical owner at snapshot time; do not automatically substitute SCHOOL_OWNER.',

    u.ORGANIZATION_SCHOOL_ID AS u.ORGANIZATION_SCHOOL_ID
        WITH SYNONYMS ('school ID', 'school identifier', 'organization school ID')
        COMMENT = 'Identifier of the individual school, the lowest geographic reporting level and the grain of SCHOOL_CNT_STUDENTS and SCHOOL_STUDENTS_LAUNCHES. Pair with SCHOOL_NAME for display and accurate school-level grouping.',

    u.SCHOOL_NAME AS u.SCHOOL_NAME
        WITH SYNONYMS ('school name', 'organization school name')
        COMMENT = 'Display name of the individual school, looked up through the source SQL view. School names can repeat across districts; group by ORGANIZATION_SCHOOL_ID, optionally with SCHOOL_NAME.'
        WITH CORTEX SEARCH SERVICE
        DW.SERVICE.ACCOUNT_NAME_SEARCH, 

    u.SCHOOL_OWNER AS u.SCHOOL_OWNER
        WITH SYNONYMS ('school owner', 'school account owner')
        COMMENT = 'Owner associated with the school account in the account dimension. This is the current account-master attribute, not necessarily historical ownership at the snapshot month.'
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

    u.GRADE_LEVEL AS u.GRADE_LEVEL
        WITH SYNONYMS ('grade', 'grade band', 'student grade', 'grade group')
        COMMENT = 'Pre-aggregated grade category. The exact value (All), including parentheses, is the default total across grades; it is NOT the same value as All Students. Codes 01-12 are individual grades; PK and KG are pre-kindergarten and kindergarten. Elementary, Middle, High, All Students, Non Students and Unknown are additional source categories and may overlap other grade categories. Never sum the categories to calculate the all-grade total. If a grade is not specified, prefer the precomputed (All) row via GRADE_PRIORITY.'
        SAMPLE_VALUES (
            '(All)', '01', '02', '03', '04', '05', '06',
            '07', '08', '09', '10', '11', '12',
            'All Students', 'Elementary', 'High', 'KG',
            'Middle', 'Non Students', 'PK', 'Unknown'
        ),

    u.GRADE_PRIORITY AS u.GRADE_PRIORITY
        WITH SYNONYMS ('default grade priority', 'grade selection order')
        COMMENT = 'Internal non-additivity ordering: 1 for GRADE_LEVEL = (All), 0 otherwise. NON ADDITIVE BY (GRADE_PRIORITY ASC) selects the precomputed (All) grade row when grade is omitted. Do not expose as a business KPI or use it as a student-count dimension.'
        SAMPLE_VALUES ('0','1'),

    u.PRODUCT_CATEGORY AS u.PRODUCT_CATEGORY
        WITH SYNONYMS ('product', 'product line', 'learning product', 'product family')
        COMMENT = 'Pre-aggregated product-category label. Exact (All) is the default across products. Students can use multiple products, and categories can overlap; never sum separate product-category distinct-student totals to calculate overall students. For all-product questions use the precomputed (All) row via PRODUCT_PRIORITY. Preserve exact stored strings, including plus signs, ampersands, and qualifiers.'
        SAMPLE_VALUES (
            '(All)',
            'AI Literacy',
            'AI Literacy (Limited)',
            'AI Literacy Student-Driven Learning Path',
            'Assessments',
            'Common Sense Education',
            'Digital Readiness',
            'Digital Safety Foundation',
            'EasyCode',
            'EasyCode Foundations',
            'EasyCode Pillars',
            'EasyTech',
            'EasyTech & TechApps for Texas',
            'EasyTech Blended Learning Path',
            'EasyTech Florida Blended Learning Path',
            'EasyTech Florida Student-Driven Learning Path',
            'EasyTech Student-Driven Learning Path',
            'EasyTech without Common Sense Education',
            'EasyTech+',
            'Fontana Tech Quest',
            'Keyboarding & Word Processing',
            'Online Safety & Digital Citizenship',
            'Safe into Summer',
            'Tech Quest',
            'TechApps for Texas',
            'Texas Blended Learning Path',
            'Texas Essentials Blended Learning Path'
        ),

    u.PRODUCT_PRIORITY AS u.PRODUCT_PRIORITY
        WITH SYNONYMS ('default product priority', 'product selection order')
        COMMENT = 'Internal non-additivity ordering: 1 for PRODUCT_CATEGORY = (All), 0 otherwise. NON ADDITIVE BY (PRODUCT_PRIORITY ASC) chooses the precomputed all-product row when product is unspecified; 1 must be sorted last (ASC). Not a business reporting metric.'
        SAMPLE_VALUES ('0','1')
)

-- ============================================================
-- 3. METRICS: DEFINITIONS PRESERVED FROM WORKING VIEW
-- ============================================================
METRICS (
    u.SCHOOL_STUDENTS
        NON ADDITIVE BY (
            MON_LASTDAY ASC,
            GRADE_PRIORITY ASC,
            PRODUCT_PRIORITY ASC
        )
        AS MAX(u.SCHOOL_CNT_STUDENTS)
        WITH SYNONYMS ('students per school', 'distinct school students', 'school student reach')
        COMMENT = 'Pre-aggregated count of distinct students for each individual school, cumulative from school-year start through snapshot month end. MAX prevents repeated identical values from being summed; at school grain the stored count is already the correct measure. Non-additive across months, grades and products. Never sum school student counts to derive district, state, country or company distinct counts; use the dedicated metric for that level.',

    u.DISTRICT_STUDENTS
        NON ADDITIVE BY (
            MON_LASTDAY ASC,
            GRADE_PRIORITY ASC,
            PRODUCT_PRIORITY ASC
        )
        AS MAX(u.DISTRICT_CNT_STUDENTS)
        WITH SYNONYMS ('students per district', 'distinct district students', 'district student reach')
        COMMENT = 'Pre-aggregated distinct students for a district, repeated on each of its school rows. MAX uses the already-correct district value without adding repetitions. Report per ORGANIZATION_DISTRICT_ID. Do not sum this metric across districts to obtain a state or company distinct count. Uses the latest snapshot and pre-aggregated (All) grade/product defaults.',

    u.STATE_STUDENTS
        NON ADDITIVE BY (
            MON_LASTDAY ASC,
            GRADE_PRIORITY ASC,
            PRODUCT_PRIORITY ASC
        )
        AS MAX(u.STATE_CNT_STUDENTS)
        WITH SYNONYMS ('students per state', 'distinct state students', 'state student reach')
        COMMENT = 'Pre-aggregated state-level distinct students, repeated across rows for schools and districts within the state. MAX ignores repeated identical state totals at the requested state level. Group by COUNTRY and STATE_CODE. Do not sum state distinct counts to derive country or company distinct counts. Uses latest cumulative snapshot and (All) grade/product when unspecified.',

    u.COUNTRY_STUDENTS
        NON ADDITIVE BY (
            MON_LASTDAY ASC,
            GRADE_PRIORITY ASC,
            PRODUCT_PRIORITY ASC
        )
        AS MAX(u.COUNTRY_CNT_STUDENTS)
        WITH SYNONYMS ('students per country', 'distinct country students', 'country student reach')
        COMMENT = 'Pre-aggregated distinct students for a country, repeated on many lower-level rows. MAX takes the already-computed country figure. Group by COUNTRY. Do not sum country distinct counts to derive the company total. Non-additive across time, grade and product.',

    u.COMPANY_STUDENTS
        NON ADDITIVE BY (
            MON_LASTDAY ASC,
            GRADE_PRIORITY ASC,
            PRODUCT_PRIORITY ASC
        )
        AS MAX(u.COMPANY_CNT_STUDENTS)
        WITH SYNONYMS ('total students', 'company-wide students', 'all students reached', 'unique students company-wide')
        COMMENT = 'Pre-aggregated company-wide distinct student count, repeated at lower geographic levels. The correct metric for total students across the company; MAX takes the one precomputed company-wide count and does not sum school, district, state or country distinct counts. Uses latest cumulative monthly snapshot and precomputed (All) grade/product totals when unspecified. This is not an enrollment count.',

    u.STUDENTS_LAUNCHES
        NON ADDITIVE BY (
            MON_LASTDAY ASC,
            GRADE_PRIORITY ASC,
            PRODUCT_PRIORITY ASC
        )
        AS SUM(u.SCHOOL_STUDENTS_LAUNCHES)
        WITH SYNONYMS ('student launches', 'product launches', 'student activity launches', 'usage launches')
        COMMENT = 'Cumulative count of launch EVENTS from the start of the school year through the snapshot month for each school, grade and product category. SUM across nonoverlapping school rows is valid to roll up to district, state, country and company. Never sum across monthly snapshots because they are cumulative. Never sum over the precomputed (All) grade/product rows and their constituent categories: those overlap. This is an event count, NOT a count of distinct students. If grade/product is unspecified, use the corresponding (All) priority row.'
)

-- ============================================================
-- 4. VIEW-LEVEL BUSINESS DESCRIPTION
-- ============================================================
COMMENT = 'Cumulative school-year-to-date product usage semantic view for Cortex Analyst and governed reporting. Provides five separately pre-aggregated distinct-student metrics at school, district, state, country and company level, plus school-based launch-event counts additive across nonoverlapping geographic schools. The distinct-student counts are repeated at lower geographic levels and MUST NOT be summed to higher geographic levels. All six metrics are non-additive across month-end cumulative snapshots and across overlapping grade and product-category rollups. NON ADDITIVE BY MON_LASTDAY ASC selects the latest available snapshot, and priority columns favor the precomputed (All) grade and (All) product rows when these dimensions are unspecified. School year follows July-June; MON_YEAR is an independent YYYYMM calendar field. Choose the metric corresponding to the requested geographic level; use COMPANY_STUDENTS for company-wide unique students and STUDENTS_LAUNCHES for launch events.'

-- ============================================================
-- 5. CORTEX ANALYST: SQL GENERATION RULES
-- ============================================================
AI_SQL_GENERATION '
CHOOSING A GEOGRAPHIC DISTINCT-STUDENT METRIC:
For the number of students by individual school, use u.SCHOOL_STUDENTS and group by u.ORGANIZATION_SCHOOL_ID; include u.SCHOOL_NAME for display if desired.
For students by district, use u.DISTRICT_STUDENTS and group by u.ORGANIZATION_DISTRICT_ID; optionally include u.DISTRICT_NAME.
For students by state, use u.STATE_STUDENTS and group by u.COUNTRY and u.STATE_CODE.
For students by country, use u.COUNTRY_STUDENTS and group by u.COUNTRY.
For total students across the whole company, use u.COMPANY_STUDENTS without a geographic grouping.
These are distinct-student counts ALREADY PRE-AGGREGATED at each geographic level. The corresponding larger-area count is intentionally repeated on all lower-area rows. Never SUM school counts to obtain district counts, never SUM district counts to obtain state counts, never SUM state counts to obtain country counts, and never SUM country counts to obtain the company count. Do not combine or add the five distinct-student metrics. MAX in the metric definition chooses an already-calculated value from repetitions at its intended grain; it is not a geographic rollup algorithm.
If the question asks for distinct students by school, use the school metric; if by district, use the district metric, and so on. Do not use the wrong metric at a broader grouping level simply because it produces a numeric answer.

LAUNCH EVENT COUNT:
For launches, number of launches, product activity, or student launches, use u.STUDENTS_LAUNCHES. These are launch EVENTS, not distinct students. It sums school-level cumulative launch values across nonoverlapping schools for an appropriate geographic grouping. It must not sum across months, grade rollups, or product-category rollups. Never assume one launch means one unique student.

TIME: TWO DIFFERENT PERIOD CONCEPTS:
MON_YEAR is YYYYMM calendar month; 202609 means September 2026.
SCHOOLYEAR is the July-June academic year; 2025/2026 means July 2025 to June 2026. September 2026 belongs to 2026/2027, NOT 2025/2026.
SCHOOLYEAR_MON means school-year month number: 1=July, 2=August, 3=September, 4=October, 5=November, 6=December, 7=January, 8=February, 9=March, 10=April, 11=May, 12=June.
For a named calendar month, filter on u.MON_YEAR inside SEMANTIC_VIEW. Do not also filter on an unrelated SCHOOLYEAR.
For school-year-end cumulative figures, filter on u.SCHOOLYEAR and use the semantic metric without an explicit month filter; NON ADDITIVE BY (MON_LASTDAY ASC) chooses the latest AVAILABLE snapshot in that school year per result group. This is June or school-year month 12 only when month-12 data actually exists. If the user explicitly requires June, include u.SCHOOLYEAR_MON = 12 and do not silently substitute an earlier month.
For monthly trends within a school year, include u.SCHOOLYEAR, u.SCHOOLYEAR_MON and u.MON_YEAR as dimensions and order results chronologically by school year/month. Never add monthly cumulative values to obtain a school-year total.
With no time restriction, the metric selects the latest available monthly snapshot. It may be a different month in different reporting groups when some groups have no recent data; do not assume a common as-of month for every group. For an apples-to-apples comparison use an explicit common MON_YEAR.

GRADE AND PRODUCT DEFAULTS -- ESSENTIAL:
GRADE_LEVEL = (All) (with parentheses) is the pre-aggregated all-grade total. All Students is a separate, distinct source category and must not be substituted for (All).
PRODUCT_CATEGORY = (All) (with parentheses) is the pre-aggregated all-product total.
GRADE_PRIORITY is 1 for (All) and 0 for every other grade; PRODUCT_PRIORITY is 1 for (All) and 0 otherwise.
NON ADDITIVE BY (MON_LASTDAY ASC, GRADE_PRIORITY ASC, PRODUCT_PRIORITY ASC) chooses the latest date first and, within that date, prefers both (All) rollup rows when grade and product are unspecified. Do not sum grade categories or product categories to reproduce the overall value.
If the user specifies a grade, filter u.GRADE_LEVEL to the exact stored value inside SEMANTIC_VIEW and allow the product (All) priority to apply if no product was specified.
If the user specifies a product, filter u.PRODUCT_CATEGORY to the exact stored category and allow grade (All) priority to apply if no grade was specified.
If a question lists values by grade or by product, include the requested dimension. Do not include (All) in a detailed breakdown unless the user wants a separate total row. Broad grade bands, individual grade codes and All Students can overlap; likewise product categories can overlap. NEVER sum displayed category counts to calculate an overall distinct-student count.
Preserve exact category spellings, punctuation, parentheses and capitalization (e.g. EasyTech+, EasyTech without Common Sense Education, AI Literacy (Limited), (All)). Do not infer a requested category from a substring when multiple exact options exist.

GEOGRAPHY AND NAMES:
COUNTRY and STATE_CODE describe geographic levels. For US state names translate full names into stored codes: California=CA, Florida=FL, New York=NY, Texas=TX. Preserve Unknown as a valid source value.
For a named state, prefer filtering COUNTRY = United States of America and STATE_CODE = the two-letter code if US geography is intended.
Use ORGANIZATION_SCHOOL_ID and ORGANIZATION_DISTRICT_ID as unique grouping keys, not display names alone; names can repeat. SCHOOL_OWNER and DISTRICT_OWNER are separate current account attributes, not guaranteed historical ownership.
Avoid summing distinct-student counts across geographic levels even if they look nearly additive due to low overlap. Use the pre-aggregated metric for the selected level.

SQL GENERATION:
In SEMANTIC_VIEW(DW.USAGE.PRODUCT_USAGE ...), use qualified names u.METRIC and u.DIMENSION for METRICS, DIMENSIONS and WHERE clauses. In the outer SELECT/ORDER BY, use returned unqualified names.
When ranking entities, order by the requested metric descending unless specified otherwise. If the user asks for highest or most, optionally use LIMIT after ORDER BY.
Never replace these declared metrics with raw sums of *_CNT_STUDENTS columns. Do not use COUNT(*) as student count or COUNT(DISTINCT ORGANIZATION_SCHOOL_ID) as unique student count.
'

-- ============================================================
-- 6. CORTEX ANALYST: QUESTION CATEGORIZATION RULES
-- ============================================================
AI_QUESTION_CATEGORIZATION '
This semantic view answers questions about cumulative student product usage, distinct students reached, student launch events, monthly snapshots, school-year end, grade levels, product categories, school/district/state/country/company hierarchy, school/district names and owners.

When the user asks simply for number of students across the whole company, use COMPANY_STUDENTS. When they ask by country, state, district, or school, choose the corresponding pre-aggregated metric. These choices are defined and are not ambiguous.
When the user asks for launches, use STUDENTS_LAUNCHES. If they ask for students who launched or unique students, use the relevant *_STUDENTS metric rather than the launch-event count. If wording is genuinely ambiguous about unique students versus launch events, ask for clarification.
When grade is unspecified, default to precomputed GRADE_LEVEL (All). When product category is unspecified, default to precomputed PRODUCT_CATEGORY (All). Do not ask for those filters merely because they are omitted. All Students is NOT a synonym for (All).
When no date is supplied, the latest available cumulative snapshot is appropriate. For a named school year, the latest available snapshot within the year is appropriate. If the question explicitly requires school-year month 12 or June, require that month rather than substituting an earlier one.
Different grade bands overlap and different product categories may overlap; no addition across those categories is meaningful for distinct-student totals. Distinct-student counts at different geographic levels must not be added into one number.
The view contains student engagement/usage counts, not enrollment, licensing quantities, revenue, ARR, NRR, curriculum quality, assessment scores, retention rates, or subscription counts. Refer questions about those metrics to an appropriate other semantic view rather than inventing them.
If user asks for owner without specifying school or district ownership and the distinction affects interpretation, ask which owner.
'

-- ============================================================
-- 7. SEMANTIC QUERIES FROM THE 10 MANUAL VALIDATION TESTS
--    User confirmed these scenario queries worked.
--    Verified timestamp: 2026-11-13 21:51 UTC (epoch below).
-- ============================================================
AI_VERIFIED_QUERIES (
    school_sep_2026 AS (
        QUESTION 'Show school students and student launches for September 2026 by school.'
        VERIFIED_AT 1794606660
        ONBOARDING_QUESTION FALSE
        VERIFIED_BY '(STEWARD = KaterynaD)'
        SQL '
            SELECT ORGANIZATION_SCHOOL_ID, SCHOOL_STUDENTS, STUDENTS_LAUNCHES
            FROM SEMANTIC_VIEW(
                DW.USAGE.PRODUCT_USAGE
                    DIMENSIONS u.ORGANIZATION_SCHOOL_ID
                METRICS u.SCHOOL_STUDENTS, u.STUDENTS_LAUNCHES
                WHERE u.MON_YEAR = 202609
            )
            ORDER BY ORGANIZATION_SCHOOL_ID
        '
    ),

    district_sep_2026 AS (
        QUESTION 'Show district students and student launches for September 2026 by district.'
        VERIFIED_AT 1794606660
        ONBOARDING_QUESTION FALSE
        VERIFIED_BY '(STEWARD = KaterynaD)'
        SQL '
            SELECT ORGANIZATION_DISTRICT_ID, DISTRICT_STUDENTS, STUDENTS_LAUNCHES
            FROM SEMANTIC_VIEW(
                DW.USAGE.PRODUCT_USAGE
                    DIMENSIONS u.ORGANIZATION_DISTRICT_ID
                METRICS u.DISTRICT_STUDENTS, u.STUDENTS_LAUNCHES
                WHERE u.MON_YEAR = 202609
            )
            ORDER BY ORGANIZATION_DISTRICT_ID
        '
    ),

    state_sep_2026 AS (
        QUESTION 'Show state students and student launches for September 2026 by state.'
        VERIFIED_AT 1794606660
        ONBOARDING_QUESTION TRUE
        VERIFIED_BY '(STEWARD = KaterynaD)'
        SQL '
            SELECT COUNTRY, STATE_CODE, STATE_STUDENTS, STUDENTS_LAUNCHES
            FROM SEMANTIC_VIEW(
                DW.USAGE.PRODUCT_USAGE
                    DIMENSIONS u.COUNTRY, u.STATE_CODE
                METRICS u.STATE_STUDENTS, u.STUDENTS_LAUNCHES
                WHERE u.MON_YEAR = 202609
            )
            ORDER BY COUNTRY, STATE_CODE
        '
    ),

    country_sep_2026 AS (
        QUESTION 'Show country students and student launches for September 2026 by country.'
        VERIFIED_AT 1794606660
        ONBOARDING_QUESTION FALSE
        VERIFIED_BY '(STEWARD = KaterynaD)'
        SQL '
            SELECT COUNTRY, COUNTRY_STUDENTS, STUDENTS_LAUNCHES
            FROM SEMANTIC_VIEW(
                DW.USAGE.PRODUCT_USAGE
                    DIMENSIONS u.COUNTRY
                METRICS u.COUNTRY_STUDENTS, u.STUDENTS_LAUNCHES
                WHERE u.MON_YEAR = 202609
            )
            ORDER BY COUNTRY
        '
    ),

    company_sep_2026 AS (
        QUESTION 'Show company students and student launches for September 2026 for the whole company.'
        VERIFIED_AT 1794606660
        ONBOARDING_QUESTION TRUE
        VERIFIED_BY '(STEWARD = KaterynaD)'
        SQL '
            SELECT COMPANY_STUDENTS, STUDENTS_LAUNCHES
            FROM SEMANTIC_VIEW(
                DW.USAGE.PRODUCT_USAGE
                METRICS u.COMPANY_STUDENTS, u.STUDENTS_LAUNCHES
                WHERE u.MON_YEAR = 202609
            )
        '
    ),

    school_schoolyear_2025_2026_end AS (
        QUESTION 'Show school students and student launches at the end of school year 2025/2026 by school.'
        VERIFIED_AT 1794606660
        ONBOARDING_QUESTION FALSE
        VERIFIED_BY '(STEWARD = KaterynaD)'
        SQL '
            SELECT ORGANIZATION_SCHOOL_ID, SCHOOL_STUDENTS, STUDENTS_LAUNCHES
            FROM SEMANTIC_VIEW(
                DW.USAGE.PRODUCT_USAGE
                    DIMENSIONS u.ORGANIZATION_SCHOOL_ID
                METRICS u.SCHOOL_STUDENTS, u.STUDENTS_LAUNCHES
                WHERE u.SCHOOLYEAR = ''2025/2026''
            )
            ORDER BY ORGANIZATION_SCHOOL_ID
        '
    ),

    district_schoolyear_2025_2026_end AS (
        QUESTION 'Show district students and student launches at the end of school year 2025/2026 by district.'
        VERIFIED_AT 1794606660
        ONBOARDING_QUESTION FALSE
        VERIFIED_BY '(STEWARD = KaterynaD)'
        SQL '
            SELECT ORGANIZATION_DISTRICT_ID, DISTRICT_STUDENTS, STUDENTS_LAUNCHES
            FROM SEMANTIC_VIEW(
                DW.USAGE.PRODUCT_USAGE
                    DIMENSIONS u.ORGANIZATION_DISTRICT_ID
                METRICS u.DISTRICT_STUDENTS, u.STUDENTS_LAUNCHES
                WHERE u.SCHOOLYEAR = ''2025/2026''
            )
            ORDER BY ORGANIZATION_DISTRICT_ID
        '
    ),

    state_schoolyear_2025_2026_end AS (
        QUESTION 'Show state students and student launches at the end of school year 2025/2026 by state.'
        VERIFIED_AT 1794606660
        ONBOARDING_QUESTION TRUE
        VERIFIED_BY '(STEWARD = KaterynaD)'
        SQL '
            SELECT COUNTRY, STATE_CODE, STATE_STUDENTS, STUDENTS_LAUNCHES
            FROM SEMANTIC_VIEW(
                DW.USAGE.PRODUCT_USAGE
                    DIMENSIONS u.COUNTRY, u.STATE_CODE
                METRICS u.STATE_STUDENTS, u.STUDENTS_LAUNCHES
                WHERE u.SCHOOLYEAR = ''2025/2026''
            )
            ORDER BY COUNTRY, STATE_CODE
        '
    ),

    country_schoolyear_2025_2026_end AS (
        QUESTION 'Show country students and student launches at the end of school year 2025/2026 by country.'
        VERIFIED_AT 1794606660
        ONBOARDING_QUESTION FALSE
        VERIFIED_BY '(STEWARD = KaterynaD)'
        SQL '
            SELECT COUNTRY, COUNTRY_STUDENTS, STUDENTS_LAUNCHES
            FROM SEMANTIC_VIEW(
                DW.USAGE.PRODUCT_USAGE
                    DIMENSIONS u.COUNTRY
                METRICS u.COUNTRY_STUDENTS, u.STUDENTS_LAUNCHES
                WHERE u.SCHOOLYEAR = ''2025/2026''
            )
            ORDER BY COUNTRY
        '
    ),

    company_schoolyear_2025_2026_end AS (
        QUESTION 'Show company students and student launches at the end of school year 2025/2026 for the whole company.'
        VERIFIED_AT 1794606660
        ONBOARDING_QUESTION TRUE
        VERIFIED_BY '(STEWARD = KaterynaD)'
        SQL '
            SELECT COMPANY_STUDENTS, STUDENTS_LAUNCHES
            FROM SEMANTIC_VIEW(
                DW.USAGE.PRODUCT_USAGE
                METRICS u.COMPANY_STUDENTS, u.STUDENTS_LAUNCHES
                WHERE u.SCHOOLYEAR = ''2025/2026''
            )
        '
    )
);


DESCRIBE SEMANTIC VIEW DW.USAGE.PRODUCT_USAGE;

SELECT GET_DDL(
    'SEMANTIC_VIEW',
    'DW.USAGE.PRODUCT_USAGE'
);




WITH source_base AS (

    -- Test 1: September 2026
    SELECT
        'MONTH_202609' AS TEST_CASE,
        f.*
    FROM DW.USAGE.FACT_STUDENTS_USAGE_MONTHLY_SNAPSHOTS f
    WHERE f.MON_YEAR = 202609

    UNION ALL

    -- Test 2: End of school year 2025/2026
    SELECT
        'SY_2025_2026_END' AS TEST_CASE,
        f.*
    FROM DW.USAGE.FACT_STUDENTS_USAGE_MONTHLY_SNAPSHOTS f
    JOIN DW.COMMON.DIM_MONTH m
        ON f.MON_LASTDAY = m.MON_LASTDAY
    WHERE m.SCHOOLYEAR = '2025/2026'
      AND m.SCHOOLYEAR_MON = 12
),

f AS (
    SELECT *
    FROM source_base
    WHERE GRADE_LEVEL = '(All)'
      AND PRODUCT_CATEGORY = '(All)'
),

-- ==================================================
-- ORIGINAL TABLE: EXPECTED RESULTS
-- ==================================================

source_data AS (

    -- SCHOOL: No aggregation
    SELECT
        TEST_CASE,
        'SCHOOL' AS HIERARCHY,
        TO_VARCHAR(ORGANIZATION_SCHOOL_ID) AS ENTITY_KEY,
        SCHOOL_CNT_STUDENTS AS STUDENTS,
        SCHOOL_STUDENTS_LAUNCHES AS LAUNCHES
    FROM f

    UNION ALL

    -- DISTRICT
    SELECT
        TEST_CASE,
        'DISTRICT',
        TO_VARCHAR(ORGANIZATION_DISTRICT_ID),
        MAX(DISTRICT_CNT_STUDENTS),
        SUM(SCHOOL_STUDENTS_LAUNCHES)
    FROM f
    GROUP BY TEST_CASE, ORGANIZATION_DISTRICT_ID

    UNION ALL

    -- STATE
    SELECT
        TEST_CASE,
        'STATE',
        TO_JSON(ARRAY_CONSTRUCT(
            COUNTRY, STATE_PROVINCE_CODE
        )),
        MAX(STATE_CNT_STUDENTS),
        SUM(SCHOOL_STUDENTS_LAUNCHES)
    FROM f
    GROUP BY TEST_CASE, COUNTRY, STATE_PROVINCE_CODE

    UNION ALL

    -- COUNTRY
    SELECT
        TEST_CASE,
        'COUNTRY',
        COUNTRY,
        MAX(COUNTRY_CNT_STUDENTS),
        SUM(SCHOOL_STUDENTS_LAUNCHES)
    FROM f
    GROUP BY TEST_CASE, COUNTRY

    UNION ALL

    -- COMPANY
    SELECT
        TEST_CASE,
        'COMPANY',
        'ALL',
        MAX(COMPANY_CNT_STUDENTS),
        SUM(SCHOOL_STUDENTS_LAUNCHES)
    FROM f
    GROUP BY TEST_CASE
),

-- ==================================================
-- SEMANTIC VIEW: ACTUAL RESULTS
-- ==================================================

semantic_data AS (

    -- TEST 1: SEPTEMBER 2026

    -- SCHOOL
    SELECT
        'MONTH_202609' AS TEST_CASE,
        'SCHOOL' AS HIERARCHY,
        TO_VARCHAR(ORGANIZATION_SCHOOL_ID) AS ENTITY_KEY,
        SCHOOL_STUDENTS AS STUDENTS,
        STUDENTS_LAUNCHES AS LAUNCHES
    FROM SEMANTIC_VIEW(
        DW.USAGE.PRODUCT_USAGE
        METRICS
            u.SCHOOL_STUDENTS,
            u.STUDENTS_LAUNCHES
        DIMENSIONS u.ORGANIZATION_SCHOOL_ID
        WHERE u.MON_YEAR = 202609
    )

    UNION ALL

    -- DISTRICT
    SELECT
        'MONTH_202609',
        'DISTRICT',
        TO_VARCHAR(ORGANIZATION_DISTRICT_ID),
        DISTRICT_STUDENTS,
        STUDENTS_LAUNCHES
    FROM SEMANTIC_VIEW(
        DW.USAGE.PRODUCT_USAGE
        METRICS
            u.DISTRICT_STUDENTS,
            u.STUDENTS_LAUNCHES
        DIMENSIONS u.ORGANIZATION_DISTRICT_ID
        WHERE u.MON_YEAR = 202609
    )

    UNION ALL

    -- STATE
    SELECT
        'MONTH_202609',
        'STATE',
        TO_JSON(ARRAY_CONSTRUCT(COUNTRY, STATE_CODE)),
        STATE_STUDENTS,
        STUDENTS_LAUNCHES
    FROM SEMANTIC_VIEW(
        DW.USAGE.PRODUCT_USAGE
        METRICS
            u.STATE_STUDENTS,
            u.STUDENTS_LAUNCHES
        DIMENSIONS u.COUNTRY, u.STATE_CODE
        WHERE u.MON_YEAR = 202609
    )

    UNION ALL

    -- COUNTRY
    SELECT
        'MONTH_202609',
        'COUNTRY',
        COUNTRY,
        COUNTRY_STUDENTS,
        STUDENTS_LAUNCHES
    FROM SEMANTIC_VIEW(
        DW.USAGE.PRODUCT_USAGE
        METRICS
            u.COUNTRY_STUDENTS,
            u.STUDENTS_LAUNCHES
        DIMENSIONS u.COUNTRY
        WHERE u.MON_YEAR = 202609
    )

    UNION ALL

    -- COMPANY
    SELECT
        'MONTH_202609',
        'COMPANY',
        'ALL',
        COMPANY_STUDENTS,
        STUDENTS_LAUNCHES
    FROM SEMANTIC_VIEW(
        DW.USAGE.PRODUCT_USAGE
        METRICS
            u.COMPANY_STUDENTS,
            u.STUDENTS_LAUNCHES
        WHERE u.MON_YEAR = 202609
    )

    UNION ALL

    -- TEST 2: SCHOOL YEAR 2025/2026

    -- SCHOOL
    SELECT
        'SY_2025_2026_END',
        'SCHOOL',
        TO_VARCHAR(ORGANIZATION_SCHOOL_ID),
        SCHOOL_STUDENTS,
        STUDENTS_LAUNCHES
    FROM SEMANTIC_VIEW(
        DW.USAGE.PRODUCT_USAGE
        METRICS
            u.SCHOOL_STUDENTS,
            u.STUDENTS_LAUNCHES
        DIMENSIONS u.ORGANIZATION_SCHOOL_ID
        WHERE u.SCHOOLYEAR = '2025/2026'
    )

    UNION ALL

    -- DISTRICT
    SELECT
        'SY_2025_2026_END',
        'DISTRICT',
        TO_VARCHAR(ORGANIZATION_DISTRICT_ID),
        DISTRICT_STUDENTS,
        STUDENTS_LAUNCHES
    FROM SEMANTIC_VIEW(
        DW.USAGE.PRODUCT_USAGE
        METRICS
            u.DISTRICT_STUDENTS,
            u.STUDENTS_LAUNCHES
        DIMENSIONS u.ORGANIZATION_DISTRICT_ID
        WHERE u.SCHOOLYEAR = '2025/2026'
    )

    UNION ALL

    -- STATE
    SELECT
        'SY_2025_2026_END',
        'STATE',
        TO_JSON(ARRAY_CONSTRUCT(COUNTRY, STATE_CODE)),
        STATE_STUDENTS,
        STUDENTS_LAUNCHES
    FROM SEMANTIC_VIEW(
        DW.USAGE.PRODUCT_USAGE
        METRICS
            u.STATE_STUDENTS,
            u.STUDENTS_LAUNCHES
        DIMENSIONS u.COUNTRY, u.STATE_CODE
        WHERE u.SCHOOLYEAR = '2025/2026'
    )

    UNION ALL

    -- COUNTRY
    SELECT
        'SY_2025_2026_END',
        'COUNTRY',
        COUNTRY,
        COUNTRY_STUDENTS,
        STUDENTS_LAUNCHES
    FROM SEMANTIC_VIEW(
        DW.USAGE.PRODUCT_USAGE
        METRICS
            u.COUNTRY_STUDENTS,
            u.STUDENTS_LAUNCHES
        DIMENSIONS u.COUNTRY
        WHERE u.SCHOOLYEAR = '2025/2026'
    )

    UNION ALL

    -- COMPANY
    SELECT
        'SY_2025_2026_END',
        'COMPANY',
        'ALL',
        COMPANY_STUDENTS,
        STUDENTS_LAUNCHES
    FROM SEMANTIC_VIEW(
        DW.USAGE.PRODUCT_USAGE
        METRICS
            u.COMPANY_STUDENTS,
            u.STUDENTS_LAUNCHES
        WHERE u.SCHOOLYEAR = '2025/2026'
    )
),

-- ==================================================
-- ROW-BY-ROW COMPARISON
-- ==================================================

-- Number rows to detect duplicates as well as
-- missing or extra entities.
source_numbered AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY TEST_CASE, HIERARCHY, ENTITY_KEY
            ORDER BY STUDENTS, LAUNCHES
        ) AS RN
    FROM source_data
),

semantic_numbered AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY TEST_CASE, HIERARCHY, ENTITY_KEY
            ORDER BY STUDENTS, LAUNCHES
        ) AS RN
    FROM semantic_data
),

compared AS (
    SELECT
        COALESCE(s.TEST_CASE, v.TEST_CASE) AS TEST_CASE,
        COALESCE(s.HIERARCHY, v.HIERARCHY) AS HIERARCHY,
        COALESCE(s.ENTITY_KEY, v.ENTITY_KEY) AS ENTITY_KEY,

        s.TEST_CASE IS NOT NULL AS HAS_SOURCE,
        v.TEST_CASE IS NOT NULL AS HAS_SEMANTIC,

        s.STUDENTS AS SOURCE_STUDENTS,
        v.STUDENTS AS SEMANTIC_STUDENTS,
        s.LAUNCHES AS SOURCE_LAUNCHES,
        v.LAUNCHES AS SEMANTIC_LAUNCHES

    FROM source_numbered s
    FULL OUTER JOIN semantic_numbered v
        ON s.TEST_CASE = v.TEST_CASE
       AND s.HIERARCHY = v.HIERARCHY
       AND EQUAL_NULL(s.ENTITY_KEY, v.ENTITY_KEY)
       AND s.RN = v.RN
),

-- Convert each comparison into a metric test.
metric_checks AS (
    SELECT
        TEST_CASE,
        HIERARCHY,
        'STUDENTS' AS METRIC_TYPE,
        HAS_SOURCE,
        HAS_SEMANTIC,
        NOT EQUAL_NULL(
            SOURCE_STUDENTS, SEMANTIC_STUDENTS
        ) AS VALUE_MISMATCH,
        ABS(SOURCE_STUDENTS - SEMANTIC_STUDENTS)
            AS ABS_DIFF
    FROM compared

    UNION ALL

    SELECT
        TEST_CASE,
        HIERARCHY,
        'LAUNCHES',
        HAS_SOURCE,
        HAS_SEMANTIC,
        NOT EQUAL_NULL(
            SOURCE_LAUNCHES, SEMANTIC_LAUNCHES
        ),
        ABS(SOURCE_LAUNCHES - SEMANTIC_LAUNCHES)
    FROM compared
),

-- Explicit expected tests: even an empty result fails.
expected AS (
    SELECT
        t.TEST_CASE,
        h.HIERARCHY,
        mt.METRIC_TYPE
    FROM (
        SELECT COLUMN1 AS TEST_CASE
        FROM VALUES
            ('MONTH_202609'),
            ('SY_2025_2026_END')
    ) t
    CROSS JOIN (
        SELECT COLUMN1 AS HIERARCHY
        FROM VALUES
            ('SCHOOL'),
            ('DISTRICT'),
            ('STATE'),
            ('COUNTRY'),
            ('COMPANY')
    ) h
    CROSS JOIN (
        SELECT COLUMN1 AS METRIC_TYPE
        FROM VALUES ('STUDENTS'), ('LAUNCHES')
    ) mt
),

summary AS (
    SELECT
        e.TEST_CASE,
        e.HIERARCHY,
        e.METRIC_TYPE,

        COUNT(c.TEST_CASE) AS CHECKED_ROWS,

        SUM(IFF(
            c.HAS_SOURCE = FALSE, 1, 0
        )) AS MISSING_IN_SOURCE,

        SUM(IFF(
            c.HAS_SEMANTIC = FALSE, 1, 0
        )) AS MISSING_IN_SEMANTIC,

        SUM(IFF(
            c.HAS_SOURCE
            AND c.HAS_SEMANTIC
            AND c.VALUE_MISMATCH,
            1, 0
        )) AS VALUE_MISMATCHES,

        MAX(c.ABS_DIFF) AS MAX_ABS_DIFF

    FROM expected e
    LEFT JOIN metric_checks c
        ON e.TEST_CASE = c.TEST_CASE
       AND e.HIERARCHY = c.HIERARCHY
       AND e.METRIC_TYPE = c.METRIC_TYPE

    GROUP BY
        e.TEST_CASE,
        e.HIERARCHY,
        e.METRIC_TYPE
)

SELECT
    TEST_CASE,
    HIERARCHY,

    CASE
        WHEN METRIC_TYPE = 'LAUNCHES'
            THEN 'STUDENTS_LAUNCHES'
        WHEN HIERARCHY = 'SCHOOL'
            THEN 'SCHOOL_STUDENTS'
        WHEN HIERARCHY = 'DISTRICT'
            THEN 'DISTRICT_STUDENTS'
        WHEN HIERARCHY = 'STATE'
            THEN 'STATE_STUDENTS'
        WHEN HIERARCHY = 'COUNTRY'
            THEN 'COUNTRY_STUDENTS'
        ELSE 'COMPANY_STUDENTS'
    END AS METRIC,

    CHECKED_ROWS,
    MISSING_IN_SOURCE,
    MISSING_IN_SEMANTIC,
    VALUE_MISMATCHES,
    MAX_ABS_DIFF,

    IFF(
        CHECKED_ROWS > 0
        AND MISSING_IN_SOURCE = 0
        AND MISSING_IN_SEMANTIC = 0
        AND VALUE_MISMATCHES = 0,
        'PASS',
        'FAIL'
    ) AS TEST_STATUS

FROM summary
ORDER BY
    TEST_STATUS DESC,
    TEST_CASE,
    HIERARCHY,
    METRIC;


--School details

WITH source_data AS (
    SELECT
        f.ORGANIZATION_SCHOOL_ID AS SCHOOL_ID,
        f.MON_LASTDAY AS SOURCE_MONTH,
        f.ORGANIZATION_DISTRICT_ID AS DISTRICT_ID,
        f.SCHOOL_CNT_STUDENTS AS SOURCE_STUDENTS,
        f.SCHOOL_STUDENTS_LAUNCHES AS SOURCE_LAUNCHES,

        ROW_NUMBER() OVER (
            PARTITION BY f.ORGANIZATION_SCHOOL_ID
            ORDER BY
                f.SCHOOL_CNT_STUDENTS,
                f.SCHOOL_STUDENTS_LAUNCHES
        ) AS RN

    FROM DW.USAGE.FACT_STUDENTS_USAGE_MONTHLY_SNAPSHOTS f
    JOIN DW.COMMON.DIM_MONTH m
        ON f.MON_LASTDAY = m.MON_LASTDAY

    WHERE m.SCHOOLYEAR = '2025/2026'
      AND m.SCHOOLYEAR_MON = 12
      AND f.GRADE_LEVEL = '(All)'
      AND f.PRODUCT_CATEGORY = '(All)'
),

semantic_data AS (
    SELECT
        ORGANIZATION_SCHOOL_ID AS SCHOOL_ID,
        SCHOOL_STUDENTS AS SEMANTIC_STUDENTS,
        STUDENTS_LAUNCHES AS SEMANTIC_LAUNCHES,

        ROW_NUMBER() OVER (
            PARTITION BY ORGANIZATION_SCHOOL_ID
            ORDER BY SCHOOL_STUDENTS, STUDENTS_LAUNCHES
        ) AS RN

    FROM SEMANTIC_VIEW(
        DW.USAGE.PRODUCT_USAGE
        METRICS
            u.SCHOOL_STUDENTS,
            u.STUDENTS_LAUNCHES
        DIMENSIONS
            u.ORGANIZATION_SCHOOL_ID
        WHERE u.SCHOOLYEAR = '2025/2026'
    )
),

-- Diagnostic: latest available snapshot for each school
latest_snapshots AS (
    SELECT
        f.ORGANIZATION_SCHOOL_ID AS SCHOOL_ID,

        MAX(f.MON_LASTDAY) AS LATEST_ANY_MONTH,

        MAX(
            IFF(
                f.GRADE_LEVEL = '(All)'
                AND f.PRODUCT_CATEGORY = '(All)',
                f.MON_LASTDAY,
                NULL
            )
        ) AS LATEST_ALL_MONTH

    FROM DW.USAGE.FACT_STUDENTS_USAGE_MONTHLY_SNAPSHOTS f
    JOIN DW.COMMON.DIM_MONTH m
        ON f.MON_LASTDAY = m.MON_LASTDAY

    WHERE m.SCHOOLYEAR = '2025/2026'
    GROUP BY f.ORGANIZATION_SCHOOL_ID
),

school_names AS (
    SELECT
        ACCOUNT_ID,
        MAX(NAME) AS SCHOOL_NAME
    FROM DW.COMMON.DIM_ACCOUNT
    GROUP BY ACCOUNT_ID
),

comparison AS (
    SELECT
        COALESCE(s.SCHOOL_ID, v.SCHOOL_ID) AS SCHOOL_ID,

        s.DISTRICT_ID,
        s.SOURCE_MONTH,

        l.LATEST_ANY_MONTH,
        l.LATEST_ALL_MONTH,

        s.SOURCE_STUDENTS,
        v.SEMANTIC_STUDENTS,

        s.SOURCE_STUDENTS - v.SEMANTIC_STUDENTS
            AS STUDENTS_DIFF,

        s.SOURCE_LAUNCHES,
        v.SEMANTIC_LAUNCHES,

        s.SOURCE_LAUNCHES - v.SEMANTIC_LAUNCHES
            AS LAUNCHES_DIFF,

        CASE
            WHEN s.RN IS NULL
                THEN 'MISSING_IN_SOURCE'

            WHEN v.RN IS NULL
                THEN 'MISSING_IN_SEMANTIC'

            WHEN NOT EQUAL_NULL(
                s.SOURCE_STUDENTS,
                v.SEMANTIC_STUDENTS
            )
            AND NOT EQUAL_NULL(
                s.SOURCE_LAUNCHES,
                v.SEMANTIC_LAUNCHES
            )
                THEN 'BOTH_METRICS_DIFFER'

            WHEN NOT EQUAL_NULL(
                s.SOURCE_STUDENTS,
                v.SEMANTIC_STUDENTS
            )
                THEN 'STUDENTS_DIFFER'

            WHEN NOT EQUAL_NULL(
                s.SOURCE_LAUNCHES,
                v.SEMANTIC_LAUNCHES
            )
                THEN 'LAUNCHES_DIFFER'

            ELSE 'MATCH'
        END AS STATUS

    FROM source_data s
    FULL OUTER JOIN semantic_data v
        ON EQUAL_NULL(s.SCHOOL_ID, v.SCHOOL_ID)
       AND s.RN = v.RN

    LEFT JOIN latest_snapshots l
        ON EQUAL_NULL(
            COALESCE(s.SCHOOL_ID, v.SCHOOL_ID),
            l.SCHOOL_ID
        )
)

SELECT
    c.STATUS,
    c.SCHOOL_ID,
    n.SCHOOL_NAME,
    c.DISTRICT_ID,

    c.SOURCE_MONTH,
    c.LATEST_ANY_MONTH,
    c.LATEST_ALL_MONTH,

    c.SOURCE_STUDENTS,
    c.SEMANTIC_STUDENTS,
    c.STUDENTS_DIFF,

    c.SOURCE_LAUNCHES,
    c.SEMANTIC_LAUNCHES,
    c.LAUNCHES_DIFF

FROM comparison c
LEFT JOIN school_names n
    ON EQUAL_NULL(c.SCHOOL_ID, n.ACCOUNT_ID)

WHERE c.STATUS <> 'MATCH'

ORDER BY
    c.STATUS,
    ABS(c.STUDENTS_DIFF) DESC NULLS LAST,
    ABS(c.LAUNCHES_DIFF) DESC NULLS LAST,
    c.SCHOOL_ID;





-- ORIGINAL TABLE
SELECT
    f.ORGANIZATION_SCHOOL_ID,
    f.organization_district_id,
    f.SCHOOL_CNT_STUDENTS AS SCHOOL_STUDENTS,
    f.SCHOOL_STUDENTS_LAUNCHES AS STUDENTS_LAUNCHES
FROM DW.USAGE.FACT_STUDENTS_USAGE_MONTHLY_SNAPSHOTS f
JOIN DW.COMMON.DIM_MONTH m
    ON f.MON_LASTDAY = m.MON_LASTDAY
WHERE m.SCHOOLYEAR = '2025/2026'
  AND m.SCHOOLYEAR_MON = 12
  AND f.GRADE_LEVEL = '(All)'
  AND f.PRODUCT_CATEGORY = '(All)'
  AND f.organization_school_id = '943b718b-35ac-4018-9ea7-0967291b9cf9'
ORDER BY f.ORGANIZATION_SCHOOL_ID;

1	884

-- SEMANTIC VIEW
SELECT
    ORGANIZATION_SCHOOL_ID,
    organization_district_id,
    SCHOOL_STUDENTS,
    STUDENTS_LAUNCHES
FROM SEMANTIC_VIEW(
    DW.USAGE.PRODUCT_USAGE
    METRICS
        u.SCHOOL_STUDENTS,
        u.STUDENTS_LAUNCHES
    DIMENSIONS
        u.ORGANIZATION_SCHOOL_ID,
        u.organization_district_id
    WHERE u.SCHOOLYEAR = '2025/2026'
    AND u.organization_school_id = '943b718b-35ac-4018-9ea7-0967291b9cf9'
)
ORDER BY ORGANIZATION_SCHOOL_ID;
