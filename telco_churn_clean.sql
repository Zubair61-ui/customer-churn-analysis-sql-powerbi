-- =====================================================================
-- Telco Customer Churn (IBM dataset): PostgreSQL setup, load, clean
-- Adjust names if CSV header differs.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. SCHEMA
-- ---------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS churn;

-- ---------------------------------------------------------------------
-- 1. STAGING TABLE (everything as TEXT so the import cannot fail on formats)
--    Column ORDER must match the CSV exactly (33 columns).
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS churn.stg_customers;
CREATE TABLE churn.stg_customers (
    customer_id        TEXT,
    row_count          TEXT,   -- source column "Count"
    country            TEXT,
    state              TEXT,
    city               TEXT,
    zip_code           TEXT,
    lat_long           TEXT,
    latitude           TEXT,
    longitude          TEXT,
    gender             TEXT,
    senior_citizen     TEXT,
    partner            TEXT,
    dependents         TEXT,
    tenure_months      TEXT,
    phone_service      TEXT,
    multiple_lines     TEXT,
    internet_service   TEXT,
    online_security    TEXT,
    online_backup      TEXT,
    device_protection  TEXT,
    tech_support       TEXT,
    streaming_tv       TEXT,
    streaming_movies   TEXT,
    contract           TEXT,
    paperless_billing  TEXT,
    payment_method     TEXT,
    monthly_charges    TEXT,
    total_charges      TEXT,
    churn_label        TEXT,
    churn_value        TEXT,
    churn_score        TEXT,
    cltv               TEXT,
    churn_reason       TEXT
);

-- ---------------------------------------------------------------------
-- 2. LOAD THE CSV  (use the CSV UTF-8 you saved from the UNTOUCHED original)
--
-- Option A (easiest): pgAdmin -> right-click churn.stg_customers ->
--   Import/Export Data -> Import; Filename = your CSV; Format = csv;
--   Header = ON; Delimiter = ,; Encoding = UTF8.
--
-- Option B: psql (single line, forward slashes, even on Windows):
COPY churn.stg_customers 
FROM 'C:\Users\Public\Telco_customer_churn.csv' 
WITH (FORMAT csv, HEADER true);
-- ---------------------------------------------------------------------
-- ---------------------------------------------------------------------
-- 3. VALIDATE THE LOAD
-- ---------------------------------------------------------------------
-- EXPECT: 7043 rows and 7043 distinct customers
SELECT COUNT(*) AS rows_loaded,
       COUNT(DISTINCT customer_id) AS distinct_customers
FROM churn.stg_customers;

-- EXPECT: 1869 churners and 26.54 percent
SELECT COUNT(*) FILTER (WHERE churn_label = 'Yes') AS churners,
       ROUND(100.0 * COUNT(*) FILTER (WHERE churn_label = 'Yes') / COUNT(*), 2) AS churn_pct
FROM churn.stg_customers;

-- EXPECT: 5174 customers with no churn reason (the retained customers)
SELECT COUNT(*) AS no_reason
FROM churn.stg_customers
WHERE NULLIF(TRIM(churn_reason), '') IS NULL;

-- ---------------------------------------------------------------------
-- 4. PROFILE BEFORE CLEANING
-- ---------------------------------------------------------------------
-- 4a. Columns that look constant or redundant (confirm before dropping)
-- EXPECT: 1, 1, and 1 / 1 for row_count if they are truly constant
SELECT COUNT(DISTINCT country)   AS countries,
       COUNT(DISTINCT state)     AS states,
       MIN(row_count)            AS min_count,
       MAX(row_count)            AS max_count
FROM churn.stg_customers;

-- 4b. Churn Label and Churn Value must agree
-- EXPECT: only (Yes,1) and (No,0)
SELECT churn_label, churn_value, COUNT(*)
FROM churn.stg_customers
GROUP BY 1, 2;

-- 4c. Distinct values of the categorical columns
SELECT 'contract' AS col, contract AS val, COUNT(*) FROM churn.stg_customers GROUP BY 2
UNION ALL SELECT 'internet_service', internet_service, COUNT(*) FROM churn.stg_customers GROUP BY 2
UNION ALL SELECT 'payment_method', payment_method, COUNT(*) FROM churn.stg_customers GROUP BY 2
UNION ALL SELECT 'multiple_lines', multiple_lines, COUNT(*) FROM churn.stg_customers GROUP BY 2
UNION ALL SELECT 'online_security', online_security, COUNT(*) FROM churn.stg_customers GROUP BY 2
UNION ALL SELECT 'senior_citizen', senior_citizen, COUNT(*) FROM churn.stg_customers GROUP BY 2
UNION ALL SELECT 'paperless_billing', paperless_billing, COUNT(*) FROM churn.stg_customers GROUP BY 2
ORDER BY 1, 3 DESC;

-- 4d. Numeric sanity (casts defensively; NULLs here mean blanks or text)
SELECT MIN(NULLIF(TRIM(tenure_months), '')::INT)            AS min_tenure,
       MAX(NULLIF(TRIM(tenure_months), '')::INT)            AS max_tenure,
       MIN(NULLIF(TRIM(monthly_charges), '')::NUMERIC)      AS min_monthly,
       MAX(NULLIF(TRIM(monthly_charges), '')::NUMERIC)      AS max_monthly,
       COUNT(*) FILTER (WHERE NULLIF(TRIM(total_charges), '') IS NULL) AS blank_total_charges,
       COUNT(*) FILTER (WHERE TRIM(tenure_months) = '0')    AS tenure_zero_customers
FROM churn.stg_customers;

-- ---------------------------------------------------------------------
-- 5. CLEAN TABLE (typed, renamed, redundant columns dropped)
--    Dropped: row_count, country, state, lat_long, churn_value
--    (only run this after confirming 4a and 4b)
-- ---------------------------------------------------------------------
DROP VIEW  IF EXISTS churn.v_customers;
DROP TABLE IF EXISTS churn.customers;
CREATE TABLE churn.customers (
    customer_id        TEXT PRIMARY KEY,
    city               TEXT,
    zip_code           TEXT,            -- text, not a number
    latitude           NUMERIC(9,6),
    longitude          NUMERIC(9,6),
    gender             TEXT,
    senior_citizen     TEXT,            -- 'Yes' / 'No'
    partner            TEXT,
    dependents         TEXT,
    tenure_months      INT,
    phone_service      TEXT,
    multiple_lines     TEXT,            -- Yes / No / No phone service
    internet_service   TEXT,            -- DSL / Fiber optic / No
    online_security    TEXT,            -- Yes / No / No internet service
    online_backup      TEXT,
    device_protection  TEXT,
    tech_support       TEXT,
    streaming_tv       TEXT,
    streaming_movies   TEXT,
    contract           TEXT,
    paperless_billing  TEXT,
    payment_method     TEXT,
    monthly_charges    NUMERIC(8,2),
    total_charges      NUMERIC(10,2),
    churned            SMALLINT NOT NULL CHECK (churned IN (0, 1)),  -- 1 = churned
    churn_score        INT,             -- IBM model output: context only, not a driver
    cltv               INT,             -- predicted lifetime value
    churn_reason       TEXT             -- NULL for customers who stayed (not missing data)
);

INSERT INTO churn.customers
SELECT
    TRIM(customer_id),
    NULLIF(TRIM(city), ''),
    NULLIF(TRIM(zip_code), ''),
    NULLIF(TRIM(latitude), '')::NUMERIC(9,6),
    NULLIF(TRIM(longitude), '')::NUMERIC(9,6),
    NULLIF(TRIM(gender), ''),
    NULLIF(TRIM(senior_citizen), ''),
    NULLIF(TRIM(partner), ''),
    NULLIF(TRIM(dependents), ''),
    NULLIF(TRIM(tenure_months), '')::INT,
    NULLIF(TRIM(phone_service), ''),
    NULLIF(TRIM(multiple_lines), ''),
    NULLIF(TRIM(internet_service), ''),
    NULLIF(TRIM(online_security), ''),
    NULLIF(TRIM(online_backup), ''),
    NULLIF(TRIM(device_protection), ''),
    NULLIF(TRIM(tech_support), ''),
    NULLIF(TRIM(streaming_tv), ''),
    NULLIF(TRIM(streaming_movies), ''),
    NULLIF(TRIM(contract), ''),
    NULLIF(TRIM(paperless_billing), ''),
    NULLIF(TRIM(payment_method), ''),
    NULLIF(TRIM(monthly_charges), '')::NUMERIC(8,2),
    NULLIF(TRIM(total_charges), '')::NUMERIC(10,2),
    CASE WHEN TRIM(churn_label) = 'Yes' THEN 1 ELSE 0 END,
    NULLIF(TRIM(churn_score), '')::INT,
    NULLIF(TRIM(cltv), '')::INT,
    NULLIF(TRIM(churn_reason), '')
FROM churn.stg_customers;

-- EXPECT: 7043 rows, 1869 churners, 1869 reasons, same 26.54 percent
SELECT COUNT(*)                                  AS customers,
       SUM(churned)                              AS churners,
       COUNT(churn_reason)                       AS reasons_filled,
       ROUND(100.0 * AVG(churned), 2)            AS churn_pct
FROM churn.customers;

-- ---------------------------------------------------------------------
-- 6. REASON CATEGORIES: LOOK AT THE DISTINCT REASONS FIRST
-- ---------------------------------------------------------------------
SELECT churn_reason, COUNT(*) AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_churners
FROM churn.customers
WHERE churned = 1
GROUP BY 1
ORDER BY 2 DESC;

-- ---------------------------------------------------------------------
-- 7. ANALYSIS VIEW (Power BI connects to this)
--    DRAFT reason groups: check the list from step 6, then adjust the
--    CASE patterns until the 'Other' group is small.
-- ---------------------------------------------------------------------
CREATE VIEW churn.v_customers AS
SELECT
    c.*,
    CASE WHEN c.churned = 1 THEN 'Churned' ELSE 'Retained' END AS churn_status,
    CASE
        WHEN tenure_months <= 12 THEN '0-12 months'
        WHEN tenure_months <= 24 THEN '13-24 months'
        WHEN tenure_months <= 48 THEN '25-48 months'
        ELSE '49+ months'
    END AS tenure_band,
    CASE
        WHEN monthly_charges < 35 THEN 'Under 35'
        WHEN monthly_charges < 70 THEN '35-70'
        WHEN monthly_charges < 95 THEN '70-95'
        ELSE '95+'
    END AS monthly_charges_band,
    CASE
        WHEN churn_reason IS NULL                                   THEN NULL
        WHEN churn_reason ILIKE 'Competitor%'                       THEN 'Competitor'
        WHEN churn_reason ILIKE '%attitude%'
          OR churn_reason ILIKE '%support%'                         THEN 'Support / service attitude'
        WHEN churn_reason ILIKE '%price%'
          OR churn_reason ILIKE '%charges%'
          OR churn_reason ILIKE '%afford%'                          THEN 'Price / charges'
        WHEN churn_reason ILIKE '%dissatisf%'
          OR churn_reason ILIKE '%network%'
          OR churn_reason ILIKE '%range of services%'
          OR churn_reason ILIKE '%self-service%'                    THEN 'Product / service'
        WHEN churn_reason ILIKE '%moved%'
          OR churn_reason ILIKE '%deceased%'                        THEN 'Life event'
        WHEN churn_reason ILIKE 'Don''t know%'                      THEN 'Unknown'
        ELSE 'Other'
    END AS churn_reason_group
FROM churn.customers c;

-- Check how many reasons fall into 'Other' (aim for a small number)
SELECT churn_reason_group, COUNT(*)
FROM churn.v_customers
WHERE churned = 1
GROUP BY 1
ORDER BY 2 DESC;

-- ---------------------------------------------------------------------
-- 8. STARTER ANALYSIS: churn RATE vs share of churners, side by side
--    churn_rate_pct      = % of customers IN this segment who left
--    share_of_churners   = % of ALL churners who belong to this segment
-- ---------------------------------------------------------------------
SELECT contract,
       COUNT(*)                                              AS customers,
       SUM(churned)                                          AS churners,
       ROUND(100.0 * AVG(churned), 1)                        AS churn_rate_pct,
       ROUND(100.0 * SUM(churned) /
             (SELECT SUM(churned) FROM churn.customers), 1)  AS share_of_churners_pct
FROM churn.customers
GROUP BY contract
ORDER BY churn_rate_pct DESC;

-- Same pattern for: internet_service, payment_method, senior_citizen,
-- paperless_billing, tenure_band, monthly_charges_band (use churn.v_customers
-- for the two band columns).
-- Internet Service
SELECT 
    internet_service,
    COUNT(*) AS customers,
    SUM(churned) AS churners,
    ROUND(100.0 * AVG(churned), 1) AS churn_rate_pct,
    ROUND(100.0 * SUM(churned) / (SELECT SUM(churned) FROM churn.customers), 1) AS share_of_churners_pct
FROM churn.customers
GROUP BY internet_service
ORDER BY churn_rate_pct DESC;
-- Payment Method
SELECT 
    payment_method,
    COUNT(*) AS customers,
    SUM(churned) AS churners,
    ROUND(100.0 * AVG(churned), 1) AS churn_rate_pct,
    ROUND(100.0 * SUM(churned) / (SELECT SUM(churned) FROM churn.customers), 1) AS share_of_churners_pct
FROM churn.customers
GROUP BY payment_method
ORDER BY churn_rate_pct DESC;
-- Senior Citizen
SELECT 
    senior_citizen,
    COUNT(*) AS customers,
    SUM(churned) AS churners,
    ROUND(100.0 * AVG(churned), 1) AS churn_rate_pct,
    ROUND(100.0 * SUM(churned) / (SELECT SUM(churned) FROM churn.customers), 1) AS share_of_churners_pct
FROM churn.customers
GROUP BY senior_citizen
ORDER BY churn_rate_pct DESC;
-- Paperless Billing 
SELECT 
    paperless_billing,
    COUNT(*) AS customers,
    SUM(churned) AS churners,
    ROUND(100.0 * AVG(churned), 1) AS churn_rate_pct,
    ROUND(100.0 * SUM(churned) / (SELECT SUM(churned) FROM churn.customers), 1) AS share_of_churners_pct
FROM churn.customers
GROUP BY paperless_billing
ORDER BY churn_rate_pct DESC;
-- Tenure Band
SELECT 
    tenure_band,
    COUNT(*) AS customers,
    SUM(churned) AS churners,
    ROUND(100.0 * AVG(churned), 1) AS churn_rate_pct,
    ROUND(100.0 * SUM(churned) / (SELECT SUM(churned) FROM churn.v_customers), 1) AS share_of_churners_pct
FROM churn.v_customers
GROUP BY tenure_band
ORDER BY churn_rate_pct DESC;
-- Monthly Charges Band
SELECT 
    monthly_charges_band,
    COUNT(*) AS customers,
    SUM(churned) AS churners,
    ROUND(100.0 * AVG(churned), 1) AS churn_rate_pct,
    ROUND(100.0 * SUM(churned) / (SELECT SUM(churned) FROM churn.v_customers), 1) AS share_of_churners_pct
FROM churn.v_customers
GROUP BY monthly_charges_band
ORDER BY churn_rate_pct DESC;


-- Revenue at stake: churned monthly revenue and share of total
SELECT SUM(monthly_charges) FILTER (WHERE churned = 1)                  AS churned_monthly_revenue,
       ROUND(100.0 * SUM(monthly_charges) FILTER (WHERE churned = 1)
             / SUM(monthly_charges), 1)                                 AS revenue_churn_pct
FROM churn.customers;