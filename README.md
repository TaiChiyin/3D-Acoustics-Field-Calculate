# 三个模型计算浅海三维声场

准备独立复现时，先阅读本目录 **`使用手册_从零复现.md`**。三个模型文件夹分别提供 **`使用手册.md`** 和 **`examples`** 原生输入小示例，涵盖 MATLAB 入口、原生程序、参数格式、数据读取和报错排查。

运行入口为 `run_all_3d_fields.m`。所有模型使用同一物理环境、频率、声源和接收坐标，结果分别存入已经建立的 `Kraken`、`Krakenc`、`Bellhop3D` 文件夹。

## 环境与方法

参数依据项目中 `compare_different_env/shallow_sea_Gaussian/pekerisK.env` 和 `p0_baseline/p0_pekeris.env`，这里采用**无冰浅海环境**，并非先前的弹性冰层环境。

| 参数 | 默认值 |
|---|---|
| 频率 | 500 Hz，三个模型相同；由原算例的 100 Hz 调整 |
| 水深 / 水中声速 / 水密度 | 200 m / 1500 m/s / 1.0 g/cm³ |
| 海面 | 平坦、压力释放 |
| 海底 | 平坦、流体吸收半空间 |
| 海底声速 / 密度 / 衰减 | 1600 m/s / 1.8 g/cm³ / 0.2 dB/波长 |
| 声源 | 全向点源，(x,y,z)=(0,0,25) m |
| 水平距离 | 500:5:3000 m |
| 接收深度 | 5:5:195 m，避开边界 |
| 接收方位 | 0:10:350°，无 360° 重复端点 |
| 数据大小 | 每个模型 39 × 501 × 36 = 703404 个复声压采样点 |

500 Hz 对应水中波长约 3 m；选择它是为了建立一个成本可控的简正波/波束对比示例，并不是保证 BELLHOP3D 准确的频率门槛。

- **KRAKEN**：计算简正波，使用同版本 `FIELD` 相干叠加得到 p(r,z)，再利用水平不变环境的轴对称性扩展为 p(z,r,theta)。
- **KRAKENC**：使用复数简正波求解器，后续同样通过 `FIELD` 和轴对称扩展生成数据。两者在本流体环境中可能非常接近，不能据此认为两种求解器没有区别。
- **BELLHOP3D**：输入运行选项为 `CG RR3`，第六位 `3` 明确启用 full 3D，程序同时检查 `.prt` 的 `3D calculation`。此环境本身轴对称，因此正确结果也应基本不随方位变化。

KRAKEN/KRAKENC 在此处不是一般三维非均匀环境求解器。默认网格是**圆柱坐标三维网格**，不是等间距笛卡尔立方体。

## 运行

在 MATLAB 将当前文件夹切换到本目录：

```matlab
results = run_all_3d_fields();
```

只运行一个模型时，在对应文件夹中调用：

```matlab
result = run_kraken_3d();   % Kraken 文件夹
result = run_krakenc_3d();  % Krakenc 文件夹
result = run_bellhop3d();   % Bellhop3D 文件夹
```

修改参数并运行（在公共目录下）：

```matlab
cfg = field3d_config();
cfg.frequencyHz = 300;
cfg.rangeM = 500:10:4000;
cfg.depthM = 5:5:195;
cfg.bearingDeg = 0:5:355;
results = run_all_3d_fields(cfg);
```

修改频率或环境后应重新进行收敛检查。各坐标轴必须等间距递增，距离必须大于零，深度必须在水层内。当前入口明确限制为单频、单声源、水平不变流体波导；改变环境的三维结构需要另外实现环境文件，而不是修改一项开关。

## 输出位置与含义

每次运行建立新的目录，拒绝覆盖同名运行：

```text
Kraken/results/run_日期_时间/...
Krakenc/results/run_日期_时间/...
Bellhop3D/results/run_日期_时间/...
```

每个模型目录中的 `latest_result.txt` 给出最近一次成功运行的 `field3d.mat` 绝对路径。

> **Git 仓库说明**：仓库按 `.gitignore` 排除了 `**/results/`、`**/validation/*.mat`、`latest_result.txt`、`*.fig` 以及本机 `.matlab_prefs/`（内含私钥与证书）。clone 后首次运行前，`results/` 目录并不存在，入口会自动创建。本 README 与 `RESULTS.md` 中引用的基线目录 `results/run_2026...` 是本机历史运行记录，只在原机器上存在；复现时应以你自己新生成的目录为准。

| 文件 | 内容 |
|---|---|
| `field3d.mat` | `result` 结构体，含复声压、TL、坐标、配置及计算方式 |
| `config.mat` | 本次配置快照 |
| `case.env` | 对应模型的实际输入 |
| `case.mod`, `case.flp`, `field.prt` | 仅简正波模型：模态、FIELD 输入和日志 |
| `case.shd`, `case.prt` | 原始声场和模型日志 |
| `*_console.txt` | 可执行程序输出及退出状态 |
| `field_3d.png/.fig` | 三维空间剖面图 |
| `field_slices.png/.fig` | 距离-深度剖面和水平剖面 |
| `summary.txt` | 维度、单位、方法、非零比例和轴对称性检查 |
| `comparison.json/.mat`, `model_comparison.png` | 执行全部模型后保存的同条件比较 |

读取示例：

```matlab
file = strtrim(fileread(fullfile('Bellhop3D','latest_result.txt')));
S = load(file,'result');
R = S.result;
p = R.pressure;  % complex single，索引顺序：[深度, 水平距离, 方位]
tl = R.TLdB;    % -20*log10(abs(p))，与工具箱点源 1 m 归一化一致

iz = 5; ir = 101; it = 10;
xyz = [R.XM(ir,it), R.YM(ir,it), R.depthM(iz)];
samplePressure = p(iz,ir,it);
% R.XM/R.YM 为 [距离, 方位]；z 由 R.depthM 给出。
% 若确实需要与 p 同维度的三维坐标数组：
[Z,rr,theta] = ndgrid(R.depthM,R.rangeM,R.bearingDeg);
X = R.sourceXYZM(1) + rr.*cosd(theta);
Y = R.sourceXYZM(2) + rr.*sind(theta);

plot_3d_field(R); % 重新保存图像
```

`pressure` 是归一化传播响应，未指定实际源级，不应直接称为 Pa。复数采用 AT 的 `exp(+i*omega*t)` 约定，保留各程序的原始整体源相位。程序不共轭或调整保存的声压。比较文件同时给出原始复数误差、整体相位偏移和仅供诊断的相位对齐误差：本版本 FIELD 与 BELLHOP3D 可出现接近 180° 的整体相位差，此时原始相对复数误差可接近 2，而 TL 和归一化相关度仍接近。整体常数相位不影响通常的 Bartlett 匹配值；涉及多源相干叠加时应先明确各源的相位参考。

默认距离和深度步长 5 m 大于半波长；这些是精确位置上的离散求解值，**不是足以恢复连续相位的密集网格**。图像在采样点间的连面仅用于显示。相干 MFP 应针对阵元和候选源的位置重新计算，不能直接在此粗网格上插值复声压。扩大网格时，计算量和文件大小会随深度数×距离数×方位数增长。

## 验证

```matlab
report = verify_3d_fields();
```

该入口在较小的相同接收网格上比较默认与加密计算：简正波网格加倍；BELLHOP3D 的俯仰和方位波束间隔减半，同时积分步长减半。保存相对复声压误差、相关度、TL 变化、轴对称误差及 `passed` 标记。检查阈值是本示例的工程门槛，不是通用精度保证。组合加密发现问题时，进一步分别调整角度和步长以定位误差来源。

验证网格保持默认 5 m 距离/深度、方位取 `0:30:330`。**不要把验证网格改得更稀**：BELLHOP3D 是离散波束追踪，波束落点在距离-深度平面内随深度斜向移动，20 m × 250 m 的稀疏采样会让 43.6% 的复声压恰好为 0 并使验证失去意义（详见 `代码审阅报告.md` 第三节）。默认 5 m 网格下恰好零值个数为 0。

验证结果仍保存在对应模型目录的 `results/verify_...` 和 `validation/` 中。验证运行也会更新 `latest_result.txt`；若要它指向正式图像结果，验证完成后再运行默认入口。

`test_f3_read_shd.m` 是 SHD 读取路径的回归测试：它把读取结果与真实二进制文件和既有 `field3d.mat` 逐元素比对，覆盖字节偏移、复数交错方式、记录排列顺序、维度与轴对称性。改动 `private/f3_read_shd.m` 后建议先跑它。

三模型间的差异按原样记录，不以“必须一致”作为运行成功标准。波束收敛不等于物理模型与简正波完全一致，特别是阴影区、干涉零点、临界角附近和近源区域。当前结果不是实验数据验证。

## 依赖与依据

需要 Windows 和 MATLAB（本机验证版本 R2023b），无需额外 MATLAB 工具箱。沿用用户预置的三个 `.exe`。额外复制两份同版本 `field.exe` 到 Kraken/Krakenc，使计算不依赖外部工具箱路径。

二进制与配套格式来自本机 `E:/programs_and_project/matlab/COA6/atWin10_2020_11_4`。三个预置程序的 SHA-256 已与该工具箱程序核对一致。二进制许可证见 `LICENSE.AcousticsToolbox`；原作者源代码与文档可在 [官方仓库](https://github.com/oalib-acoustics/Acoustics-Toolbox) 获取。本程序的 SHD 读取器按该版本布局实现，严格拒绝不支持的多频/多源/非规则数据，未把旧版和新版文件格式混用。

仓库中随源码分发的 5 个可执行文件（Acoustics Toolbox 2020-11-4 构建）可用以下命令核对其完整性；重新编译或替换版本后，这些值应随之更新：

```text
A23FFC01444C12FE468798E11BDBC044CF05322FF706846FDA853BDD778451AA  Bellhop3D/bellhop3d.exe
398B29DC339D1B06A1B15E7CAE37574FFAE083E9BBA4049863D4A087798E48EC  Kraken/kraken.exe
6605665373A47BC7B9F0A709E743AB6277B9A5F137C999B58B5FB9C1B75E58FB  Krakenc/krakenc.exe
5A0126B1DD7ADDDDF21E4C8873019308718A79DD85E00A061B2668570558B374  Kraken/field.exe
5A0126B1DD7ADDDDF21E4C8873019308718A79DD85E00A061B2668570558B374  Krakenc/field.exe
```

Windows 上校验：`Get-FileHash -Algorithm SHA256 <文件>`；Linux/macOS：`sha256sum <文件>`。

输入格式参考本机官方 `tests/Bellhop3DTests/PerfectWedge/wedge3dHat.env`、`Bellhop/ReadEnvironmentBell.f90`、`KrakenField/field.f90`，归一化和相位参考 `KrakenField/EvaluateMod.f90`。工具箱的概述见 [官方说明](https://github.com/oalib-acoustics/Acoustics-Toolbox/blob/main/index.htm)。
