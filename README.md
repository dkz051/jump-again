# Jump Again

2020 春《数字逻辑设计》课程项目：体感平台跳跃游戏

## 项目来源

软院大一上程设大作业：平台跳跃游戏（例如 Celeste、I wanna 系列、超级玛丽等）

## 操作方法

键盘操作，或体感模拟。

* 左/右：键盘 S/F 键；体感左/右横滚旋转
* 跳：键盘 E 键；体感快速向上移动
* 二段跳：键盘再次按 E 键；体感再次快速向上移动

## 硬件
* FPGA: Cyclone II EP2C70F672C8
* PS/2 键盘

### 管脚分配方案

| 信号 | 方向 | FPGA 管脚 |
|:----:|:---:|:---------:|
| clock | 输入 | PIN_N2 |
| ps2Clock | 输入 | PIN_AD6 |
| ps2Data | 输入 | PIN_AD7 |
| reset | 输入 | PIN_N1 |
| rx | 输入 | PIN_C19 |
| down | 输出 | PIN_AD15 |
| kDown | 输出 | PIN_AF9 |
| kLeft | 输出 | PIN_AE7 |
| kRight | 输出 | PIN_AC7 |
| kUp | 输出 | PIN_AE11 |
| left | 输出 | PIN_AE9 |
| right | 输出 | PIN_AB10 |
| sDown | 输出 | PIN_AD10 |
| sLeft | 输出 | PIN_AF7 |
| sRight | 输出 | PIN_AB8 |
| sUp | 输出 | PIN_AC15 |
| up | 输出 | PIN_AE15 |
| vgaB[0] | 输出 | PIN_T4 |
| vgaB[1] | 输出 | PIN_U2 |
| vgaB[2] | 输出 | PIN_U1 |
| vgaG[0] | 输出 | PIN_R5 |
| vgaG[1] | 输出 | PIN_T2 |
| vgaG[2] | 输出 | PIN_T3 |
| vgaHs | 输出 | PIN_U3 |
| vgaR[0] | 输出 | PIN_R2 |
| vgaR[1] | 输出 | PIN_R3 |
| vgaR[2] | 输出 | PIN_R4 |
| vgaVs | 输出 | PIN_U4 |

体感操作需要以下额外硬件：

* MPU6050
* Arduino Uno
* HC-12（2 个）

## 接线方法

* FPGA
  * HC-12（体感控制）
    * VCC -- 3.3V
    * GND -- GND
    * TXD -- PIN_C19（GPIO 左上角引脚）
* Arduino（体感控制）
  * MPU6050
      * VCC -- 3.3V
      * GND -- GND
      * SCL -- A5
      * SDA -- A4
      * INT -- 2
      * AD0 -- GND
  * HC-12
      * VCC -- 5V
      * GND -- GND
      * RXD -- 5
  * 9V 圆口供电

## License
GNU GPL v3。
