# Phase 4. 视频与作者历史表现分析
-- 本阶段基于standard_pre前期历史窗口，围绕视频和作者构建历史表现特征表。
USE kuairand_pure;

-- =====================================================================================================================

## 4.1 视频历史表现特征表
-- 基于前期历史窗口，汇总每个视频的曝光、观看、互动和作者意向表现。
DROP TABLE IF EXISTS ads_video_pre_performance_feature;

CREATE TABLE ads_video_pre_performance_feature AS
with
### 4.1.1 从桥接表中获取每个视频的标签数量
tag_summary AS (
    SELECT video_id,                # 视频id
           COUNT(*) AS tag_count    # 每个视频的标签数量
    FROM bridge_video_tag
    GROUP BY video_id
)

### 4.1.2 构建视频前期历史窗口表现特征表
SELECT
-- （1）视频基础属性（dim_video_basic,bridge_video_tag）
    v.video_id,                                     # 视频id
    v.author_id,                                    # 作者id
    v.video_duration/1000.   as video_duration_s,   # 视频时长，单位：s
    COALESCE(t.tag_count, 0) AS tag_count,          # 标签数量（来自桥接表）

-- （2）视频历史曝光、观看与互动行为特征
    -- 触达规模（dws_video_window_metrics）
    COALESCE(m.exposures, 0)             AS exposures,             # 前期历史窗口内总曝光次数
    COALESCE(m.unique_exposed_users, 0)  AS unique_exposed_users,  # 前期历史窗口内去重触达用户数
    -- 观看行为规模（dws_video_window_metrics）
    COALESCE(m.valid_view_events, 0)    AS valid_view_events,    # 有效观看次数
    COALESCE(m.long_view_events, 0)     AS long_view_events,     # 长播放次数
    COALESCE(m.complete_view_events, 0) AS complete_view_events, # 完播次数
    COALESCE(m.total_play_time_s, 0)    AS total_play_time_s,    # 总播放时长（单位：s）
    m.avg_play_time_per_exposure_s,                              # 每次曝光平均播放时长（秒）
    -- 互动行为规模（dws_video_window_metrics）
    COALESCE(m.likes, 0)          AS likes,                      # 点赞次数
    COALESCE(m.comments, 0)       AS comments,                   # 评论次数
    COALESCE(m.forwards, 0)       AS forwards,                   # 转发次数
    COALESCE(m.hates, 0)          AS hates,                      # 点踩次数
    COALESCE(m.profile_enters, 0) AS profile_enters,             # 进入作者主页次数
    COALESCE(m.follows, 0)        AS follows,                    # 关注作者次数

    -- 历史行为率（dws_video_window_metrics）
    m.valid_view_rate,                      # 有效观看率
    m.long_view_rate,                       # 长播放率
    m.complete_view_rate,                   # 完播率
    m.like_rate,                            # 点赞率
    m.comment_rate,                         # 评论率
    m.forward_rate,                         # 转发率
    m.profile_enter_rate,                   # 主页进入率
    m.follow_rate,                          # 关注率
    m.hate_rate                             # 点踩率

FROM dim_video_basic AS v
LEFT JOIN tag_summary AS t  ON v.video_id = t.video_id
LEFT JOIN dws_video_window_metrics AS m ON v.video_id = m.video_id AND m.log_source = 'standard_pre';

ALTER TABLE ads_video_pre_performance_feature ADD PRIMARY KEY (video_id);

-- =====================================================================================================================

## 4.2 作者历史表现特征
-- 基于standard_pre前期历史窗口，汇总每个作者的作品供给、触达规模、观看和互动表现。
DROP TABLE IF EXISTS ads_author_pre_performance_feature;

CREATE TABLE ads_author_pre_performance_feature AS
WITH
### 4.2.1 从dim_video_basic中获取：上传了视频的全量作者数据，及截止至快照日上传的作品数量
author_base AS (
    SELECT
        author_id,
        COUNT(DISTINCT video_id) AS uploaded_video_count           # 上传的去重作品数（包括0曝光作品）
    FROM dim_video_basic
    GROUP BY author_id
)

### 4.2.2 构建作者历史表现特征表（直接读取窗口级 dws_author_window_metrics，行为率已算好直接透传）
-- 该表不对dim_users关联，因为两个表的作者、用户并不匹配
SELECT
-- （1）作者基础属性（author_base）
    b.author_id,            # 作者id

-- （2）作者作品的曝光、观看与互动行为特征
    -- 作品曝光与触达规模（author_base,dws_author_window_metrics）
    b.uploaded_video_count,                                                 # 截至快照日上传的作品数（包括0曝光作品，去重）
    COALESCE(m.unique_exposed_videos,0)  AS unique_exposed_videos,          # 前期历史窗口内实际获得曝光的作品数（去重）
    COALESCE(m.exposures, 0)             AS exposures,                      # 前期历史窗口内作品总曝光次数
    COALESCE(m.unique_exposed_users, 0)  AS unique_exposed_users,           # 前期历史窗口内实际触达的去重用户数
    -- 观看行为（dws_author_window_metrics）
    COALESCE(m.valid_view_events, 0)     AS valid_view_events,    # 有效观看次数
    COALESCE(m.long_view_events, 0)      AS long_view_events,     # 长播放次数
    COALESCE(m.complete_view_events, 0)  AS complete_view_events, # 完播次数
    COALESCE(m.total_play_time_s, 0)     AS total_play_time_s,    # 总播放时长（单位：s）
    m.avg_play_time_per_exposure_s,                               # 每次曝光平均播放时长（单位：s）
    -- 互动行为（dws_author_window_metrics）
    COALESCE(m.likes, 0)           AS likes,          # 点赞次数
    COALESCE(m.comments, 0)        AS comments,       # 评论次数
    COALESCE(m.forwards, 0)        AS forwards,       # 转发次数
    COALESCE(m.profile_enters, 0)  AS profile_enters, # 进入作者主页次数
    COALESCE(m.follows, 0)         AS follows,        # 关注作者次数
    COALESCE(m.hates, 0)           AS hates,          # 点踩次数

    -- 观看与互动行为率（dws_author_window_metrics）
    m.valid_view_rate,                 # 有效观看率
    m.long_view_rate,                  # 长播放率
    m.complete_view_rate,              # 完播率
    m.like_rate,                       # 点赞率
    m.comment_rate,                    # 评论率
    m.forward_rate,                    # 转发率
    m.hate_rate,                       # 点踩率
    m.profile_enter_rate,              # 主页进入率
    m.follow_rate                      # 关注率

FROM author_base AS b
LEFT JOIN dws_author_window_metrics AS m ON b.author_id = m.author_id AND m.log_source = 'standard_pre';


ALTER TABLE ads_author_pre_performance_feature ADD PRIMARY KEY (author_id);

-- =====================================================================================================================

-- 质量检查
-- （1）总行数 + 主键唯一
SELECT COUNT(*) AS 总行数, COUNT(DISTINCT video_id) AS 去重视频数
FROM ads_video_pre_performance_feature;
SELECT COUNT(*) AS 总行数, COUNT(DISTINCT author_id) AS 去重作者数
FROM ads_author_pre_performance_feature;

-- （2）视频表rate 是否都在 0~1
SELECT COUNT(*) AS 异常行数
FROM ads_video_pre_performance_feature
WHERE valid_view_rate NOT BETWEEN 0 AND 1
   OR long_view_rate NOT BETWEEN 0 AND 1
   OR complete_view_rate NOT BETWEEN 0 AND 1
   OR like_rate NOT BETWEEN 0 AND 1
   OR comment_rate NOT BETWEEN 0 AND 1
   OR forward_rate NOT BETWEEN 0 AND 1
   OR profile_enter_rate NOT BETWEEN 0 AND 1
   OR follow_rate NOT BETWEEN 0 AND 1
   OR hate_rate NOT BETWEEN 0 AND 1;

-- 作者表 rate 是否都在 0~1
SELECT COUNT(*) AS 异常行数
FROM ads_author_pre_performance_feature
WHERE valid_view_rate NOT BETWEEN 0 AND 1
   OR long_view_rate NOT BETWEEN 0 AND 1
   OR complete_view_rate NOT BETWEEN 0 AND 1
   OR like_rate NOT BETWEEN 0 AND 1
   OR comment_rate NOT BETWEEN 0 AND 1
   OR forward_rate NOT BETWEEN 0 AND 1
   OR profile_enter_rate NOT BETWEEN 0 AND 1
   OR follow_rate NOT BETWEEN 0 AND 1
   OR hate_rate NOT BETWEEN 0 AND 1;

-- （3）历史零曝光数量
SELECT COUNT(*) AS 零曝光视频数 FROM ads_video_pre_performance_feature WHERE exposures = 0;
SELECT COUNT(*) AS 零曝光作者数 FROM ads_author_pre_performance_feature WHERE exposures = 0;
