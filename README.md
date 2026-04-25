# E-Commerce A/B Testing Analysis
### Does Showing Ads Actually Increase Conversions?

![Python](https://img.shields.io/badge/Python-3.10+-blue?logo=python)
![MySQL](https://img.shields.io/badge/MySQL-8.0-orange?logo=mysql)
![PowerBI](https://img.shields.io/badge/Power_BI-Dashboard-yellow?logo=powerbi)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen)

---

## Business Problem

A marketing team ran an experiment: some users saw real **ads**, while others saw a **Public Service Announcement (PSA)** — the control group. The business question:

> **Do the ads significantly increase conversion rates, and if so, by how much?**

---

## Dataset

| Field | Detail |
|---|---|
| Source | [Kaggle — Marketing A/B Testing](https://www.kaggle.com/datasets/faviovaz/marketing-ab-testing) |
| Rows | 588,101 users |
| Columns | user_id, test_group, converted, total_ads, most_ads_day, most_ads_hour |
| Groups | `ad` (564,577 users) vs `psa` control (23,524 users) |

---

## Tools & Skills

| Tool | Used For |
|---|---|
| **MySQL** | Data loading, EDA, window functions, CTEs |
| **Python** | Statistical testing, visualisations |
| **pandas / numpy** | Data manipulation |
| **scipy.stats** | Chi-square significance test |
| **matplotlib / seaborn** | 5 charts |
| **Power BI** | 4-page interactive dashboard |

---

## Key Findings

| Metric | Value |
|---|---|
| Ad group CVR | **2.55%** |
| PSA group CVR (control) | **1.79%** |
| **Relative Lift** | **+43.1%** |
| Chi² statistic | 54.0058 |
| **p-value** | **2.00 × 10⁻¹³** |
| Statistically significant? | ✅ **YES** (p < 0.001) |

### Additional Insights
- **Best day**: Monday shows highest conversion rate
- **Peak hour**: 16:00 (4 PM) has highest conversions
- **Sweet spot**: Users seeing **21–50 ads** convert at the highest rate
- **Diminishing returns**: Conversion rate flattens for users seeing 100+ ads

---

## Project Structure

```
ab_testing_project/
│
├── data/
│   └── AB_Testing_dataset.csv         ← Raw dataset
│
├── sql_queries/
|   └── AB_queries.sql             ← All EDA + window functions
│
├── notebooks/
│   └── a-b-testing-analysis.py         ← Full Python analysis
│
├── assets/
│   ├── chart1_cvr_comparison.png
│   ├── chart2_day_cvr.png
│   ├── chart3_hour_cvr.png
│   ├── chart4_ad_exposure.png
│   └── chart5_heatmap.png
│
├── powerbi_dashboard
│
└── README.md
```

--

## Charts

### Conversion Rate — Ad vs PSA Group
![Chart 1](assets/chart1_cvr_comparison.png)

### Conversion Rate by Day of Week
![Chart 2](assets/chart2_day_cvr.png)

### Conversion Rate by Hour of Day
![Chart 3](assets/chart3_hour_cvr.png)

### Ad Exposure vs Conversion Rate
![Chart 4](assets/chart4_ad_exposure.png)

### Day × Hour Heatmap
![Chart 5](assets/chart5_heatmap.png)

---

## SQL Highlights

Key SQL techniques used in this project:

```sql
-- Window function: rank days by CVR within each test group
WITH daily_group AS (
    SELECT test_group, most_ads_day,
           COUNT(*) AS total_users,
           SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END) AS conversions,
           ROUND(SUM(CASE WHEN converted='TRUE' THEN 1 ELSE 0 END)*100.0/COUNT(*), 4) AS cvr
    FROM ab_test
    GROUP BY test_group, most_ads_day
)
SELECT *,
    RANK() OVER (PARTITION BY test_group ORDER BY cvr DESC) AS rank_by_cvr
FROM daily_group;
```

```sql
-- CTE: calculate lift between groups
WITH group_cvr AS (
    SELECT test_group,
           ROUND(SUM(CASE WHEN converted='TRUE' THEN 1 ELSE 0 END)*100.0/COUNT(*), 4) AS cvr
    FROM ab_test GROUP BY test_group
)
SELECT
    MAX(CASE WHEN test_group='ad'  THEN cvr END) AS ad_cvr,
    MAX(CASE WHEN test_group='psa' THEN cvr END) AS psa_cvr,
    ROUND(
        (MAX(CASE WHEN test_group='ad' THEN cvr END)
       - MAX(CASE WHEN test_group='psa' THEN cvr END))
        * 100.0
        / MAX(CASE WHEN test_group='psa' THEN cvr END), 2
    ) AS lift_pct
FROM group_cvr;
```

---

## Recommendation

The ad campaign produced a **+43.1% relative increase** in conversion rate versus the control group. This is statistically significant at the 95% confidence level (p < 0.001).

**Action items:**
1. Continue the ad campaign — it demonstrably works
2. Concentrate delivery on **Mondays** and **weekends**
3. Schedule peak ad delivery between **14:00–22:00**
4. Optimal ad frequency: **21–50 ads per user** (sweet spot before diminishing returns)

---

## How to Reproduce

```bash
# 1. Clone the repo
git clone https://github.com/Ruchi797/ab-testing-analysis.git
cd ab-testing-analysis

# 2. Install Python dependencies
pip install pandas numpy scipy matplotlib seaborn

# 3. Run analysis
cd notebooks
python ab_testing_analysis.py

# 4. SQL: Open sql_queries/ files in MySQL Workbench
#    Update the file path in 01_create_and_load.sql and run
```

---

## Connect

**Ruchi** | Data Analyst | Pune, India  
[LinkedIn](https://linkedin.com/in/your-profile) · [GitHub](https://github.com/Ruchi797)

