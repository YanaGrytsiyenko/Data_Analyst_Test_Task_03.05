WITH trial_start AS (
  SELECT
    uuid
    , MIN(event_timestamp) AS trial_started_time
  FROM my-test-project-445920.test_task_data.tasks_1_2
  WHERE event_name = 'purchase'
    AND is_trial = TRUE
  GROUP BY uuid
),
first_purchase AS (
  SELECT
    uuid
    , MIN(event_timestamp) AS first_purchase_time
  FROM my-test-project-445920.test_task_data.tasks_1_2
  WHERE event_name = 'purchase'
  GROUP BY uuid
), 
last_purchase_time AS (
  SELECT
    uuid
    , MAX(event_timestamp) AS last_purchase_time
  FROM my-test-project-445920.test_task_data.tasks_1_2
  WHERE event_name = 'purchase'
  GROUP BY uuid
), 
total_purchases AS (
  SELECT
    uuid,
    COUNT(event_name) AS total_purchases
  FROM my-test-project-445920.test_task_data.tasks_1_2
  WHERE event_name = 'purchase'
  GROUP BY uuid
),
total_revenue_usd AS (
  SELECT
    uuid,
    SUM(revenue_usd) AS total_revenue_usd
  FROM my-test-project-445920.test_task_data.tasks_1_2
  GROUP BY uuid
), 
refund_time AS (
  SELECT
    uuid
    , MAX(event_timestamp) AS refund_time
  FROM my-test-project-445920.test_task_data.tasks_1_2
  WHERE event_name = 'refund'
  GROUP BY uuid
),
cancelation_time AS (
  SELECT
    uuid,
    MAX(event_timestamp) AS cancelation_time
  FROM my-test-project-445920.test_task_data.tasks_1_2
  WHERE event_name = 'cancellation'
  GROUP BY uuid
), 
latest_purchase AS (
  SELECT
    uuid,
    product_id AS current_product_id,
    event_timestamp,
    period,
    trial_period,
    is_trial,
    CASE 
      WHEN is_trial = TRUE THEN trial_period
      ELSE period
    END AS duration_days,
    ROW_NUMBER() OVER (
      PARTITION BY uuid
      ORDER BY event_timestamp DESC
    ) AS row_num
  FROM my-test-project-445920.test_task_data.tasks_1_2
  WHERE event_name = 'purchase'
)

SELECT
  fp.uuid
  , lp.current_product_id
  , lp.duration_days
  , ts.trial_started_time
  , fp.first_purchase_time
  , lpt.last_purchase_time
  , tp.total_purchases
  , tr.total_revenue_usd
  , ct.cancelation_time
  , rt.refund_time
FROM first_purchase fp
LEFT JOIN latest_purchase lp
  ON fp.uuid = lp.uuid AND lp.row_num = 1
LEFT JOIN trial_start ts
  ON fp.uuid = ts.uuid
LEFT JOIN last_purchase_time lpt
  ON fp.uuid = lpt.uuid
LEFT JOIN total_purchases tp
  ON fp.uuid = tp.uuid
LEFT JOIN total_revenue_usd tr
  ON fp.uuid = tr.uuid
LEFT JOIN cancelation_time ct
  ON fp.uuid = ct.uuid
LEFT JOIN refund_time rt
  ON fp.uuid = rt.uuid
ORDER BY fp.uuid;
