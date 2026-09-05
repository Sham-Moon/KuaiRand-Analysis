
USE kuairand_pure;

-- ===============================================================================================================================================
### 5.1.2 （1）构建后期用户行为表现表
-- 粒度： user_id × log_source * 用户各类行为表现

DROP TABLE IF EXISTS ads_user_post_behavior_feature;

CREATE TABLE ads_user_post_behavior_feature AS
SELECT
    d.user_id,                                                          # 用户ID
    s.user_segment,                                                     # 历史用户类型
    d.log_source,                                                       # 曝光类型（标准/随机）

    -- 曝光规模
    d.exposures,                                                        # 用户在该曝光来源下后期接收的总曝光次数

    -- 观看行为
    d.avg_play_time_per_exposure_s,                                     # 用户平均每次曝光平均播放时长
    d.valid_view_rate,
    d.long_view_rate,
    d.complete_view_rate,
    -- 互动行为率
    d.like_rate,
    d.comment_rate,
    d.forward_rate,
    d.hate_rate,
    d.profile_enter_rate,
    d.follow_rate

FROM dws_user_window_metrics AS d
LEFT JOIN ads_user_segment_pre as s on d.user_id = s.user_id    # 将用户类型标签写入后期表现表
WHERE d.log_source IN ('standard_post','random_post');          # 仅保留后期日志

ALTER TABLE ads_user_post_behavior_feature ADD PRIMARY KEY (user_id, log_source);


-- ===============================================================================================================================================
### 5.1.2 （2）构建后期视频行为表现表
-- 粒度： video_id × log_source * 视频各类行为表现

DROP TABLE IF EXISTS ads_video_post_behavior_feature;

CREATE TABLE ads_video_post_behavior_feature AS
SELECT
    d.video_id,                          # 视频ID
    s.video_segment,                     # 历史视频类型
    d.log_source,                        # 曝光类型（标准/随机）

    -- 触达规模
    d.exposures,                         # 视频在该曝光来源下后期总曝光次数

    -- 观看行为
    d.avg_play_time_per_exposure_s,
    d.valid_view_rate,
    d.long_view_rate,
    d.complete_view_rate,
    -- 互动行为率
    d.like_rate,
    d.comment_rate,
    d.forward_rate,
    d.hate_rate,
    d.profile_enter_rate,
    d.follow_rate

FROM dws_video_window_metrics AS d
LEFT JOIN ads_video_segment_pre as s on d.video_id = s.video_id     # 将视频类型标签写入后期表现表
WHERE d.log_source IN ('standard_post','random_post');              # 仅保留后期日志

ALTER TABLE ads_video_post_behavior_feature ADD PRIMARY KEY (video_id, log_source);

-- ===============================================================================================================================================

### 5.1.2 （3）构建后期作者类型曝光份额分配
-- 粒度： author_segment × log_source * 曝光份额
DROP TABLE IF EXISTS ads_author_segment_exposure_share;

CREATE TABLE ads_author_segment_exposure_share AS

    #拿到作者类型在该曝光来源下的曝光次数
WITH author_seg_exp AS (
    SELECT
        a.author_segment,               # 历史作者类型
        d.log_source,                   # 曝光来源
        SUM(d.exposures) AS exposures   # 该组合曝光次数（该作者类型在该曝光来源下的作品总曝光次数）
    FROM dws_author_window_metrics AS d
    LEFT JOIN ads_author_segment_pre AS a ON d.author_id = a.author_id  # 拿到历史作者类型
    WHERE d.log_source IN ('standard_post', 'random_post')
    GROUP BY a.author_segment, d.log_source
)
    # 构建作者类型曝光份额分配表
SELECT
    author_segment,
    log_source,
    exposures,
    exposures * 1. / SUM(exposures) OVER (PARTITION BY log_source) AS exposure_share    # 该组合曝光次数占该曝光来源下总曝光份额
FROM author_seg_exp;


-- ==========================================================================================================================================================================
-- ==========================================================================================================================================================================


### 5.2.4 构建后期“用户类型 × 视频类型“ 曝光分布表：在后期的曝光窗口中，不同的用户类型，分别接触到了什么类型的视频
-- 粒度： user_segment × video_segment × log_source

DROP TABLE IF EXISTS ads_user_video_segment_exposure_distribution;

CREATE TABLE ads_user_video_segment_exposure_distribution AS

    # 拿到后期双曝光来源用户的id
WITH dual_users AS (
    SELECT user_id
    FROM ads_user_post_behavior_feature
    GROUP BY user_id
    HAVING COUNT(DISTINCT log_source) = 2
),

    # 拿到每个用户类型对不同视频类型的曝光数
cross_exp AS (
    SELECT
        u.user_segment,
        v.video_segment,
        f.log_source,
        COUNT(*) AS exposures
    FROM exposure_log AS f
    JOIN dual_users AS d ON f.user_id = d.user_id                   # 取到后期双曝光来源用户
    LEFT JOIN ads_user_segment_pre AS u ON f.user_id = u.user_id    # 取到用户历史类型
    LEFT JOIN ads_video_segment_pre AS v ON f.video_id = v.video_id # 取到视频历史类型
    WHERE f.log_source IN ('standard_post', 'random_post')          # 取后期窗口
    GROUP BY u.user_segment, v.video_segment, f.log_source)

    # 构建最终曝光份额分配表
SELECT
    user_segment,   # 用户历史类型
    video_segment,  # 视频历史类型
    log_source,     # 曝光来源
    exposures,      # 该组合的曝光次数（该用户类型在该曝光来源下接触到的该视频类型的所有曝光次数）
    exposures * 1. / SUM(exposures) OVER (PARTITION BY user_segment, log_source) AS exposure_share  # 该组合曝光次数占该用户类型在该曝光来源下的曝光份额
FROM cross_exp;


-- =======================================================================================================================================

-- 检查历史分层，避免 user_segment / video_segment / author_segment 为 NULL。否则后续的 pivot_table(fill_value=0) 可能将标签缺失误处理为0曝光，导致曝光份额分析失真。
SELECT COUNT(*) AS null_segment_rows
FROM ads_user_video_segment_exposure_distribution
WHERE user_segment IS NULL OR video_segment IS NULL;
-- 结果必须为 0

SELECT COUNT(*) AS null_segment_rows
FROM ads_author_segment_exposure_share
WHERE author_segment IS NULL;
-- 结果必须为 0
