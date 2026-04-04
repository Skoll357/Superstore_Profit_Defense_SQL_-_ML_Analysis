-- 1. 基础 Cohort 数据 (基于之前的逻辑)
WITH Cohort_Base AS (
    SELECT 
        f.Region,
        f.Cohort_Month,
        (CAST(STRFTIME('%Y', s.Order_Date) AS INTEGER) - CAST(STRFTIME('%Y', f.First_Order_Date) AS INTEGER)) * 12 +
        (CAST(STRFTIME('%m', s.Order_Date) AS INTEGER) - CAST(STRFTIME('%m', f.First_Order_Date) AS INTEGER)) AS Month_Index,
        s.Profit,
        s."Customer ID"
    FROM cleaned_superstore s
    JOIN (
        SELECT "Customer ID", Region, MIN(Order_Date) as First_Order_Date, STRFTIME('%Y-%m', MIN(Order_Date)) as Cohort_Month
        FROM cleaned_superstore GROUP BY 1
    ) f ON s."Customer ID" = f."Customer ID"
),

-- 2. 计算每个 Cohort 的初始规模 (Month_Index = 0)
Cohort_Sizes AS (
    SELECT Region, Cohort_Month, COUNT(DISTINCT "Customer ID") as Initial_Size, SUM(Profit) as Initial_Profit
    FROM Cohort_Base
    WHERE Month_Index = 0
    GROUP BY 1, 2
),

-- 3. 计算次月留存人数 (Month_Index = 1)
Retention_M1 AS (
    SELECT Region, Cohort_Month, COUNT(DISTINCT "Customer ID") as Retained_Size_M1
    FROM Cohort_Base
    WHERE Month_Index = 1
    GROUP BY 1, 2
)

-- 4. 最终聚合：按 Region 汇总所有时间段的平均表现
SELECT 
    b.Region,
    -- 指标 1：平均初始客户数
    ROUND(AVG(s.Initial_Size), 1) as Avg_New_Customers_Per_Month,
    
    -- 指标 2：平均次月留存率 (核心指标！)
    ROUND(AVG(CAST(IFNULL(r.Retained_Size_M1, 0) AS FLOAT) / s.Initial_Size) * 100, 2) || '%' as Avg_M1_Retention,
    
    -- 指标 3：首月人均利润 (获客时的盈亏)
    ROUND(SUM(CASE WHEN b.Month_Index = 0 THEN b.Profit ELSE 0 END) / SUM(DISTINCT s.Initial_Size), 2) as Avg_Initial_Profit_Per_Capita,
    
    -- 指标 4：全生命周期人均利润 (到目前为止，每个客户平均一共赚了多少)
    ROUND(SUM(b.Profit) / SUM(DISTINCT s.Initial_Size), 2) as Total_LTV_Profit_Per_Capita
    
FROM Cohort_Base b
JOIN Cohort_Sizes s ON b.Region = s.Region AND b.Cohort_Month = s.Cohort_Month
LEFT JOIN Retention_M1 r ON b.Region = r.Region AND b.Cohort_Month = r.Cohort_Month
GROUP BY b.Region;

-- 1. 确定每个客户的“首购品类” (First Category Cohort)
WITH Customer_First_Category AS (
    SELECT 
        "Customer ID",
        Category as First_Category,
        MIN(Order_Date) as First_Order_Date,
        STRFTIME('%Y-%m', MIN(Order_Date)) as Cohort_Month
    FROM cleaned_superstore
    GROUP BY 1
),

-- 2. 基础数据关联
Category_Cohort_Base AS (
    SELECT 
        fc.First_Category,
        fc.Cohort_Month,
        (CAST(STRFTIME('%Y', s.Order_Date) AS INTEGER) - CAST(STRFTIME('%Y', fc.First_Order_Date) AS INTEGER)) * 12 +
        (CAST(STRFTIME('%m', s.Order_Date) AS INTEGER) - CAST(STRFTIME('%m', fc.First_Order_Date) AS INTEGER)) AS Month_Index,
        s.Profit,
        s."Customer ID"
    FROM cleaned_superstore s
    JOIN Customer_First_Category fc ON s."Customer ID" = fc."Customer ID"
),

-- 3. 计算每个品类 Cohort 的初始规模
Cat_Cohort_Sizes AS (
    SELECT First_Category, Cohort_Month, COUNT(DISTINCT "Customer ID") as Initial_Size
    FROM Category_Cohort_Base
    WHERE Month_Index = 0
    GROUP BY 1, 2
),

-- 4. 计算次月留存
Cat_Retention_M1 AS (
    SELECT First_Category, Cohort_Month, COUNT(DISTINCT "Customer ID") as Retained_Size_M1
    FROM Category_Cohort_Base
    WHERE Month_Index = 1
    GROUP BY 1, 2
)

-- 5. 最终聚合输出
SELECT 
    b.First_Category,
    ROUND(AVG(s.Initial_Size), 1) as Avg_New_Customers_Per_Month,
    ROUND(AVG(CAST(IFNULL(r.Retained_Size_M1, 0) AS FLOAT) / s.Initial_Size) * 100, 2) || '%' as Avg_M1_Retention,
    ROUND(SUM(CASE WHEN b.Month_Index = 0 THEN b.Profit ELSE 0 END) / SUM(DISTINCT s.Initial_Size), 2) as Avg_Initial_Profit_Per_Capita,
    ROUND(SUM(b.Profit) / SUM(DISTINCT s.Initial_Size), 2) as Total_LTV_Profit_Per_Capita
FROM Category_Cohort_Base b
JOIN Cat_Cohort_Sizes s ON b.First_Category = s.First_Category AND b.Cohort_Month = s.Cohort_Month
LEFT JOIN Cat_Retention_M1 r ON b.First_Category = r.First_Category AND b.Cohort_Month = r.Cohort_Month
GROUP BY b.First_Category;