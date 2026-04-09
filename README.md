# Superstore Profit Defense: Bridging SQL Audits with XGBoost Prediction

## Project Overview
This project provides a comprehensive data-driven strategy to identify historical profit leakage via SQL auditing and predict long-term customer retention using an XGBoost machine learning model.

## Tech Stack
- **Database:** SQLite (Complex CTEs, Window Functions, Self-Joins)
- **Programming:** Python (Pandas, Scikit-learn, XGBoost)
- **Visualization:** Matplotlib, Seaborn (Times New Roman styling)
- **Methodologies:** RFM Modeling, Cohort Analysis, Market Basket Analysis (MBA)

## Project Structure

### Phase 1: SQL Diagnostic Audit (The "What")
*Goal: Identify where and why profit is leaking from the organization.*
- **Scaling Paradox:** Discovered that rapid revenue growth was being "bought" at the cost of a significant net margin dip.
- **Regional Paradoxes:** Exposed the "Leaky Bucket" in the South (High initial profit, abysmal retention) and "Value Polarization" in the Central region.
- **Surgical Strike:** Pinpointed "Toxic Discounts" and logistics misallocations where loss-making orders received premium shipping.

### Phase 2: ML Predictive Insights (The "So What")
*Goal: Predict 180-day customer retention based on first-order characteristics.*
- **Model Choice:** Built an XGBoost Classifier with a `scale_pos_weight` strategy to handle class imbalance.
- **Retention Window:** Shifted from a 30-day tactical view to a 180-day strategic window to capture the true office supply purchase cycle.
- **Key Discovery:** Validated that initial **Region** and **Ship Mode** are the strongest systemic predictors of long-term churn.

### Phase 3: Strategic Recommendations (The "Now What")
*Goal: Move from volume-at-any-cost to value-driven acquisition.*
- **Strategy Matrix:** Developed a 2x2 Retention-Profitability Matrix to categorize customers into four actionable segments: **Champions**, **Leaky Bucket**, **Strategic Growth**, and **Vampires**.
- **Tactical Pivot:** Proposed a Hard Cap on discounts for "Vampire" segments and a Tiered Logistics SLA to reserve First Class shipping for high-LTV customers.

## Key Conclusions
1. **Discipline Over Volume:** 9.2% of orders were "Loss Anomalies" driven by unsustainable discounts; eliminating these provides an immediate $96.78k profit recovery.
2. **Loyalty is Predictable:** A customer's first order (category, quantity, and discount) is a reliable early warning system for their lifetime value.
3. **Resource Realignment:** Logistics (and other resources) must be used as a retention tool for "Champions" rather than a hidden subsidy for one-off buyers.

## Data Resource
**SuperStore Dataset - https://www.kaggle.com/datasets/vivek468/superstore-dataset-final**


## Notice
**Please replace your_path with your local directory when running the code.**
---
*Developed as a comprehensive lifecycle & supply chain analysis of Superstore Operations.*