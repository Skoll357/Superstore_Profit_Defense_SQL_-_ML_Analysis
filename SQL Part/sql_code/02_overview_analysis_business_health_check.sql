-- 1. 区域与品类健康度概览
SELECT 
    Region,
    Category,
    COUNT(*) AS Total_Orders,
    -- 物流效率：平均到货天数
    ROUND(AVG(Shipping_Duration), 2) AS Avg_Shipping_Days,
    -- 折扣力度：平均折扣率
    ROUND(AVG(Discount) * 100, 2) || '%' AS Avg_Discount_Rate,
    -- 盈利健康度：亏损订单占比 (作为退货/风险的预测指标)
    ROUND(CAST(COUNT(CASE WHEN Profit < 0 THEN 1 END) AS FLOAT) / COUNT(*) * 100, 2) || '%' AS Loss_Order_Ratio,
    -- 整体利润率
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2) || '%' AS Overall_Margin
FROM cleaned_superstore
GROUP BY Region, Category
ORDER BY Region, Avg_Shipping_Days DESC;

-- 2. 物流模式的 ROI 验证
SELECT 
    "Ship Mode",
    -- 时效分布
    MIN(Shipping_Duration) AS Min_Days,
    ROUND(AVG(Shipping_Duration), 1) AS Avg_Days,
    MAX(Shipping_Duration) AS Max_Days,
    -- 财务贡献
    ROUND(AVG(Profit_Margin) * 100, 2) || '%' AS Avg_Profit_Margin,
    -- 异常订单占比（高折扣且亏损）
    ROUND(CAST(COUNT(CASE WHEN Operational_Anomaly_Tag = 'High Discount Loss' THEN 1 END) AS FLOAT) / COUNT(*) * 100, 2) || '%' AS Anomaly_Ratio,
    -- 计算该物流模式下每单的平均利润
    ROUND(AVG(Profit), 2) AS Avg_Profit_Per_Order
FROM cleaned_superstore
GROUP BY "Ship Mode"
ORDER BY Avg_Days ASC;