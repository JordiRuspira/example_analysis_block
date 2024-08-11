  SELECT 
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
    AND JSON_EXTRACT_SCALAR(CAST(m.data AS string), '$.order.order_id.subaccount_id.owner') = 'dydx1lg573vmcyee66h2808379lfcum0uedyzn2cku7'
    AND JSON_EXTRACT_SCALAR(m.attributes, '$.tx_msg_type') = '/dydxprotocol.clob.MsgPlaceOrder'  
    AND  JSON_EXTRACT_SCALAR(CAST(m.data AS string), '$.order.side') = '1' 
  AND  JSON_EXTRACT_SCALAR(CAST(m.data AS string), '$.order.order_id.clob_pair_id') IS NULL
  order by CAST(m.publish_time AS STRING) desc  

  LIMIT 200