# Phase 3. 用户画像与历史特征建设
-- 本阶段使用画像快照日前的历史数据，构建一套“一行一个用户”的历史画像
-- 历史特征窗口：2022-04-08 至 2022-04-21
-- 日志来源：standard_pre
-- 画像快照日：2022-04-21
use kuairand_pure;

-- =====================================================================================================================================================================

## 3.1 构建用户历史表现特征表：对dws_user_window_metrics表读取在前期历史窗口(standard_pre)的数据

DROP table if EXISTS ads_user_pre_behavior_feature;

CREATE table if not exists ads_user_pre_behavior_feature AS
SELECT
     user_id,                                                                # 用户id
-- 用户活跃特征
     active_days,                                                              # 用户在历史窗口内活跃天数
     last_seen_date,                                                           # 用户在历史窗口内最后活跃日
    DATEDIFF(DATE('2022-04-21'),  last_seen_date) AS days_since_last_active,   # 快照日距离用户最后活跃日的天数
-- 用户曝光规模
     exposures,                                                                # 用户在历史窗口内获得的视频曝光次数
     unique_exposed_videos,                                                    # 用户在历史窗口内触达的去重视频数
-- 用户观看行为
     valid_view_events,                                                        # 用户在历史窗口内总有效观看行为数
     long_view_events,                                                         # 用户在历史窗口内总长播放行为数
     complete_view_events,                                                     # 用户在历史窗口内总完播行为数
     total_play_time_s,                                                        # 用户在历史窗口内总播放时长（s）
     avg_play_time_per_exposure_s ,                                            # 用户单次曝光平均播放时长（s）
-- 用户互动行为
     likes ,
     comments,
     forwards ,
     follows,
     profile_enters,
     hates,

-- 观看行为率
     valid_view_rate,
     long_view_rate,
     complete_view_rate,
-- 互动行为率
     like_rate,
     comment_rate,
     forward_rate,
     hate_rate,
     profile_enter_rate,
     follow_rate

FROM dws_user_window_metrics
WHERE log_source = 'standard_pre';    # 取前期历史窗口

alter table ads_user_pre_behavior_feature add primary key (user_id);    #给user_id添加主键

-- =====================================================================================================================================================================

## 3.2 用户视频偏好画像表：根据用户在standard_pre日志中的观看、互动和负反馈行为，推断用户对不同视频标签的相对偏好倾向。
-- 基于用户在standard_pre历史窗口中的观看、互动和负反馈行为，结合视频标签，计算用户对不同视频标签的相对偏好，形成用户视频偏好画像表。

-- （1）构建视频—标签桥接表：将dim_video_basic中的tag字段规范化为一行一个 video_id × tag 的表
DROP TABLE IF EXISTS bridge_video_tag;

CREATE TABLE if not exists bridge_video_tag AS
SELECT DISTINCT v.video_id, CAST(TRIM(jt.tag_value) AS UNSIGNED) AS tag
FROM dim_video_basic AS v
CROSS JOIN JSON_TABLE(
    CONCAT('["', REPLACE(REPLACE(REPLACE(TRIM(v.tag), '"', ''), '\'', ''), ',', '","'), '"]'),
    '$[*]' COLUMNS (tag_value VARCHAR(20) PATH '$')
) AS jt
WHERE TRIM(v.tag) <> 'unknown' AND TRIM(jt.tag_value) REGEXP '^[0-9]+$';
-- 为桥接表添加主键
ALTER TABLE bridge_video_tag ADD PRIMARY KEY (video_id, tag);


DROP TABLE IF EXISTS ads_user_interest_profile;
CREATE TABLE if not exists ads_user_interest_profile AS
WITH
-- 从视频-标签桥接表读取已拆分的标签
	video_tag AS (
	    SELECT video_id, tag FROM bridge_video_tag
),

-- （2）user_tag_score:计算用户对每个标签的偏好得分(自定义各指标权重)：
    user_tag_score AS (
    SELECT
        f.user_id,
        vt.tag,
        SUM(f.valid_view*1 + f.long_view*2 + f.is_like*4 + f.is_comment*3 + f.is_forward*3 + f.is_follow*5 - f.is_hate*5) AS interest_score
-- 用户对该标签的累计加权净偏好得分。偏好得分采用自定义权重：
    # 有效观看+1：表示用户产生了初步观看偏好
    # 长播放 +2：表示用户进行了较深度观看
    # 点赞   +4：通常属于较明确的正向反馈
    # 评论   +3：评论可能包含批评或质疑，不一定完全代表喜欢
    # 转发   +3：转发可能用于讨论或批评，不一定完全代表认可
    # 关注   +5：表示用户对作者产生了较强的偏好
    # 点踩   -5：属于明确的负反馈
    FROM exposure_log AS f                                  # 从exposure_log中得到用户行为
    JOIN video_tag AS vt ON f.video_id = vt.video_id    # 从标签桥接表中得到视频tag
    WHERE f.log_source = 'standard_pre'
    GROUP BY f.user_id,vt.tag    # 按照每行一个 user_id × tag 进行聚合
),

    -- （3）all_score_summary:从user_tag_score表汇总每个用户的全部标签净得分,包含正向行为加分和点踩扣分。
all_score_summary AS (
    SELECT
        user_id,
        SUM(interest_score) AS net_interest_score   # 用户全部标签净得分
    FROM user_tag_score
    GROUP BY user_id
),

-- （4）positive_tag_rank:筛选正偏好标签并排名，对user_tag_score中每个用户的正向偏好标签得分进行排序
    positive_tag_rank AS (
    SELECT
        user_id,
        tag,
        interest_score,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY interest_score DESC, tag) AS interest_rank,      # 标签在用户内的正向偏好得分排名,同排名按偏好编号排序
        SUM(interest_score) OVER (PARTITION BY user_id) AS total_positive_interest_score                  # 用户全部正向偏好标签得分之和
    FROM user_tag_score
    where interest_score > 0
),

-- （5）positive_interest_summary：从positive_tag_rank汇总用户正向偏好画像,并提取Top1、Top2标签及其得分
    positive_interest_summary AS (
    SELECT
        user_id,
        MAX(CASE WHEN interest_rank = 1 THEN tag END) AS top1_interest_tag,              # 正向偏好得分top1的标签
        MAX(CASE WHEN interest_rank = 2 THEN tag END) AS top2_interest_tag,              # 正向偏好得分top2的标签
        MAX(CASE WHEN interest_rank = 1 THEN interest_score END) AS top1_interest_score, # Top1标签对应的偏好得分
        MAX(CASE WHEN interest_rank = 2 THEN interest_score END) AS top2_interest_score, # Top2标签对应的偏好得分
        COUNT(*) AS interest_diversity,                                                  # 用户正向偏好标签数量
        MAX(total_positive_interest_score) AS total_positive_interest_score,             # 用户全部正向偏好标签得分之和
        MAX(CASE WHEN interest_rank = 1 THEN interest_score END) * 1.
              / NULLIF(MAX(total_positive_interest_score),0) AS top1_interest_share,     #Top1标签得分占全部正向偏好得分的比例
        MAX(CASE WHEN interest_rank = 2 THEN interest_score END) * 1.
              / NULLIF(MAX(total_positive_interest_score),0) AS top2_interest_share      #Top2标签得分占全部正向偏好得分的比例
    FROM positive_tag_rank
    GROUP BY user_id
)

-- （6）生成最终用户偏好画像表：以ads_user_pre_behavior_feature为主表，汇总用户正向偏好画像与标签净得分。
SELECT
    b.user_id,                  # 取出ads_user_pre_behavior_feature中的所有user_id
    p.top1_interest_tag,        # 用户正向偏好得分排名第1的视频标签
    p.top1_interest_score,      # Top1标签对应的偏好得分
    p.top2_interest_tag,        # 用户正向偏好得分排名第2的视频标签
    p.top2_interest_score,      # Top2标签对应的偏好得分
    COALESCE(p.interest_diversity,0) AS interest_diversity,      # 用户正向偏好标签数量
    COALESCE(p.total_positive_interest_score,0) AS total_positive_interest_score, # 用户全部正向偏好标签得分之和
    p.top1_interest_share,      # Top1标签得分占全部正向偏好得分的比例，没有正向偏好标签时为NULL
    p.top2_interest_share,      # Top2标签得分占全部正向偏好得分的比例，正向偏好标签少于两个时为NULL
    COALESCE(a.net_interest_score,0) AS net_interest_score       # 用户全部有效标签的加权净行为得分

FROM ads_user_pre_behavior_feature b
LEFT JOIN positive_interest_summary p ON b.user_id = p.user_id
LEFT JOIN all_score_summary a ON b.user_id = a.user_id;

-- 为用户偏好画像表添加主键
ALTER TABLE ads_user_interest_profile ADD PRIMARY KEY (user_id);

-- =====================================================================================================================================================================

## 3.3 最终用户历史行为画像表
-- 将dim_users,ads_user_pre_behavior_feature,ads_user_interest_profile表合并，得到用户画像宽表，用于后续分析
-- 表粒度：user_id * 用户各类特征
drop table if exists ads_user_pre_performance_feature;
create table if not exists ads_user_pre_performance_feature as
    select
-- （1）用户基础属性（dim_users）
        -- 用户身份
        u.user_id,
        u.is_video_author,
        u.is_live_streamer,
        -- 注册属性
        u.register_days,
        -- 社交关系属性
        u.fans_user_num,
        u.follow_user_num,
        u.friend_user_num,
        -- 活跃程度
        u.is_lowactive_period,
        u.user_active_degree,

-- （2）用户历史行为特征(ads_user_pre_behavior_feature)
        -- 历史活跃特征
        coalesce(b.active_days,0) as active_days,                    # 用户在历史窗口期活跃天数，若存在缺失值则取0
        b.last_seen_date,                                            # 用户在历史窗口期活跃的最后一天
        b.days_since_last_active,                                    # last_seen_date距离快照日的天数
        -- 历史曝光规模
        COALESCE(b.exposures, 0) AS exposures,                       # 用户在历史窗口内获得的视频曝光次数
        COALESCE(b.unique_exposed_videos,0) AS unique_exposed_videos,# 用户在历史窗口内触达的去重视频数

        -- 历史观看行为
        COALESCE(b.valid_view_events, 0)    AS valid_view_events,    # 用户在历史窗口内总有效观看视频行为数
        COALESCE(b.long_view_events, 0)     AS long_view_events,     # 用户在历史窗口内总长播放视频行为数
        COALESCE(b.complete_view_events, 0) AS complete_view_events, # 用户在历史窗口内总完播视频行为数
        COALESCE(b.total_play_time_s, 0)    AS total_play_time_s,    # 用户在历史窗口内总播放时长
        b.avg_play_time_per_exposure_s,                              # 用户在历史窗口内单次曝光平均播放时长（s）

        -- 历史互动行为
        COALESCE(b.likes, 0)          AS likes,                      # 用户在历史窗口内总点赞行为次数
        COALESCE(b.comments, 0)       AS comments,                   # 用户在历史窗口内总评论行为次数
        COALESCE(b.forwards, 0)       AS forwards,                   # 用户在历史窗口内总转发行为次数
        COALESCE(b.follows, 0)        AS follows,                    # 用户在历史窗口内总关注行为次数
        COALESCE(b.profile_enters, 0) AS profile_enters,             # 用户在历史窗口内总进入作者主页行为次数
        COALESCE(b.hates, 0)          AS hates,                      # 用户在历史窗口内总点踩行为次数
        -- 历史行为率
        b.valid_view_rate,
        b.long_view_rate,
        b.complete_view_rate,
        b.like_rate,
        b.comment_rate,
        b.forward_rate,
        b.follow_rate,
        b.profile_enter_rate,
        b.hate_rate,

-- （3）用户偏好画像（ads_user_interest_profile）
        i.top1_interest_tag,    # 用户正向偏好得分Top1的视频标签
        i.top1_interest_score,  # 用户Top1偏好标签对应的得分
        i.top1_interest_share,  # 用户Top1偏好得分占所有正向偏好得分的比例
        i.top2_interest_tag,    # 用户正向偏好得分Top2的视频标签
        i.top2_interest_score,  # 用户Top2偏好标签对应的得分
        i.top2_interest_share,  # 用户Top2偏好得分占所有正向偏好得分的比例
        COALESCE(i.interest_diversity, 0) AS interest_diversity,                        # 用户正向偏好标签数量，没有正向偏好标签时填充为0
        COALESCE(i.total_positive_interest_score, 0) AS total_positive_interest_score,  # 用户所有正向偏好标签得分之和，没有正向偏好标签时填充为0
        COALESCE(i.net_interest_score, 0) AS net_interest_score                         # 用户所有标签的加权净行为得分

    from dim_users as u
    left join ads_user_pre_behavior_feature b on u.user_id = b.user_id
    left join ads_user_interest_profile i on u.user_id = i.user_id;

ALTER TABLE ads_user_pre_performance_feature ADD PRIMARY KEY (user_id);

-- =====================================================================================================================================================================

## 3.4 检查用户画像宽表在历史窗口期有活跃的用户，以及各指标范围是否正确
SELECT
    COUNT(*) AS total_users,
    SUM(CASE WHEN active_days > 0 THEN 1 ELSE 0 END) AS users_with_pre_behavior,
    MIN(active_days) AS min_active_days,
    MAX(active_days) AS max_active_days,
    MIN(valid_view_rate) AS min_valid_view_rate,
    MAX(valid_view_rate) AS max_valid_view_rate,
    MIN(long_view_rate) AS min_long_view_rate,
    MAX(long_view_rate) AS max_long_view_rate,
    MIN(complete_view_rate) AS min_complete_view_rate,
    MAX(complete_view_rate) AS max_complete_view_rate,
    MIN(hate_rate) AS min_hate_rate,
    MAX(hate_rate) AS max_hate_rate,
    MIN(top1_interest_share) AS min_top1_share,
    MAX(top1_interest_share) AS max_top1_share,
    MIN(top2_interest_share) AS min_top2_share,
    MAX(top2_interest_share) AS max_top2_share,
    SUM(CASE
            WHEN top1_interest_share < 0
              OR top1_interest_share > 1
              OR top2_interest_share < 0
              OR top2_interest_share > 1
            THEN 1
            ELSE 0 END) AS invalid_share_count,
    SUM(CASE WHEN top2_interest_share > top1_interest_share THEN 1 ELSE 0 END) AS invalid_rank_count
FROM ads_user_pre_performance_feature;

#检查一下所有表的行数
SELECT
    (SELECT COUNT(*) FROM ads_user_pre_behavior_feature)
        AS behavior_users,

    (SELECT COUNT(*) FROM ads_user_interest_profile)
        AS interest_users,

    (SELECT COUNT(*) FROM ads_user_pre_performance_feature)
        AS profile_users,

    (SELECT COUNT(*) FROM dim_users)
        AS dim_users_count;

