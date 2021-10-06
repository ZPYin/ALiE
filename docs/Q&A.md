**怎么知道REAL数据拼接结果的好坏？**

```matlab
close all;
LEMain('D:\Coding\Matlab\lidar_evaluation_1064\config\test_REAL_signalMerge_config.yml', 'flagReadData', true, 'flagDebug', true, 'flagQL', true);
```

修改拼接系数的代码在`lidarPreprocess.m`中。

**怎么设置chTag（通道标识）**

在`config`文件设置通道标识需要按照实际数据中的通道顺序，通道类别标识代号可以参考[LidarList.md](lidarList.md)。

**0.2版本更新**

1. 暗噪声系统误差计算方法更正。原来采用绝对值的标准差，现在采用binning后信号的最大偏差，另外计算过程中包括最大信号范围（原来只采用一段平稳的信号）
2. 平均相对偏差计算（原来采用偏差绝对值的平均，现在采用信号平均后的偏差）