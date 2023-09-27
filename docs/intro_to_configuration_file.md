# Introduction to the configuration file

## YAML file

The configuration file is in YAML file with the file extension of [`.yml`][1]. The element before semicolon stands for a keyword. Two white spaces are used for line indentation to separate keywords in different levels. All keywords are cascaded by a tree structure. The string after `#` are the comments and will be neglected by the YAML file interpreter. See an example below,

```yaml
resultPath: D:\Users\zhenping   # This will be interpreted as a Matlab string
result: 0.2                     # This will be interpreted as a Matlab double
results: [0.1, 0.2, 0.3]        # double array
resultPaths: ['D:\Users\zhenping', 'C:\Users\Yin']   # Matlab cell array
resultPaths:                    # same as above
  - D:\Users\zhenping
  - C:\Users\Yin
results:                        # Matlab 2x2 matrix
  - [0, 1]
  - [2, 3]
resultsStruct:                  # Matlab struct with two fields ('results' and 'resultPath')
  results: [0.1, 0.2, 0.3]
  resultPath: D:\Users\zhenping
```

> Pay attention! The line indentation is very important for the file interpretation.

## Configuration file

The configurations are composed of KEYWORDS. The keywords in the configuration file can be divided into two groups: **General** and **Specific**. The general keywords are mandatory and will be valid for all the outputs; while, specific keywords are only valid for single lidar.

Genreal keywords are as below:

|Keyword|Description|Example|
|:--:|:----|:--:|
|resultPath|save path of the output results|C:\Users\zhenping\cmp|
|dataSavePath|save path of the lidar data after data conversion|C:\Users\zhenping\data|
|figFormat|figure format|png（fig, jpg, or pdf）|

The structure of the evaluation program is as below：

<p align='center'>
<img src='../image/程序整体结构图.png', width=500, height=400, lat='lat'>
<br>
<b>Struction of the evaluation program</b>

The specific keywords can be divided into three parts, based on their functionality：

- Data Conversion (dataLoaderCfg)
- Internal Validation (internalChkCfg)
- External Comparison (externalChkCfg)

### dataLoaderCfg

Regarding `Data Conversion`, it will convert the raw lidar data into **HDF5** data file, which is a hierarchy data format in binary format. Below is an example for data conversion.

```yaml
dataLoaderCfg:
  lidarList: ['AW']
  AW:
    dataPath: D:\Data\CMA_Lidar_Comparison\externalChk\AW
    dataFilenamePattern: .*Lidar.*
    dataFormat: 3
    chTag: ['532p', '532s']
    nMaxBin: 1800
    nBin: 4000
    flagFilenameTime: true
```

|Keyword|Description|Example|
|:--:|:----|:--:|
|lidarList|Lidar list. For all the lidars listed in this list must be configured for their data format.|['AW']|
|{AW}|lidar tag. Same as the element in the lidar list.|AW|
|dataPath|lidar data path|D:\Data\CMA_Lidar_Comparison\externalChk\AW|
|dataFilenamePattern|regular expression for lidar data file filtering|.* Lidar .*|
|dataFormat|lidar data format: <p>1: WHU reference 1064 nm lidar</p> <p>2: WHU compact 1064 nm lidar</p> <p>3: (old) CMA binary data</p> <p>4: Darsun lidar data</p> <p>5: REAL lidar data</p>  <p>6: (2021) CMA binary data format</p>  <p>7: lidar data exported by ALA data digitizer</p>|3|
|chTag|lidar channel tag # 355e; 355p; 355s; 387; 407; 532e; 532p; 532s; 607; 1064e; 1064p; 1064s; 532pl; 532sl; 607l; 532ph; 532sh; 607h;|['532p', '532s']|
|nMaxBin|maximum number of range bins to be processed|1800|
|nBin|maximium number of range bins to be loaded|2000|
|flagFilenameTime|whether to parse measurement time from lidar data filename (true or false)|true|

### Internal Validation (internalChkCfg)

`internalChkCfg` is used for controlling the details of internal validation. See an example as below:

```yaml
internalChkCfg:
  lidarList: ['WH1']
  WH1:
    lidarNo: 12   # lidar number. (see ./docs/lidarList.md)
    chTag: ['1064e']
    figVisible: 'on'   # whether display figures
    preprocessCfg:
      hOffset: 0   # height offset. (m)
      tOffset: 0   # time offset. (min)
      deadTime: []   # deadtime (ns). If it's empty, deadtime correction is disabled.
      bgBins: [1500, 2000]   # [start index, stop index] for background correction
      nPretrigger: 15   # if nPretrigger < 0, move signal up
      bgCorFile: ''   # data file of dark measurement results
      overlapFile: ''
    fullOverlapHeight: 400   # minimum height with complete overlap. (m)
    flagRetrievalChk: false   # backscatter retrieval check
    flagSaturationChk: false   # signal saturation check
    flagQuadrantChk: false   # quadrant check
    flagOverlapChk: false   # overlap evaluation
    flagRayleighChk: false   # Rayleigh fit check
    flagBgNoiseChk: false   # background noise check
    flagDetectRangeChk: false   # detection ability check
    flagContOptChk: true   # continuous operation check
    contOptChkCfg:
      deltaT: 1   # temporal resolution (min)
      nMinProfile: 1440   # minimum profiles required
      tRange: '2021-09-28 12:00:00 ~ 2021-09-29 12:00:00'
      hRange: [0, 13000]
      cRange:   # color range for Range-corrected signal
        - [0, 0.2e10]
```

|Keyword|Description|Example|
|:--:|:----|:--:|
|lidarList|Lidar list. For all the lidars listed in this list must be configured for their data format.|['WH1']|
|{WH1}|lidar tag. Same as the element in the lidar list.|AW|
|lidarNo|lidar identifier is the only tag for different lidar system. This identifier can guide the code to implement different lidar preprocessing scheme. If you don't know the exact lidar identifer, use 12 instead.|12|
|chTag|lidar channel tag # 355e; 355p; 355s; 387; 407; 532e; 532p; 532s; 607; 1064e; 1064p; 1064s; 532pl; 532sl; 607l; 532ph; 532sh; 607h;|['532p', '532s']|
|figVisible|whether to display matlab figure window, `on` or `off`|on|
|preprocessCfg|preprocess configurations||
|hOffset|height offset in meters|0|
|tOffset|temporal shift in days|0|
|deadTime|deadtime for each channel. If this is empty, no deadtime correction will be implemented.|[]|
|bgBins|range bins for calculating solar background|[1500， 2000]|
|nPretrigger|number of pre-triggers|0|
|bgCorFile|background file, which is useful for characterizing temporal dependent background. If this is empty, height independent background corrected will be applied.|''|
|overlapFile|Overlap file, which can only be search d in the folder of `lib\overlap`. If this is empty, no overlap correction will be applied.|''|
|fullOverlapHeight|height with full overlap (m)|400|
|flagRetrievalChk|whether to test retrieval algorithm. If `true`, some corresponding keywords need to configured|false|
|flagSaturationChk|whetehre to implement telecover test. |false|
|flagQuadrantChk|whether to implement quadrant test. |false|
|flagOverlapChk|whether to take overlap test.|false|
|flagRayleighChk|whether to implement Rayleigh fit test|false|
|flagBgNoiseChk|whether to implement dark noise test. |false|
|flagDetectRangeChk|whether to implement detection range test. |false|
|flagWVChk|whether to implement water vapor product test. |false|

### External intercomparison (internalChkCfg)

```yaml
externalChkCfg:
  figVisible: 'on'   # whether display figures
  WH1:
    lidarNo: 12   # lidar number. (see ./docs/lidarList.md)
    chTag: ['1064e']
    fullOverlapHeight: 400   # minimum height with complete overlap. (m)
    overlapFile: ''
    hOffset: 0   # height offset. (m)
    tOffset: 0   # time offset. (min)
    deadTime: []   # deadtime (ns). If it's empty, deadtime correction is disabled.
    bgBins: [1500, 2000]   # [start index, stop index] for background correction
    nPretrigger: 15   # if nPretrigger < 0, move signal up
    bgCorFile: ''   # data file of dark measurement results
  WH2:
    lidarNo: 13   # lidar number. (see ./docs/lidarList.md)
    chTag: ['1064e']
    fullOverlapHeight: 200   # minimum height with complete overlap. (m)
    overlapFile: ''
    hOffset: 0   # height offset. (m)
    tOffset: 0   # time offset. (min)
    deadTime: []   # deadtime (ns). If it's empty, deadtime correction is disabled.
    bgBins: [1100, 1250]   # [start index, stop index] for background correction
    nPretrigger: 0   # if nPretrigger < 0, move signal up
    bgCorFile: ''   # data file of dark measurement results
  flagRangeCmp: false
  flagRCSCmp: true
  flagVDRCmp: false
  flagFernaldCmp: false
  flagRamanCmp: false
  rangeCmpCfg:   # 1064
    LidarList: ['WH1', 'WH2']   # lidar in comparison (1: standard lidar)
    tRange: '2021-09-27 19:30:00 ~ 2021-09-27 19:35:00'
    hRange: [6000, 15000]
    fitRange: [8000, 12000]
    normRange: [2500, 3000]
    sigRange: [0, 3e10]
    sigCompose:  # 1064
      - [1]   # first lidar
      - [1]   # second lidar
    maxRangeDev: 15   # (m)
```

|Keyword|Description|Example|
|:--:|:----|:--:|
|figVisible|whether to display Matlab figure window，`on` or `off`|on|
|flagRangeCmp|whether to perform object ranging accuracy comparison|false|
|flagRCSCmp|whether to perform intercomparison of range corrected signal|false|
|flagVDRCmp|whether to compare volume depolarization ratio|false|
|flagFernaldCmp|whether to compare profiles of aerosol optical properties based on Fernald method. |false|
|flagRamanCmp|whether to compare profiles of aerosol optical properties based on Raman method. |false|


[1]: https://yaml.org/