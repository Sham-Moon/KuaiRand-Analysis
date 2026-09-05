# KuaiRand-Analysis Python 代码字典

本文件记录了 Python 分析中的核心变量、函数和模型对象。

SQL 数据表及字段说明见 [`data_dictionary.md`](data_dictionary.md)。

---

# 0. 公共配置与函数

## 0.1 路径与数据库连接

| 变量 | 类型 | 含义 | 使用范围 |
|---|---|---|---|
| `engine` | SQLAlchemy Engine | MySQL 数据库连接 | Phase 3～6 |
| `PROJECT_ROOT` | Path | 项目根目录 | 全局 |
| `DATA_DIR` | Path | 原始 CSV 文件目录 | Phase 1 |
| `OUTPUT_ROOT` | Path | 项目结果输出根目录 | Phase 3～6 |
| `OUT_PHASE3` | Path | Phase 3 用户分析结果输出目录 | Phase 3 |
| `OUT_PHASE4` | Path | Phase 4 视频 / 作者分析结果输出目录 | Phase 4 |
| `OUT_PHASE5` | Path | Phase 5 standard / random 分析结果输出目录 | Phase 5 |
| `OUT_PHASE6` | Path | Phase 6 `long_view` 预测结果输出目录 | Phase 6 |

## 0.2 公共函数

| 函数 | 作用 | 使用阶段 |
|---|---|---|
| `log1p_axis_values()` | 为长尾指标生成 `log1p` 可视化坐标 | Phase 3 / 4 |
| `rank_score()` | 将多个指标转换为可比较的排名得分 | Phase 3 / 4 |
| `gini()` | 计算视频曝光、作者作品数或作者曝光的集中程度 | Phase 4 |
| `get_pair()` | 将同一 `user_id` 或 `video_id` 在 `standard_post` 与 `random_post` 下的数据配对 | Phase 5 |
| `rank_biserial()` | 计算 Wilcoxon 配对比较对应的 rank-biserial 效应量 | Phase 5 |

---

#  Phase 3｜用户历史画像与分层

## 3.1 用户历史分析

| 变量 | 粒度 / 类型 | 含义                           | 主要用途 |
|---|---|------------------------------|---|
| `u` | 一行一个用户 | 用户历史画像表                      | Phase 3 用户分析主表 |
| `u_active` | 用户子集 | 在 `standard_pre` 中存在历史曝光的用户表 | 历史活跃、曝光、观看和互动描述 |
| `u_eligible` | 用户子集 | 历史曝光次数达到 P30 门槛、进入正式分层的用户表   | 用户历史分层 |

## 3.2 用户分层参数

| 变量 | 类型 | 含义 | 主要用途 |
|---|---|---|---|
| `USER_EXP_THRESHOLD` | int | 用户历史曝光次数 P30 门槛 | 排除极低曝光用户后进行行为率分析和正式分层 |
| `USER_ACTIVITY_CUTOFF` | float | `active_score` 的 P70 分界值 | 区分高活跃与一般活跃用户 |
| `USER_FEEDBACK_CUTOFF` | float | `feedback_score` 的 P70 分界值 | 区分高反馈与一般反馈用户 |

## 3.3 用户分层结果

| 变量 | 粒度 / 类型 | 含义 | 下游用途 |
|---|---|---|---|
| `user_seg` | 一行一个用户 | 用户最终历史分层结果 | 写回 MySQL，供 Phase 5 使用 |
| `user_seg_order` | list | 6 类用户的固定展示顺序 | Phase 3 / 5 图表和结果展示 |

---

# 4. Phase 4｜视频与作者历史分析

## 4.1 视频分析

| 变量 | 类型 | 含义 | 主要用途 |
|---|---|---|---|
| `v` | DataFrame | 视频历史特征表 | Phase 4 视频分析 |
| `v_exp` | DataFrame | 达到历史曝光描述门槛的视频 | 视频观看和互动表现分析 |
| `v_eligible` | DataFrame | 达到正式分层曝光门槛的视频 | 视频历史分层 |
| `VIDEO_EXP_THRESHOLD` | int | 视频历史曝光次数 P30 门槛 | 视频行为率描述和分层前筛选 |
| `VIDEO_EXPOSURE_CUTOFF` | float | 正式分层样本中 `exposures` 的 P70 分界值 | 区分高曝光与一般曝光视频 |
| `VIDEO_PERFORMANCE_CUTOFF` | float | `performance_score` 的 P70 分界值 | 区分高表现与一般表现视频 |
| `video_seg` | DataFrame | 视频最终历史分层结果 | 写回 MySQL，供 Phase 5 使用 |
| `video_seg_order` | list | 视频历史类型固定展示顺序 | Phase 4 / 5 图表和结果展示 |

## 4.2 作者分析

| 变量 | 类型 | 含义 | 主要用途 |
|---|---|---|---|
| `a` | DataFrame | 作者历史表现主 DataFrame | Phase 4 作者分析 |
| `a_exp` | DataFrame | 达到历史曝光描述门槛的作者 | 作者作品观看和互动表现分析 |
| `a_eligible` | DataFrame | 达到正式分层条件的作者 | 作者历史分层 |
| `AUTHOR_EXP_THRESHOLD` | int | 作者作品历史曝光次数 P30 门槛 | 作者行为率描述和分层前筛选 |
| `AUTHOR_VIEW_CUTOFF` | float | `view_score` 的 P70 分界值 | 区分观看表现较高的作者 |
| `AUTHOR_INTERACTION_CUTOFF` | float | `interaction_score` 的 P70 分界值 | 区分互动表现较高的作者 |
| `author_seg` | DataFrame | 作者最终历史分层结果 | 写回 MySQL，供 Phase 5 使用 |
| `author_seg_order` | list | 作者历史类型固定展示顺序 | Phase 4 / 5 图表和结果展示 |

---

# 5. Phase 5｜standard / random 对比分析

## 5.1 用户侧

| 变量 | 类型 | 含义 | 主要用途 |
|---|---|---|---|
| `users_post` | DataFrame | 用户在 `standard_post` / `random_post` 下的后期行为表现 | 用户侧分析主表 |
| `dual_user_ids` | Index | 同时出现在 `standard_post` 和 `random_post` 中的用户 | 确定双来源用户范围 |
| `base_user_id` | Index | 双来源且两侧曝光次数均达到 P30 的有效用户 | 用户反馈配对比较 |
| `users_paired_comparison` | DataFrame | 用户整体 Wilcoxon、rank-biserial 等比较结果 | 用户整体反馈差异分析 |
| `users_seg_paired_comparison` | DataFrame | 按历史用户类型得到的配对比较结果 | 不同历史用户类型反馈差异分析 |
| `user_video_share` | DataFrame | 不同历史用户类型在两种来源下接收到的历史视频类型曝光份额差 | 用户侧视频结构分析 |

## 5.2 视频侧

| 变量 | 类型 | 含义 | 主要用途 |
|---|---|---|---|
| `videos_post` | DataFrame | 视频在 `standard_post` / `random_post` 下获得的用户反馈 | 视频侧分析主表 |
| `dual_video_ids` | Index | 同时出现在两种后期曝光来源中的视频 | 确定双来源视频范围 |
| `base_video_ids` | Index | 双来源且两侧曝光次数均达到 P30 的有效视频 | 视频反馈配对比较 |
| `videos_paired_comparison` | DataFrame | 视频整体配对比较结果 | 同一批视频整体反馈差异分析 |
| `videos_seg_paired_comparison` | DataFrame | 按历史视频类型得到的配对比较结果 | 不同历史视频类型反馈差异分析 |

## 5.3 历史视频类型曝光分配

| 变量 | 类型 | 含义 | 主要用途 |
|---|---|---|---|
| `video_segment_exposure` | DataFrame | 各历史视频类型在 `standard_pre`、`standard_post`、`random_post` 中的曝光次数 | 三个窗口的视频曝光结构比较 |
| `video_segment_exp_wide` | DataFrame | 历史视频类型 × 三个窗口的曝光次数宽表 | 计算和展示曝光结构 |
| `video_segment_share_wide` | DataFrame | 历史视频类型 × 三个窗口的曝光份额宽表 | 比较各类型曝光份额 |
| `video_segment_exposure_result` | DataFrame | 最终用于展示的历史视频类型曝光份额结果表 | Phase 5 视频曝光分配图表和结论 |

## 5.4 作者侧

| 变量 | 类型 | 含义 | 主要用途 |
|---|---|---|---|
| `author_share` | DataFrame | 不同历史作者类型在 `standard` / `random` 下的作品曝光份额 | 作者作品曝光分配分析 |

## 5.5 统一比较设置

| 变量 | 类型 | 含义 | 主要用途 |
|---|---|---|---|
| `comparison_metrics` | list | Phase 5 统一比较的观看和互动指标列表 | 用户、视频整体及分层配对分析 |

---

# 6. Phase 6｜`long_view` 预测

## 6.1 模型样本与数据划分

| 变量 | 类型 | 含义 | 主要用途 |
|---|---|---|---|
| `model_sample` | DataFrame | `standard_post` 中的 `long_view` 预测样本 | Phase 6 建模主数据 |
| `train` | DataFrame | 约 60% 的训练集 | LightGBM 模型训练 |
| `valid` | DataFrame | 约 20% 的验证集 | 阈值选择 |
| `test` | DataFrame | 约 20% 的测试集 | 最终模型评估 |
| `features` | list | 最终模型输入特征列表 | LightGBM 训练和预测 |

## 6.2 模型与阈值

| 变量 | 类型 | 含义 | 主要用途 |
|---|---|---|---|
| `lgb_model` | LightGBM 模型 | 训练完成的 LightGBM 二分类模型 | 预测一次曝光产生 `long_view` 的概率 |
| `threshold_result` | DataFrame | 验证集不同阈值对应的 Precision、Recall 和 F1 | 比较候选分类阈值 |
| `BEST_THRESHOLD` | float | 验证集最终选定的分类阈值，当前为 **0.30** | 将预测概率转换为 0 / 1 分类结果 |

## 6.3 基线与测试集预测

| 变量 | 类型 | 含义 | 主要用途 |
|---|---|---|---|
| `baseline_score` | ndarray | 使用用户历史 `long_view_rate` 得到的基线预测分数 | 与 LightGBM ROC-AUC 进行比较 |
| `lgb_pred_test` | ndarray | LightGBM 对测试集输出的 `long_view` 预测概率 | 计算测试集 ROC-AUC、Precision、Recall、F1、Lift 等指标 |

---

# 7. 文档分工

- [`data_dictionary.md`](data_dictionary.md)：说明原始数据字段，以及各 Phase SQL 生成表的粒度、主要内容和用途；
- `code_dictionary.md`：说明 Python 中的主要变量、函数、阈值和模型对象；
- [`analysis_report.md`](analysis_report.md)：展示完整分析过程、主要图表和结论；
- [`run_order.md`](run_order.md)：说明 SQL 与 Python Notebook 的实际运行顺序。
