# KuaiRand-Pure 数据字典

本文件分为两部分：

1. **原始数据表**：详细说明 KuaiRand-Pure 原始文件、数据粒度和各字段含义；
2. **项目生成表**：按照 Phase 2～6 整理项目中生成的主要数据表，仅说明表的粒度、主要内容和用途。

Python 中的主要变量、函数及其分析用途另见 [`code_dictionary.md`](code_dictionary.md)。

---

# 1. 原始数据表

## 1.1 原始文件清单

本项目共使用 6 个 KuaiRand-Pure 原始 CSV 文件：

| # | 文件名 | 行数 | 大小 | 说明 |
|:--|---|---:|---:|---|
| 1 | `log_standard_4_08_to_4_21_pure.csv` | 1,141,112 | ~80 MB | 2022-04-08～2022-04-21 标准推荐交互日志 |
| 2 | `log_standard_4_22_to_5_08_pure.csv` | 295,497 | ~21 MB | 2022-04-22～2022-05-08 标准推荐交互日志 |
| 3 | `log_random_4_22_to_5_08_pure.csv` | 1,186,059 | ~83 MB | 2022-04-22～2022-05-08 随机干预交互日志 |
| 4 | `user_features_pure.csv` | 27,285 | ~3.4 MB | 用户特征表 |
| 5 | `video_features_basic_pure.csv` | 7,583 | ~612 KB | 视频基础特征表 |
| 6 | `video_features_statistic_pure.csv` | 7,583 | ~6.3 MB | 视频历史统计特征表 |

---

## 1.2 三份交互日志
项目中将三份交互日志分别记为：

```text
standard_pre   时间窗口：2022-04-08 ～ 2022-04-21
standard_post  时间窗口：2022-04-22 ～ 2022-05-08
random_post    时间窗口：2022-04-22 ～ 2022-05-08
```

三份日志使用相同字段结构。

**粒度：** 一行 = 一次用户-视频曝光交互行为。

### 基本标识

| # | 字段 | 类型 | 说明 | 取值范围 / 单位 |
|:--|---|---|---|---|
| 1 | `user_id` | int64 | 用户 ID，可关联用户特征表 | 0–27284 |
| 2 | `video_id` | int64 | 视频 ID，可关联视频基础特征表 | 0–7582 |
| 3 | `date` | int64 | 日期编码 | `yyyymmdd`，如 20220421 |
| 4 | `hourmin` | int64 | 时分编码 | `hhmm`，如 1430 表示 14:30 |
| 5 | `time_ms` | int64 | Unix 毫秒时间戳 | 毫秒 |

### 观看与互动字段

| # | 字段 | 类型 | 说明 | 取值范围 |
|:--|---|---|---|---|
| 6 | `is_click` | int64 | 原始点击 / 有效播放相关字段；不同页面场景下含义并不完全相同，本项目不直接将其统一解释为有效观看 | 0 / 1 |
| 7 | `is_like` | int64 | 是否点赞 | 0 / 1 |
| 8 | `is_follow` | int64 | 是否关注作者 | 0 / 1 |
| 9 | `is_comment` | int64 | 是否评论 | 0 / 1 |
| 10 | `is_forward` | int64 | 是否转发 | 0 / 1 |
| 11 | `is_hate` | int64 | 是否产生点踩等负反馈 | 0 / 1 |
| 12 | `long_view` | int64 | 原始长播放字段；项目根据官方定义进一步核对并在 DWD 层统一重新计算 | 0 / 1 |
| 13 | `is_profile_enter` | int64 | 是否进入作者主页 | 0 / 1 |

### 播放与停留时长

| # | 字段 | 类型 | 说明 | 单位 |
|:--|---|---|---|---|
| 14 | `play_time_ms` | int64 | 本次曝光对应的播放时长 | 毫秒 |
| 15 | `duration_ms` | int64 | 视频总时长 | 毫秒 |
| 16 | `profile_stay_time` | int64 | 作者主页停留时长 | 毫秒 |
| 17 | `comment_stay_time` | int64 | 评论区停留时长 | 毫秒 |

### 曝光来源与场景

| # | 字段 | 类型 | 说明 | 取值范围 |
|:--|---|---|---|---|
| 18 | `is_rand` | int64 | 原始曝光来源标记 | 0 = 标准推荐，1 = 随机干预 |
| 19 | `tab` | int64 | 交互场景编码 | 0–14 |

---

## 1.3 用户特征表

文件：`user_features_pure.csv`

**粒度：** 一行 = 一个用户的各项信息。

### 标识与活跃信息

| # | 字段 | 类型 | 说明 | 取值 |
|:--|---|---|---|---|
| 1 | `user_id` | int64 | 用户 ID，主键 | 0–27284 |
| 2 | `user_active_degree` | object | 用户活跃度等级 | `full_active` / `high_active` / `middle_active` / `UNKNOWN` |
| 3 | `is_lowactive_period` | int64 | 是否处于低活跃期 | 0 / 1 |
| 4 | `is_live_streamer` | int64 | 原始主播相关标记 | 原始数据存在 1、-124 等取值；项目清洗时将非 1 值统一映射为 0 |

### 身份

| # | 字段 | 类型 | 说明 | 取值 |
|:--|---|---|---|---|
| 5 | `is_video_author` | int64 | 是否为视频作者 | 0 / 1 |

### 社交关系

| # | 字段 | 类型 | 说明 | 单位 / 取值 |
|:--|---|---|---|---|
| 6 | `follow_user_num` | int64 | 关注用户数 | 人 |
| 7 | `follow_user_num_range` | object | 关注数区间 | `0` / `(0,10]` / `(10,50]` / … / `500+` |
| 8 | `fans_user_num` | int64 | 粉丝数 | 人 |
| 9 | `fans_user_num_range` | object | 粉丝数区间 | `0` / `[1,10)` / … / `[1w,10w)` |
| 10 | `friend_user_num` | int64 | 好友数 | 人 |
| 11 | `friend_user_num_range` | object | 好友数区间 | `0` / `[1,5)` / … / `250+` |

### 注册信息

| # | 字段 | 类型 | 说明 | 单位 / 取值 |
|:--|---|---|---|---|
| 12 | `register_days` | int64 | 注册距数据统计时点的天数 | 天 |
| 13 | `register_days_range` | object | 注册天数区间 | `15-30` / … / `730+` |

### 匿名特征

这些字段由数据集提供，但业务含义未公开。本项目不对其作业务解释。

| # | 字段 | 类型 | 原始取值范围 |
|:--|---|---|---|
| 14 | `onehot_feat0` | int64 | 0–1 |
| 15 | `onehot_feat1` | int64 | 0–6 |
| 16 | `onehot_feat2` | int64 | 0–49 |
| 17 | `onehot_feat3` | int64 | 0–1470 |
| 18 | `onehot_feat4` | float64 | 0–14 |
| 19 | `onehot_feat5` | int64 | 0–33 |
| 20 | `onehot_feat6` | int64 | 0–2 |
| 21 | `onehot_feat7` | int64 | 0–117 |
| 22 | `onehot_feat8` | int64 | 0–453 |
| 23 | `onehot_feat9` | int64 | 0–6 |
| 24 | `onehot_feat10` | int64 | 0–4 |
| 25 | `onehot_feat11` | int64 | 0–4 |
| 26 | `onehot_feat12` | float64 | 0–1 |
| 27 | `onehot_feat13` | float64 | 0–1 |
| 28 | `onehot_feat14` | float64 | 0–1 |
| 29 | `onehot_feat15` | float64 | 0–1 |
| 30 | `onehot_feat16` | float64 | 0–1 |
| 31 | `onehot_feat17` | float64 | 0–1 |

---

## 1.4 视频基础特征表

文件：`video_features_basic_pure.csv`

**粒度：** 一行 = 一个视频的各项信息。

### 标识与作者

| # | 字段 | 类型 | 说明 |
|:--|---|---|---|
| 1 | `video_id` | int64 | 视频 ID，主键 |
| 2 | `author_id` | int64 | 视频对应的作者 ID |

### 视频基础属性

| # | 字段 | 类型 | 说明 | 取值 / 单位 |
|:--|---|---|---|---|
| 3 | `video_type` | object | 视频类型 | `NORMAL` / `AD` |
| 4 | `upload_dt` | object | 视频上传日期 | 如 `2022-04-10` |
| 5 | `upload_type` | object | 上传方式 | `LongImport` / `ShortImport` / `Kmovie` / `Web` / `LipsSync` / `PhotoCopy` / `PictureSet` 等 |
| 6 | `tag` | object | 逗号分隔的匿名视频标签 | 如 `39`、`12,65` |
| 7 | `visible_status` | float64 | 数据提取时的视频可见状态 | 0.0 为主 |

### 视频物理属性

| # | 字段 | 类型 | 说明 | 单位 |
|:--|---|---|---|---|
| 8 | `video_duration` | float64 | 视频时长，存在缺失值 | 毫秒 |
| 9 | `server_width` | float64 | 视频宽度 | 像素 |
| 10 | `server_height` | float64 | 视频高度 | 像素 |

### 背景音乐

| # | 字段 | 类型 | 说明 |
|:--|---|---|---|
| 11 | `music_id` | float64 | 背景音乐 ID |
| 12 | `music_type` | float64 | 背景音乐类型编码 |

---

## 1.5 视频历史统计特征表

文件：`video_features_statistic_pure.csv`

**粒度：** 一行 = 一个视频的更详细曝光信息。

该表包含 52 个字段。除 `video_id` 和 `counts` 外，其余主要为数据集提供的过去一个月日均统计指标。

### 基础字段

| # | 字段 | 类型 | 说明 |
|:--|---|---|---|
| 1 | `video_id` | int64 | 视频 ID，主键 |
| 2 | `counts` | float64 | 参与统计平均的“日期 × 场景”记录数量 |

### 曝光

| # | 字段 | 说明 | 单位 |
|:--|---|---|---|
| 3 | `show_cnt` | 日均曝光次数 | 次 / 天 |
| 4 | `show_user_num` | 日均曝光人数 | 人 / 天 |

### 播放

| # | 字段 | 说明 | 单位 |
|:--|---|---|---|
| 5 | `play_cnt` | 日均播放次数 | 次 / 天 |
| 6 | `play_user_num` | 日均播放人数 | 人 / 天 |
| 7 | `play_duration` | 日均总播放时长 | 毫秒 / 天 |
| 8 | `play_progress` | 平均播放进度 | 比例 |

### 完播

| # | 字段 | 说明 | 单位 |
|:--|---|---|---|
| 9 | `complete_play_cnt` | 日均完播次数 | 次 / 天 |
| 10 | `complete_play_user_num` | 日均完播人数 | 人 / 天 |

### 有效播放

| # | 字段 | 说明 | 单位 |
|:--|---|---|---|
| 11 | `valid_play_cnt` | 日均有效播放次数 | 次 / 天 |
| 12 | `valid_play_user_num` | 日均有效播放人数 | 人 / 天 |

### 长播放

| # | 字段 | 说明 | 单位 |
|:--|---|---|---|
| 13 | `long_time_play_cnt` | 日均长播放次数 | 次 / 天 |
| 14 | `long_time_play_user_num` | 日均长播放人数 | 人 / 天 |

### 短播放

| # | 字段 | 说明 | 单位 |
|:--|---|---|---|
| 15 | `short_time_play_cnt` | 日均短播放次数 | 次 / 天 |
| 16 | `short_time_play_user_num` | 日均短播放人数 | 人 / 天 |

### 评论区停留

| # | 字段 | 说明 | 单位 |
|:--|---|---|---|
| 17 | `comment_stay_duration` | 日均评论区停留总时长 | 毫秒 / 天 |

### 点赞

| # | 字段 | 说明 | 单位 |
|:--|---|---|---|
| 18 | `like_cnt` | 日均点赞次数 | 次 / 天 |
| 19 | `like_user_num` | 日均点赞人数 | 人 / 天 |
| 20 | `click_like_cnt` | 日均单击点赞次数 | 次 / 天 |
| 21 | `double_click_cnt` | 日均双击点赞次数 | 次 / 天 |
| 22 | `cancel_like_cnt` | 日均取消点赞次数 | 次 / 天 |
| 23 | `cancel_like_user_num` | 日均取消点赞人数 | 人 / 天 |

### 评论

| # | 字段 | 说明 | 单位 |
|:--|---|---|---|
| 24 | `comment_cnt` | 日均评论次数 | 次 / 天 |
| 25 | `comment_user_num` | 日均评论人数 | 人 / 天 |
| 26 | `direct_comment_cnt` | 日均直接评论次数 | 次 / 天 |
| 27 | `direct_comment_user_num` | 日均直接评论人数 | 人 / 天 |
| 28 | `reply_comment_cnt` | 日均回复评论次数 | 次 / 天 |
| 29 | `reply_comment_user_num` | 日均回复评论人数 | 人 / 天 |
| 30 | `delete_comment_cnt` | 日均删除评论次数 | 次 / 天 |
| 31 | `delete_comment_user_num` | 日均删除评论人数 | 人 / 天 |
| 32 | `comment_like_cnt` | 日均评论点赞次数 | 次 / 天 |
| 33 | `comment_like_user_num` | 日均评论点赞人数 | 人 / 天 |

### 关注

| # | 字段 | 说明 | 单位 |
|:--|---|---|---|
| 34 | `follow_cnt` | 日均关注次数 | 次 / 天 |
| 35 | `follow_user_num` | 日均关注人数 | 人 / 天 |
| 36 | `cancel_follow_cnt` | 日均取消关注次数 | 次 / 天 |
| 37 | `cancel_follow_user_num` | 日均取消关注人数 | 人 / 天 |

### 分享

| # | 字段 | 说明 | 单位 |
|:--|---|---|---|
| 38 | `share_cnt` | 日均分享次数 | 次 / 天 |
| 39 | `share_user_num` | 日均分享人数 | 人 / 天 |
| 40 | `share_all_cnt` | 日均全平台分享次数 | 次 / 天 |
| 41 | `share_all_user_num` | 日均全平台分享人数 | 人 / 天 |
| 42 | `outsite_share_all_cnt` | 日均站外分享次数 | 次 / 天 |

### 下载

| # | 字段 | 说明 | 单位 |
|:--|---|---|---|
| 43 | `download_cnt` | 日均下载次数 | 次 / 天 |
| 44 | `download_user_num` | 日均下载人数 | 人 / 天 |

### 举报与负反馈

| # | 字段 | 说明 | 单位 |
|:--|---|---|---|
| 45 | `report_cnt` | 日均举报次数 | 次 / 天 |
| 46 | `report_user_num` | 日均举报人数 | 人 / 天 |
| 47 | `reduce_similar_cnt` | 日均减少相似推荐次数 | 次 / 天 |
| 48 | `reduce_similar_user_num` | 日均减少相似推荐人数 | 人 / 天 |

### 收藏

| # | 字段 | 说明 | 单位 |
|:--|---|---|---|
| 49 | `collect_cnt` | 日均收藏次数 | 次 / 天 |
| 50 | `collect_user_num` | 日均收藏人数 | 人 / 天 |
| 51 | `cancel_collect_cnt` | 日均取消收藏次数 | 次 / 天 |
| 52 | `cancel_collect_user_num` | 日均取消收藏人数 | 人 / 天 |

> 该表的统计截止时间不能仅根据当前 CSV 明确确认，因此本项目只在 Phase 1 中检查其字段和数据情况，后续章节不参与分析。

---

# 2. 项目生成表

本部分记录了项目中参与分析的主要数据表，对其粒度和用途进行说明。

---

## 2.1 Phase 2｜ODS → DWD → DWS

对应 SQL：

```text
01_Phase2_ODS.sql
02_Phase2_DWD.sql
03_Phase2_DWS.sql
```

### ODS 原始入库表

| 表名 | 粒度 | 主要内容 | 用途        |
|---|---|---|-----------|
| `ods_log_standard_pre` | 一次用户-视频曝光记录 | 原始历史标准推荐日志 | 保留原始数据  |
| `ods_log_standard_post` | 一次用户-视频曝光记录 | 原始后期标准推荐日志 | 保留原始数据  |
| `ods_log_random_post` | 一次用户-视频曝光记录 | 原始后期随机干预日志 | 保留原始数据  |
| `ods_users` | `user_id` | 原始用户特征 | 保留原始数据 |
| `ods_video_basic` | `video_id` | 原始视频基础特征 | 保留原始数据 |
| `ods_video_statistic` | `video_id` | 原始视频历史统计特征 | 保留原始数据  |

### DWD 清洗表

| 表名 | 粒度 | 主要内容 | 用途 |
|---|---|---|---|
| `dwd_log_standard_pre` | 一次用户-视频曝光记录 | 清洗后的 `standard_pre` 日志 | 统一日志字段和数据质量 |
| `dwd_log_standard_post` | 一次用户-视频曝光记录 | 清洗后的 `standard_post` 日志 | 同上 |
| `dwd_log_random_post` | 一次用户-视频曝光记录 | 清洗后的 `random_post` 日志 | 同上 |
| `dim_users` | `user_id` | 清洗后的用户基础属性 | 用户信息关联 |
| `dim_video_basic` | `video_id` | 清洗后的视频、作者、时长、标签等基础属性 | 视频与作者信息关联 |
| `dim_video_statistic` | `video_id` | 清洗后的官方视频统计特征 | 保留原始统计信息 |
| `exposure_log` | 一次用户-视频曝光记录 | 合并三张日志，增加 `log_source`，统一有效观看、长播放、完播等字段 | Phase 2 之后曝光、观看和互动分析的统一明细表 |

### DWS 核心指标汇总表

| 表名 | 粒度 | 主要内容                           | 用途 |
|---|---|--------------------------------|---|
| `dws_user_window_metrics` | `user_id × log_source` | 用户窗口级活跃、曝光、观看、互动次数及对应行为率       | Phase 3 用户历史分析、Phase 5 用户反馈分析 |
| `dws_video_window_metrics` | `video_id × log_source` | 视频窗口级曝光、触达用户、观看、互动次数及对应行为率        | Phase 4 视频历史分析、Phase 5 视频反馈分析 |
| `dws_author_window_metrics` | `author_id × log_source` | 作者窗口级作品曝光、触达用户 / 视频、观看、互动次数及对应行为率 | Phase 4 作者历史分析 |

---

## 2.2 Phase 3｜用户历史画像与分层

对应 SQL：

```text
04_Phase3_ADS_user_profile.sql
```

| 表名 | 粒度 | 主要内容 | 用途 |
|---|---|---|---|
| `ads_user_pre_behavior_feature` | `user_id` | `standard_pre` 中的用户活跃、曝光、观看和互动指标 | 用户历史行为分析 |
| `bridge_video_tag` | `video_id × tag` | 将原始逗号分隔的视频标签拆成一行一个标签 | 用户视频标签偏好分析、Phase 6 标签匹配 |
| `ads_user_interest_profile` | `user_id` | 用户 Top1 / Top2 视频标签偏好、偏好数量和集中度 | 用户兴趣结构分析 |
| `ads_user_pre_performance_feature` | `user_id` | 合并用户基础属性、历史行为和视频标签偏好的用户历史画像宽表 | Phase 3 主分析、Phase 6 用户历史特征 |
| `ads_user_segment_pre` | `user_id` | 用户历史分层标签 | Notebook Phase 3 生成并写回 MySQL，供 Phase 5 使用 |

---

## 2.3 Phase 4｜视频与作者历史分析

对应 SQL：

```text
05_Phase4_ADS_video_author_history.sql
```

| 表名 | 粒度 | 主要内容 | 用途 |
|---|---|---|---|
| `ads_video_pre_performance_feature` | `video_id` | 视频基础属性、历史曝光、触达用户、观看和互动表现 | Phase 4 视频分析、视频分层、Phase 6 视频历史特征 |
| `ads_author_pre_performance_feature` | `author_id` | 作者作品数量、历史曝光、触达用户 / 视频以及作品整体观看和互动表现 | Phase 4 作者分析与作者分层 |
| `ads_video_segment_pre` | `video_id` | `video_id`、`author_id` 和历史视频分层 | Notebook Phase 4 生成并写回 MySQL，供 Phase 5 使用 |
| `ads_author_segment_pre` | `author_id` | `author_id` 和历史作者分层 | Notebook Phase 4 生成并写回 MySQL，供 Phase 5 使用 |

说明：

- 无历史曝光视频 / 作者的曝光和行为次数可以明确记为 0；
- 没有历史曝光时，观看率和互动率没有实际分母，因此保留 `NULL`。

---

## 2.4 Phase 5｜standard / random 对比分析

对应 SQL：

```text
06_Phase5_ADS_standard_random_analysis.sql
```

| 表名 | 粒度 | 主要内容 | 用途 |
|---|---|---|---|
| `ads_user_post_behavior_feature` | `user_id × log_source` | 用户在 `standard_post` / `random_post` 下的曝光、观看和互动反馈 | 用户整体及不同历史用户类型的配对比较 |
| `ads_video_post_behavior_feature` | `video_id × log_source` | 视频在 `standard_post` / `random_post` 下获得的观看和互动反馈 | 视频整体及不同历史视频类型的配对比较 |
| `ads_user_video_segment_exposure_distribution` | `user_segment × video_segment × log_source` | 双来源用户中，不同历史用户类型接收到的历史视频类型曝光份额 | 分析同一类用户在两种曝光来源下实际看到的视频结构 |
| `ads_author_segment_exposure_share` | `author_segment × log_source` | 不同历史作者类型作品获得的曝光次数和曝光份额 | 比较两种曝光来源下的作者作品分配 |

---

## 2.5 Phase 6｜`long_view` 预测

对应 SQL：

```text
07_Phase6_ADS_long_view_sample.sql
```

| 表名 | 粒度 | 主要内容 | 用途 |
|---|---|---|---|
| `ads_long_view_sample` | `standard_post` 中一次用户-视频曝光记录 | `target=long_view`，并关联用户历史行为、视频历史表现、视频标签偏好匹配及当前视频基础特征 | LightGBM `long_view` 模型训练与评估 |

该表中的历史行为特征均来自 `standard_pre`。本次曝光发生后的播放、点赞、评论等结果不作为模型输入特征。

如果用户或视频在 `standard_pre` 没有历史曝光，对应历史行为率保留 `NULL`，表示没有历史观测，不等同于行为率为 0。
