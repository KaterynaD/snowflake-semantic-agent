SHOW AGENTS IN SCHEMA DW.SERVICE;

CREATE OR REPLACE MCP SERVER DW.SERVICE.BUSINESS_MCP
FROM SPECIFICATION $$
tools:
  - name: "business_agent"
    type: "CORTEX_AGENT_RUN"
    identifier: "DW.SERVICE.BUSINESS_ANALYTICS_AGENT"
    title: "Business Analytics Agent"
    description: >
      Answers business questions about bookings,a
      ARR, product usage, and customer status.
      Uses the governed Snowflake Cortex Agent
      and its semantic views and business rules.
$$;

SHOW MCP SERVERS IN SCHEMA DW.SERVICE;

DESCRIBE MCP SERVER DW.SERVICE.BUSINESS_MCP;