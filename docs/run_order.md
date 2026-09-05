# KuaiRand-Analysis 运行顺序

---

## 0. 环境准备

1. 安装 MySQL；
2. 安装 Python 依赖：

```bash
pip install -r requirements.txt
```

3. 将 6 个 KuaiRand-Pure CSV 放入 `data/`；
4. 复制 `.env.example` 为本机 `.env`，填写 MySQL 连接参数：

```text
DB_HOST
DB_PORT
DB_USER
DB_PASSWORD
DB_NAME
```

---

## 1. Notebook Phase 1：原始数据理解与质量检查

打开：

```text
notebooks/01_kuairand_pure_analysis.ipynb
```

先运行 Phase 1，确认：

- 6 个原始文件能够正常读取；
- 主键、缺失值、异常取值、重复记录等与数据字典一致；
- 后续数据清洗规则已经明确。

---

## 2. 执行 SQL 01～05

按顺序执行：

```text
sql/01_Phase2_ODS.sql
sql/02_Phase2_DWD.sql
sql/03_Phase2_DWS.sql
sql/04_Phase3_ADS_user_profile.sql
sql/05_Phase4_ADS_video_author_history.sql
```
---

## 3. Notebook Phase 3～4：完成历史分析与分层

继续运行 Notebook Phase 3 / Phase 4。

Notebook 会生成：

```text
user_seg
video_seg
author_seg
```

并将最终历史分层写回 MySQL：

```text
ads_user_segment_pre
ads_video_segment_pre
ads_author_segment_pre
```

Phase 5 SQL 运行前，需要先生成这三张表。

---

## 4. 执行 SQL 06：构建 Phase 5 分析资产

执行：

```text
sql/06_Phase5_ADS_standard_random_analysis.sql
```

生成：

```text
ads_user_post_behavior_feature
ads_video_post_behavior_feature
ads_author_segment_exposure_share
ads_user_video_segment_exposure_distribution
```
---

## 5. Notebook Phase 5：standard / random 差异分析

继续运行 Notebook Phase 5：

1. 用户双来源配对样本 + 双侧曝光 P30；
2. Wilcoxon + rank_biserial + BH-FDR；
3. 用户类型 × 视频类型曝光份额；
4. 视频双来源配对样本 + 双侧曝光 P30；
5. 不同视频历史类型的反馈差异；
6. 不同历史视频分层在 standard_pre / standard_post / random_post 的曝光份额；
7. 作者历史类型作品曝光份额。

---

## 6. 执行 SQL 07：构建 long_view 模型样本

执行：

```text
sql/07_Phase6_ADS_long_view_sample.sql
```
---

## 7. Notebook Phase 6：LightGBM

运行 Notebook Phase 6

---