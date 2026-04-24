 USE ab_testing_db;
 
 CREATE TABLE ab_test (
    row_id        INT,
    user_id       BIGINT,
    test_group    VARCHAR(10),  
    converted     VARCHAR(5),   
    total_ads     INT,
    most_ads_day  VARCHAR(10),
    most_ads_hour TINYINT);
 
 SET PERSIST local_infile=1;
 SHOW GLOBAL VARIABLES LIKE 'local_infile';
   
LOAD DATA LOCAL INFILE 'C:/Users/DeLL/OneDrive/Documents/AB_testing_data.csv'
INTO TABLE ab_test
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(row_id, user_id, test_group, converted, total_ads, most_ads_day, most_ads_hour);

SELECT COUNT(*) AS total_rows FROM ab_test; 

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT user_id) AS unique_users
FROM ab_test;

SELECT
    test_group,
    COUNT(*) AS users,
    SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END) AS conversions,
    ROUND(SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 4) AS cvr_pct
FROM ab_test
GROUP BY test_group;

#EDA
SELECT
    SUM(CASE WHEN user_id       IS NULL THEN 1 ELSE 0 END) AS null_user_id,
    SUM(CASE WHEN test_group    IS NULL THEN 1 ELSE 0 END) AS null_test_group,
    SUM(CASE WHEN converted     IS NULL THEN 1 ELSE 0 END) AS null_converted,
    SUM(CASE WHEN total_ads     IS NULL THEN 1 ELSE 0 END) AS null_total_ads,
    SUM(CASE WHEN most_ads_day  IS NULL THEN 1 ELSE 0 END) AS null_most_ads_day,
    SUM(CASE WHEN most_ads_hour IS NULL THEN 1 ELSE 0 END) AS null_most_ads_hour
FROM ab_test;

-- To find out how many users are in each test group
SELECT
    test_group,
    COUNT(*)                                   AS total_users,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM ab_test
GROUP BY test_group;

 -- overall conversion rate
 SELECT 
 COUNT(*) AS total_users,
 SUM(CASE WHEN converted='TRUE' THEN 1 ELSE 0 END) AS total_converted,
 ROUND(SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END)*100.0/COUNT(*), 4) AS overall_conversion_rate_pct
 FROM ab_test;

-- Total ads statistics
SELECT
    MIN(total_ads)                   AS min_ads,
    MAX(total_ads)                   AS max_ads,
    ROUND(AVG(total_ads), 2)         AS avg_ads,
    ROUND(STDDEV(total_ads), 2)      AS stddev_ads
FROM ab_test;
 
--  Conversion rate: ad group vs psa (control) group
SELECT
    test_group,
    COUNT(*)                                                         AS total_users,
    SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END)             AS conversions,
    SUM(CASE WHEN converted = 'FALSE' THEN 1 ELSE 0 END)            AS non_conversions,
    ROUND(
        SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 4)                                       AS conversion_rate_pct
FROM ab_test
GROUP BY test_group
ORDER BY conversion_rate_pct DESC;

-- Lift calculation — how much better is the ad group vs control
WITH group_cvr AS (
SELECT
        test_group,
        ROUND(SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END)
            * 100.0 / COUNT(*), 4) AS cvr
    FROM ab_test
    GROUP BY test_group)
    
SELECT
    MAX(CASE WHEN test_group = 'ad'  THEN cvr END) AS ad_cvr,
    MAX(CASE WHEN test_group = 'psa' THEN cvr END) AS psa_cvr,
    ROUND((MAX(CASE WHEN test_group = 'ad'  THEN cvr END)
       - MAX(CASE WHEN test_group = 'psa' THEN cvr END))
        * 100.0/ MAX(CASE WHEN test_group = 'psa' THEN cvr END),
    2) AS lift_pct
FROM group_cvr;

--  Conversion rate by day of week
SELECT
    most_ads_day,
    COUNT(*) AS total_users,
    SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END)  AS conversions,
    ROUND(SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 4)  AS conversion_rate_pct
FROM ab_test
GROUP BY most_ads_day
ORDER BY conversion_rate_pct DESC;

--  Conversion rate by hour of day
SELECT
    most_ads_hour,
    COUNT(*)  AS total_users,
    SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END) AS conversions,
    ROUND(SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END)* 100.0 / COUNT(*), 4) AS conversion_rate_pct
FROM ab_test
GROUP BY most_ads_hour
ORDER BY conversion_rate_pct DESC;

-- Best hour per test group (using WINDOW FUNCTION → interview-worthy!)
WITH hourly_cvr AS (
    SELECT
        test_group,
        most_ads_hour,
        COUNT(*)   AS total_users,
        SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END)  AS conversions,
        ROUND(SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END)* 100.0 / COUNT(*), 4)   AS cvr
    FROM ab_test
    GROUP BY test_group, most_ads_hour
),
ranked AS (
    SELECT *,
        RANK() OVER (PARTITION BY test_group ORDER BY cvr DESC)         AS rnk
    FROM hourly_cvr
)
SELECT test_group, most_ads_hour, total_users, conversions, cvr
FROM ranked
WHERE rnk = 1;

--  Day + Group heatmap data 
SELECT
    test_group,
    most_ads_day,
    COUNT(*) AS total_users,
    SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END) AS conversions,
    ROUND(SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END)* 100.0 / COUNT(*), 4) AS cvr
FROM ab_test
GROUP BY test_group, most_ads_day
ORDER BY test_group, cvr DESC;

-- Bucket users by number of ads seen (CASE WHEN binning)
SELECT
    CASE
        WHEN total_ads BETWEEN 1  AND 5   THEN '1-5 ads'
        WHEN total_ads BETWEEN 6  AND 20  THEN '6-20 ads'
        WHEN total_ads BETWEEN 21 AND 50  THEN '21-50 ads'
        WHEN total_ads BETWEEN 51 AND 100 THEN '51-100 ads'
        ELSE '100+ ads'
    END   AS ad_exposure_bucket,
    COUNT(*)  AS total_users,
    SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END) AS conversions,
    ROUND(SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END)* 100.0 / COUNT(*), 4)  AS conversion_rate_pct
FROM ab_test
WHERE test_group = 'ad'
GROUP BY ad_exposure_bucket
ORDER BY MIN(total_ads);

--  Average ads seen: converters vs non-converters
SELECT
    converted,
    COUNT(*)                     AS users,
    ROUND(AVG(total_ads), 2)     AS avg_ads_seen,
    MIN(total_ads)               AS min_ads,
    MAX(total_ads)               AS max_ads
FROM ab_test
GROUP BY converted;

-- Running total of conversions by hour (for trend chart)
WITH hourly AS (
    SELECT
        most_ads_hour,
        SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END) AS conversions
    FROM ab_test
    GROUP BY most_ads_hour
)
SELECT
    most_ads_hour,
    conversions,
    SUM(conversions) OVER (ORDER BY most_ads_hour ROWS UNBOUNDED PRECEDING) AS running_total
FROM hourly
ORDER BY most_ads_hour;

-- Rank days by conversion rate within each test group
WITH daily_group AS (
    SELECT
        test_group,
        most_ads_day,
        COUNT(*) AS total_users,
        SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END)  AS conversions,
        ROUND(SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END)* 100.0 / COUNT(*), 4) AS cvr
    FROM ab_test
    GROUP BY test_group, most_ads_day
)
SELECT
    test_group,
    most_ads_day,
    total_users,
    conversions,
    cvr,
    RANK() OVER (PARTITION BY test_group ORDER BY cvr DESC) AS rank_by_cvr,
    ROW_NUMBER() OVER (PARTITION BY test_group ORDER BY total_users DESC) AS rank_by_volume
FROM daily_group;

--  Percentile buckets — what % of the ad group sits in each CVR decile?
SELECT
    CASE
        WHEN total_ads <= 4  THEN 'Bottom 25%'
        WHEN total_ads <= 13 THEN '25-50th pct'
        WHEN total_ads <= 27 THEN '50-75th pct'
        ELSE 'Top 25%'
    END   AS ad_volume_quartile,
    COUNT(*) AS users,
    SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END)  AS conversions,
    ROUND(SUM(CASE WHEN converted = 'TRUE' THEN 1 ELSE 0 END)* 100.0 / COUNT(*), 4) AS cvr
FROM ab_test
WHERE test_group = 'ad'
GROUP BY ad_volume_quartile
ORDER BY MIN(total_ads);





