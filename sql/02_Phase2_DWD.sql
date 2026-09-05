## 2.2 构建DWD层：对ODS层进行数据清洗与质量检查
-- 在对原始数据导入后，需对原始数据进行集中清洗，以便后续分析处理
use kuairand_pure;

-- =======================================================================================================

### 2.2.1清洗前期标准推荐交互日志表
-- （1）去重
drop table if exists dwd_log_standard_pre;
create table if not exists dwd_log_standard_pre as (
    select distinct * from ods_log_standard_pre where duration_ms > 0 AND play_time_ms >= 0 # 过滤视频时长或播放时长异常记录
);
-- （2）转换时间格式
alter table dwd_log_standard_pre add column event_time datetime;
alter table dwd_log_standard_pre add column event_date date;

update dwd_log_standard_pre set event_time = STR_TO_DATE(CONCAT(
        date,
        LPAD(hourmin,4,'0'),    #左侧补0直至变为4位数
        '00'),'%Y%m%d%H%i%s'    #标准时间格式
);                                                                  #将date和hourmin字段结合形成标准时间格式
update dwd_log_standard_pre set event_date = DATE(event_time);      #具体到天的时间

-- =======================================================================================================

### 2.2.2 清洗后期标准推荐交互日志表，操作同上
drop table if exists dwd_log_standard_post;
create table if not exists dwd_log_standard_post as (
    select distinct * from ods_log_standard_post where duration_ms > 0 AND play_time_ms >= 0 # 过滤视频时长或播放时长异常记录
);

alter table dwd_log_standard_post add column event_time datetime;
alter table dwd_log_standard_post add column event_date date;

update dwd_log_standard_post set event_time = STR_TO_DATE(CONCAT(
        date,
        LPAD(hourmin,4,'0'),
        '00'),'%Y%m%d%H%i%s'
);
update dwd_log_standard_post set event_date = DATE(event_time);
-- =======================================================================================================

### 2.2.3 清洗后期随机曝光交互日志表，操作同上
drop table if exists dwd_log_random_post;
create table if not exists dwd_log_random_post as (
    select distinct * from ods_log_random_post where duration_ms > 0 AND play_time_ms >= 0 # 过滤视频时长或播放时长异常记录
);

alter table dwd_log_random_post add column event_time datetime;
alter table dwd_log_random_post add column event_date date;

update dwd_log_random_post set event_time = STR_TO_DATE(CONCAT(
        date,
        LPAD(hourmin,4,'0'),
        '00'),'%Y%m%d%H%i%s'
);
update dwd_log_random_post set event_date = DATE(event_time);

-- =======================================================================================================

### 2.2.4 清洗用户特征表
drop table if exists dim_users;
-- （1）去重
create table if not exists dim_users as (
    select distinct * from ods_users
);
-- （2）将is_live_streamer字段的-124值全部改为0
update dim_users set is_live_streamer = 0 where is_live_streamer = -124;
-- （3）为user_id列添加主键
alter table dim_users add primary key (user_id);
-- user_active_degree存在6个unknown值，此处不做处理。

    -- =======================================================================================================

### 2.2.5 清洗视频基础特征表
drop table if exists dim_video_basic;
-- （1）去重
create table if not exists dim_video_basic as (
    select distinct * from ods_video_basic
);
-- （2）处理时间格式
alter table dim_video_basic add column upload_date date;
update dim_video_basic set upload_date = str_to_date(upload_dt,'%Y-%m-%d');

-- （3）缺失值处理：tag为标签字段，缺失填充为unknown;
--               music_type,video_duration为数值字段，缺失值保留NULL
update dim_video_basic set tag = 'unknown' where tag is null;
-- （4）为video_id列添加主键
ALTER TABLE dim_video_basic ADD PRIMARY KEY (video_id);
-- video_type存在1个unknown,upload_type存在80个unknown，此处不做处理。

-- =======================================================================================================

### 2.2.6 视频统计特征表清洗：无异常情况
drop table if exists dim_video_statistic;
create table if not exists dim_video_statistic as (
    select * from ods_video_statistic
);
-- 为video_id列添加主键
alter table dim_video_statistic add primary key (video_id);

-- =======================================================================================================

### 2.2.7 合并三张日志表
-- 三张日志表本质上是同一业务过程（字段也一致），只是时间范围不同。为了方便后续取表分析，对三张日志表进行合并。
-- （1）合并日志表，并标注数据来源
drop table if exists exposure_log;
create table if not exists exposure_log as (
    select *, 'standard_pre'  AS log_source from dwd_log_standard_pre
    union all
    select *, 'standard_post' AS log_source from dwd_log_standard_post
    union all
    select *, 'random_post'   AS log_source from dwd_log_random_post
);

-- (2)添加索引
alter table exposure_log add index idx_source_user(log_source, user_id);    # 为log_source和用户、视频id添加索引，因为后续查询经常用到
alter table exposure_log add index idx_source_video(log_source, video_id);

-- （3）新增两个特征字段：有效观看、完整播放。（有效观看字段是官方定义）
alter table exposure_log add column valid_view TINYINT;     # 是否有效观看：当视频时长<=7s时，观看时长≥视频时长；或者当视频时长>7s时，观看时长>7s（该定义为官方给出）
alter table exposure_log add column complete_view TINYINT;  # 是否完播：播放时长≥视频时长

update exposure_log set valid_view = case
                                    when duration_ms <= 7000 and play_time_ms >= duration_ms then 1
                                    when duration_ms > 7000 and play_time_ms > 7000 then 1
                                    else 0
                                end;

update exposure_log set complete_view = case
                                        when play_time_ms >= duration_ms THEN 1
                                        else 0
                                    end;

-- (4)long_view字段重新设置：（此处出现这个检查是因为后续处理的时候发现这个字段存在不符合官方解释的异常值）
-- 官方对long_view字段的解释是：当视频时长<=18s时，播放时长>=视频时长；当视频时长>18s时，播放时长>=18s
update exposure_log set long_view = case
                                    when duration_ms <= 18000 and play_time_ms >= duration_ms then 1
                                    when duration_ms > 18000 and play_time_ms >= 18000 then 1
                                    else 0
                                end;
-- =======================================================================================================

### 2.2.8 DWD层质量检查
-- （1）数据量一致性校验：检查各表行数是否一致
SELECT 'dwd_log_standard_pre' AS tbl, COUNT(*) AS hang FROM dwd_log_standard_pre
UNION ALL SELECT 'dwd_log_standard_post', COUNT(*) FROM dwd_log_standard_post
UNION ALL SELECT 'dwd_log_random_post',   COUNT(*) FROM dwd_log_random_post
UNION ALL SELECT 'dim_users',             COUNT(*) FROM dim_users
UNION ALL SELECT 'dim_video_basic',       COUNT(*) FROM dim_video_basic
UNION ALL SELECT 'dim_video_statistic',   COUNT(*) FROM dim_video_statistic
UNION ALL SELECT 'exposure_log',              COUNT(*) FROM exposure_log;
-- 检查发现行数一致：行数检查方法如下例：
-- dwd_log_standard_pre行数为： 1141112初始值 - 15609重复值 - 24062时长异常值 = 1101441

-- （2）event_time,event_date字段缺失值检查
SELECT 'dwd_log_standard_pre_et' AS log_source,
    SUM(CASE WHEN event_time IS NULL THEN 1 ELSE 0 END) AS event_null
FROM dwd_log_standard_pre
UNION ALL
SELECT 'dwd_log_standard_post_et',
    SUM(CASE WHEN event_time IS NULL THEN 1 ELSE 0 END)
FROM dwd_log_standard_post
UNION ALL
SELECT 'dwd_log_random_post_et',
    SUM(CASE WHEN event_time IS NULL THEN 1 ELSE 0 END)
FROM dwd_log_random_post
UNION ALL
SELECT 'dwd_log_standard_pre_ed',
       SUM(CASE WHEN event_date IS NULL THEN 1 ELSE 0 END)
FROM dwd_log_standard_pre
UNION ALL
SELECT 'dwd_log_standard_post_ed',
    SUM(CASE WHEN event_date IS NULL THEN 1 ELSE 0 END)
FROM dwd_log_standard_post
UNION ALL
SELECT 'dwd_log_random_post_ed',
    SUM(CASE WHEN event_date IS NULL THEN 1 ELSE 0 END)
FROM dwd_log_random_post;
# 结果为三张表 event_time,event_date 的缺失值均为 0

-- （3）来源一致性检查：验证每个 log_source 的时间范围和 is_rand 取值符合预期
SELECT log_source, MIN(event_date), MAX(event_date), MIN(is_rand), MAX(is_rand), COUNT(*)
FROM exposure_log
GROUP BY log_source;
-- 预期： standard_pre  = 2022-04-09 ~ 04-21, is_rand=0
--       standard_post = 2022-04-22 ~ 05-08, is_rand=0
--       random_post   = 2022-04-22 ~ 05-08, is_rand=1
