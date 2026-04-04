-- 1. 核心逻辑：自连接，寻找同一个订单中的不同商品对
WITH Product_Pairs AS (
    SELECT 
        a."Sub-Category" AS Product_A,
        b."Sub-Category" AS Product_B,
        a."Order ID"
    FROM cleaned_superstore a
    JOIN cleaned_superstore b ON a."Order ID" = b."Order ID" 
        AND a."Sub-Category" < b."Sub-Category" -- 避免重复计数 (A,B 和 B,A) 以及自己连自己
)

-- 2. 统计最常成对出现的组合
SELECT 
    Product_A,
    Product_B,
    COUNT(*) AS Times_Bought_Together
FROM Product_Pairs
GROUP BY 1, 2
ORDER BY Times_Bought_Together DESC
LIMIT 10;