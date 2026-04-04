-- 1. 删除旧表
DROP TABLE IF EXISTS cleaned_superstore;

-- 2. 重新创建，集成所有清洗逻辑 + 异常识别
CREATE TABLE cleaned_superstore AS
WITH DateParts AS (
    SELECT 
        *,
        INSTR("Order Date", '/') as f_slash_o,
        INSTR(SUBSTR("Order Date", INSTR("Order Date", '/') + 1), '/') + INSTR("Order Date", '/') as s_slash_o,
        INSTR("Ship Date", '/') as f_slash_s,
        INSTR(SUBSTR("Ship Date", INSTR("Ship Date", '/') + 1), '/') + INSTR("Ship Date", '/') as s_slash_s
    FROM "Sample - Superstore"
)
SELECT 
    "Row ID",
    "Order ID",
    -- 日期标准化
    PRINTF('%04d-%02d-%02d', 
        CAST(SUBSTR("Order Date", s_slash_o + 1) AS INTEGER), 
        CAST(SUBSTR("Order Date", 1, f_slash_o - 1) AS INTEGER), 
        CAST(SUBSTR("Order Date", f_slash_o + 1, s_slash_o - f_slash_o - 1) AS INTEGER)
    ) AS Order_Date,

    PRINTF('%04d-%02d-%02d', 
        CAST(SUBSTR("Ship Date", s_slash_s + 1) AS INTEGER), 
        CAST(SUBSTR("Ship Date", 1, f_slash_s - 1) AS INTEGER), 
        CAST(SUBSTR("Ship Date", f_slash_s + 1, s_slash_s - f_slash_s - 1) AS INTEGER)
    ) AS Ship_Date,

    "Ship Mode",
    "Customer ID",
    "Customer Name",
    Segment,
    Country,
    City,
    State,
    PRINTF('%05d', CAST("Postal Code" AS INTEGER)) AS Postal_Code,
    Region,
    "Product ID",
    Category,
    "Sub-Category",
    "Product Name",
    Sales,
    Quantity,
    Discount,
    Profit,

    -- 新增特征 1：物流时效
    (JULIANDAY(PRINTF('%04d-%02d-%02d', CAST(SUBSTR("Ship Date", s_slash_s + 1) AS INTEGER), CAST(SUBSTR("Ship Date", 1, f_slash_s - 1) AS INTEGER), CAST(SUBSTR("Ship Date", f_slash_s + 1, s_slash_s - f_slash_s - 1) AS INTEGER))) - 
     JULIANDAY(PRINTF('%04d-%02d-%02d', CAST(SUBSTR("Order Date", s_slash_o + 1) AS INTEGER), CAST(SUBSTR("Order Date", 1, f_slash_o - 1) AS INTEGER), CAST(SUBSTR("Order Date", f_slash_o + 1, s_slash_o - f_slash_o - 1) AS INTEGER)))) AS Shipping_Duration,

    -- 新增特征 2：利润率
    ROUND(CAST(Profit AS FLOAT) / CAST(Sales AS FLOAT), 4) AS Profit_Margin,

    -- 新增特征 3：运营异常标签 (Anomaly Detection)
    -- 逻辑：如果折扣 >= 50% 且利润为负，标记为 'High Discount Loss'，否则为 'Normal'
    CASE 
        WHEN Discount >= 0.5 AND Profit < 0 THEN 'High Discount Loss'
        WHEN Profit < -1000 THEN 'Extreme Loss' -- 补充：即便折扣不高但亏损巨大的订单
        ELSE 'Normal'
    END AS Operational_Anomaly_Tag

FROM DateParts;

-- 3. 快速统计一下异常情况
SELECT 
    Operational_Anomaly_Tag, 
    COUNT(*) as Order_Count, 
    SUM(Profit) as Total_Profit
FROM cleaned_superstore
GROUP BY 1;

-- ==========================================================
-- Chapter 0: Macro-Level Landscape (Overview Analysis)
-- 目的：在进入细节分析前，获取业务全貌的基准指标
-- ==========================================================

-- 0.1 核心 KPI 总览 (Core Business Magnitude)
-- 展示公司的总营收、总利润、整体利润率以及时间跨度
SELECT 
    COUNT(DISTINCT "Order ID") AS Total_Unique_Orders,
    COUNT(*) AS Total_Line_Items,
    ROUND(SUM("Sales"), 2) AS Total_Revenue,
    ROUND(SUM("Profit"), 2) AS Total_Net_Profit,
    ROUND(SUM("Profit") / SUM("Sales") * 100, 2) || '%' AS Aggregate_Profit_Margin,
    COUNT(DISTINCT "Customer ID") AS Total_Unique_Customers,
    MIN("Order_Date") AS Audit_Start_Date,
    MAX("Order_Date") AS Audit_End_Date
FROM cleaned_superstore;


-- 0.2 年度增长趋势 (Temporal Footprint: YoY Growth)
-- 验证业务是否在扩张，以及利润是否跟上了销售额的增长
SELECT 
    SUBSTR(Order_Date, 1, 4) AS Sales_Year,
    ROUND(SUM("Sales"), 2) AS Annual_Revenue,
    ROUND(SUM("Profit"), 2) AS Annual_Profit,
    ROUND(SUM("Profit") / SUM("Sales") * 100, 2) || '%' AS Annual_Profit_Margin,
    COUNT(DISTINCT "Order ID") AS Order_Volume
FROM cleaned_superstore
GROUP BY 1
ORDER BY 1;


-- 0.3 业务广度评估 (Geographic & Product Breadth)
-- 展示 Superstore 的覆盖规模
SELECT 
    COUNT(DISTINCT "Region") AS Total_Regions,
    COUNT(DISTINCT "State") AS Total_States_Covered,
    COUNT(DISTINCT "City") AS Total_Cities_Covered,
    COUNT(DISTINCT "Category") AS Total_Main_Categories,
    COUNT(DISTINCT "Sub-Category") AS Total_Sub_Categories
FROM cleaned_superstore;


-- 0.4 异常状况在“大盘”中的占比 (Macro Anomaly Impact)
-- 这一步非常重要，为 Chapter 1 埋下伏笔：到底多少钱是被“异常订单”吞掉的？
SELECT 
    Operational_Anomaly_Tag,
    COUNT(*) AS Line_Item_Count,
    ROUND(SUM("Sales"), 2) AS Impacted_Sales,
    ROUND(SUM("Profit"), 2) AS Impacted_Profit,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cleaned_superstore), 2) || '%' AS Percentage_of_Total_Items
FROM cleaned_superstore
GROUP BY 1;