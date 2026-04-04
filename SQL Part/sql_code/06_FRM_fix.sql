-- 这里完全保留你刚才发给我的、最引以为傲的洁净逻辑
WITH Customer_Stats AS (
    SELECT 
        "Customer ID",
        CAST(JULIANDAY((SELECT MAX(Order_Date) FROM cleaned_superstore)) - JULIANDAY(MAX(Order_Date)) AS INTEGER) AS Recency_Days,
        COUNT(DISTINCT "Order ID") AS Frequency,
        SUM(Profit) AS Total_Profit,
        AVG(Discount) as Avg_Discount
    FROM cleaned_superstore
    GROUP BY 1
),
RFM_Scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY Recency_Days DESC) as R,
        NTILE(5) OVER (ORDER BY Frequency ASC) as F,
        NTILE(5) OVER (ORDER BY Total_Profit ASC) as M
    FROM Customer_Stats
),
Tagged_Segments AS (
    SELECT "Customer ID",
        CASE 
            WHEN Total_Profit < 0 AND Avg_Discount >= 0.3 THEN 'Profit Drains'
            WHEN R >= 4 AND F >= 4 AND M >= 4 THEN 'Champions'
            WHEN R >= 4 AND M >= 4 THEN 'Loyalists'
            WHEN R <= 2 AND F <= 2 THEN 'Hibernating'
            ELSE 'Others/Normal'
        END AS Segment
    FROM RFM_Scores
)
-- 【救命的一步】：把这个洁净的 Segment 关联回原始表，只为拿到 Region
-- 这样既保证了 793 人的逻辑，又能让 Python 画出 Central 的图
SELECT 
    s.Region,
    t.Segment,
    SUM(s.Profit) as Total_Segment_Profit
FROM cleaned_superstore s
JOIN Tagged_Segments t ON s."Customer ID" = t."Customer ID"
-- 我们只拿图 2 需要的 Central 地区和那两个关键分群
WHERE s.Region = 'Central' AND t.Segment IN ('Champions', 'Profit Drains')
GROUP BY 1, 2;

WITH Customer_Stats AS (
    -- 1. 基础聚合：在计算 RFM 指标的同时，带上配送天数的平均值
    SELECT 
        "Customer ID",
        CAST(JULIANDAY((SELECT MAX(Order_Date) FROM cleaned_superstore)) - JULIANDAY(MAX(Order_Date)) AS INTEGER) AS Recency_Days,
        COUNT(DISTINCT "Order ID") AS Frequency,
        SUM(Profit) AS Total_Profit,
        AVG(Discount) as Avg_Discount,
        -- 【补丁点 A】：计算每个客户平均每单要等几天
        AVG(Shipping_Duration) as Avg_Shipping_Duration 
    FROM cleaned_superstore
    GROUP BY 1
),
RFM_Scores AS (
    -- 2. 评分逻辑保持不变
    SELECT *,
        NTILE(5) OVER (ORDER BY Recency_Days DESC) as R,
        NTILE(5) OVER (ORDER BY Frequency ASC) as F,
        NTILE(5) OVER (ORDER BY Total_Profit ASC) as M
    FROM Customer_Stats
),
Tagged_Segments AS (
    -- 3. 分群打标保持不变
    SELECT *,
        CASE 
            WHEN Total_Profit < 0 AND Avg_Discount >= 0.3 THEN 'Profit Drains'
            WHEN R >= 4 AND F >= 4 AND M >= 4 THEN 'Champions'
            WHEN R >= 4 AND M >= 4 THEN 'Loyalists'
            WHEN R <= 2 AND F <= 2 THEN 'Hibernating'
            ELSE 'Others/Normal'
        END AS Segment
    FROM RFM_Scores
)
-- 4. 最终展示：导出每个分群的平均配送时间
SELECT 
    Segment,
    COUNT(*) as Customer_Count,
    -- 【补丁点 B】：看看不同价值的人，享受的物流服务是否有区别
    ROUND(AVG(Avg_Shipping_Duration), 2) as Avg_Lead_Time_Days,
    ROUND(SUM(Total_Profit), 2) as Total_Segment_Profit
FROM Tagged_Segments
GROUP BY 1
ORDER BY Total_Segment_Profit DESC;