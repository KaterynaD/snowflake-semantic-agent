create or replace semantic view DW.USAGE.PRODUCT_USAGE
	tables (
		U as DW.USAGE.VW_FACT_PRODUCT_USAGE with synonyms=('monthly product usage snapshots','student product usage','student activity by school','school-year usage facts') comment='One logical source for cumulative school-year-to-date product usage by reporting month, school, district, state, country, grade level, and product category. Each snapshot has already-computed distinct student counts at five geographic levels: school, district, state, country, and company for each product category and grade level.  School launch counts are cumulative school-year-to-date events at school grain. The table also includes precomputed (All) values for grade and product. Multiple grade bands and product categories may overlap. A student may attend more than one school or district and counted only once at each level.'
	)
	dimensions (
		U.MON_LASTDAY as u.MON_LASTDAY with synonyms=('snapshot date','month end date','as of date') comment='Actual calendar month-end date of a cumulative school-year-to-date snapshot. NON ADDITIVE BY (MON_LASTDAY ASC) selects the latest available monthly snapshot within the selected period. Do not sum cumulative snapshots across months.',
		U.MON_YEAR as u.MON_YEAR with synonyms=('reporting month','calendar year month','YYYYMM') comment='Calendar reporting month as numeric YYYYMM, for example 202609 is September 2026. This is NOT a school-year number. Use MON_YEAR for an explicitly specified calendar month; never combine September 2026 with school year 2025/2026.' sample_values ('202606', '202609'),
		U.SCHOOLYEAR as u.SCHOOLYEAR with synonyms=('school year','academic year','SY') comment='July-through-June academic reporting year. For example 2025/2026 means July 2025 through June 2026. When asked for a school-year ending balance, filter by SCHOOLYEAR and let the non-additive snapshot logic select the latest available month within that school year.' sample_values ('2025/2026', '2026/2027'),
		U.SCHOOLYEAR_MON as u.SCHOOLYEAR_MON with synonyms=('school year month','academic month number','month in school year') comment='School-year month number: 1=July, 2=August, 3=September, 4=October, 5=November, 6=December, 7=January, 8=February, 9=March, 10=April, 11=May, 12=June. Use ascending order to display monthly snapshots within a school year; 12 is June, the school-year ending month.' sample_values ('1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'),
		U.COUNTRY as u.COUNTRY with synonyms=('country','nation','country name') comment='Country of the district. Country is a geographic aggregation level, not a measure. Use COUNTRY_STUDENTS, not a sum of state or district distinct-student counts, for country-level student numbers. Unknown is a legitimate stored value.' sample_values ('Bahamas', 'Egypt', 'Guatemala', 'Panama', 'Philippines', 'Saudi Arabia', 'United Arab Emirates', 'United States of America', 'Unknown'),
		U.STATE_CODE as u.STATE_CODE with synonyms=('state','state abbreviation','province code','US state') comment='Geographic state, territory, or province code, sometimes Unknown. When a US state name is specified, translate it to the exact stored abbreviation (California=CA, Florida=FL, New York=NY, Texas=TX). Use COUNTRY together with STATE_CODE for unambiguous geographic groupings, especially Unknown. Use STATE_STUDENTS for distinct counts at this level.' sample_values ('AK', 'AL', 'AR', 'AZ', 'CA', 'CO', 'CT', 'DC', 'FL', 'GA', 'HI', 'IA', 'ID', 'IL', 'IN', 'KS', 'KY', 'LA', 'MA', 'MD', 'ME', 'MI', 'MN', 'MO', 'MS', 'MT', 'NC', 'ND', 'NE', 'NH', 'NJ', 'NM', 'NV', 'NY', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC', 'SD', 'TN', 'TX', 'UT', 'Unknown', 'VA', 'VI', 'WA', 'WI', 'WV', 'WY'),
		U.ORGANIZATION_DISTRICT_ID as u.ORGANIZATION_DISTRICT_ID with synonyms=('district ID','district identifier') comment='Identifier of the district containing a school. Use as the grouping key when a question is about districts; name alone is not guaranteed to be unique. This is not an individual school identifier.',
		U.DISTRICT_NAME as u.DISTRICT_NAME with synonyms=('district name','school district') comment='Display name of the associated district, obtained from DIM_ACCOUNT through the source SQL view. Pair with ORGANIZATION_DISTRICT_ID when grouping or identifying a particular district; district names need not be unique.',
		U.DISTRICT_OWNER as u.DISTRICT_OWNER with synonyms=('district owner','district account owner') comment='Owner associated with the district account in the account dimension. This is the present account-master owner, not necessarily the historical owner at snapshot time; do not automatically substitute SCHOOL_OWNER.',
		U.ORGANIZATION_SCHOOL_ID as u.ORGANIZATION_SCHOOL_ID with synonyms=('school ID','school identifier','organization school ID') comment='Identifier of the individual school, the lowest geographic reporting level and the grain of SCHOOL_CNT_STUDENTS and SCHOOL_STUDENTS_LAUNCHES. Pair with SCHOOL_NAME for display and accurate school-level grouping.',
		U.SCHOOL_NAME as u.SCHOOL_NAME with synonyms=('school name','organization school name') comment='Display name of the individual school, looked up through the source SQL view. School names can repeat across districts; group by ORGANIZATION_SCHOOL_ID, optionally with SCHOOL_NAME.',
		U.SCHOOL_OWNER as u.SCHOOL_OWNER with synonyms=('school owner','school account owner') comment='Owner associated with the school account in the account dimension. This is the current account-master attribute, not necessarily historical ownership at the snapshot month.',
		U.GRADE_LEVEL as u.GRADE_LEVEL with synonyms=('grade','grade band','student grade','grade group') comment='Pre-aggregated grade category. The exact value (All), including parentheses, is the default total across grades; it is NOT the same value as All Students. Codes 01-12 are individual grades; PK and KG are pre-kindergarten and kindergarten. Elementary, Middle, High, All Students, Non Students and Unknown are additional source categories and may overlap other grade categories. Never sum the categories to calculate the all-grade total. If a grade is not specified, prefer the precomputed (All) row via GRADE_PRIORITY.' sample_values ('(All)', '01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12', 'All Students', 'Elementary', 'High', 'KG', 'Middle', 'Non Students', 'PK', 'Unknown'),
		U.GRADE_PRIORITY as u.GRADE_PRIORITY with synonyms=('default grade priority','grade selection order') comment='Internal non-additivity ordering: 1 for GRADE_LEVEL = (All), 0 otherwise. NON ADDITIVE BY (GRADE_PRIORITY ASC) selects the precomputed (All) grade row when grade is omitted. Do not expose as a business KPI or use it as a student-count dimension.' sample_values ('0', '1'),
		U.PRODUCT_CATEGORY as u.PRODUCT_CATEGORY with synonyms=('product','product line','learning product','product family') comment='Pre-aggregated product-category label. Exact (All) is the default across products. Students can use multiple products, and categories can overlap; never sum separate product-category distinct-student totals to calculate overall students. For all-product questions use the precomputed (All) row via PRODUCT_PRIORITY. Preserve exact stored strings, including plus signs, ampersands, and qualifiers.' sample_values ('(All)', 'AI Literacy', 'AI Literacy (Limited)', 'AI Literacy Student-Driven Learning Path', 'Assessments', 'Common Sense Education', 'Digital Readiness', 'Digital Safety Foundation', 'EasyCode', 'EasyCode Foundations', 'EasyCode Pillars', 'EasyTech', 'EasyTech & TechApps for Texas', 'EasyTech Blended Learning Path', 'EasyTech Florida Blended Learning Path', 'EasyTech Florida Student-Driven Learning Path', 'EasyTech Student-Driven Learning Path', 'EasyTech without Common Sense Education', 'EasyTech+', 'Fontana Tech Quest', 'Keyboarding & Word Processing', 'Online Safety & Digital Citizenship', 'Safe into Summer', 'Tech Quest', 'TechApps for Texas', 'Texas Blended Learning Path', 'Texas Essentials Blended Learning Path'),
		U.PRODUCT_PRIORITY as u.PRODUCT_PRIORITY with synonyms=('default product priority','product selection order') comment='Internal non-additivity ordering: 1 for PRODUCT_CATEGORY = (All), 0 otherwise. NON ADDITIVE BY (PRODUCT_PRIORITY ASC) chooses the precomputed all-product row when product is unspecified; 1 must be sorted last (ASC). Not a business reporting metric.' sample_values ('0', '1')
	)
	metrics (
		U.SCHOOL_STUDENTS non additive by (U.MON_LASTDAY asc nulls last, U.GRADE_PRIORITY asc nulls last, U.PRODUCT_PRIORITY asc nulls last) as MAX(u.SCHOOL_CNT_STUDENTS) with synonyms=('students per school','distinct school students','school student reach') comment='Pre-aggregated count of distinct students for each individual school, cumulative from school-year start through snapshot month end. MAX prevents repeated identical values from being summed; at school grain the stored count is already the correct measure. Non-additive across months, grades and products. Never sum school student counts to derive district, state, country or company distinct counts; use the dedicated metric for that level.',
		U.DISTRICT_STUDENTS non additive by (U.MON_LASTDAY asc nulls last, U.GRADE_PRIORITY asc nulls last, U.PRODUCT_PRIORITY asc nulls last) as MAX(u.DISTRICT_CNT_STUDENTS) with synonyms=('students per district','distinct district students','district student reach') comment='Pre-aggregated distinct students for a district, repeated on each of its school rows. MAX uses the already-correct district value without adding repetitions. Report per ORGANIZATION_DISTRICT_ID. Do not sum this metric across districts to obtain a state or company distinct count. Uses the latest snapshot and pre-aggregated (All) grade/product defaults.',
		U.STATE_STUDENTS non additive by (U.MON_LASTDAY asc nulls last, U.GRADE_PRIORITY asc nulls last, U.PRODUCT_PRIORITY asc nulls last) as MAX(u.STATE_CNT_STUDENTS) with synonyms=('students per state','distinct state students','state student reach') comment='Pre-aggregated state-level distinct students, repeated across rows for schools and districts within the state. MAX ignores repeated identical state totals at the requested state level. Group by COUNTRY and STATE_CODE. Do not sum state distinct counts to derive country or company distinct counts. Uses latest cumulative snapshot and (All) grade/product when unspecified.',
		U.COUNTRY_STUDENTS non additive by (U.MON_LASTDAY asc nulls last, U.GRADE_PRIORITY asc nulls last, U.PRODUCT_PRIORITY asc nulls last) as MAX(u.COUNTRY_CNT_STUDENTS) with synonyms=('students per country','distinct country students','country student reach') comment='Pre-aggregated distinct students for a country, repeated on many lower-level rows. MAX takes the already-computed country figure. Group by COUNTRY. Do not sum country distinct counts to derive the company total. Non-additive across time, grade and product.',
		U.COMPANY_STUDENTS non additive by (U.MON_LASTDAY asc nulls last, U.GRADE_PRIORITY asc nulls last, U.PRODUCT_PRIORITY asc nulls last) as MAX(u.COMPANY_CNT_STUDENTS) with synonyms=('total students','company-wide students','all students reached','unique students company-wide') comment='Pre-aggregated company-wide distinct student count, repeated at lower geographic levels. The correct metric for total students across the company; MAX takes the one precomputed company-wide count and does not sum school, district, state or country distinct counts. Uses latest cumulative monthly snapshot and precomputed (All) grade/product totals when unspecified. This is not an enrollment count.',
		U.STUDENTS_LAUNCHES non additive by (U.MON_LASTDAY asc nulls last, U.GRADE_PRIORITY asc nulls last, U.PRODUCT_PRIORITY asc nulls last) as SUM(u.SCHOOL_STUDENTS_LAUNCHES) with synonyms=('student launches','product launches','student activity launches','usage launches') comment='Cumulative count of launch EVENTS from the start of the school year through the snapshot month for each school, grade and product category. SUM across nonoverlapping school rows is valid to roll up to district, state, country and company. Never sum across monthly snapshots because they are cumulative. Never sum over the precomputed (All) grade/product rows and their constituent categories: those overlap. This is an event count, NOT a count of distinct students. If grade/product is unspecified, use the corresponding (All) priority row.'
	)
	comment='Cumulative school-year-to-date product usage semantic view for Cortex Analyst and governed reporting. Provides five separately pre-aggregated distinct-student metrics at school, district, state, country and company level, plus school-based launch-event counts additive across nonoverlapping geographic schools. The distinct-student counts are repeated at lower geographic levels and MUST NOT be summed to higher geographic levels. All six metrics are non-additive across month-end cumulative snapshots and across overlapping grade and product-category rollups. NON ADDITIVE BY MON_LASTDAY ASC selects the latest available snapshot, and priority columns favor the precomputed (All) grade and (All) product rows when these dimensions are unspecified. School year follows July-June; MON_YEAR is an independent YYYYMM calendar field. Choose the metric corresponding to the requested geographic level; use COMPANY_STUDENTS for company-wide unique students and STUDENTS_LAUNCHES for launch events.'
	ai_sql_generation '
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
	ai_question_categorization '
This semantic view answers questions about cumulative student product usage, distinct students reached, student launch events, monthly snapshots, school-year end, grade levels, product categories, school/district/state/country/company hierarchy, school/district names and owners.

When the user asks simply for number of students across the whole company, use COMPANY_STUDENTS. When they ask by country, state, district, or school, choose the corresponding pre-aggregated metric. These choices are defined and are not ambiguous.
When the user asks for launches, use STUDENTS_LAUNCHES. If they ask for students who launched or unique students, use the relevant *_STUDENTS metric rather than the launch-event count. If wording is genuinely ambiguous about unique students versus launch events, ask for clarification.
When grade is unspecified, default to precomputed GRADE_LEVEL (All). When product category is unspecified, default to precomputed PRODUCT_CATEGORY (All). Do not ask for those filters merely because they are omitted. All Students is NOT a synonym for (All).
When no date is supplied, the latest available cumulative snapshot is appropriate. For a named school year, the latest available snapshot within the year is appropriate. If the question explicitly requires school-year month 12 or June, require that month rather than substituting an earlier one.
Different grade bands overlap and different product categories may overlap; no addition across those categories is meaningful for distinct-student totals. Distinct-student counts at different geographic levels must not be added into one number.
The view contains student engagement/usage counts, not enrollment, licensing quantities, revenue, ARR, NRR, curriculum quality, assessment scores, retention rates, or subscription counts. Refer questions about those metrics to an appropriate other semantic view rather than inventing them.
If user asks for owner without specifying school or district ownership and the distinction affects interpretation, ask which owner.
'
	ai_verified_queries (
		SCHOOL_SEP_2026 AS ( 
QUESTION 'Show school students and student launches for September 2026 by school.' 
VERIFIED_AT 1794606660
VERIFIED_BY '(STEWARD = KaterynaD)'
ONBOARDING_QUESTION false
SQL '
            SELECT ORGANIZATION_SCHOOL_ID, SCHOOL_STUDENTS, STUDENTS_LAUNCHES
            FROM SEMANTIC_VIEW(
                DW.USAGE.PRODUCT_USAGE
                    DIMENSIONS u.ORGANIZATION_SCHOOL_ID
                METRICS u.SCHOOL_STUDENTS, u.STUDENTS_LAUNCHES
                WHERE u.MON_YEAR = 202609
            )
            ORDER BY ORGANIZATION_SCHOOL_ID
        '),
		DISTRICT_SEP_2026 AS ( 
QUESTION 'Show district students and student launches for September 2026 by district.' 
VERIFIED_AT 1794606660
VERIFIED_BY '(STEWARD = KaterynaD)'
ONBOARDING_QUESTION false
SQL '
            SELECT ORGANIZATION_DISTRICT_ID, DISTRICT_STUDENTS, STUDENTS_LAUNCHES
            FROM SEMANTIC_VIEW(
                DW.USAGE.PRODUCT_USAGE
                    DIMENSIONS u.ORGANIZATION_DISTRICT_ID
                METRICS u.DISTRICT_STUDENTS, u.STUDENTS_LAUNCHES
                WHERE u.MON_YEAR = 202609
            )
            ORDER BY ORGANIZATION_DISTRICT_ID
        '),
		STATE_SEP_2026 AS ( 
QUESTION 'Show state students and student launches for September 2026 by state.' 
VERIFIED_AT 1794606660
VERIFIED_BY '(STEWARD = KaterynaD)'
ONBOARDING_QUESTION true
SQL '
            SELECT COUNTRY, STATE_CODE, STATE_STUDENTS, STUDENTS_LAUNCHES
            FROM SEMANTIC_VIEW(
                DW.USAGE.PRODUCT_USAGE
                    DIMENSIONS u.COUNTRY, u.STATE_CODE
                METRICS u.STATE_STUDENTS, u.STUDENTS_LAUNCHES
                WHERE u.MON_YEAR = 202609
            )
            ORDER BY COUNTRY, STATE_CODE
        '),
		COUNTRY_SEP_2026 AS ( 
QUESTION 'Show country students and student launches for September 2026 by country.' 
VERIFIED_AT 1794606660
VERIFIED_BY '(STEWARD = KaterynaD)'
ONBOARDING_QUESTION false
SQL '
            SELECT COUNTRY, COUNTRY_STUDENTS, STUDENTS_LAUNCHES
            FROM SEMANTIC_VIEW(
                DW.USAGE.PRODUCT_USAGE
                    DIMENSIONS u.COUNTRY
                METRICS u.COUNTRY_STUDENTS, u.STUDENTS_LAUNCHES
                WHERE u.MON_YEAR = 202609
            )
            ORDER BY COUNTRY
        '),
		COMPANY_SEP_2026 AS ( 
QUESTION 'Show company students and student launches for September 2026 for the whole company.' 
VERIFIED_AT 1794606660
VERIFIED_BY '(STEWARD = KaterynaD)'
ONBOARDING_QUESTION true
SQL '
            SELECT COMPANY_STUDENTS, STUDENTS_LAUNCHES
            FROM SEMANTIC_VIEW(
                DW.USAGE.PRODUCT_USAGE
                METRICS u.COMPANY_STUDENTS, u.STUDENTS_LAUNCHES
                WHERE u.MON_YEAR = 202609
            )
        '),
		SCHOOL_SCHOOLYEAR_2025_2026_END AS ( 
QUESTION 'Show school students and student launches at the end of school year 2025/2026 by school.' 
VERIFIED_AT 1794606660
VERIFIED_BY '(STEWARD = KaterynaD)'
ONBOARDING_QUESTION false
SQL '
            SELECT ORGANIZATION_SCHOOL_ID, SCHOOL_STUDENTS, STUDENTS_LAUNCHES
            FROM SEMANTIC_VIEW(
                DW.USAGE.PRODUCT_USAGE
                    DIMENSIONS u.ORGANIZATION_SCHOOL_ID
                METRICS u.SCHOOL_STUDENTS, u.STUDENTS_LAUNCHES
                WHERE u.SCHOOLYEAR = ''2025/2026''
            )
            ORDER BY ORGANIZATION_SCHOOL_ID
        '),
		DISTRICT_SCHOOLYEAR_2025_2026_END AS ( 
QUESTION 'Show district students and student launches at the end of school year 2025/2026 by district.' 
VERIFIED_AT 1794606660
VERIFIED_BY '(STEWARD = KaterynaD)'
ONBOARDING_QUESTION false
SQL '
            SELECT ORGANIZATION_DISTRICT_ID, DISTRICT_STUDENTS, STUDENTS_LAUNCHES
            FROM SEMANTIC_VIEW(
                DW.USAGE.PRODUCT_USAGE
                    DIMENSIONS u.ORGANIZATION_DISTRICT_ID
                METRICS u.DISTRICT_STUDENTS, u.STUDENTS_LAUNCHES
                WHERE u.SCHOOLYEAR = ''2025/2026''
            )
            ORDER BY ORGANIZATION_DISTRICT_ID
        '),
		STATE_SCHOOLYEAR_2025_2026_END AS ( 
QUESTION 'Show state students and student launches at the end of school year 2025/2026 by state.' 
VERIFIED_AT 1794606660
VERIFIED_BY '(STEWARD = KaterynaD)'
ONBOARDING_QUESTION true
SQL '
            SELECT COUNTRY, STATE_CODE, STATE_STUDENTS, STUDENTS_LAUNCHES
            FROM SEMANTIC_VIEW(
                DW.USAGE.PRODUCT_USAGE
                    DIMENSIONS u.COUNTRY, u.STATE_CODE
                METRICS u.STATE_STUDENTS, u.STUDENTS_LAUNCHES
                WHERE u.SCHOOLYEAR = ''2025/2026''
            )
            ORDER BY COUNTRY, STATE_CODE
        '),
		COUNTRY_SCHOOLYEAR_2025_2026_END AS ( 
QUESTION 'Show country students and student launches at the end of school year 2025/2026 by country.' 
VERIFIED_AT 1794606660
VERIFIED_BY '(STEWARD = KaterynaD)'
ONBOARDING_QUESTION false
SQL '
            SELECT COUNTRY, COUNTRY_STUDENTS, STUDENTS_LAUNCHES
            FROM SEMANTIC_VIEW(
                DW.USAGE.PRODUCT_USAGE
                    DIMENSIONS u.COUNTRY
                METRICS u.COUNTRY_STUDENTS, u.STUDENTS_LAUNCHES
                WHERE u.SCHOOLYEAR = ''2025/2026''
            )
            ORDER BY COUNTRY
        '),
		COMPANY_SCHOOLYEAR_2025_2026_END AS ( 
QUESTION 'Show company students and student launches at the end of school year 2025/2026 for the whole company.' 
VERIFIED_AT 1794606660
VERIFIED_BY '(STEWARD = KaterynaD)'
ONBOARDING_QUESTION true
SQL '
            SELECT COMPANY_STUDENTS, STUDENTS_LAUNCHES
            FROM SEMANTIC_VIEW(
                DW.USAGE.PRODUCT_USAGE
                METRICS u.COMPANY_STUDENTS, u.STUDENTS_LAUNCHES
                WHERE u.SCHOOLYEAR = ''2025/2026''
            )
        ')
	);