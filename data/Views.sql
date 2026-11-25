CREATE OR REPLACE VIEW dw.revenue.vw_fact_arr
as
with
opportunities_issues as (
select 
a.opportunity_id,
listagg(i.issue, ', ') WITHIN GROUP (ORDER BY i.issue) AS  issues
from dw.revenue.dim_arr_audit a
join dw.revenue.dim_arr_issue i
on a.issue_id = i.issue_id
group by a.opportunity_id
)
    select 
        fa.arr_type,      
        fa.mon_year, 
        fa.mon_lastday,
        fa.fiscalyear,
        fa.fiscalyear_mon, 
        fa.bucket,
        fa.account_id,
        sum(total_price) as total_price,
        sum(parent_total_price) as parent_total_price,
        sum(fa.arr_amount) as arr_amount,
        max(loaddate) as loaddate
    from dw.revenue.fact_arr fa
    left outer join opportunities_issues i
    on fa.opportunity_id = i.opportunity_id             
    where current_date between fa.arr_activation_date and fa.arr_deactivation_date
      and ifnull(i.issues,'Valid') not ilike '%negative opp%'
      and ifnull(i.issues,'Valid') not ilike '%replacement opp%'  
      and fa.record_type='ARR'
    group by
        fa.arr_type, 
        fa.record_type,        
        fa.mon_year, 
        fa.mon_lastday,
        fa.fiscalyear,
        fa.fiscalyear_mon, 
        fa.bucket,
        fa.account_id
;


select * from dw.revenue.vw_fact_arr

COMMENT ON VIEW dw.revenue.vw_fact_arr IS '
The view applies standard filters to ARR data in fact_arr:  - how arr looks like today (current_date between arr_activation_date and arr_deactivation_date) - excluding negative and replacement opportunities
The view is needed to exclude the same filters in the most downstream models.
ARR validation models have their own specific logic and do not use this view.
ARR Reporting view (vw_arr_booking_monthly) initially was developed to provide ARR amounts at any point of time and  the first filter is applied dynamically in Tableau, probably hidden. The second filter is also dynamic in Tableau and allows to estimate impact of negative and replacement opportunities.
The model does not depend on data in an other database so it can be implemented as a late binding view.  Should be safe in CI/CD.
';






CREATE OR REPLACE VIEW dw.revenue.vw_fact_booking
as
    select       
        fb.mon_year, 
        fb.mon_lastday,
        fb.bucket,
        fb.account_id,
        sum(fb.total_price) as booking_amount
    from dw.revenue.fact_booking fb
    where record_type = 'MonthlyBooking'
    group by
        fb.mon_year, 
        fb.mon_lastday,
        fb.bucket,
        fb.account_id
;


CREATE OR REPLACE VIEW DW.USAGE.VW_FACT_PRODUCT_USAGE AS
SELECT
    f.MON_LASTDAY,
    f.MON_YEAR,
    m.SCHOOLYEAR,
    m.SCHOOLYEAR_MON,
    f.COUNTRY,
    f.STATE_PROVINCE_CODE as STATE_CODE,
    f.ORGANIZATION_DISTRICT_ID,
    d.NAME AS DISTRICT_NAME,
    d.OWNER AS DISTRICT_OWNER,
    f.ORGANIZATION_SCHOOL_ID,
    s.NAME AS SCHOOL_NAME,
    s.OWNER AS SCHOOL_OWNER,
    f.GRADE_LEVEL,
    IFF(f.GRADE_LEVEL = '(All)', 1, 0)
        AS GRADE_PRIORITY,
    f.PRODUCT_CATEGORY,
    IFF(f.PRODUCT_CATEGORY = '(All)', 1, 0)
        AS PRODUCT_PRIORITY,
    f.SCHOOL_CNT_STUDENTS,
    f.SCHOOL_STUDENTS_LAUNCHES,
    f.DISTRICT_CNT_STUDENTS,
    f.STATE_CNT_STUDENTS,
    f.COUNTRY_CNT_STUDENTS,
    f.COMPANY_CNT_STUDENTS
FROM DW.USAGE.FACT_STUDENTS_USAGE_MONTHLY_SNAPSHOTS f
LEFT JOIN DW.COMMON.DIM_MONTH m
    ON f.MON_LASTDAY = m.MON_LASTDAY
LEFT JOIN DW.COMMON.DIM_ACCOUNT d
    ON f.ORGANIZATION_DISTRICT_ID = d.ACCOUNT_ID
LEFT JOIN DW.COMMON.DIM_ACCOUNT s
    ON f.ORGANIZATION_SCHOOL_ID = s.ACCOUNT_ID;

    CREATE OR REPLACE VIEW DW.COMMON.VW_ACCOUNT_KNOWLEDGE AS
SELECT
    a.*,
    m.TOTAL_WON_OPPORTUNITIES,
    m.TOTAL_OPEN_OPPORTUNITIES,
    m.LATEST_START_DATE,
    m.LATEST_END_DATE,
    m.LATEST_OPEN_OPPORTUNITIES_MODIFIED_DATE,
    m.FIRST_INVOICED_DATE,
    m.TOTAL_WON_DEALS,
    m.TOTAL_WON_STATE_PROGRAM_DEALS,
    m.TOTAL_TRAINING_SESSIONS,
    m.LATEST_TRAINING_SESSION_ON,
    m.TOTAL_CASES,
    m.CURRENTLY_OPEN_CASES,
    m.LATEST_OPEN_CASE_MODIFIED_DATE,
    m.LATEST_CASE_CREATED_DATE,
    m.HAS_PRODUCT_LICENSES,
    m.HAS_PRODUCT_USAGE,
    m.LOADDATE AS METRICS_LOADED_AT
FROM DW.COMMON.DIM_ACCOUNT a
JOIN DW.COMMON.DIM_ACCOUNT_METRICS m
    ON a.ACCOUNT_ID = m.ACCOUNT_ID;

