## 2.3 构建DWS层：按用户、视频、作者进行窗口级聚合
use kuairand_pure;

### 2.3.1 按照 用户×log_source窗口 粒度将exposure_log表进行聚合
drop table if exists dws_user_window_metrics;
create table if not exists dws_user_window_metrics as (
    select
-- 用户基础信息：
    user_id,                                                #用户id
    log_source,                                             #交互行为来源
-- 用户活跃特征
    count(distinct event_date) as active_days,              #用户在该窗口的活跃天数
    max(event_date) as last_seen_date,                      #用户在该窗口活跃的最后一天
-- 用户曝光规模
    count(*) as exposures,                                  #用户在窗口接收到的视频曝光数
    count(distinct video_id) as unique_exposed_videos,      #用户在窗口接收到的不同视频数
-- 用户观看行为
    sum(valid_view) as valid_view_events,                                                   #用户在窗口的有效观看事件数
    sum(long_view) as long_view_events,                                                     #用户在窗口的长播放事件数
    sum(complete_view) as complete_view_events,                                             #用户在窗口的完播事件数
    sum(play_time_ms) /1000. as total_play_time_s,                                          #用户在窗口的累计播放时间(单位：s)
-- 用户互动行为
    sum(is_like) as likes,                                  #用户在窗口的点赞行为次数
    sum(is_comment) as comments,                            #用户在窗口的评论行为次数
    sum(is_forward) as forwards,                            #用户在窗口的转发行为次数
    sum(is_profile_enter) as profile_enters,                #用户在窗口的进入作者主页的次数
    sum(is_follow) as follows,                              #用户在窗口的关注行为次数
    sum(is_hate) as hates,                                  #用户在窗口的点踩行为次数

-- 观看行为率
    SUM(valid_view) * 1. / NULLIF(COUNT(*), 0) AS valid_view_rate,                          #每次曝光产生有效观看的比例
    SUM(long_view) * 1. / NULLIF(COUNT(*), 0) AS long_view_rate,                            #每次曝光产生长播放的比例
    SUM(complete_view) * 1. / NULLIF(COUNT(*), 0) AS complete_view_rate,                    #每次曝光产生完播的比例
    sum(play_time_ms) * 0.001 /NULLIF(COUNT(*),0) as avg_play_time_per_exposure_s,          #用户每次接收到视频的平均播放时长(单位：s)
-- 互动行为率
    sum(is_like) * 1. /nullif(count(*),0) as like_rate,                     #用户每次视频曝光产生点赞行为的比例
    sum(is_comment) * 1. /nullif(count(*),0) as comment_rate,               #用户每次视频曝光产生评论行为的比例
    sum(is_forward) * 1. /nullif(count(*),0) as forward_rate,               #用户每次视频曝光产生转发行为的比例
    sum(is_hate) * 1. /nullif(count(*),0) as hate_rate,                     #用户每次视频曝光产生点踩行为的比例
    sum(is_profile_enter) * 1. /nullif(count(*),0) as profile_enter_rate,   #用户每次视频曝光产生进入作者主页行为的比例
    sum(is_follow) * 1. /nullif(count(*),0) as follow_rate                  #用户每次视频曝光产生关注行为的比例

    from exposure_log
    group by user_id, log_source
);

-- 添加主键
alter table dws_user_window_metrics add primary key (user_id,log_source);

-- =======================================================================================================

### 2.3.2 按照 视频×log_source窗口 粒度将exposure_log表进行聚合
drop table if exists dws_video_window_metrics;
create table if not exists dws_video_window_metrics as (
    select
-- 视频基础信息：
    video_id,                                   #视频id
    log_source,                                 #交互行为来源
-- 视频曝光规模
    count(*) as exposures,                                      #视频在窗口的曝光次数
    count(distinct user_id) as unique_exposed_users,            #视频在窗口触达去重用户数
-- 视频产生的观看行为
    sum(valid_view) as valid_view_events,                       #视频在窗口产生的有效观看次数
    sum(long_view) as long_view_events,                         #视频在窗口产生的长播放事件数
    sum(complete_view) as complete_view_events,                 #视频在窗口产生的完播事件数
    sum(play_time_ms) /1000. as total_play_time_s,              #视频在窗口产生的总播放时长(单位：s)
-- 视频产生的互动行为
    sum(is_like) as likes,                                      #视频在窗口获得点赞数
    sum(is_comment) as comments,                                #视频在窗口获得评论数
    sum(is_forward) as forwards,                                #视频在窗口获得转发数
    sum(is_hate) as hates,                                      #视频在窗口获得点踩数
    sum(is_profile_enter) as profile_enters,                    #视频在窗口获得进入作者主页行为数
    sum(is_follow) as follows,                                  #视频在窗口获得关注行为数

-- 视频产生的观看行为率
    sum(valid_view) * 1. /nullif(count(*),0) as valid_view_rate,                        #视频每次曝光的有效观看的比例
    sum(long_view) * 1. /nullif(count(*),0) as long_view_rate,                          #视频每次曝光产生长播放行为的比例
    SUM(complete_view) * 1. /nullif(count(*),0) AS complete_view_rate,                  #视频每次曝光的完播比例
    SUM(play_time_ms) * 0.001 /NULLIF(COUNT(*),0) AS avg_play_time_per_exposure_s,      #视频每次曝光的平均播放时长(单位：s)
-- 视频产生的互动行为率
    sum(is_like) * 1. /nullif(count(*),0) as like_rate,                     #视频每次曝光的点赞率
    sum(is_comment) * 1. /nullif(count(*),0) as comment_rate,               #视频每次曝光的评论率
    sum(is_forward) * 1. /nullif(count(*),0) as forward_rate,               #视频每次曝光的转发率
    sum(is_hate) * 1. /nullif(count(*),0) as hate_rate,                     #视频每次曝光的点踩率
    sum(is_profile_enter) * 1. /nullif(count(*),0) as profile_enter_rate,   #视频每次曝光的进入作者主页行为率
    sum(is_follow) * 1. /nullif(count(*),0) as follow_rate                  #视频每次曝光的关注作者行为率

    from exposure_log
    group by video_id, log_source
    );

-- （4）添加主键
alter table dws_video_window_metrics add primary key (video_id, log_source);

-- =======================================================================================================

### 2.3.3 按照 作者×log_source窗口 粒度将exposure_log链接dim_video_basic表进行聚合
drop table if exists dws_author_window_metrics;
create table if not exists dws_author_window_metrics as (
    select
-- 作者基础信息
    v.author_id,                                  #作者id
    f.log_source,                                 #交互行为来源
-- 作者作品曝光规模
    count(*) as exposures,                                       #作者的作品在窗口内总曝光次数
    count(distinct f.user_id) as unique_exposed_users,           #作者的作品在窗口内触达去重用户数
    count(distinct f.video_id) as unique_exposed_videos,         #作者在窗口内得到曝光的去重作品数
-- 作者作品产生的观看行为
    sum(f.valid_view) as valid_view_events,                      #作者的作品在窗口内产生的有效观看事件数
    sum(f.long_view) as long_view_events,                        #作者的作品在窗口内产生的长播放事件数
    sum(f.complete_view) as complete_view_events,                #作者的作品在窗口内产生的完播事件数
    sum(f.play_time_ms) /1000. as total_play_time_s,             #作者的作品在窗口内的总播放时长(单位：s)
-- 作者作品产生的互动行为
    sum(f.is_like) as likes,                                     #作者的作品在窗口内获得点赞数
    sum(f.is_comment) as comments,                               #作者的作品在窗口内获得评论数
    sum(f.is_forward) as forwards,                               #作者的作品在窗口内获得转发数
    sum(f.is_hate) as hates,                                     #作者的作品在窗口内获得点踩行为数
    sum(f.is_profile_enter) as profile_enters,                   #作者的作品在窗口内获得进入作者主页行为数
    sum(f.is_follow) as follows,                                 #作者的作品在窗口内获得关注作者行为数

-- 作者作品产生的观看行为率
    sum(f.valid_view) * 1. /nullif(count(*),0) AS valid_view_rate,                  #作者的作品在窗口内的有效观看率
    sum(f.long_view) * 1. /nullif(count(*),0) AS long_view_rate,                    #作者的作品在窗口内的长播放率
    SUM(f.complete_view) * 1./NULLIF(count(*),0) AS complete_view_rate,             #作者的作品在窗口内的完播率
    SUM(f.play_time_ms)* 0.001 /NULLIF(COUNT(*),0) AS avg_play_time_per_exposure_s, #作者的作品在窗口内每次曝光的平均播放时长(单位：s)

 -- 作者作品产生的互动行为率
    sum(f.is_like) * 1. /nullif(count(*),0) as like_rate,                   #作者的作品在窗口内的点赞率
    sum(f.is_comment) * 1. /nullif(count(*),0) as comment_rate,             #作者的作品在窗口内的评论率
    sum(f.is_forward) * 1. /nullif(count(*),0) as forward_rate,             #作者的作品在窗口内的转发率
    sum(f.is_hate) * 1. /nullif(count(*),0) as hate_rate,                   #作者的作品在窗口内的点踩率
    sum(f.is_profile_enter) * 1. /nullif(count(*),0) as profile_enter_rate, #作者的作品在窗口内的进入作者主页行为率
    sum(f.is_follow) * 1. /nullif(count(*),0) as follow_rate                #作者的作品在窗口内的关注作者行为率

    from exposure_log as f
    join dim_video_basic as v on f.video_id = v.video_id
    group by v.author_id, f.log_source
    );

 -- 添加主键
alter table dws_author_window_metrics add primary key (author_id, log_source);

-- =======================================================================================================

### 2.3.4 DWS层质量检查
-- （1）数据量一致性校验：检查各表总曝光量是否一致
SELECT
    (SELECT COUNT(*) FROM exposure_log) AS exposure_log总曝光记录,
    (SELECT SUM(exposures) FROM dws_user_window_metrics) AS user表曝光记录,
    (SELECT SUM(exposures) FROM dws_video_window_metrics) AS video表曝光记录,
    (SELECT SUM(exposures) FROM dws_author_window_metrics) AS author表曝光记录;

-- （2）DWS指标范围检查：各比例指标必须满足0 <= rate <= 1
SELECT 'dws_user_window_metrics' AS table_name, COUNT(*) AS invalid_rows
FROM dws_user_window_metrics
WHERE
    valid_view_rate     NOT BETWEEN 0 AND 1 OR
    long_view_rate      NOT BETWEEN 0 AND 1 OR
    complete_view_rate  NOT BETWEEN 0 AND 1 OR
    like_rate           NOT BETWEEN 0 AND 1 OR
    comment_rate        NOT BETWEEN 0 AND 1 OR
    forward_rate        NOT BETWEEN 0 AND 1 OR
    follow_rate         NOT BETWEEN 0 AND 1 OR
    profile_enter_rate  NOT BETWEEN 0 AND 1 OR
    hate_rate           NOT BETWEEN 0 AND 1

UNION ALL

SELECT 'dws_video_window_metrics', COUNT(*)
FROM dws_video_window_metrics
WHERE
    valid_view_rate     NOT BETWEEN 0 AND 1 OR
    long_view_rate      NOT BETWEEN 0 AND 1 OR
    complete_view_rate  NOT BETWEEN 0 AND 1 OR
    like_rate           NOT BETWEEN 0 AND 1 OR
    comment_rate        NOT BETWEEN 0 AND 1 OR
    forward_rate        NOT BETWEEN 0 AND 1 OR
    follow_rate         NOT BETWEEN 0 AND 1 OR
    profile_enter_rate  NOT BETWEEN 0 AND 1 OR
    hate_rate           NOT BETWEEN 0 AND 1

UNION ALL

SELECT 'dws_author_window_metrics', COUNT(*)
FROM dws_author_window_metrics
WHERE
    valid_view_rate     NOT BETWEEN 0 AND 1 OR
    long_view_rate      NOT BETWEEN 0 AND 1 OR
    complete_view_rate  NOT BETWEEN 0 AND 1 OR
    like_rate           NOT BETWEEN 0 AND 1 OR
    comment_rate        NOT BETWEEN 0 AND 1 OR
    forward_rate        NOT BETWEEN 0 AND 1 OR
    follow_rate         NOT BETWEEN 0 AND 1 OR
    profile_enter_rate  NOT BETWEEN 0 AND 1 OR
    hate_rate           NOT BETWEEN 0 AND 1;
#结果：三张表 invalid_rows 均为 0