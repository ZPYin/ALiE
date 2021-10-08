**怎么知道REAL数据拼接结果的好坏？**

```matlab
close all;
LEMain('D:\Coding\Matlab\lidar_evaluation_1064\config\test_REAL_signalMerge_config.yml', 'flagReadData', true, 'flagDebug', true, 'flagQL', true);
```

修改拼接系数的代码在`lidarPreprocess.m`中。

**怎么设置chTag（通道标识）**

在`config`文件设置通道标识需要按照实际数据中的通道顺序，通道类别标识代号可以参考[LidarList.md](lidarList.md)。
