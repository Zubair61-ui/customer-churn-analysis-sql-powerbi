-- =====================================================================
-- Telco Customer Churn: analysis queries (run after 01_setup_and_clean.sql)
-- Each section answers a business question from the BRD.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. DATA QUALITY: the 11 tenure-zero customers (blank total_charges)
--    These are new customers, kept as NULL (not 0). Check they did not churn.
-- ---------------------------------------------------------------------
SELECT churned,
       COUNT(*)             AS customers,
       COUNT(total_charges) AS with_total_charges
FROM churn.customers
WHERE tenure_months = 0
GROUP BY churned;

-- ---------------------------------------------------------------------
-- Q1. HEADLINE KPIs
-- ---------------------------------------------------------------------
SELECT COUNT(*)                                                         AS customers,
       SUM(churned)                                                     AS churners,
       ROUND(100.0 * AVG(churned), 2)                                   AS churn_rate_pct,
       ROUND(SUM(monthly_charges) FILTER (WHERE churned = 1), 2)        AS churned_monthly_revenue,
       ROUND(100.0 * SUM(monthly_charges) FILTER (WHERE churned = 1)
             / SUM(monthly_charges), 1)                                 AS revenue_churn_pct,
       ROUND(AVG(tenure_months) FILTER (WHERE churned = 1), 1)          AS avg_tenure_churned,
       ROUND(AVG(tenure_months) FILTER (WHERE churned = 0), 1)          AS avg_tenure_retained,
       ROUND(AVG(monthly_charges) FILTER (WHERE churned = 1), 2)        AS avg_monthly_churned,
       ROUND(AVG(monthly_charges) FILTER (WHERE churned = 0), 2)        AS avg_monthly_retained,
       SUM(cltv) FILTER (WHERE churned = 1)                             AS cltv_of_churned
FROM churn.customers;

-- ---------------------------------------------------------------------
-- Q2 to Q5. SEGMENT SUMMARY VIEW (one row per dimension and value)
--    churn_rate_pct         = % of customers in the segment who left
--    share_of_churners_pct  = % of all churners in the segment
--    share_of_customers_pct = % of all customers in the segment
--    churn_lift             = segment churn rate / overall churn rate
--                             (1.0 = average, 2.0 = twice the average)
--    Power BI can use this view directly.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW churn.v_segment_summary AS
WITH seg_long AS (
    SELECT 'Gender'               AS dimension, gender            AS segment, churned FROM churn.customers
    UNION ALL SELECT 'Senior citizen',         senior_citizen,     churned FROM churn.customers
    UNION ALL SELECT 'Partner',                partner,            churned FROM churn.customers
    UNION ALL SELECT 'Dependents',             dependents,         churned FROM churn.customers
    UNION ALL SELECT 'Contract',               contract,           churned FROM churn.customers
    UNION ALL SELECT 'Payment method',         payment_method,     churned FROM churn.customers
    UNION ALL SELECT 'Paperless billing',      paperless_billing,  churned FROM churn.customers
    UNION ALL SELECT 'Internet service',       internet_service,   churned FROM churn.customers
    UNION ALL SELECT 'Phone service',          phone_service,      churned FROM churn.customers
    UNION ALL SELECT 'Multiple lines',         multiple_lines,     churned FROM churn.customers
    UNION ALL SELECT 'Online security',        online_security,    churned FROM churn.customers
    UNION ALL SELECT 'Online backup',          online_backup,      churned FROM churn.customers
    UNION ALL SELECT 'Device protection',      device_protection,  churned FROM churn.customers
    UNION ALL SELECT 'Tech support',           tech_support,       churned FROM churn.customers
    UNION ALL SELECT 'Streaming TV',           streaming_tv,       churned FROM churn.customers
    UNION ALL SELECT 'Streaming movies',       streaming_movies,   churned FROM churn.customers
    UNION ALL SELECT 'Tenure band',            tenure_band,        churned FROM churn.v_customers
    UNION ALL SELECT 'Monthly charges band',   monthly_charges_band, churned FROM churn.v_customers
)
SELECT dimension,
       segment,
       COUNT(*)                                                                AS customers,
       SUM(churned)                                                            AS churners,
       ROUND(100.0 * AVG(churned), 1)                                          AS churn_rate_pct,
       ROUND(100.0 * SUM(churned) / (SELECT SUM(churned) FROM churn.customers), 1) AS share_of_churners_pct,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM churn.customers), 1)     AS share_of_customers_pct,
       ROUND(AVG(churned) / (SELECT AVG(churned) FROM churn.customers), 2)     AS churn_lift
FROM seg_long
GROUP BY dimension, segment;

-- All segments, highest churn rate first
SELECT * FROM churn.v_segment_summary ORDER BY churn_rate_pct DESC;

-- Segments with the biggest gap from average, ignoring tiny groups
SELECT * FROM churn.v_segment_summary
WHERE customers >= 200
ORDER BY churn_lift DESC
LIMIT 15;

-- ---------------------------------------------------------------------
-- Q2. WHO CHURNS: location (cities with at least 50 customers)
-- ---------------------------------------------------------------------
SELECT city,
       COUNT(*)                         AS customers,
       SUM(churned)                     AS churners,
       ROUND(100.0 * AVG(churned), 1)   AS churn_rate_pct
FROM churn.customers
GROUP BY city
HAVING COUNT(*) >= 50
ORDER BY churn_rate_pct DESC;

-- ---------------------------------------------------------------------
-- Q3. ACCOUNT DRIVERS: do the effects overlap? (cross-tabs)
-- ---------------------------------------------------------------------
-- Contract x tenure band: is it the contract or just being new?
SELECT contract, tenure_band,
       COUNT(*)                         AS customers,
       SUM(churned)                     AS churners,
       ROUND(100.0 * AVG(churned), 1)   AS churn_rate_pct
FROM churn.v_customers
GROUP BY contract, tenure_band
ORDER BY contract, MIN(tenure_months);

-- Contract x payment method
SELECT contract, payment_method,
       COUNT(*)                         AS customers,
       ROUND(100.0 * AVG(churned), 1)   AS churn_rate_pct
FROM churn.customers
GROUP BY contract, payment_method
ORDER BY contract, churn_rate_pct DESC;

-- ---------------------------------------------------------------------
-- Q4. SERVICES: among customers WITH internet, Yes vs No for each add-on
--     (excludes the 'No internet service' group so it does not distort the comparison)
-- ---------------------------------------------------------------------
SELECT service, status,
       COUNT(*)                         AS customers,
       SUM(churned)                     AS churners,
       ROUND(100.0 * AVG(churned), 1)   AS churn_rate_pct
FROM (
    SELECT 'Online security'   AS service, online_security   AS status, churned FROM churn.customers WHERE internet_service <> 'No'
    UNION ALL SELECT 'Online backup',     online_backup,     churned FROM churn.customers WHERE internet_service <> 'No'
    UNION ALL SELECT 'Device protection', device_protection, churned FROM churn.customers WHERE internet_service <> 'No'
    UNION ALL SELECT 'Tech support',      tech_support,      churned FROM churn.customers WHERE internet_service <> 'No'
    UNION ALL SELECT 'Streaming TV',      streaming_tv,      churned FROM churn.customers WHERE internet_service <> 'No'
    UNION ALL SELECT 'Streaming movies',  streaming_movies,  churned FROM churn.customers WHERE internet_service <> 'No'
) s
GROUP BY service, status
ORDER BY service, status;

-- ---------------------------------------------------------------------
-- Q5. PRICING: separate price from internet type
-- ---------------------------------------------------------------------
SELECT internet_service, monthly_charges_band,
       COUNT(*)                         AS customers,
       ROUND(100.0 * AVG(churned), 1)   AS churn_rate_pct
FROM churn.v_customers
GROUP BY internet_service, monthly_charges_band
ORDER BY internet_service, MIN(monthly_charges);

-- ---------------------------------------------------------------------
-- Q6. WHY: churn reasons (stated reasons, churned customers only)
-- ---------------------------------------------------------------------
-- By group
SELECT churn_reason_group,
       COUNT(*)                                                    AS churners,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)          AS pct_of_churners
FROM churn.v_customers
WHERE churned = 1
GROUP BY churn_reason_group
ORDER BY churners DESC;

-- Reason group by contract (percent within each contract type)
SELECT contract, churn_reason_group,
       COUNT(*)                                                                 AS churners,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY contract), 1)  AS pct_within_contract
FROM churn.v_customers
WHERE churned = 1
GROUP BY contract, churn_reason_group
ORDER BY contract, churners DESC;

-- Reason group by internet service
SELECT internet_service, churn_reason_group,
       COUNT(*)                                                                         AS churners,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY internet_service), 1)  AS pct_within_service
FROM churn.v_customers
WHERE churned = 1
GROUP BY internet_service, churn_reason_group
ORDER BY internet_service, churners DESC;

-- ---------------------------------------------------------------------
-- Q7. PRIORITISATION: where is the most revenue and value being lost?
--     CLTV is a predicted value, used here only to rank segments.
-- ---------------------------------------------------------------------
SELECT contract, internet_service, payment_method,
       COUNT(*)                                                    AS customers,
       SUM(churned)                                                AS churners,
       ROUND(100.0 * AVG(churned), 1)                              AS churn_rate_pct,
       ROUND(SUM(monthly_charges) FILTER (WHERE churned = 1), 0)   AS churned_monthly_revenue,
       SUM(cltv) FILTER (WHERE churned = 1)                        AS cltv_of_churned
FROM churn.customers
GROUP BY contract, internet_service, payment_method
HAVING COUNT(*) >= 100
ORDER BY churners DESC
LIMIT 10;