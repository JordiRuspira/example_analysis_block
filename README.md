# Block number 22064978 analysis


## Introduction


On Aug 5th 2024, 10:50:11 (UTC), block number 22064978, the skip dashboard showed a single block proposed by Dora Factory with over $14k of order book discrepancy. We pulled our logs from our node and checked the proposed operations by the block proposer to those proposed by our node. 

During block 22064978, trader dydx1lg573vmcyee66h2808379lfcum0uedyzn2cku7 bought 10 BTC for a total of $533,253.10, meaning an average of $53,325.31 per BTC in 25 different matches. According to our logs, he should have bought 10 BTC for a total of $521,493.09, meaning an average of $52,149.31 per BTC in 3 matches. The block price of BTC was $51,569.00 per BTC. This means that the buyer paid an extra 3.23% than the block price, compared to an 1.12% according to our logs.

This could have been triggered by the total size of the operation, but it is a high discrepancy nonetheless. 

## Analysis

Out of the availble docs, query_1_matches.sql returns, for the given block, all matches. Using that together with the pulled logs (22064978.json) in the streamlit app (https://dydx-mev-comparison.streamlit.app/), we see what's specified in the introduction. Additionally, we see via the query that the order id for taker dydx1lg573vmcyee66h2808379lfcum0uedyzn2cku7 is 1771405256. 

Our next step has been looking at placed orders by said user to see when the order entered, and here we have our first problem. Looking at the "place_orders" table in numia, we see no placed orders matching the order id. Again, using that table and checking together with the "match" table, we see that the latest one of them to be matched was in May 1st, 2024 (query_2_place.sql). 

On our quest to check for the placed order, we do see two possible ones on the mempool table (query_3_placeorders.sql), which returns the following two tx hash:

C14FF12CEDBC109DF7A7FAA39A28DE0E0600445E39C1DF7DF9532E2D11EC8E14 by dydx1lg.., buy order of 10 BTC and trade_id 1771405256 (matching the one we were expecting). However, we do see the follwing submitted time: Aug  5 10:50:11.557503469, a few ms after the max block timestamp according to the block_events table: 2024-08-05 10:50:11.386000 UTC

06C14E9CB59AE110382B8EC272410FA9C1500444355953C9185382C986F26990 by dydx1lg.., buy order of 10 BTC and trade_id 133981381 (not matching the one we were expecting). We do see it was submitted 10 seconds before the block timestamp: Aug  5 10:50:04.366823663


None of them, however, appear on the "place_order" or block scanners. 

Finally, we've got the result of "query_4_possible_better_matches", where we've checked possible better matches for the buy order. However, the two ones proposed by our node (via seller dydx14dltc2w6y3dhf0naz8luglsvjt0vhvswm2j6d0) are not shown there. Trying to find those ones, we've seen "query_5" and "query_6", where the first one shows that, for the hours prior to the block, dydx14dlc (our potential seller to our buyer) did not have any order submitted with "good til block" later or equal to our block. Query 6, on the other hand, shows a handful of trades which make sense with those expected by our node, but all of them have "good til block" prior than our block, so it makes sense for the BP to not have matched them.



# example_analysis_block
