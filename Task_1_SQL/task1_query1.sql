WITH first_transactions AS (
  SELECT
    uuid
    ,product_id
    ,transaction_id AS original_transaction_id
    ,event_timestamp
    ,ROW_NUMBER() OVER (
      PARTITION BY uuid, product_id 
      ORDER BY event_timestamp
    ) AS number_row
  FROM my-test-project-445920.test_task_data.tasks_1_2
)

SELECT 
  t.uuid
  , t.product_id
  , t.transaction_id
  , f.original_transaction_id
  , ROW_NUMBER() OVER (PARTITION BY f.original_transaction_id ORDER BY t.event_timestamp) - 1 AS renewal_number
  , CASE 
    WHEN refunded_transaction_id IS NOT NULL THEN 0
    ELSE revenue_usd
   END AS revenue_usd_corrected
FROM my-test-project-445920.test_task_data.tasks_1_2 t
LEFT JOIN first_transactions f
  ON t.uuid = f.uuid
  AND t.product_id = f.product_id
  AND f.number_row = 1;
