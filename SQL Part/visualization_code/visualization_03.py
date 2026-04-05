import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from matplotlib import rcParams

# 1. 全局配置
sns.set_theme(style="white")
plt.rcParams["font.family"] = "serif"
plt.rcParams["font.serif"] = ["Times New Roman"]

# 2. 导入数据 (请确保文件名与你本地一致)
df_seg = pd.read_csv('your_path.04_FRM_customer_segmentation.csv')
df_state = pd.read_csv('your_path.04_FRM_profit_drains_by_state.csv')
df_sub = pd.read_csv('your_path.04_FRM_profit_drains_by_sub_category.csv')
df_mba = pd.read_csv('your_path.05_market_basket_analysis_association.csv')

# 数据清洗：将百分比字符串转换为浮点数以便绘图
df_seg['Avg_Discount_Rate'] = df_seg['Avg_Discount_Rate'].str.rstrip('%').astype('float')
df_state['Avg_Discount'] = df_state['Avg_Discount'].str.rstrip('%').astype('float')
df_sub['Avg_Discount'] = df_sub['Avg_Discount'].str.rstrip('%').astype('float')

# 3. 创建画布
fig, axes = plt.subplots(2, 2, figsize=(20, 16), dpi=150)
fig.suptitle('Phase 3: The Surgical Strike - Unmasking the "Profit Drains" Segment', fontsize=28, fontweight='bold', y=0.95)

# --- Plot 1: Segment Profit Contribution (Highlighting the Gap) ---
# 目标：展示 Champions 与 Profit Drains 的巨大鸿沟
colors_seg = ['#d35400' if x == 'Profit Drains' else '#bdc3c7' for x in df_seg['Segment']]
sns.barplot(data=df_seg, x='Segment', y='Total_Segment_Profit', palette=colors_seg, ax=axes[0, 0])
axes[0, 0].set_title('1. Total Profit Contribution by Segment', fontsize=18, pad=15)
axes[0, 0].set_ylabel('Total Net Profit ($)', fontsize=14)
# 在柱状图上标注人数
for i, p in enumerate(axes[0, 0].patches):
    axes[0, 0].annotate(f"N={df_seg.iloc[i]['Customer_Count']}", 
                        (p.get_x() + p.get_width() / 2., p.get_height()), 
                        ha='center', va='bottom', fontsize=12, xytext=(0, 5), textcoords='offset points')

# --- Plot 2: Top 5 Loss-Making States (Where the Vampires Live) ---
# 目标：锁定地理重灾区
df_state_top5 = df_state.sort_values('Total_Loss').head(5)
sns.barplot(data=df_state_top5, x='Total_Loss', y='State', palette='Reds_r', ax=axes[0, 1])
axes[0, 1].set_title('2. Top 5 Hotspots of Loss (State Level)', fontsize=18, pad=15)
axes[0, 1].set_xlabel('Total Net Loss ($)', fontsize=14)
# 标注每个州的平均折扣率
for i, v in enumerate(df_state_top5['Total_Loss']):
    axes[0, 1].text(v, i, f" Disc: {df_state_top5.iloc[i]['Avg_Discount']}%", va='center', fontsize=12, fontweight='bold')

# --- Plot 3: Toxic Sub-Categories (The Root Cause) ---
# 目标：找出哪些产品被过度打折，导致巨额亏损
df_sub_top = df_sub.sort_values('Total_Loss').head(8)
sns.barplot(data=df_sub_top, x='Total_Loss', y='Sub-Category', palette='YlOrRd_r', ax=axes[1, 0])
axes[1, 0].set_title('3. "Toxic" Products: Loss by Sub-Category', fontsize=18, pad=15)
axes[1, 0].set_xlabel('Total Net Loss ($)', fontsize=14)
# 标注折扣率，实锤 Binders 的问题
for i, v in enumerate(df_sub_top['Total_Loss']):
    axes[1, 0].text(v, i, f" Disc: {df_sub_top.iloc[i]['Avg_Discount']}%", va='center', fontsize=12)

# --- Plot 4: Market Basket Audit: 'Poor Bundling' Evidence ---
# 逻辑：展示 Binders 并没有带动高价值电子产品，而是和低价值耗材捆绑
ax4 = axes[1, 1]

# 创建组合名称用于展示
df_mba['Pair'] = df_mba['Product_A'] + " + " + df_mba['Product_B']
# 取前 5 个最频繁的组合进行展示
df_mba_top = df_mba.head(5).sort_values('Times_Bought_Together', ascending=True)

# 绘图：使用深灰色调，强调“低价值耗材”的重复性
sns.barplot(data=df_mba_top, x='Times_Bought_Together', y='Pair', color='#636363', ax=ax4)

ax4.set_title("4. Market Basket Audit: 'Poor Bundling' Evidence\n(Frequency of Product Pairs)", fontsize=18, pad=15)
ax4.set_xlabel("Times Bought Together", fontsize=14)
ax4.set_ylabel("Product Pair", fontsize=14)

# 在条形图末尾标注具体次数
for i, v in enumerate(df_mba_top['Times_Bought_Together']):
    ax4.text(v + 3, i, str(v), color='black', va='center', fontweight='bold', fontsize=12)

# 重点标注：如果第一名是 Binders + Paper，加上高亮提示（可选文字说明）
ax4.annotate('Low-Value Bundling Trap', xy=(df_mba_top.iloc[-1]['Times_Bought_Together'], 4), 
             xytext=(df_mba_top.iloc[-1]['Times_Bought_Together'] - 100, 3.5),
             arrowprops=dict(facecolor='black', shrink=0.05, width=1, headwidth=5),
             fontsize=12, fontweight='bold', color='#c0392b')

# 整体修饰
sns.despine()
plt.tight_layout(rect=[0, 0.03, 1, 0.95])

# 保存
plt.savefig('Phase3_The_Surgical_Strike.png', bbox_inches='tight')
plt.show()

print("喵！新的 Visual Cue 已生成并保存为 Final_Audit_Visual_Cue.png！")