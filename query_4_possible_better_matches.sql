WITH
  mempool AS (
  SELECT
    m.attributes,
    CAST(m.data AS string) AS full_data,
    JSON_EXTRACT_SCALAR(m.attributes, '$.tx_hash') AS tx_hash,
    JSON_EXTRACT_SCALAR(m.attributes, '$.tx_msg_type') AS order_type,
    JSON_EXTRACT_SCALAR(m.attributes, '$.timestamp') AS order_submitted_time,
    m.publish_time AS numia_publish_time,
    (
    SELECT
      MAX(block_timestamp)
    FROM
      `numia-data.dydx_mainnet.dydx_block_events`
    WHERE
      block_height = 22064978) AS block_timestamp,
    CAST(JSON_EXTRACT_SCALAR(CAST(m.data AS string), '$.order.order_id.client_id') AS INT64) AS trade_id,
    JSON_EXTRACT_SCALAR(CAST(m.data AS string), '$.order.order_id.subaccount_id.owner') AS subaccount,
    JSON_EXTRACT_SCALAR(CAST(m.data AS string), '$.order.order_id.clob_pair_id') AS clob_pair_id,
    JSON_EXTRACT_SCALAR(CAST(m.data AS string), '$.order.quantums') AS trade_volume,
    CASE
      WHEN JSON_EXTRACT_SCALAR(CAST(m.data AS string), '$.order.side') = '1' THEN 'buy'
    ELSE
    'sell'
  END
    AS side,
    JSON_EXTRACT_SCALAR(CAST(m.data AS string), '$.order.subticks') AS subticks,
    JSON_EXTRACT_SCALAR(CAST(m.data AS string), '$.order.GoodTilOneof.good_til_block') AS good_til_block,
    JSON_EXTRACT_SCALAR(CAST(m.data AS string), '$.order.GoodTilOneof.good_til_block_time') AS good_til_block_time
  FROM
    `numia-data.dydx_mainnet.dydx_mempool_transactions` m
  WHERE
    1 = 1
    -- Filter for new orders only
    AND JSON_EXTRACT_SCALAR(m.attributes, '$.tx_msg_type') = '/dydxprotocol.clob.MsgPlaceOrder'
    -- Filter for the right perp market
    AND JSON_EXTRACT_SCALAR(CAST(m.data AS string), '$.order.order_id.clob_pair_id') is null 
    -- Make sure the order good till the block in question or later, or it wouldn't be accepted
    AND (CAST(JSON_EXTRACT(CAST(m.data AS string), '$.order.GoodTilOneof.good_til_block') AS INT64) >= 22064978
      OR JSON_EXTRACT(CAST(m.data AS string), '$.order.GoodTilOneof.good_til_block') IS NULL)
    -- Make sure the order is good till the block time or later, or it shouldn't be included
    AND (JSON_EXTRACT_SCALAR(CAST(m.data AS string), '$.order.GoodTilOneof.good_til_block_time') IS NULL
      OR TIMESTAMP_SECONDS(CAST(JSON_EXTRACT_SCALAR(CAST(m.data AS string), '$.order.GoodTilOneof.good_til_block_time') AS INT64)) >= (
      SELECT
        MAX(block_timestamp)
      FROM
        `numia-data.dydx_mainnet.dydx_block_events`
      WHERE
        block_height = 22064978))
    -- Make sure the order is submitted before the block is processed
    AND m.publish_time < (
    SELECT
      MAX(block_timestamp)
    FROM
      `numia-data.dydx_mainnet.dydx_block_events`
    WHERE
      block_height = 22064978) ),
  min_publish_time AS (
  SELECT
    MIN(numia_publish_time) AS min_time
  FROM
    mempool ),
  matches AS (
  SELECT
    match.taker_order_id,
    match.maker_order_id
  FROM
    `numia-data.dydx_mainnet.dydx_match` match
  CROSS JOIN
    min_publish_time min_time
  WHERE
    1 = 1
    AND match.block_height < 22064978
    AND match.block_timestamp > min_time.min_time
    AND match.perpetual_id is null ),
  cancels AS (
  SELECT
    cancel.order_id
  FROM
    `numia-data.dydx_mainnet.dydx_cancel_order` cancel
  CROSS JOIN
    min_publish_time min_time
  WHERE
    1 = 1
    AND cancel.block_height < 22064978
    AND cancel.block_timestamp > min_time.min_time
    AND cancel.market_id is null )
SELECT
  m.*,
  place.type,
  place.trigger_condition,
  place.trigger_subticks,
  place.on_expiration
FROM
  mempool m
LEFT JOIN
  `numia-data.dydx_mainnet.dydx_place_order` place
ON
  m.tx_hash = place.tx_hash
LEFT JOIN
  matches match
ON
  (m.trade_id = match.taker_order_id
    OR m.trade_id = match.maker_order_id)
LEFT JOIN
  cancels cancel
ON
  m.trade_id = cancel.order_id
WHERE
  1 = 1
  AND match.taker_order_id IS NULL
  AND match.maker_order_id IS NULL
  AND cancel.order_id IS NULL
  AND m.side = 'sell'
  AND m.trade_volume is not null  
  order by CAST(m.numia_publish_time AS STRING) desc 
  limit 3000