WITH matches AS (
  SELECT
    match.taker_order_id,
    match.maker_order_id
  FROM
    `numia-data.dydx_mainnet.dydx_match` match 
  WHERE
    1 = 1
    AND match.block_height < 22064978 
    AND match.perpetual_id is null
),
cancels AS (
  SELECT
    cancel.order_id
  FROM
    `numia-data.dydx_mainnet.dydx_cancel_order` cancel 
  WHERE
    1 = 1
    AND cancel.block_height < 22064978 
    AND cancel.market_id is null
)
SELECT
  match.maker_order_id,
  match.taker_order_id,
  cancel.order_id,
  m.data,
  m.attributes,
  CAST(m.data AS string) AS full_data,
  JSON_EXTRACT_SCALAR(m.attributes, '$.tx_hash') AS tx_hash,
  JSON_EXTRACT_SCALAR(m.attributes, '$.tx_msg_type') AS order_type,
  JSON_EXTRACT_SCALAR(m.attributes, '$.timestamp') AS order_submitted_time,
  m.publish_time AS numia_publish_time,
  CAST(JSON_EXTRACT_SCALAR(CAST(m.data AS string), '$.order.order_id.client_id') AS INT64) AS trade_id,
  JSON_EXTRACT_SCALAR(CAST(m.data AS string), '$.order.order_id.subaccount_id.owner') AS subaccount,
  JSON_EXTRACT_SCALAR(CAST(m.data AS string), '$.order.order_id.clob_pair_id') AS clob_pair_id,
  JSON_EXTRACT_SCALAR(CAST(m.data AS string), '$.order.quantums') AS trade_volume,
  CASE
    WHEN JSON_EXTRACT_SCALAR(CAST(m.data AS string), '$.order.side') = '1' THEN 'buy'
    ELSE 'sell'
  END AS side,
  JSON_EXTRACT_SCALAR(CAST(m.data AS string), '$.order.subticks') AS subticks,
  JSON_EXTRACT_SCALAR(CAST(m.data AS string), '$.order.GoodTilOneof.good_til_block') AS good_til_block,
  JSON_EXTRACT_SCALAR(CAST(m.data AS string), '$.order.GoodTilOneof.good_til_block_time') AS good_til_block_time
FROM
  `numia-data.dydx_mainnet.dydx_mempool_transactions` m
LEFT JOIN
  cancels cancel ON CAST(JSON_EXTRACT_SCALAR(CAST(m.data AS string), '$.order.order_id.client_id') AS INT64) = cancel.order_id
LEFT JOIN
  matches match ON (CAST(JSON_EXTRACT_SCALAR(CAST(m.data AS string), '$.order.order_id.client_id') AS INT64) = match.taker_order_id
    OR CAST(JSON_EXTRACT_SCALAR(CAST(m.data AS string), '$.order.order_id.client_id') AS INT64) = match.maker_order_id)
WHERE
  1 = 1
  AND JSON_EXTRACT_SCALAR(CAST(m.data AS string), '$.order.order_id.subaccount_id.owner') = 'dydx14dltc2w6y3dhf0naz8luglsvjt0vhvswm2j6d0'
  AND JSON_EXTRACT_SCALAR(m.attributes, '$.tx_msg_type') = '/dydxprotocol.clob.MsgPlaceOrder' 
  AND JSON_EXTRACT_SCALAR(CAST(m.data AS string), '$.order.order_id.clob_pair_id') IS NULL   
  AND JSON_EXTRACT_SCALAR(CAST(m.data AS string), '$.order.side') = '2'
   
  AND CAST(JSON_EXTRACT_SCALAR(CAST(m.data AS string), '$.order.GoodTilOneof.good_til_block') AS INT) >= 22064978 
  AND ( CAST(m.publish_time AS STRING) LIKE '2024-08-05 10%'
  OR CAST(m.publish_time AS STRING) LIKE '2024-08-05 09%'
  OR CAST(m.publish_time AS STRING) LIKE '2024-08-05 08%'
  OR CAST(m.publish_time AS STRING) LIKE '2024-08-05 07%'
  OR CAST(m.publish_time AS STRING) LIKE '2024-08-05 06%'
  OR CAST(m.publish_time AS STRING) LIKE '2024-08-05 05%'
  OR CAST(m.publish_time AS STRING) LIKE '2024-08-05 04%')
ORDER BY 
  CAST(m.publish_time AS STRING) ASC 
LIMIT 1000