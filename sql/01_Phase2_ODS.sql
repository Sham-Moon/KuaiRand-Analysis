# Phase 2 数据基座与质量验证(构建ODS,DWD,DWS层)

## 2.1 构建ODS层，存储原始数据

### 2.1.1 创建数据库
create database if not exists kuairand_pure
default character set utf8mb4;                       # 数据库默认字符集
-- =======================================================================================================

### 2.1.2 创建前期标准推荐交互日志表、后期标准推荐交互日志表、后期随机曝光交互日志表
-- 字段的类型（宽度）以及约束条件，在phase 1的检查中已经明确。
drop table if exists ods_log_standard_pre;
create table if not exists  ods_log_standard_pre(
    user_id bigint,     # user_id数值范围较大，使用BIGINT
    video_id bigint,
    date int,
    hourmin int,
    time_ms bigint,
    is_click tinyint,   # 对于二值字段只需要tinyint
    is_like tinyint,
    is_follow tinyint,
    is_comment tinyint,
    is_forward tinyint,
    is_hate tinyint,
    long_view tinyint,
    play_time_ms bigint,
    duration_ms bigint,
    profile_stay_time bigint,
    comment_stay_time bigint,
    is_profile_enter tinyint,
    is_rand tinyint,
    tab int
) ;

-- 按照相同样式创建其他两个表
drop table if exists ods_log_standard_post;
drop table if exists ods_log_random_post;
create table  if not exists ods_log_standard_post like ods_log_standard_pre;
create table if not exists  ods_log_random_post like ods_log_standard_pre;

-- =======================================================================================================

### 2.1.3 创建用户特征表(ODS层只进行存储原始数据，后续应该将user_id设置为主键)
drop table if exists ods_users;
create table if not exists ods_users (
    user_id bigint,
    user_active_degree varchar(20),
    is_lowactive_period tinyint,
    is_live_streamer int,
    is_video_author tinyint,
    follow_user_num bigint,
    follow_user_num_range varchar(20),
    fans_user_num bigint,
    fans_user_num_range varchar(20),
    friend_user_num bigint,
    friend_user_num_range varchar(20),
    register_days int,
    register_days_range varchar(20),
    onehot_feat0 bigint, onehot_feat1 bigint, onehot_feat2 bigint,
    onehot_feat3 bigint, onehot_feat4 double, onehot_feat5 bigint,
    onehot_feat6 bigint, onehot_feat7 bigint, onehot_feat8 bigint,
    onehot_feat9 bigint, onehot_feat10 bigint, onehot_feat11 bigint,
    onehot_feat12 double, onehot_feat13 double,
    onehot_feat14 double, onehot_feat15 double,
    onehot_feat16 double, onehot_feat17 double      #onehot类型特征不做校验
);

-- =======================================================================================================

### 2.1.4 创建视频基础特征表（后续应设置video_id作主键）
drop table if exists ods_video_basic;
create table if not exists ods_video_basic (
    video_id bigint,
    author_id bigint,
    video_type varchar(10),               #该字段存在unknown值
    upload_dt varchar(20),
    upload_type varchar(30),              #该字段存在unknown值
    visible_status double,
    video_duration double,                #该字段存在缺失值
    server_width double,
    server_height double,
    music_id double,
    music_type double,                    #该字段存在缺失值
    tag TEXT                              #该字段是以','分隔的标签编号字符串；存在缺失值
);

-- =======================================================================================================

### 2.1.5 创建视频统计特征表
drop table if exists ods_video_statistic;
create table if not exists ods_video_statistic(
    video_id bigint ,
    counts double,
    show_cnt double,
    show_user_num double,
    play_cnt double,
    play_user_num double,
    play_duration double,
    complete_play_cnt double,
    complete_play_user_num double,
    valid_play_cnt double,
    valid_play_user_num double,
    long_time_play_cnt double,
    long_time_play_user_num double,
    short_time_play_cnt double,
    short_time_play_user_num double,
    play_progress double,
    comment_stay_duration double,
    like_cnt double,
    like_user_num double,
    click_like_cnt double,
    double_click_cnt double,
    cancel_like_cnt double,
    cancel_like_user_num double,
    comment_cnt double ,
    comment_user_num double ,
    direct_comment_cnt double ,
    reply_comment_cnt double,
    delete_comment_cnt double,
    delete_comment_user_num double,
    comment_like_cnt double,
    comment_like_user_num double,
    follow_cnt double ,
    follow_user_num double,
    cancel_follow_cnt double,
    cancel_follow_user_num double,
    share_cnt double,
    share_user_num double,
    download_cnt double,
    download_user_num double,
    report_cnt double,
    report_user_num double,
    reduce_similar_cnt double,
    reduce_similar_user_num double,
    collect_cnt double,
    collect_user_num double,
    cancel_collect_cnt double,
    cancel_collect_user_num double,
    direct_comment_user_num double,
    reply_comment_user_num double,
    share_all_cnt double,
    share_all_user_num double,
    outsite_share_all_cnt double
);

-- =======================================================================================================

### 2.1.6 将各csv数据导入创建好的表格中
-- SHOW VARIABLES LIKE 'local_infile';  # 查看本地文件导入权限
-- SET GLOBAL local_infile = 1;         # 打开mysql本地文件导入权限

-- 导入前期标准推荐交互日志表数据
LOAD DATA LOCAL INFILE 'data/log_standard_4_08_to_4_21_pure.csv'
INTO TABLE ods_log_standard_pre
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' #csv数据行内以,分隔，行间以换行符\n分隔
IGNORE 1 LINES ;                                  #第1行是标题，所以忽略

-- 导入后期标准推荐交互日志表数据
LOAD DATA LOCAL INFILE 'data/log_standard_4_22_to_5_08_pure.csv'
INTO TABLE ods_log_standard_post
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- 导入后期随机曝光交互日志表数据
LOAD DATA LOCAL INFILE 'data/log_random_4_22_to_5_08_pure.csv'
INTO TABLE ods_log_random_post
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- 导入用户特征表数据
LOAD DATA LOCAL INFILE 'data/user_features_pure.csv'
INTO TABLE ods_users
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    user_id,
    user_active_degree,
    is_lowactive_period,
    is_live_streamer,
    is_video_author,
    follow_user_num,
    follow_user_num_range,
    fans_user_num,
    fans_user_num_range,
    friend_user_num,
    friend_user_num_range,
    register_days,
    register_days_range,
    onehot_feat0,
    onehot_feat1,
    onehot_feat2,
    onehot_feat3,
    @onehot_feat4,
    onehot_feat5,
    onehot_feat6,
    onehot_feat7,
    onehot_feat8,
    onehot_feat9,
    onehot_feat10,
    onehot_feat11,
    @onehot_feat12,
    @onehot_feat13,
    @onehot_feat14,
    @onehot_feat15,
    @onehot_feat16,
    @onehot_feat17
)
SET
    onehot_feat4  = NULLIF(TRIM(@onehot_feat4), ''),
    onehot_feat12 = NULLIF(TRIM(@onehot_feat12), ''),
    onehot_feat13 = NULLIF(TRIM(@onehot_feat13), ''),
    onehot_feat14 = NULLIF(TRIM(@onehot_feat14), ''),
    onehot_feat15 = NULLIF(TRIM(@onehot_feat15), ''),
    onehot_feat16 = NULLIF(TRIM(@onehot_feat16), ''),
    onehot_feat17 = NULLIF(TRIM(@onehot_feat17), '');   # 避免空字符串直接写入数值字段造成类型异常或错误编码

-- 导入视频基础特征表数据
LOAD DATA LOCAL INFILE 'data/video_features_basic_pure.csv'
INTO TABLE ods_video_basic
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    video_id,
    author_id,
    video_type,
    upload_dt,
    upload_type,
    visible_status,
    @video_duration,
    @server_width,
    @server_height,
    @music_id,
    @music_type,
    @tag
)
SET
    video_duration = NULLIF(TRIM(@video_duration), ''),
    server_width   = NULLIF(TRIM(@server_width), ''),
    server_height  = NULLIF(TRIM(@server_height), ''),
    music_id       = NULLIF(TRIM(@music_id), ''),
    music_type     = NULLIF(TRIM(@music_type), ''),
    tag            = NULLIF(TRIM(TRAILING '\r' FROM @tag), '');

-- 导入视频统计特征表数据
LOAD DATA LOCAL INFILE 'data/video_features_statistic_pure.csv'
INTO TABLE ods_video_statistic
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- =======================================================================================================

-- 验证表格行数是否正确
SELECT 'ods_log_standard_pre' AS tbl, COUNT(*) FROM ods_log_standard_pre
UNION ALL SELECT 'ods_log_standard_post', COUNT(*) FROM ods_log_standard_post
UNION ALL SELECT 'ods_log_random_post', COUNT(*) FROM ods_log_random_post
UNION ALL SELECT 'ods_users', COUNT(*) FROM ods_users
UNION ALL SELECT 'ods_video_basic', COUNT(*) FROM ods_video_basic
UNION ALL SELECT 'ods_video_statistic', COUNT(*) FROM ods_video_statistic;
-- 检查发现没有丢失行数，数据导入成功
-- 此ODS层用于保存原始数据