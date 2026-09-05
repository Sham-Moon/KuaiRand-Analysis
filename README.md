# KuaiRand-Pure 用户、视频与曝光差异分析

- 本项目基于 KuaiRand-Pure 推荐日志，完成原始数据检查清洗和 ODS/DWD/DWS 分层数仓建设，整理用户、视频和作者的历史行为指标并进行分层；
- 在此基础上，分析 standard 与 random 两种曝光来源下的视频曝光分布和用户反馈差异，并基于历史用户和视频特征构建 LightGBM 模型，预测一次 standard_post 视频曝光是否会产生 long_view，形成从数据处理、业务分析到预测建模的完整流程；
- 项目目标主要是回答以下问题：
```text
1. standard 与 random 两种曝光来源实际展示的视频结构有什么不同；
2. 同一批用户、同一批视频在两种曝光来源下的观看与互动反馈有什么差异；
3. 结合历史视频分层和实际曝光分配，进一步分析两种曝光来源下反馈差异可能与哪些因素有关。
```
---

## 数据范围

项目使用 KuaiRand-Pure 的 6 个官方文件：

```text
log_standard_4_08_to_4_21_pure.csv
log_standard_4_22_to_5_08_pure.csv
log_random_4_22_to_5_08_pure.csv
user_features_pure.csv
video_features_basic_pure.csv
video_features_statistic_pure.csv
```

其中：

- `standard_pre`：画像快照日前的标准推荐历史日志；
- `standard_post`：后期标准推荐曝光日志；
- `random_post`：同期随机干预曝光日志。

原始 CSV 文件不随仓库提交，数据下载及本地目录配置见 [`data/README.md`](data/README.md)。

---

## 技术栈

```text
- SQL：MySQL
- Python：Pandas、NumPy
- 统计分析：Wilcoxon、rank-biserial、BH-FDR
- 预测模型：LightGBM
```
## AI 辅助开发
```text
使用 Claude（PyCharm 集成）辅助可视化代码编写，以及部分代码修改与调试。
```
---

## 分析流程

### Phase 1｜原始数据理解与质量检查
* 检查原始数据的字段、缺失值、异常值和时间范围，确认数据可用于后续分析。


---

### Phase 2｜ODS → DWD → DWS 分层数仓建设

**将原始 CSV 整理成后续可以直接分析的数据表。**

* **ODS**：保留原始数据并完成入库
* **DWD**：清洗异常值、统一字段格式，并标记不同曝光来源
* **DWS**：按用户、视频和作者三个粒度汇总曝光、观看和互动指标

---

### Phase 3｜用户历史画像与分层

* 基于 `standard_pre` 历史窗口，构建用户活跃、曝光、观看和互动行为指标
* 根据用户历史正向反馈，结合视频标签分析用户的视频标签偏好
* 根据历史曝光规模和反馈表现划分不同用户类型

---

### Phase 4｜视频与作者历史分析

* 基于 `standard_pre` 历史窗口，分析视频和作者的作品供给与历史曝光情况
* 使用 Gini 系数分析历史曝光是否集中在少数视频或作者
* 基于 `standard_pre` 历史窗口，构建并分析视频与作者作品的观看、互动等用户反馈指标
* 根据历史曝光规模和反馈表现完成视频和作者分层

---

### Phase 5｜standard / random 曝光与用户反馈差异分析

* 比较同一批用户在两种曝光来源下的观看和互动行为反馈
* 分析不同历史用户类型接收到的视频结构
* 比较同一批视频在两种曝光来源下的用户观看和互动行为反馈
* 分析不同历史视频类型在不同窗口的曝光份额
* 比较不同历史作者类型获得的曝光份额
* 结合历史视频分层和曝光分配结果，分析两种曝光来源下反馈差异的可能原因

---

### Phase 6｜long_view 预测

* 以 standard_post 中的单次视频曝光作为预测样本，使用用户和视频在 standard_pre 中的历史指标作为特征，构建 LightGBM 模型预测该次曝光是否产生 long_view
* 使用 ROC-AUC、Precision、Recall 和 F1 评价测试集预测效果
---

### 运行说明

本项目使用 SQL 完成数仓建表和指标计算，Python Notebook 负责分层、统计分析、可视化和建模。部分后续步骤需要使用前面 SQL 或 Python 已生成的结果，因此两者需要按照项目流程穿插执行，不能直接一次性运行全部文件。
完整运行顺序见 [`docs/run_order.md`](docs/run_order.md)。
---

## 核心结果

### 1. 视频历史曝光具有明显集中性

* 在本数据集中，约 96.3% 的视频在历史窗口内获得过曝光，但曝光分布并不均匀：视频曝光 Gini 约为 0.729，Top 20% 视频获得约 76.5% 的历史曝光；
* 作者侧也呈现类似结果：作者上传视频数 Gini 仅约为 0.127，而作者作品曝光 Gini 约为 0.723，说明作者上传作品数量相对分散，但历史曝光明显集中在少数作者的作品上。由于本数据集中约 87% 的作者只上传了 1 个视频，因此作者曝光分布与视频曝光分布高度相似。

### 2. standard 与 random 的视频曝光分配明显不同

* 从整体曝光分配看，standard_post 与历史 standard_pre 的视频曝光结构较为接近，两类历史高曝光视频在 standard_post 中仍获得约 71.1% 的曝光；而在 random_post 中，这一比例下降至约 20.0%，一般曝光一般表现视频和低曝光次数视频的曝光份额分别达到了 37.8% 和 30.2%；
* 对同一批用户，standard 下的曝光也更多集中于 standard_pre 历史高曝光视频，而 random 更多覆盖历史一般曝光、低曝光和无历史曝光视频；
* 作者侧的曝光分配与视频侧基本一致：standard 对历史高曝光、高表现作者作品的曝光份额更高，而 random 对低曝光作者作品的覆盖更多。由于作者和视频分层使用的核心历史指标相近，且本数据集中约 87% 的作者只上传了 1 个视频，因此作者侧与视频侧的结果会比较接近。

### 3. 对于同一批用户，两种曝光来源下的反馈存在明显差异

* 对 18368 名同时受到两种曝光来源且曝光次数达到双侧曝光门槛的用户进行配对比较发现：除转发率外，standard 下用户的有效观看率、长播放率等观看行为指标，以及点赞、评论等互动行为指标都显著更优。

### 4. 对于同一批视频，standard 下观看反馈整体更优，但互动差异因历史视频分层而异

* 对 4626 个同时受到两种曝光来源且曝光次数达到双侧曝光门槛的视频进行配对比较发现：standard 下有效观看率、长播放率等观看指标整体显著更优；
* 但互动指标在不同历史视频类型中的差异方向并不一致：在高曝光或高表现视频中，多项互动指标在 standard 下更优，而在一般曝光一般表现视频和低曝光次数视频中，多项互动指标在 random 下更优。

### 5. 当前结果不能直接说明 standard 本身造成了更好的反馈

* 如第 2 点所示，standard 和 random 实际展示的视频构成明显不同；如第 3、4 点所示，即使比较同一批用户或同一批视频，两种曝光来源下的反馈结果仍然存在明显差异；
* 当前 standard 与 random 并不是严格随机分组，实际出现的用户—视频组合并不完全一致，因此目前只能说明两种曝光来源下存在稳定的关联差异。如果要进一步验证曝光方式本身是否造成反馈差异，需要通过随机 A/B Test 进行因果验证。

### 6. long_view 预测

* 基于 standard_pre 中用户和视频的历史曝光、观看、互动及兴趣匹配特征，构建 LightGBM 二分类模型，预测 standard_post 中一次视频曝光是否产生 long_view；
* 按 60% / 20% / 20% 分层划分训练集、验证集和测试集，并在验证集选择分类阈值；
* 预测结果如下：

```text
历史 user long_view_rate baseline ROC-AUC：0.6684
LightGBM 测试集 ROC-AUC：0.7329
验证集选定阈值：0.30
测试集 Precision：46.88%
测试集 Recall：74.23%
测试集 F1：0.5747
Lift：1.4541
```

---

## 项目结构

```text
KuaiRand-Analysis/
│
├── README.md              # 项目说明
├── requirements.txt       # python运行环境所需依赖库
├── .gitignore             # Git 忽略规则，避免提交本地配置、原始数据和缓存文件
├── .env.example           # mysql连接配置示例
│
├── data/
│   └── README.md          # 原始数据下载与本地存放说明
│
├── docs/
│   ├── analysis_report.md         # 项目完整分析过程、主要图表和结论说明
│   ├── data_dictionary.md          # SQL建表说明，包括各表粒度、字段含义、时间窗口和指标口径（配合sql文件查看）
│   ├── code_dictionary.md          # Python分析说明，包括主要变量、函数及其用途（配合python文件查看）
│   └── run_order.md                # SQL 与 Python Notebook 的运行顺序说明
│
├── notebooks/
│   └── 01_kuairand_pure_analysis.ipynb     # Python 主分析文件，负责分层、统计分析、可视化和建模
│
├── outputs/                        # Python 分析生成的图表和结果文件
│   ├── phase3_user/
│   ├── phase4_video_author/
│   ├── phase5_standard_random/
│   └── phase6_precision/
│
└── sql/                            # SQL 代码文件
    ├── 01_Phase2_ODS.sql
    ├── 02_Phase2_DWD.sql
    ├── 03_Phase2_DWS.sql
    ├── 04_Phase3_ADS_user_profile.sql
    ├── 05_Phase4_ADS_video_author_history.sql
    ├── 06_Phase5_ADS_standard_random_analysis.sql
    └── 07_Phase6_ADS_long_view_sample.sql
```

---

## 文档入口

- [`docs/analysis_report.md`](docs/analysis_report.md)：项目完整分析过程、主要图表和结论说明（无代码版）；
- [`docs/data_dictionary.md`](docs/data_dictionary.md)：项目使用的数据表、字段含义、时间范围和主要数据处理说明；
- [`docs/code_dictionary.md`](docs/code_dictionary.md)：Python 中主要变量、函数、阈值和模型对象说明；
- [`docs/run_order.md`](docs/run_order.md)：项目运行顺序说明，包括 SQL 和 Python Notebook 应按什么顺序执行。
