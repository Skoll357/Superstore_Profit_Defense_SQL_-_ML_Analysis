import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# 1. 加载数据 (请确保文件名与你的本地文件一致)
df_growth = pd.read_csv('your_path.01_annual_growth_analysis.csv')
df_kpi = pd.read_csv('your_path.01_core_KPI_overview.csv')
df_anomaly = pd.read_csv('your_path.01_macro_anomaly_impact.csv')

# 清洗百分比字符串
df_growth['Annual_Profit_Margin'] = df_growth['Annual_Profit_Margin'].str.rstrip('%').astype('float')
df_anomaly['Percentage_of_Total_Items'] = df_anomaly['Percentage_of_Total_Items'].str.rstrip('%').astype('float')

# 2. 设置全局风格
sns.set_theme(style="white") 
plt.rcParams["font.family"] = "serif"
plt.rcParams["font.serif"] = ["Times New Roman"]
plt.rcParams["axes.unicode_minus"] = False

# 3. 创建画布 (注意：这里只创建 Figure，不创建默认轴)
fig = plt.figure(figsize=(22, 11))
# 使用 GridSpec 进行布局控制
gs = fig.add_gridspec(2, 2, height_ratios=[1, 5], hspace=0.3, wspace=0.2)

# ==========================================================
# PART 1: 顶部 KPI 卡片 (彻底清空背景)
# ==========================================================
ax_header = fig.add_subplot(gs[0, :])
ax_header.axis('off') # 彻底关掉这一层的坐标轴

kpi_text = [
    ("Total Revenue", f"${df_kpi['Total_Revenue'][0]/1e6:.2f}M"),
    ("Net Profit", f"${df_kpi['Total_Net_Profit'][0]/1e3:.1f}K"),
    ("Avg. Margin", f"{df_kpi['Aggregate_Profit_Margin'][0]}"),
    ("Unique Customers", f"{df_kpi['Total_Unique_Customers'][0]}")
]

for i, (label, val) in enumerate(kpi_text):
    x_pos = 0.12 + i * 0.25
    ax_header.text(x_pos, 0.5, val, fontsize=42, fontweight='bold', ha='center', color='#2c3e50')
    ax_header.text(x_pos, 0.1, label, fontsize=18, ha='center', color='#7f8c8d')

# ==========================================================
# PART 2: 左侧图表 - 增长悖论 (Annual Growth Paradox)
# ==========================================================
ax1 = fig.add_subplot(gs[1, 0])

# 绘制柱状图 (Sales)
bars = ax1.bar(df_growth['Sales_Year'].astype(str), df_growth['Annual_Revenue'], 
               color='#d1d8e0', alpha=0.8, width=0.6, label='Annual Revenue')

ax1.set_title("Annual Sales vs. Profit Margin: The Scaling Paradox", fontsize=20, fontweight='bold', pad=25)
ax1.set_ylabel("Annual Revenue ($)", fontsize=14, labelpad=15)
ax1.tick_params(axis='both', labelsize=12)
ax1.grid(axis='y', linestyle='--', alpha=0.3)

# 绘制次坐标轴 (Margin %)
ax1_twin = ax1.twinx()
ax1_twin.plot(df_growth['Sales_Year'].astype(str), df_growth['Annual_Profit_Margin'], 
              marker='o', markersize=12, color='#e74c3c', linewidth=4, label='Profit Margin %')

ax1_twin.set_ylabel("Profit Margin (%)", fontsize=14, color='#e74c3c', labelpad=15)
ax1_twin.set_ylim(0, 20)
ax1_twin.tick_params(axis='y', colors='#e74c3c', labelsize=12)

# 标注 2017 下滑点
ax1_twin.annotate('Profitability Dip', xy=('2017', 12.59), xytext=(0.65, 0.85),
                  textcoords='axes fraction',
                  arrowprops=dict(facecolor='black', shrink=0.05, width=1, headwidth=8),
                  fontsize=13, fontweight='bold')

# 合并图例
lines, labels = ax1.get_legend_handles_labels()
lines2, labels2 = ax1_twin.get_legend_handles_labels()
ax1_twin.legend(lines + lines2, labels + labels2, loc='upper left', frameon=True)

# ==========================================================
# PART 3: 右侧图表 - 异常漏损 (Donut Chart)
# ==========================================================
ax2 = fig.add_subplot(gs[1, 1])

# 颜色设置
colors = ['#c0392b', '#e67e22', '#ecf0f1'] # 极端亏损/高折扣/正常

# --- 修改饼图(PART 3)部分 ---
wedges, texts, autotexts = ax2.pie(
    df_anomaly['Percentage_of_Total_Items'], 
    labels=df_anomaly['Operational_Anomaly_Tag'],
    # 修改1：精度改为 1.2f，这样 0.04% 就能显示出来了
    autopct='%1.2f%%', 
    startangle=140, 
    colors=colors, 
    pctdistance=0.82,
    # 修改2：给前两个异常分类加一点间隙，防止 0.04% 的标签挤在一起
    explode=[0.2, 0.05, 0], 
    textprops={'fontsize': 12, 'fontweight': 'bold', 'family': 'serif'}
)

# 绘制中心白圆（变成环形图）
centre_circle = plt.Circle((0,0), 0.70, fc='white')
ax2.add_artist(centre_circle)

# 中间文字标注
ax2.text(0, 0, f"9.2% Loss\nAnomalies", ha='center', va='center', fontsize=22, fontweight='bold', color='#c0392b')
ax2.set_title("Operational Anomaly Share: The Profit Leakage", fontsize=20, fontweight='bold', pad=25)

# ==========================================================
# 4. 最终美化
# ==========================================================
plt.suptitle("Phase 0: Macro-Level Landscape - Strategic Business Overview", 
             fontsize=28, fontweight='bold', y=0.98)

# 自动紧凑布局，并强制去掉任何多余的轴
plt.tight_layout(rect=[0, 0.03, 1, 0.95])
plt.savefig('Phase0_Overview.png', dpi=300, bbox_inches='tight')
plt.show()