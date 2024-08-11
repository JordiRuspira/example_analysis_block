SELECT B.*, A.* FROM `numia-data.dydx_mainnet.dydx_place_order` A 
LEFT JOIN `numia-data.dydx_mainnet.dydx_match` B 
ON (A.order_id = b.taker_order_id
    OR a.order_id = b.maker_order_id)
WHERE 1 = 1
AND A.SENDER = 'dydx1lg573vmcyee66h2808379lfcum0uedyzn2cku7'
AND A.MARKET_ID = 0
AND A.DIRECTION = 'BUY'
order by CAST(A.BLOCK_TIMESTAMP AS STRING) desc  

LIMIT 100  
