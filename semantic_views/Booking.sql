create or replace semantic view DW.REVENUE.BOOKING
	tables (
		DW.REVENUE.VW_FACT_BOOKING with synonyms=('booking facts','monthly booking records') comment='Monthly booking fact records used for financial and sales reporting. Each row contributes a booking amount associated with a reporting month, booking classification, and account. The Booking metric is a flow metric that can be aggregated over time. It is not an ARR balance or point-in-time snapshot. The underlying view must select the intended monthly booking records without duplicating amounts.',
		DW.COMMON.DIM_ACCOUNT primary key (ACCOUNT_ID) with synonyms=('customer accounts','organizations','account master') comment='Flattened organizational hierarchy with three reporting levels: Customer, District, and Account. Each row represents one ACCOUNT_ID and contains NAME, DISTRICT_NAME, and CUSTOMER_NAME. These values may be identical when the account itself represents a district or customer. Multiple accounts may belong to the same district, and multiple districts may belong to the same customer. Use CUSTOMER_NAME for customer-level aggregation, DISTRICT_NAME for district-level aggregation, and NAME for individual account-level reporting.',
		DW.COMMON.DIM_MONTH primary key (MON_LASTDAY) with synonyms=('calendar table','fiscal calendar','month dimension') comment='Calendar and fiscal reporting dimension with one row per month-end date. The fiscal year begins July 1 and ends June 30. Fiscal month 1 represents July, fiscal month 2 represents August, and fiscal month 12 represents June. Fiscal years are labeled with both calendar years, for example 2024/2025 covers July 2024 through June 2025. Fiscal month 0 exists in the source and requires business clarification.'
	)
	relationships (
		BOOKING_TO_ACCOUNT as VW_FACT_BOOKING(ACCOUNT_ID) references DIM_ACCOUNT(ACCOUNT_ID),
		BOOKING_TO_MONTH as VW_FACT_BOOKING(MON_LASTDAY) references DIM_MONTH(MON_LASTDAY)
	)
	facts (
		VW_FACT_BOOKING.BOOKING_AMOUNT as BOOKING_AMOUNT with synonyms=('booking fact amount','individual booking amount') comment='Numeric booking amount for a fact record. This is the source USD value used to calculate the Booking metric. Amounts are additive across non-overlapping fact records. Positive and negative values, if present, retain their signs. Do not interpret this amount as an ARR snapshot or independently calculated customer count.' sample_values ('3594.5400000000', '4035.7200000000', '314.4900000000')
	)
	dimensions (
		VW_FACT_BOOKING.BUCKET as BUCKET with synonyms=('booking category','booking bucket','booking classification') comment='Business classification of the booking amount. Categories distinguish New Business, Renewal, Upsell, Reseller, ARR-related, NRR-related, Biz Dev, and upfront multi-year booking classifications. ARR and NRR in category names describe the booking classification. They do not represent an ARR or NRR balance metric. The Unknown category represents unclassified records. Do not assume that selecting ARR-related booking categories is equivalent to calculating ARR.' sample_values ('New Business: ARR', 'Renewal: ARR', 'Upsell: ARR', 'Renewal: Biz Dev', 'Upsell: Biz Dev', 'New Business: Biz Dev', 'New Business: NRR', 'Renewal: NRR', 'Unknown', 'New Business: Upfront yr 2&3', 'Renewal: Upfront Yrs>3', 'Upsell: Upfront Yrs>3', 'Reseller ARR Renewal', 'Reseller ARR Upsell', 'New Business: Upfront Yrs>3', 'Reseller ARR Renewal Upfront Yr 2&3', 'Renewal: Upfront Yr 2&3', 'Upsell: NRR', 'Upsell: Upfront Yr 2&3'),
		DIM_ACCOUNT.ACCOUNT_ID as ACCOUNT_ID with synonyms=('account identifier','organization ID') comment='Unique account identifier used to associate booking records with the account dimension. Use this field when identifying or grouping individual accounts. The identifier is not itself a count or metric.' sample_values ('0014100000v3N4wAAE', '0014100000wXBowAAG', '05081ca7-d9cb-4b2b-b538-16c0bcd87c62'),
		DIM_ACCOUNT.NAME as NAME with synonyms=('account name','organization display name') comment='Individual account or organization name. An account may represent a school, district, or customer. This is the lowest reporting level in the flattened organizational hierarchy. Use NAME for account-level reporting, not for customer or district rollups.' sample_values ('S* M****** E******** School', 'S* F****** D* S**** S* S******', 'A**** Elementary School'),
		DIM_ACCOUNT.DISTRICT_NAME as DISTRICT_NAME with synonyms=('district','district name','district organization') comment='District-level organization name. Multiple accounts may belong to the same district. DISTRICT_NAME may equal NAME when the account itself represents the district. Use DISTRICT_NAME to aggregate bookings across all accounts belonging to a district.' sample_values ('S* M****** E******** School', 'S* F****** D* S**** S* S******', 'A**** Elementary School'),
		DIM_ACCOUNT.CUSTOMER_NAME as CUSTOMER_NAME with synonyms=('customer name','customer organization') comment='Customer-level organization name. A customer may contain multiple districts and accounts. CUSTOMER_NAME may equal DISTRICT_NAME or NAME when the customer and account represent the same organization. Use CUSTOMER_NAME to aggregate bookings across all associated accounts and districts.' sample_values ('S* M****** E******** School', 'S* F****** D* S**** S* S******', 'A**** Elementary School'),
		DIM_ACCOUNT.OWNER as OWNER with synonyms=('account owner','assigned owner','sales owner','CSM') comment='Owner assigned to the account in the account dimension. Use for bookings by account owner. This represents the account owner attribute, not necessarily the opportunity owner or historical booking owner. Names are masked, so distinct real owners may have identical masked values.' sample_values ('A***** L*****', 'B**** H******', 'B****** F****', 'D**** T***', 'F*** A****', 'H****** I**********', 'K** v** P*******', 'K**** C****', 'K**** M********', 'K***** W*****', 'M**** P****', 'M***** R*****', 'N****** C*****', 'P******* C******', 'R*** D******', 'R***** M******', 'S**** R*******', 'S**** T********', 'S********* S*****', 'T****** K*****', 'U*** I**********', 'U******'),
		DIM_ACCOUNT.STATE_CODE as STATE_CODE with synonyms=('state abbreviation','US state code','account state','territory code','state') comment='Two-character US state or territory code associated with an account. Examples: CA means California, NY means New York, TX means Texas. Unknown represents missing or unclassified geography. Use this field for bookings by state or territory. Geographic attribution is based on the account dimension, not necessarily the physical location where the booking occurred.' sample_values ('AK', 'AL', 'AR', 'AS', 'AZ', 'CA', 'CO', 'CT', 'DC', 'DE', 'FL', 'GA', 'HI', 'IA', 'ID', 'IL', 'IN', 'KS', 'KY', 'LA', 'MA', 'MD', 'ME', 'MI', 'MN', 'MO', 'MP', 'MS', 'MT', 'NC', 'ND', 'NE', 'NH', 'NJ', 'NM', 'NV', 'NY', 'OH', 'OK', 'OR', 'PA', 'PR', 'RI', 'SC', 'SD', 'TN', 'TX', 'UT', 'Unknown', 'VA', 'VI', 'VT', 'WA', 'WI', 'WV', 'WY'),
		DIM_MONTH.MON_LASTDAY as MON_LASTDAY with synonyms=('month end date','last day of month','reporting month end') comment='Last calendar date of the reporting month. The Booking fact is related to the calendar dimension through MON_LASTDAY. Use this date for chronological monthly reporting and date-range filtering. It is a reporting month-end date rather than necessarily the original opportunity close date.',
		DIM_MONTH.MON_YEAR as MON_YEAR with synonyms=('calendar month','year month','YYYYMM') comment='Calendar year and month represented numerically as YYYYMM. For example 202307 means July 2023 and 202504 means April 2025. Use this dimension for calendar-month reporting. It is not a fiscal month index.' sample_values ('202307', '202308', '202504'),
		DIM_MONTH.FISCALYEAR as FISCALYEAR with synonyms=('fiscal year','financial year','FY') comment='Fiscal year in YYYY/YYYY format, beginning July 1 of the first year and ending June 30 of the second year. For example 2024/2025 covers July 2024 through June 2025. Use for annual fiscal reporting and year-over-year fiscal comparisons. When displaying months within a fiscal year, order by FISCALYEAR_MON.' sample_values ('2015/2016', '2016/2017', '2017/2018', '2018/2019', '2019/2020', '2020/2021', '2021/2022', '2022/2023', '2023/2024', '2024/2025', '2025/2026'),
		DIM_MONTH.FISCALYEAR_MON as FISCALYEAR_MON with synonyms=('fiscal month','fiscal month number','month within fiscal year') comment='Fiscal month number in the July-June fiscal calendar. 1=July, 2=August, 3=September, 4=October, 5=November, 6=December, 7=January, 8=February, 9=March, 10=April, 11=May, 12=June. The source also includes 0, whose meaning is not yet confirmed. Use ascending fiscal month order to display months from July through June.' sample_values ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12')
	)
	metrics (
		VW_FACT_BOOKING.BOOKING as SUM(VW_FACT_BOOKING.BOOKING_AMOUNT) with synonyms=('total bookings','booking total','booked amount','total booked amount') comment='Total Booking amount, calculated as SUM(BOOKING_AMOUNT). This is a fully additive flow metric. Booking amounts can be summed across reporting months, fiscal years, booking buckets, accounts, states, and other compatible dimensions, provided the source records do not duplicate the same booking contributions. Positive and negative adjustments are included according to their signs. Booking is not a point-in-time ARR balance and does not require NON ADDITIVE BY.'
	)
	comment='Monthly Booking semantic view for business reporting and AI-assisted analytics. Provides the fully additive Booking metric with booking classification, account, ownership, geography, calendar month, and July-June fiscal calendar dimensions. Booking represents financial activity during a period rather than a recurring revenue balance. Intended for fiscal reporting, booking trend analysis, customer analysis, state rankings, and booking-category reporting.'
	ai_sql_generation '
Use VW_FACT_BOOKING.BOOKING for total bookings, booked amounts, and booking totals.

Booking is a fully additive flow metric. Aggregate booking amounts over the requested reporting periods and dimensions.

Do not use Booking as a substitute for ARR balances, NRR rates, or other recurring-revenue snapshot metrics.

For calendar-month questions, use DIM_MONTH.MON_YEAR.

For fiscal-year questions, use DIM_MONTH.FISCALYEAR.

For monthly bookings within a fiscal year, use DIM_MONTH.FISCALYEAR and DIM_MONTH.FISCALYEAR_MON.

Fiscal years start in July and end in June. Fiscal month 1 means July and fiscal month 12 means June.

Use DIM_MONTH.MON_LASTDAY for month-end dates and chronological date filters.

Use DIM_ACCOUNT.STATE_CODE for bookings by state.

When a question specifies a full US state name, translate it to the correct two-character state code. For example, California means CA, New York means NY, and Texas means TX.

Use VW_FACT_BOOKING.BUCKET for booking classification.

Do not assume bucket names containing ARR or NRR are separate financial metrics.

Do not automatically restrict total bookings to ARR-related categories.

Do not automatically exclude Unknown buckets, negative amounts, or zero amounts.

For New Business, Renewal, Upsell, or Reseller questions, use the exact available booking categories and do not invent category values.

When the business category is ambiguous, request clarification rather than silently choosing one.

When ranking groups by total bookings, order by Booking descending unless another order is requested.

Use DIM_ACCOUNT.ACCOUNT_ID when grouping individual accounts, especially because masked account names can repeat.

Account owner is the owner recorded in DIM_ACCOUNT and should not automatically be interpreted as the historical owner of the booking.

For SEMANTIC_VIEW queries, use qualified dimension and metric names inside the function. In the outer SELECT and ORDER BY, use the returned column names or their explicit aliases.


The fiscal month 0 represent unknown  calendar and fiscal month.

ORGANIZATIONAL HIERARCHY:

DIM_ACCOUNT represents a flattened organizational hierarchy:
Customer -> District -> Account.

The hierarchy levels are attributes of the same dimension table, not separate tables.

NAME identifies the individual account.
DISTRICT_NAME identifies the associated district.
CUSTOMER_NAME identifies the associated customer.

These names may be equal when an organization represents more than one hierarchy level.

For bookings by customer, group by DIM_ACCOUNT.CUSTOMER_NAME.
For bookings by district, group by DIM_ACCOUNT.DISTRICT_NAME.
For bookings by account, group by DIM_ACCOUNT.ACCOUNT_ID and DIM_ACCOUNT.NAME.

For a specific customer, filter using DIM_ACCOUNT.CUSTOMER_NAME.
For a specific district, filter using DIM_ACCOUNT.DISTRICT_NAME.
For a specific account, filter using DIM_ACCOUNT.ACCOUNT_ID or DIM_ACCOUNT.NAME.

For customer-to-district drill-down, group by CUSTOMER_NAME and DISTRICT_NAME.

For district-to-account drill-down, group by DISTRICT_NAME, ACCOUNT_ID and NAME.

The Booking metric is additive across accounts. Customer-level and district-level booking amounts are rollups of the underlying account-level booking records.

Never sum customer-level, district-level, and account-level totals together because they represent overlapping aggregation levels of the same data.

'
	ai_question_categorization '
This semantic view answers questions about booking amounts, booking classifications, accounts, owners, state geography, calendar months, and fiscal reporting.


If the user asks for a business concept not defined in this view, do not invent a metric.

If the question does not specify whether a booking category should be included, default to all booking categories for total bookings.

Questions about customers, districts, schools, accounts, and organizational hierarchies are supported.

Interpret "by customer" as grouping by CUSTOMER_NAME, "by district" as grouping by DISTRICT_NAME, and "by account" as grouping by individual account.

If the requested organizational level is ambiguous, ask for clarification.

If the question asks for an ambiguous business classification that cannot be mapped reliably to the available buckets, ask for clarification.
'
	ai_verified_queries (
		BOOKING_BY_FISCAL_YEAR AS ( 
QUESTION 'What were total bookings by fiscal year?' 
VERIFIED_AT 1794590880
VERIFIED_BY '(STEWARD = KaterynaD)'
ONBOARDING_QUESTION true
SQL '
            SELECT FISCALYEAR, BOOKING
            FROM SEMANTIC_VIEW(
                DW.REVENUE.BOOKING
                DIMENSIONS DIM_MONTH.FISCALYEAR
                METRICS VW_FACT_BOOKING.BOOKING
            )
            ORDER BY FISCALYEAR DESC
        '),
		MONTHLY_BOOKING AS ( 
QUESTION 'Show monthly bookings in fiscal year order.' 
VERIFIED_AT 1794590880
VERIFIED_BY '(STEWARD = KaterynaD)'
ONBOARDING_QUESTION true
SQL '
            SELECT
                FISCALYEAR,
                FISCALYEAR_MON,
                MON_YEAR,
                BOOKING
            FROM SEMANTIC_VIEW(
                DW.REVENUE.BOOKING
                DIMENSIONS
                    DIM_MONTH.FISCALYEAR,
                    DIM_MONTH.FISCALYEAR_MON,
                    DIM_MONTH.MON_YEAR
                METRICS VW_FACT_BOOKING.BOOKING
            )
            ORDER BY
                FISCALYEAR DESC,
                FISCALYEAR_MON ASC
        '),
		BOOKING_BY_STATE AS ( 
QUESTION 'What are the top 10 states by total bookings?' 
VERIFIED_AT 1794590880
VERIFIED_BY '(STEWARD = KaterynaD)'
ONBOARDING_QUESTION true
SQL '
            SELECT STATE_CODE, BOOKING
            FROM SEMANTIC_VIEW(
                DW.REVENUE.BOOKING
                DIMENSIONS DIM_ACCOUNT.STATE_CODE
                METRICS VW_FACT_BOOKING.BOOKING
            )
            ORDER BY BOOKING DESC
            LIMIT 10
        '),
		BOOKING_BY_BUCKET AS ( 
QUESTION 'Show total bookings by booking classification.' 
VERIFIED_AT 1794590880
VERIFIED_BY '(STEWARD = KaterynaD)'
ONBOARDING_QUESTION false
SQL '
            SELECT BUCKET, BOOKING
            FROM SEMANTIC_VIEW(
                DW.REVENUE.BOOKING
                DIMENSIONS VW_FACT_BOOKING.BUCKET
                METRICS VW_FACT_BOOKING.BOOKING
            )
            ORDER BY BOOKING DESC
        '),
		BOOKING_BY_CUSTOMER AS ( 
QUESTION 'Show total bookings by customer.' 
VERIFIED_AT 1794590880
VERIFIED_BY '(STEWARD = KaterynaD)'
ONBOARDING_QUESTION false
SQL '
              SELECT
               CUSTOMER_NAME,
               BOOKING
             FROM SEMANTIC_VIEW (
                DW.REVENUE.BOOKING
                DIMENSIONS DIM_ACCOUNT.CUSTOMER_NAME
                METRICS VW_FACT_BOOKING.BOOKING
                                )
             ORDER BY BOOKING DESC
        '),
		DISTRICT_DRILL_DOWN AS ( 
QUESTION 'Show total bookings by customer and district.' 
VERIFIED_AT 1794590880
VERIFIED_BY '(STEWARD = KaterynaD)'
ONBOARDING_QUESTION false
SQL '
              SELECT
                    CUSTOMER_NAME,
                    DISTRICT_NAME,
                    BOOKING
              FROM SEMANTIC_VIEW (
                    DW.REVENUE.BOOKING
                   DIMENSIONS
                     DIM_ACCOUNT.CUSTOMER_NAME,
                     DIM_ACCOUNT.DISTRICT_NAME
               METRICS VW_FACT_BOOKING.BOOKING
                                 )
        ORDER BY CUSTOMER_NAME, BOOKING DESC
        ')
	);