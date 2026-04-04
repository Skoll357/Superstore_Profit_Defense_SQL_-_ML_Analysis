import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# 1. 全局配置：字体设置为 Times New Roman
sns.set_theme(style="white")
plt.rcParams["font.family"] = "serif"
plt.rcParams["font.serif"] = ["Times New Roman"]

# 2. 加载已经聚合好的三份关键 CSV
df_region_agg = pd.read_csv('your_path.03_customer_retention_and_profit_cycle_by_region.csv')
df_segment_agg = pd.read_csv('your_path.06_phase2_central_fix.csv')
df_category_agg = pd.read_csv('your_path.03_customer_retention_and_profit_cycle_by_category.csv')

# 清洗百分号函数
def clean_pct(val):
    return float(val.strip('%'))

# 处理数据中的百分比字符串
df_region_agg['Avg_M1_Retention'] = df_region_agg['Avg_M1_Retention'].apply(clean_pct)
df_category_agg['Avg_M1_Retention'] = df_category_agg['Avg_M1_Retention'].apply(clean_pct)

# --- 绘图开始 ---
fig, axes = plt.subplots(1, 3, figsize=(20, 7))
fig.suptitle("Phase 2: The Hidden Paradox - Exposing the Truth Behind Averages", fontsize=22, fontweight='bold', y=1.05)

# --- 图表 1: South's Leaky Bucket (Dual Axis) ---
# 核心逻辑：展示南部的“高利润、低留存”矛盾
ax1 = axes[0]
ax1_twin = ax1.twinx()

sns.barplot(x='Region', y='Avg_Initial_Profit_Per_Capita', data=df_region_agg, palette="Oranges", ax=ax1, alpha=0.7)
sns.lineplot(x='Region', y='Avg_M1_Retention', data=df_region_agg, marker='o', 
             color='#c0392b', linewidth=4, ax=ax1_twin)

ax1.set_title("1. South: The 'Leaky Bucket' Paradox\n(High Profit, Low Retention)", fontsize=14, fontweight='bold')
ax1.set_ylabel("Avg Initial Profit per Capita ($)")
ax1_twin.set_ylabel("Month 1 Retention Rate (%)")
ax1_twin.set_ylim(0, 15) # 留存率范围

# --- 图表 2: Central's Polarization (Contrast) ---
# 核心逻辑：展示中部不是穷，而是被吸血鬼拖累
ax2 = axes[1]

# 直接画，不需要再在 Python 里过滤了，因为 SQL 已经帮你过滤干净了！
sns.barplot(x='Segment', y='Total_Segment_Profit', data=df_segment_agg, 
            palette=['#2980b9', '#c0392b'], ax=ax2)

ax2.set_title("2. Central: Polarization of Value\n(Champions vs. Profit Drains)", fontsize=14, fontweight='bold')
ax2.set_ylabel("Total Net Profit ($)")
# 标注具体金额
for p in ax2.patches:
    ax2.annotate(f'${p.get_height():,.0f}', (p.get_x() + p.get_width() / 2., p.get_height()), 
                ha='center', va='center', xytext=(0, 10 if p.get_height() > 0 else -10), textcoords='offset points', fontweight='bold')

# --- 图表 3: Category Stickiness (Retention Comparison) ---
# 核心逻辑：展示 Technology 的压倒性留存优势
ax3 = axes[2]
sns.barplot(x='First_Category', y='Avg_M1_Retention', data=df_category_agg, palette="Greens_d", ax=ax3)

ax3.set_title("3. Category Stickiness\n(Technology as the Growth Anchor)", fontsize=14, fontweight='bold')
ax3.set_ylabel("Month 1 Retention Rate (%)")
ax3.set_xlabel("First-Order Category")
for i, v in enumerate(df_category_agg['Avg_M1_Retention']):
    ax3.text(i, v + 0.5, f"{v:.1f}%", ha='center', fontweight='bold')

plt.tight_layout()
plt.savefig('Phase2_The_Hidden_Paradox.png', dpi=300, bbox_inches='tight')
plt.show()