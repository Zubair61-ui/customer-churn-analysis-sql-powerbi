# Customer Churn Analysis: Who Leaves and Why

An end-to-end analysis of telecom customer churn using **Excel** (profiling), **PostgreSQL** (cleaning and analysis) and **Power BI** (5-page interactive dashboard).

**Author:** Zubair Hashmat | **Contact:** hashmatzubair32@gmail.com | **Dashboard PDF:** [link]

![Dashboard overview](images/01_overview.png)

---

## Executive Summary

Of the 7,043 customers in the IBM Telco sample dataset, **26.5% (1,869) churned**, and they accounted for **30.5% of monthly revenue** because churners pay more on average (74.44 vs 61.27 per month) and leave after about half the tenure of retained customers (18.0 vs 37.6 months). Churn is concentrated: **month-to-month customers are 88.6% of churners**, customers in their first year churn at 47.4%, and fiber optic customers churn at 41.9% against 19.0% for DSL, with a seven-fold gap between the two even at similar bills (48.2% vs 6.8% in the 70-95 charge band). One segment, **month-to-month fiber customers paying by electronic check**, is 18.6% of customers but 42.2% of churners and about 49% of lost monthly revenue. Among customers who left, a third cite a competitor (33.2%), and the attitude of the support person is the most common single reason (10.3%). All findings are associations from a one-quarter snapshot, not causal claims.

## Business Problem and Questions

A telecom provider is losing customers and does not know which ones or why. This project answers:

1. How many customers churn, and how much revenue does that represent?
2. Who churns (customer profile)?
3. Which account, service and pricing factors are associated with churn?
4. What reasons do churned customers give?
5. Which customer segments should the retention team prioritise?

The scope, KPIs and assumptions are in the [Business Requirements Document](docs/BRD.pdf).

## Data

| Item | Detail |
|---|---|
| Source | [Telco Customer Churn: IBM dataset (Kaggle)](https://www.kaggle.com/datasets/yeanzc/telco-customer-churn-ibm-dataset) |
| Size | 7,043 customers, 33 columns, one row per customer |
| Content | Demographics, location, services, account and billing details, churn label, IBM churn score, CLTV and churn reason |
| Target | Churn label (customer left during the quarter): 1,869 churned, 5,174 retained |

## Tools and Workflow

| Step | Tool | Output |
|---|---|---|
| 1. Requirements | Document | Business Requirements Document |
| 2. Profile | Excel (working copy; raw file untouched) | Row count, blanks, early pivot-table hypotheses |
| 3. Load and clean | PostgreSQL | Staging table, clean typed table, analysis views |
| 4. Analyse | PostgreSQL | Queries answering each business question |
| 5. Visualise | Power BI Desktop, DAX | 5-page dashboard |

## Dashboard

| Page | What it shows |
|---|---|
| **Overview** | Headline KPIs, churn rate by contract and tenure, key takeaways |
| **Customer profile** | Churn by age group, partner, dependents, gender and city |
| **Drivers** | Contract x tenure and internet service x charges matrices, payment method, add-on services |
| **Reasons** | Churn reasons grouped and individual, reason mix by contract, with slicers |
| **Priority segments** | The ten segments losing the most customers and revenue |

![Drivers page](images/03_drivers.png)
![Priority segments page](images/05_priority_segments.png)

## Key Findings

*Churn rate = % of customers in a group who churned. Company average = 26.5%.*

### Headline numbers
| Measure | Value |
|---|---|
| Customers / churned | 7,043 / 1,869 |
| Churn rate | 26.54% |
| Monthly revenue lost to churn | 139,130.85 (30.5% of total) |
| Average tenure, churned vs retained | 18.0 vs 37.6 months |
| Average monthly charge, churned vs retained | 74.44 vs 61.27 |

### Who churns
- **Seniors** churn at 41.7% vs 23.6% for non-seniors (16% of customers but 25.5% of churners).
- Customers **without a partner** churn at 33.0% (with a partner: 19.7%), and **without dependents** at 32.6% (with dependents: 6.5%).
- Women and men churn at similar rates (26.9% and 26.2%).

### What is associated with churn
| Factor | Churn rate |
|---|---|
| Contract: month-to-month / one year / two year | 42.7% / 11.3% / 2.8% |
| Tenure: 0-12 / 13-24 / 25-48 / 49+ months | 47.4% / 28.7% / 20.4% / 9.5% |
| Internet service: fiber optic / DSL / none | 41.9% / 19.0% / 7.4% |
| Payment: electronic check / mailed check / bank transfer / credit card | 45.3% / 19.1% / 16.7% / 15.2% |
| Paperless billing: yes / no | 33.6% / 16.3% |

- **It is the contract, not just newness.** Month-to-month churn falls with tenure (51.4%, 37.7%, 32.9%, 26.0%) but stays far above one-year (8.1-12.9%) and two-year (0-3.3%) contracts at every tenure. First-year month-to-month customers are 28% of customers but 55% of churners.
- **Fiber looks like its own problem, not a price problem.** Within each internet type, churn falls as the bill rises (DSL: 36.6%, 21.2%, 6.8%; fiber: 61.0%, 48.2%, 32.3%). In the same 70-95 band, fiber churns at 48.2% and DSL at 6.8%.
- **Add-ons show a large gap** among internet customers: no online security 41.8% vs 14.6% with it; no tech support 41.6% vs 15.2%. Backup and device protection show smaller gaps; streaming barely matters (about 3-4 points).
- Factors overlap heavily and customers who buy add-ons may simply be more committed, so these are associations only.

### Why customers say they left (1,869 churned customers)
| Reason group | Churners | Share |
|---|---|---|
| Competitor (better offer, speeds, data, devices) | 621 | 33.2% |
| Product / service | 426 | 22.8% |
| Support / service attitude | 366 | 19.6% |
| Price / charges | 243 | 13.0% |
| Unknown ("Don't know") | 154 | 8.2% |
| Life event (moved, deceased) | 59 | 3.2% |

The attitude of the support person is the most common single reason (192 customers, 10.3%). Competitors lead in all three contract types (32.8%, 35.5% and 39.6% for month-to-month, one-year and two-year; the latter two groups are small).

### Where to focus
| Segment (contract / internet / payment) | Customers | Churned | Churn rate | Monthly revenue lost |
|---|---|---|---|---|
| Month-to-month / Fiber optic / Electronic check | 1,307 | 789 | 60.4% | 68,282 |
| Month-to-month / DSL / Electronic check | 474 | 192 | 40.5% | 8,776 |
| Month-to-month / Fiber optic / Bank transfer (automatic) | 327 | 149 | 45.6% | 13,062 |

The top ten segments (100+ customers each) hold 55% of customers but **1,674 of 1,869 churners (about 90%)**, and nine of the ten are month-to-month. Month-to-month fiber customers churn at 41.6% to 60.4% whichever way they pay, while month-to-month DSL customers range from 19.8% to 40.5%.

### Ideas to test (hypotheses, not conclusions)
Onboarding support for new month-to-month customers, contract-upgrade offers, bundling online security or tech support, a review of the fiber service against competitor speeds, and moving electronic check customers to automatic payment. This dataset cannot show whether any of these would reduce churn.

## Data Cleaning Log

| Step | Issue | Decision |
|---|---|---|
| 1 | Profiling in Excel: 7,043 rows, no duplicate customer IDs, no blanks apart from Churn Reason | Excel used for profiling only; the file was not edited. |
| 2 | Churn Reason blank for 5,174 customers | These are exactly the retained customers (7,043 - 1,869), so the blanks are structural, not missing data. Kept as NULL; reasons analysed for churned customers only. |
| 3 | 11 blank Total Charges (missed by the Excel check, found in SQL) | All have tenure 0: new customers not yet billed, all retained. Kept as NULL, not set to 0. |
| 4 | Redundant or constant columns | Dropped Count, Country and State (constant), Lat Long (duplicates latitude and longitude) and Churn Value (agrees with Churn Label on every row). |
| 5 | Everything loaded as text first | Staging table of text columns, then a typed clean table with casts, trimmed values and a primary key; checked 7,043 rows, 1,869 churners and 26.54% after the load. |
| 6 | "No internet service" / "No phone service" overlap with "No" | Kept as a separate category. Add-on comparisons use internet customers only, so these customers do not distort Yes vs No. |
| 7 | Churn Score and CLTV | Churn Score is IBM's own model output, so it is not treated as a driver. CLTV is a predicted value, used only to rank segments. |
| 8 | Derived fields | Churned flag (1/0), tenure bands, monthly-charge bands and six churn-reason groups (the grouping of the 20 reasons is the analyst's own and is documented in the SQL). |
| 9 | Power BI sort order | Band sort columns built from the underlying numbers (not the band text) to avoid a circular dependency; reason groups sorted by size. |

## Limitations

- **Correlation is not causation.** Every finding is an association, and the segments overlap, so effects should not be added together.
- **One-quarter snapshot.** The churn label shows who left during the quarter, so trends over time cannot be shown.
- **Stated reasons.** Churn reasons exist only for customers who left, so they rank complaints and cannot be compared with customers who stayed. The six reason groups are an analyst categorisation, and some assignments are judgement calls (for example, affordability of download speed counted as price).
- **Small groups.** For example, two-year customers in their first 24 months (68 and 90 customers) show 0% churn, and fiber customers paying 35-70 are only 105. Contract terms can also lock customers in, so low churn does not necessarily mean higher satisfaction.
- **Analyst-chosen bands.** Tenure and charge band cut-offs are my own, and the price pattern is not a straight line.
- **Predicted fields.** CLTV and Churn Score are model outputs from the source data.
- **Sample data.** This is a fictional IBM sample dataset, so results illustrate the method, not a real company. The currency of the charges is not stated in the dataset.
- **Typed dashboard text.** The insight panels on the dashboard are written text, so they do not update if the data or filters change.
- **No predictive model.** This is descriptive analysis only.

## Repository Structure

```
customer-churn-analysis/
├── README.md
├── docs/
│   └── BRD.pdf                      # business requirements document
├── data/
│   └── README.md                    # how to download the dataset (not committed)
├── sql/
│   ├── 01_setup_and_clean.sql       # staging, load, validation, clean table, views
│   └── 02_analysis.sql              # analysis queries and segment summary view
├── powerbi/
│   └── churn_dashboard.pbix
├── exports/
│   └── churn_dashboard.pdf
└── images/                          # dashboard screenshots used in this README
```

## How to Reproduce

1. Download the dataset from [Kaggle](https://www.kaggle.com/datasets/yeanzc/telco-customer-churn-ibm-dataset) (free login) and save it as a CSV (UTF-8).
2. In PostgreSQL, create a database (for example `telco_churn`) and run `sql/01_setup_and_clean.sql` section by section. Compare each result with the EXPECT notes (7,043 rows, 1,869 churners, 26.54%, 5,174 blank reasons).
3. Run `sql/02_analysis.sql` to create the segment summary view and the analysis queries.
4. Open `powerbi/churn_dashboard.pbix` in Power BI Desktop (Windows), then use **Transform data, Data source settings** to point it at your PostgreSQL server and database.

## Possible Extensions

- Build a predictive churn model and compare its drivers with these findings.
- Test the retention ideas above with an experiment or a longer dataset.
- Add a monthly time dimension if multi-period data is available.
- Weight reason groups by revenue or CLTV, not just customer counts.
