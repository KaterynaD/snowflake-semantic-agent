CREATE OR REPLACE PROCEDURE DW.SERVICE.ACCOUNT_QUERY(
    P_ACCOUNT_NAME VARCHAR,
    P_STATE_CODE VARCHAR DEFAULT NULL,
    P_DISTRICT_NAME VARCHAR DEFAULT NULL
)
RETURNS VARIANT
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
    V_COUNT NUMBER;
    V_DATA VARIANT;
BEGIN
    IF (P_ACCOUNT_NAME IS NULL
        OR TRIM(P_ACCOUNT_NAME) = '') THEN
        RETURN OBJECT_CONSTRUCT(
            'status', 'error',
            'message', 'Account name is required'
        );
    END IF;

    SELECT COUNT(*)
    INTO :V_COUNT
    FROM DW.SERVICE.VW_ACCOUNT_KNOWLEDGE
    WHERE NAME ILIKE '%' || :P_ACCOUNT_NAME || '%'
      AND (:P_STATE_CODE IS NULL
           OR STATE_CODE = UPPER(:P_STATE_CODE))
      AND (:P_DISTRICT_NAME IS NULL
           OR DISTRICT_NAME ILIKE
              '%' || :P_DISTRICT_NAME || '%');

    IF (V_COUNT = 0) THEN
        RETURN OBJECT_CONSTRUCT(
            'status', 'not_found',
            'match_count', 0
        );
    END IF;

    IF (V_COUNT > 1) THEN
        SELECT ARRAY_AGG(
            OBJECT_CONSTRUCT_KEEP_NULL(
                'account_id', ACCOUNT_ID,
                'name', NAME,
                'state_code', STATE_CODE,
                'district_name', DISTRICT_NAME,
                'customer_name', CUSTOMER_NAME
            )
        )
        INTO :V_DATA
        FROM (
            SELECT *
            FROM DW.COMMON.VW_ACCOUNT_KNOWLEDGE
            WHERE NAME ILIKE '%' || :P_ACCOUNT_NAME || '%'
              AND (:P_STATE_CODE IS NULL
                   OR STATE_CODE = UPPER(:P_STATE_CODE))
              AND (:P_DISTRICT_NAME IS NULL
                   OR DISTRICT_NAME ILIKE
                      '%' || :P_DISTRICT_NAME || '%')
            ORDER BY NAME
            LIMIT 10
        );

        RETURN OBJECT_CONSTRUCT(
            'status', 'multiple_matches',
            'match_count', V_COUNT,
            'candidates', V_DATA
        );
    END IF;

    SELECT OBJECT_CONSTRUCT_KEEP_NULL(*)
    INTO :V_DATA
    FROM DW.COMMON.VW_ACCOUNT_KNOWLEDGE
    WHERE NAME ILIKE '%' || :P_ACCOUNT_NAME || '%'
      AND (:P_STATE_CODE IS NULL
           OR STATE_CODE = UPPER(:P_STATE_CODE))
      AND (:P_DISTRICT_NAME IS NULL
           OR DISTRICT_NAME ILIKE
              '%' || :P_DISTRICT_NAME || '%');

    RETURN OBJECT_CONSTRUCT(
        'status', 'ok',
        'match_count', 1,
        'data', V_DATA
    );
END;
$$;
