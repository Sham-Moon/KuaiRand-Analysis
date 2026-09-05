# 数据放置说明

本项目使用 KuaiRand-Pure 数据集。原始 CSV 体积较大且存在独立的数据使用条款，因此不随本仓库提交。

数据集主页：`https://kuairand.com/`

请将以下 6 个文件下载后直接放入本目录：

```text
data/
├── log_standard_4_08_to_4_21_pure.csv
├── log_standard_4_22_to_5_08_pure.csv
├── log_random_4_22_to_5_08_pure.csv
├── user_features_pure.csv
├── video_features_basic_pure.csv
├── video_features_statistic_pure.csv
└── README.md
```

文件用途：

| 文件 | 用途                                                    |
|---|-------------------------------------------------------|
| `log_standard_4_08_to_4_21_pure.csv` | `standard_pre`：画像快照日前历史标准推荐日志                         |
| `log_standard_4_22_to_5_08_pure.csv` | `standard_post`：画像快照日后标准推荐日志                          |
| `log_random_4_22_to_5_08_pure.csv` | `random_post`：画像快照日后随机曝光日志                            |
| `user_features_pure.csv` | 用户基础特征表                                               |
| `video_features_basic_pure.csv` | 视频基础属性表                                               |
| `video_features_statistic_pure.csv` | 视频统计特征表 |

`notebooks/01_kuairand_pure_analysis.ipynb` 会从项目根目录下的 `data/` 读取这些文件；SQL ODS 层也按 `data/...` 的路径示例导入。
