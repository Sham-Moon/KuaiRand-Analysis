use kuairand_pure;

## 6.1 构建模型样本：将standard_post交互日志中的 用户-视频曝光行为 连接用户前期(standard_pre)特征与视频前期(standard_pre)特征

DROP TABLE IF EXISTS ads_long_view_sample;

CREATE TABLE ads_long_view_sample AS
SELECT
    -- （1）样本定位字段
    f.user_id,
    f.video_id,
    f.log_source,

    -- （2）预测目标（标签）
    f.long_view AS target,

    -- （3）样本特征：（从用户、视频历史行为特征中挑选几个关键特征）
    -- 用户历史行为：
    u.exposures                     AS user_hist_exposures,
    u.valid_view_rate               AS user_hist_valid_view_rate,
    u.long_view_rate                AS user_hist_long_view_rate,
    u.complete_view_rate            AS user_hist_complete_view_rate,
    u.avg_play_time_per_exposure_s  AS user_hist_avg_play_time_per_exposure_s,
    -- 用户历史活跃特征
    u.active_days,              # 前期历史窗口活跃天数

    -- 用户兴趣匹配：当前视频tag是否命中用户Top1/Top2偏好
    CASE WHEN EXISTS (SELECT 1 FROM bridge_video_tag AS bt
                      WHERE bt.video_id = f.video_id AND bt.tag = u.top1_interest_tag)
         THEN 1 ELSE 0 END AS top1_tag_match,
    CASE WHEN EXISTS (SELECT 1 FROM bridge_video_tag AS bt
                      WHERE bt.video_id = f.video_id AND bt.tag = u.top2_interest_tag)
         THEN 1 ELSE 0 END AS top2_tag_match,

     -- 视频属性：
    f.duration_ms,
    -- 视频历史表现
    v.exposures                     AS video_hist_exposures,
    v.valid_view_rate               AS video_hist_valid_view_rate,
    v.long_view_rate                AS video_hist_long_view_rate,
    v.complete_view_rate            AS video_hist_complete_view_rate,
    v.avg_play_time_per_exposure_s  AS video_hist_avg_play_time_per_exposure_s

FROM exposure_log AS f
LEFT JOIN ads_user_pre_performance_feature AS u ON f.user_id = u.user_id    # 拿到用户历史行为
LEFT JOIN ads_video_pre_performance_feature AS v ON f.video_id = v.video_id # 拿到视频历史表现

WHERE f.log_source = 'standard_post';   # 只保留standard_post预测样本

-- ========================================================================================================================
-- 查询总样本量
SELECT
    COUNT(*) AS sample_count,
    COUNT(DISTINCT user_id) AS user_count,
    COUNT(DISTINCT video_id) AS video_count,
    AVG(target) AS long_view_rate
FROM ads_long_view_sample;

