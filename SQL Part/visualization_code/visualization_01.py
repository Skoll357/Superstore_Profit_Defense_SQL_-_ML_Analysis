import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# 设置全局字体
sns.set_theme(style="white")
plt.rcParams["font.family"] = "serif"
plt.rcParams["font.serif"] = ["Times New Roman"]

# 1. 加载数据 (请确保文件名与你本地一致)
df_region = pd.read_csv('your_path.02_overview_analysis_region_and_category_health.csv')
df_ship = pd.read_csv('your_path.02_overview_analysis_ship_mode.csv')

# 清洗百分比数据
def clean_pct(column):
    return column.str.rstrip('%').astype('float')

df_region['Overall_Margin'] = clean_pct(df_region['Overall_Margin'])
df_ship['Avg_Profit_Margin'] = clean_pct(df_ship['Avg_Profit_Margin'])

# 创建画布
fig, axes = plt.subplots(1, 3, figsize=(20, 6.5)) # 稍微调高了高度
fig.suptitle("Phase 1: Surface Mirage - Preliminary Business Health Check", fontsize=22, fontweight='bold', y=0.98)

# --- 图表 1: Regional Profit Margin ---
region_margin = df_region.groupby('Region')['Overall_Margin'].mean().sort_values()
colors_reg = ['#c0392b' if x == 'Central' else '#bdc3c7' for x in region_margin.index]
sns.barplot(x=region_margin.index, y=region_margin.values, ax=axes[0], palette=colors_reg)
axes[0].set_title("Average Profit Margin by Region", fontsize=15, pad=15)
axes[0].set_ylabel("Overall Margin (%)")
axes[0].set_xlabel("Region")
# 【修正 1】手动增加 Y 轴上限，给顶部文字留出 15% 的空隙
axes[0].set_ylim(0, region_margin.max() * 1.15) 
for i, v in enumerate(region_margin.values):
    axes[0].text(i, v + 0.3, f"{v:.1f}%", ha='center', fontweight='bold', fontsize=11)

# --- 图表 2: Category Profit Margin ---
cat_margin = df_region.groupby('Category')['Overall_Margin'].mean().sort_values()
colors_cat = ['#c0392b' if x == 'Furniture' else '#bdc3c7' for x in cat_margin.index]
sns.barplot(x=cat_margin.index, y=cat_margin.values, ax=axes[1], palette=colors_cat)
axes[1].set_title("Average Profit Margin by Category", fontsize=15, pad=15)
axes[1].set_ylabel("Overall Margin (%)")
axes[1].set_xlabel("Category")
# 【修正 2】同样增加 Y 轴上限
axes[1].set_ylim(0, cat_margin.max() * 1.15)
for i, v in enumerate(cat_margin.values):
    axes[1].text(i, v + 0.3, f"{v:.1f}%", ha='center', fontweight='bold', fontsize=11)

# --- 图表 3: Ship Mode Efficiency vs Profit ---
ship_colors = {"First Class": "#e67e22", "Standard Class": "#7f8c8d", "Second Class": "#2ecc71", "Same Day": "#3498db"}
sns.scatterplot(data=df_ship, x='Avg_Days', y='Avg_Profit_Margin', s=250, hue='Ship Mode', 
                palette=ship_colors, ax=axes[2], zorder=3)
axes[2].set_title("Ship Mode: Efficiency vs. Profitability", fontsize=15, pad=15)
axes[2].set_xlabel("Avg. Shipping Days")
axes[2].set_ylabel("Avg. Profit Margin (%)")
# 【修正 3】手动设置 X 轴范围，给最右侧的 "Standard Class" 留出足够的标注空间
axes[2].set_xlim(df_ship['Avg_Days'].min() - 0.5, df_ship['Avg_Days'].max() + 1.5)
# 给点打标签，并稍微向右偏移
for i in range(df_ship.shape[0]):
    axes[2].text(df_ship.Avg_Days[i] + 0.15, df_ship.Avg_Profit_Margin[i], 
                 df_ship['Ship Mode'][i], fontsize=11, va='center')

# 移除冗余的图例（因为我们已经直接在点旁边标了名字）
axes[2].get_legend().remove()

plt.tight_layout(rect=[0, 0.03, 1, 0.93]) # 调整整体布局，防止标题重叠
plt.savefig('Phase1_Surface_Mirage.png', dpi=300, bbox_inches='tight')
plt.show()