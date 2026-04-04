WITH Customer_Stats AS (
    -- 1. 基础聚合：每个客户只产生一行数据，没有任何地区干扰
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
    -- 2. 评分逻辑 (NTILE(5) 分成 5 组，5 分为优)
    SELECT *,
        NTILE(5) OVER (ORDER BY Recency_Days DESC) as R, -- 天数越小(近)，分越高
        NTILE(5) OVER (ORDER BY Frequency ASC) as F,   -- 频率越高，分越高
        NTILE(5) OVER (ORDER BY Total_Profit ASC) as M   -- 利润越高，分越高
    FROM Customer_Stats
),
Tagged_Segments AS (
    -- 3. 分群打标
    SELECT *,
        CASE 
            WHEN Total_Profit < 0 AND Avg_Discount >= 0.3 THEN 'Profit Drains' -- 这种定义极其精准
            WHEN R >= 4 AND F >= 4 AND M >= 4 THEN 'Champions'
            WHEN R >= 4 AND M >= 4 THEN 'Loyalists'
            WHEN R <= 2 AND F <= 2 THEN 'Hibernating'
            ELSE 'Others/Normal'
        END AS Segment
    FROM RFM_Scores
)
-- 4. 最终展示：干净、直接、无偏差
SELECT 
    Segment,
    COUNT(*) as Customer_Count,
    ROUND(SUM(Total_Profit), 2) as Total_Segment_Profit,
    ROUND(AVG(Avg_Discount) * 100, 2) || '%' as Avg_Discount_Rate,
    -- 额外加一个指标：人均利润贡献（这比地区更有说服力）
    ROUND(SUM(Total_Profit) / COUNT(*), 2) as Profit_Per_Capita
FROM Tagged_Segments
GROUP BY 1
ORDER BY Total_Segment_Profit DESC;

WITH Target_Drains AS (
    -- 1. 先把那 39 个吸血鬼的 Customer ID 捞出来
    SELECT "Customer ID"
    FROM (
        SELECT "Customer ID", SUM(Profit) as Total_Profit, AVG(Discount) as Avg_Disc
        FROM cleaned_superstore
        GROUP BY 1
    )
    WHERE Total_Profit < 0 AND Avg_Disc >= 0.3
),
Drain_Transactions AS (
    -- 2. 关联回原始表，获取他们的每一笔订单明细
    SELECT 
        s.*
    FROM cleaned_superstore s
    JOIN Target_Drains d ON s."Customer ID" = d."Customer ID"
)

-- 3. 开始全方位解剖
-- 分析 A: 看看这些“吸血鬼”最爱买什么品类？
SELECT 
    "Sub-Category",
    COUNT(*) as Order_Count,
    ROUND(SUM(Profit), 2) as Total_Loss,
    ROUND(AVG(Discount) * 100, 2) || '%' as Avg_Discount,
    ROUND(AVG(Shipping_Duration), 1) as Avg_Ship_Days
FROM Drain_Transactions
GROUP BY 1
ORDER BY Total_Loss ASC; -- 赔钱最多的排前面

WITH Target_Drains AS (
    -- 1. 先把那 39 个吸血鬼的 Customer ID 捞出来
    SELECT "Customer ID"
    FROM (
        SELECT "Customer ID", SUM(Profit) as Total_Profit, AVG(Discount) as Avg_Disc
        FROM cleaned_superstore
        GROUP BY 1
    )
    WHERE Total_Profit < 0 AND Avg_Disc >= 0.3
),
Drain_Transactions AS (
    -- 2. 关联回原始表，获取他们的每一笔订单明细
    SELECT 
        s.*
    FROM cleaned_superstore s
    JOIN Target_Drains d ON s."Customer ID" = d."Customer ID"
)

-- 分析 B: 看看这些“吸血鬼”的地理分布
-- (接上面的 WITH 模块)
SELECT 
    State,
    COUNT(DISTINCT "Customer ID") as Vampire_Count,
    ROUND(SUM(Profit), 2) as Total_Loss,
    ROUND(AVG(Discount) * 100, 2) || '%' as Avg_Discount
FROM Drain_Transactions
GROUP BY 1
ORDER BY Total_Loss ASC;

WITH Customer_Base AS (
    -- 1. 确定每个客户的“家乡” (下单次数最多的地区)
    SELECT "Customer ID", Region as Main_Region
    FROM (
        SELECT "Customer ID", Region, COUNT(*) as cnt,
               ROW_NUMBER() OVER(PARTITION BY "Customer ID" ORDER BY COUNT(*) DESC) as rn
        FROM cleaned_superstore
        GROUP BY 1, 2
    ) WHERE rn = 1
),
RFM_Core AS (
    -- 2. 计算每个客户的全局指标 (不分地区)
    SELECT 
        "Customer ID",
        SUM(Profit) as Total_Profit,
        AVG(Discount) as Avg_Discount,
        COUNT(DISTINCT "Order ID") as Frequency,
        CAST(JULIANDAY((SELECT MAX(Order_Date) FROM cleaned_superstore)) - JULIANDAY(MAX(Order_Date)) AS INTEGER) AS Recency_Days
    FROM cleaned_superstore
    GROUP BY 1
),
Tagged_Customers AS (
    -- 3. 打标签
    SELECT r.*, b.Main_Region,
        CASE 
            WHEN Total_Profit < 0 AND Avg_Discount >= 0.3 THEN 'Profit Drains'
            WHEN NTILE(5) OVER(ORDER BY Recency_Days DESC) >= 4 
                 AND NTILE(5) OVER(ORDER BY Frequency ASC) >= 4 
                 AND NTILE(5) OVER(ORDER BY Total_Profit ASC) >= 4 THEN 'Champions'
            ELSE 'Others'
        END AS Segment
    FROM RFM_Core r
    JOIN Customer_Base b ON r."Customer ID" = b."Customer ID"
)
-- 4. 导出给绘图用的聚合表
SELECT 
    Main_Region as Dominant_Region,
    Segment,
    SUM(Total_Profit) as Segment_Total_Profit
FROM Tagged_Customers
GROUP BY 1, 2;