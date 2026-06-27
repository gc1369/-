# -*- coding: utf-8 -*-
"""
淘宝用户行为分析 — K-means RFM聚类验证
使用前安装：pip install pymysql pandas scikit-learn --break-system-packages
"""
import pymysql, pandas as pd
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score
import warnings
warnings.filterwarnings('ignore')

# ══════════════════════════════════════
# 配置（改成你的MySQL密码）
# ══════════════════════════════════════
CFG = {
    'host': 'localhost',
    'port': 3306,
    'user': 'root',
    'password': '123456',
    'database': 'taobao',
    'charset': 'utf8mb4'
}

# ══════════════════════════════════════
# 1. 读RF数据
# ══════════════════════════════════════
print('>>> [1/5] 读取RF数据...')
conn = pymysql.connect(**CFG)
rfm = pd.read_sql("SELECT 用户ID, R, F FROM RF数据导出", conn)
print(f'    读取 {len(rfm)} 个购买用户')
print(f'    R值范围: {rfm["R"].min()}~{rfm["R"].max()}, 均值: {rfm["R"].mean():.1f}')
print(f'    F值范围: {rfm["F"].min()}~{rfm["F"].max()}, 均值: {rfm["F"].mean():.1f}')

# ══════════════════════════════════════
# 2. 标准化 + 手肘法
# ══════════════════════════════════════
print('\n>>> [2/5] 标准化 + 手肘法确定K...')
scaler = StandardScaler()
rf_scaled = scaler.fit_transform(rfm[['R', 'F']])

sil_scores = []
for k in range(2, 9):
    km = KMeans(n_clusters=k, random_state=42, n_init=10)
    labels = km.fit_predict(rf_scaled)
    sil_scores.append(silhouette_score(rf_scaled, labels))
    print(f'    K={k}, 轮廓系数={sil_scores[-1]:.4f}')

best_k = range(2, 9)[sil_scores.index(max(sil_scores))]
print(f'    最优K={best_k}')

# ══════════════════════════════════════
# 3. K-means聚类
# ══════════════════════════════════════
print(f'\n>>> [3/5] K-means聚类(K={best_k})...')
km = KMeans(n_clusters=best_k, random_state=42, n_init=10)
rfm['簇'] = km.fit_predict(rf_scaled)

stats = rfm.groupby('簇').agg(
    用户数=('用户ID', 'count'),
    平均R=('R', 'mean'),
    平均F=('F', 'mean')
).round(2)
stats['占比'] = round(stats['用户数'] * 100 / len(rfm), 2)
print(stats)

# 标签映射
avg_r, avg_f = rfm['R'].mean(), rfm['F'].mean()
def label(row):
    rh, fh = row['平均R'] <= avg_r, row['平均F'] >= avg_f
    if rh and fh: return '价值用户'
    elif rh: return '新用户'
    elif fh: return '保持用户'
    else: return '挽留用户'
stats['Kmeans标签'] = stats.apply(label, axis=1)
print('\n', stats[['用户数', '占比', '平均R', '平均F', 'Kmeans标签']])

# ══════════════════════════════════════
# 4. 对比SQL分层
# ══════════════════════════════════════
print('\n>>> [4/5] 对比SQL评分分层...')
sqlseg = pd.read_sql("SELECT 用户ID, 用户分层 FROM RFM分层", conn)
cmap = stats['Kmeans标签'].to_dict()
compare = rfm[['用户ID', '簇']].merge(sqlseg, on='用户ID')
compare['Kmeans标签'] = compare['簇'].map(cmap)
cross = pd.crosstab(compare['用户分层'], compare['Kmeans标签'], margins=True)
print(cross)

# ══════════════════════════════════════
# 5. 写回MySQL
# ══════════════════════════════════════
print('\n>>> [5/5] 写回MySQL...')
cur = conn.cursor()
cur.execute("DROP TABLE IF EXISTS Kmeans结果")
cur.execute("""CREATE TABLE Kmeans结果 (
    用户ID BIGINT PRIMARY KEY, R INT, F INT, 簇 INT, 标签 VARCHAR(20)
)""")
labels_map = stats['Kmeans标签'].to_dict()
rfm['标签'] = rfm['簇'].map(labels_map)
for _, row in rfm.iterrows():
    cur.execute("INSERT INTO Kmeans结果 VALUES (%s,%s,%s,%s,%s)",
                (int(row['用户ID']), int(row['R']), int(row['F']),
                 int(row['簇']), row['标签']))
conn.commit()
cur.execute("SELECT 标签, COUNT(*) AS n FROM Kmeans结果 GROUP BY 标签 ORDER BY n DESC")
for r in cur.fetchall():
    print(f'    {r[0]}: {r[1]}人')

cur.close(); conn.close()
print('\n>>> 完成！Kmeans结果写入 Kmeans结果 表。')
