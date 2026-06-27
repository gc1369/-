-- ============================================================
-- 淘宝用户购物行为分析 — 全流程SQL（sample_110k.csv）
-- 样本：110,000行 / 1,092用户 / 69,974商品 / 3,221类目
-- ============================================================
-- 使用方式（PowerShell）：
--   mysql -u root -p --local-infile=1 --default-character-set=utf8mb4
--   进入 mysql> 后逐段执行或 source 本文件
-- ============================================================

-- ============================================================
-- 一、环境准备
-- ============================================================

CREATE DATABASE IF NOT EXISTS taobao CHARACTER SET utf8mb4;
USE taobao;

DROP TABLE IF EXISTS 用户行为;

CREATE TABLE 用户行为 (
    用户ID   BIGINT       NOT NULL,
    商品ID   BIGINT       NOT NULL,
    类目ID   BIGINT       NOT NULL,
    行为类型 VARCHAR(10)  NOT NULL,
    时间戳   BIGINT       NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 导入CSV（⚠️ 把路径改成你电脑上的实际路径）
LOAD DATA LOCAL INFILE 'C:/tempdata/sample_110k.csv'
INTO TABLE 用户行为
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
(用户ID, 商品ID, 类目ID, 行为类型, @ts)
SET 时间戳 = CAST(@ts AS UNSIGNED);

SELECT COUNT(*) AS 总行数 FROM 用户行为;
SELECT 行为类型, COUNT(*) AS 数量 FROM 用户行为 GROUP BY 行为类型;

-- ============================================================
-- 二、数据清洗
-- ============================================================

-- 添加时间衍生列
ALTER TABLE 用户行为
    ADD COLUMN 日期时间 DATETIME NULL,
    ADD COLUMN 日期     DATE     NULL,
    ADD COLUMN 小时     TINYINT  NULL;

UPDATE 用户行为
SET 日期时间 = FROM_UNIXTIME(时间戳),
    日期     = DATE(FROM_UNIXTIME(时间戳)),
    小时     = HOUR(FROM_UNIXTIME(时间戳));

-- 删除日期范围外的数据
DELETE FROM 用户行为 WHERE 日期 < '2017-11-25' OR 日期 > '2017-12-03';

-- 缺失值检查
SELECT
    SUM(CASE WHEN 用户ID   IS NULL THEN 1 ELSE 0 END) AS 用户ID空值,
    SUM(CASE WHEN 商品ID   IS NULL THEN 1 ELSE 0 END) AS 商品ID空值,
    SUM(CASE WHEN 类目ID   IS NULL THEN 1 ELSE 0 END) AS 类目ID空值,
    SUM(CASE WHEN 行为类型 IS NULL THEN 1 ELSE 0 END) AS 行为类型空值,
    SUM(CASE WHEN 时间戳   IS NULL THEN 1 ELSE 0 END) AS 时间戳空值
FROM 用户行为;

-- 重复值检查与去重
DELETE t1 FROM 用户行为 t1
INNER JOIN 用户行为 t2
WHERE t1.用户ID = t2.用户ID AND t1.商品ID = t2.商品ID
  AND t1.类目ID = t2.类目ID AND t1.行为类型 = t2.行为类型
  AND t1.时间戳 = t2.时间戳 AND t1.日期 IS NULL;

-- 建索引
CREATE INDEX idx_uid  ON 用户行为(用户ID);
CREATE INDEX idx_beh  ON 用户行为(行为类型);
CREATE INDEX idx_date ON 用户行为(日期);
CREATE INDEX idx_hour ON 用户行为(小时);
CREATE INDEX idx_cat  ON 用户行为(类目ID);

-- 清洗后概况
SELECT
    COUNT(*)                               AS 总行数,
    COUNT(DISTINCT 用户ID)                 AS 用户数,
    COUNT(DISTINCT 商品ID)                 AS 商品数,
    COUNT(DISTINCT 类目ID)                 AS 类目数,
    MIN(日期)                              AS 起始日期,
    MAX(日期)                              AS 结束日期
FROM 用户行为;

-- ============================================================
-- 三、用户行为习惯分析
-- ============================================================

-- 3-1 KPI汇总
DROP TABLE IF EXISTS KPI汇总;
CREATE TABLE KPI汇总 AS
SELECT
    COUNT(DISTINCT 用户ID)                                              AS 总UV,
    COUNT(*)                                                            AS 总PV,
    COUNT(DISTINCT CASE WHEN 行为类型='buy' THEN 用户ID END)             AS 成交用户数,
    COUNT(DISTINCT 商品ID)                                              AS 商品数,
    COUNT(DISTINCT 类目ID)                                              AS 类目数,
    ROUND(COUNT(*) / COUNT(DISTINCT 用户ID), 1)                         AS 人均PV,
    ROUND(COUNT(DISTINCT CASE WHEN 行为类型='buy' THEN 用户ID END)
          * 100.0 / COUNT(DISTINCT 用户ID), 2)                          AS 整体成交率
FROM 用户行为;

SELECT * FROM KPI汇总;

-- 3-2 每日指标
DROP TABLE IF EXISTS 每日指标;
CREATE TABLE 每日指标 AS
SELECT
    日期,
    COUNT(*)                                                  AS PV,
    COUNT(DISTINCT 用户ID)                                    AS UV,
    SUM(CASE WHEN 行为类型='buy' THEN 1 ELSE 0 END)           AS 购买次数,
    COUNT(DISTINCT CASE WHEN 行为类型='buy' THEN 用户ID END)  AS 购买用户数,
    ROUND(COUNT(*) / COUNT(DISTINCT 用户ID), 1)               AS 人均PV,
    ROUND(COUNT(DISTINCT CASE WHEN 行为类型='buy' THEN 用户ID END)
          * 100.0 / COUNT(DISTINCT 用户ID), 2)                AS 成交率
FROM 用户行为
GROUP BY 日期 ORDER BY 日期;

SELECT * FROM 每日指标;

-- 3-3 每小时行为分布
DROP TABLE IF EXISTS 每小时行为;
CREATE TABLE 每小时行为 AS
SELECT 小时, 行为类型, COUNT(*) AS 行为次数, COUNT(DISTINCT 用户ID) AS UV
FROM 用户行为
GROUP BY 小时, 行为类型 ORDER BY 小时, 行为类型;

SELECT * FROM 每小时行为;

-- 3-4 活跃天数分布
DROP TABLE IF EXISTS 活跃天数分布;
CREATE TABLE 活跃天数分布 AS
SELECT 活跃天数, COUNT(*) AS 用户数,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS 占比
FROM (SELECT 用户ID, COUNT(DISTINCT 日期) AS 活跃天数 FROM 用户行为 GROUP BY 用户ID) t
GROUP BY 活跃天数 ORDER BY 活跃天数;

SELECT * FROM 活跃天数分布;

-- ============================================================
-- 四、AARRR漏斗转化分析
-- ============================================================

-- 4-1 用户行为标签
DROP TABLE IF EXISTS 用户行为标签;
CREATE TABLE 用户行为标签 AS
SELECT 用户ID,
    MAX(CASE WHEN 行为类型='pv'   THEN 1 ELSE 0 END) AS 有点击,
    MAX(CASE WHEN 行为类型='fav'  THEN 1 ELSE 0 END) AS 有收藏,
    MAX(CASE WHEN 行为类型='cart' THEN 1 ELSE 0 END) AS 有加购,
    MAX(CASE WHEN 行为类型='buy'  THEN 1 ELSE 0 END) AS 有购买,
    SUM(CASE WHEN 行为类型='buy'  THEN 1 ELSE 0 END) AS 购买次数
FROM 用户行为 GROUP BY 用户ID;

-- 4-2 漏斗数据
DROP TABLE IF EXISTS 漏斗数据;
CREATE TABLE 漏斗数据 AS
SELECT '点击' AS 阶段, SUM(有点击) AS UV, 1 AS 排序 FROM 用户行为标签
UNION ALL SELECT '收藏', SUM(有收藏), 2 FROM 用户行为标签
UNION ALL SELECT '加购', SUM(有加购), 3 FROM 用户行为标签
UNION ALL SELECT '购买', SUM(有购买), 4 FROM 用户行为标签;

ALTER TABLE 漏斗数据 ADD COLUMN 整体转化率 DECIMAL(8,2);
ALTER TABLE 漏斗数据 ADD COLUMN 环比转化率 DECIMAL(8,2);
UPDATE 漏斗数据 SET 整体转化率 = ROUND(UV * 100.0 / (SELECT UV FROM (SELECT UV FROM 漏斗数据 WHERE 排序=1) x), 2);
UPDATE 漏斗数据 t1 SET 环比转化率 = CASE
    WHEN 排序=1 THEN 100.00
    ELSE ROUND(t1.UV * 100.0 / (SELECT UV FROM (SELECT UV FROM 漏斗数据 WHERE 排序=t1.排序-1) t2), 2)
END;

SELECT * FROM 漏斗数据 ORDER BY 排序;

-- 4-3 四条转化路径
DROP TABLE IF EXISTS 转化路径;
CREATE TABLE 转化路径 AS
SELECT 'A-直接购买' AS 路径, COUNT(*) AS 人数,
    ROUND(COUNT(*)*100.0/(SELECT COUNT(*) FROM 用户行为标签 WHERE 有购买=1),1) AS 占比
FROM 用户行为标签 WHERE 有点击=1 AND 有购买=1 AND 有收藏=0 AND 有加购=0
UNION ALL SELECT 'B-收藏后购买', COUNT(*),
    ROUND(COUNT(*)*100.0/(SELECT COUNT(*) FROM 用户行为标签 WHERE 有购买=1),1)
FROM 用户行为标签 WHERE 有点击=1 AND 有收藏=1 AND 有购买=1 AND 有加购=0
UNION ALL SELECT 'C-加购后购买', COUNT(*),
    ROUND(COUNT(*)*100.0/(SELECT COUNT(*) FROM 用户行为标签 WHERE 有购买=1),1)
FROM 用户行为标签 WHERE 有点击=1 AND 有加购=1 AND 有购买=1 AND 有收藏=0
UNION ALL SELECT 'D-收藏加购后购买', COUNT(*),
    ROUND(COUNT(*)*100.0/(SELECT COUNT(*) FROM 用户行为标签 WHERE 有购买=1),1)
FROM 用户行为标签 WHERE 有点击=1 AND 有收藏=1 AND 有加购=1 AND 有购买=1;

SELECT * FROM 转化路径;

-- 4-4 跳失率与复购率
DROP TABLE IF EXISTS 跳失复购;
CREATE TABLE 跳失复购 AS
SELECT
    SUM(CASE WHEN 有点击=1 AND 有收藏=0 AND 有加购=0 AND 有购买=0 THEN 1 ELSE 0 END) AS 跳失用户数,
    ROUND(SUM(CASE WHEN 有点击=1 AND 有收藏=0 AND 有加购=0 AND 有购买=0 THEN 1 ELSE 0 END)
          *100.0/SUM(有点击), 2)                                               AS 跳失率,
    SUM(CASE WHEN 购买次数>=2 THEN 1 ELSE 0 END)                                AS 复购用户数,
    ROUND(SUM(CASE WHEN 购买次数>=2 THEN 1 ELSE 0 END)
          *100.0/SUM(有购买), 2)                                               AS 复购率
FROM 用户行为标签;

SELECT * FROM 跳失复购;

-- ============================================================
-- 五、类目偏好分析
-- ============================================================

-- 5-1 类目排行
DROP TABLE IF EXISTS 类目排行;
CREATE TABLE 类目排行 AS
SELECT 类目ID,
    SUM(CASE WHEN 行为类型='pv'   THEN 1 ELSE 0 END) AS 点击量,
    SUM(CASE WHEN 行为类型='fav'  THEN 1 ELSE 0 END) AS 收藏量,
    SUM(CASE WHEN 行为类型='cart' THEN 1 ELSE 0 END) AS 加购量,
    SUM(CASE WHEN 行为类型='buy'  THEN 1 ELSE 0 END) AS 购买量,
    COUNT(DISTINCT 用户ID)                           AS 覆盖用户数,
    COUNT(DISTINCT 商品ID)                           AS 商品数,
    ROUND(SUM(CASE WHEN 行为类型='buy' THEN 1 ELSE 0 END)*100.0
          / NULLIF(SUM(CASE WHEN 行为类型='pv' THEN 1 ELSE 0 END),0), 2) AS 转化率
FROM 用户行为
GROUP BY 类目ID ORDER BY 点击量 DESC;

SELECT * FROM 类目排行 LIMIT 20;

-- 5-2 商品四象限
DROP TABLE IF EXISTS 商品四象限;
CREATE TABLE 商品四象限 AS
SELECT 商品ID, 类目ID,
    SUM(CASE WHEN 行为类型='pv'  THEN 1 ELSE 0 END) AS 浏览量,
    SUM(CASE WHEN 行为类型='buy' THEN 1 ELSE 0 END) AS 购买量,
    COUNT(DISTINCT CASE WHEN 行为类型='buy' THEN 用户ID END) AS 购买用户数,
    ROUND(SUM(CASE WHEN 行为类型='buy' THEN 1 ELSE 0 END)*100.0
          / NULLIF(SUM(CASE WHEN 行为类型='pv' THEN 1 ELSE 0 END),0), 2) AS 转化率
FROM 用户行为
GROUP BY 商品ID, 类目ID HAVING 浏览量 > 0;

-- 添加四象限标签
ALTER TABLE 商品四象限 ADD COLUMN 象限 VARCHAR(20);
SET @avg_views = (SELECT AVG(浏览量) FROM 商品四象限);
SET @avg_buys  = (SELECT AVG(购买量) FROM 商品四象限 WHERE 购买量 > 0);
UPDATE 商品四象限 SET 象限 = CASE
    WHEN 浏览量 >= @avg_views AND 购买量 >= @avg_buys THEN '主打款'
    WHEN 浏览量 >= @avg_views AND 购买量 <  @avg_buys THEN '问题款'
    WHEN 浏览量 <  @avg_views AND 购买量 >= @avg_buys THEN '发展款'
    ELSE '长尾款' END;

SELECT 象限, COUNT(*) AS 商品数 FROM 商品四象限 GROUP BY 象限;

-- ============================================================
-- 六、RFM用户价值分析
-- ============================================================

-- 6-1 计算R和F
DROP TABLE IF EXISTS RF原始值;
CREATE TABLE RF原始值 AS
SELECT 用户ID,
    DATEDIFF('2017-12-03', MAX(日期)) AS R值,
    COUNT(*)                           AS F值
FROM 用户行为 WHERE 行为类型='buy' GROUP BY 用户ID;

SELECT COUNT(*) AS 购买用户数, ROUND(AVG(R值),1) AS 平均R, ROUND(AVG(F值),1) AS 平均F FROM RF原始值;

-- 6-2 SQL评分法分层
DROP TABLE IF EXISTS RFM分层;
CREATE TABLE RFM分层 AS
SELECT 用户ID, R值, F值,
    CASE WHEN R值<=1 THEN 4 WHEN R值<=3 THEN 3 WHEN R值<=6 THEN 2 ELSE 1 END AS R分数,
    CASE WHEN F值<=5 THEN 1 WHEN F值<=12 THEN 2 WHEN F值<=23 THEN 3
         WHEN F值<=35 THEN 4 WHEN F值<=50 THEN 5 ELSE 6 END AS F分数,
    CASE WHEN
        (CASE WHEN R值<=1 THEN 4 WHEN R值<=3 THEN 3 WHEN R值<=6 THEN 2 ELSE 1 END +
         CASE WHEN F值<=5 THEN 1 WHEN F值<=12 THEN 2 WHEN F值<=23 THEN 3
              WHEN F值<=35 THEN 4 WHEN F值<=50 THEN 5 ELSE 6 END) >= 9 THEN '重要价值用户'
        WHEN
        (CASE WHEN R值<=1 THEN 4 WHEN R值<=3 THEN 3 WHEN R值<=6 THEN 2 ELSE 1 END +
         CASE WHEN F值<=5 THEN 1 WHEN F值<=12 THEN 2 WHEN F值<=23 THEN 3
              WHEN F值<=35 THEN 4 WHEN F值<=50 THEN 5 ELSE 6 END) >= 6 THEN '重要发展用户'
        WHEN
        (CASE WHEN R值<=1 THEN 4 WHEN R值<=3 THEN 3 WHEN R值<=6 THEN 2 ELSE 1 END +
         CASE WHEN F值<=5 THEN 1 WHEN F值<=12 THEN 2 WHEN F值<=23 THEN 3
              WHEN F值<=35 THEN 4 WHEN F值<=50 THEN 5 ELSE 6 END) >= 4 THEN '重要保持用户'
        ELSE '一般挽留用户'
    END AS 用户分层
FROM RF原始值;

SELECT 用户分层, COUNT(*) AS 用户数,
       ROUND(COUNT(*)*100.0/(SELECT COUNT(*) FROM RFM分层), 1) AS 占比,
       ROUND(AVG(R值), 1) AS 平均R, ROUND(AVG(F值), 1) AS 平均F
FROM RFM分层 GROUP BY 用户分层
ORDER BY FIELD(用户分层, '重要价值用户','重要发展用户','重要保持用户','一般挽留用户');

-- ============================================================
-- 七、导出（供Python使用）
-- ============================================================
DROP TABLE IF EXISTS RF数据导出;
CREATE TABLE RF数据导出 AS SELECT 用户ID, R值 AS R, F值 AS F FROM RF原始值;
SELECT COUNT(*) FROM RF数据导出;

-- ============================================================
-- 完成！
-- ============================================================
SELECT '全部完成' AS 状态;
SELECT TABLE_NAME AS 结果表 FROM information_schema.TABLES
WHERE TABLE_SCHEMA='taobao' AND TABLE_NAME NOT IN ('用户行为')
ORDER BY TABLE_NAME;
