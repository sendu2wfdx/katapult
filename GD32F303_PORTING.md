# Katapult GD32 移植与目录重构记录

## 目标

- MCU：GD32F303xB/xC/xE、GD32E230x6/x8
- F009 物理 MCU：实物丝印已确认为 GD32F303RCT6（64 引脚、256 KiB）；
  V57 原厂 G31 应用字典明确为 `MCU=gd32f303xc`，两项证据一致，替换目标按
  xC 容量边界构建。早期文档中的 RET6 是配置注释误记
- 外部晶振：8 MHz
- 系统时钟：120 MHz
- APB1/APB2：60 MHz
- 原厂主通讯：GD32 USART1，PA2/PA3，230400 baud
- 可选通讯：CAN0，PB8/PB9 重映射，1 Mbps
- 可选通讯：USB FS，PA11/PA12，48 MHz USB时钟
- Katapult：占用 `0x08000000..0x08001fff`（8 KiB）
- Klipper 应用入口：`0x08002000`

## 实现方式

GD32 现在是独立平台，不再借用 `lib/stm32f1` 的设备头文件或
`system_stm32f1xx.c`：

- 平台运行时代码统一位于 `src/gd32`；
- 家族差异使用 `gd32f30x_*`、`gd32e23x_*` 前缀；
- 厂商设备头文件分别放在 `lib/gd32f30x/include` 和
  `lib/gd32e23x/include`；
- 不再保留第二套 `src/gd32e23x` 目录；
- F303 Flash 使用 GD32 FMC 寄存器实现解锁、擦除、半字写入、错误检查及
  写后比较；xB 使用 1 KiB 页，xC/xE 使用 2 KiB 页；
- F303 xB/xC/xE 分别具有独立的 Flash/RAM 容量配置，均使用 Cortex-M4 和
  120 MHz GD32 时钟初始化；
- E230 使用独立的 Cortex-M23 启动、GPIO、定时器、串口和 Flash 实现。

寄存器相似只用于辅助核对，GD32 不再伪装成 STM32F103。

## 固定构建入口

Windows 下运行：

```powershell
.\build-gd32.ps1
```

脚本固定使用 `T113` WSL、32 线程，依次验证：

- GD32F303xB/xC/xE，USART1 PA2/PA3，230400 baud；
- GD32F303xC USB FS；
- GD32F303xC CAN0 PB8/PB9；
- GD32E230x8 USART1 PA2/PA3；
- GD32E230x8 USART0 PA9/PA10。

2026-09-03 在 `T113`、GCC 9.2.1 中重新执行完整矩阵，均通过编译、链接，并生成
`katapult.bin` 和 `deployer.bin`。当前 `katapult.bin` 结果为：

| 目标 | text/data/bss | SHA-256 |
|---|---:|---|
| F303xB USART1 | `3583/0/824` | `8d3076437448826caf91dc06ed59e7a3c4e7fe513124d4c3bf37180d62762829` |
| F303xC USART1 | `3583/0/824` | `0d00cfc26cc9010cb214f165a43079f96045b2f8d420c521dd077298424ad3de` |
| F303xE USART1 | `3583/0/824` | `a7df27ea42fa2832c32dbbdc30294a8045c5eb98da45a94ab8b27c1c33bba720` |
| F303xC USB 单缓冲 | `5276/0/932` | `f4d5b53e28aa0d5f7239001bccf3b2defeeb6076dbfcec4f3220610a75b6114c` |
| F303xC CAN PB8/PB9 | `4639/0/976` | `d8fc7c9b1068388efd649121844ad7e850ac9cafb01211e2adb34607e01c41ee` |
| E230x8 USART1 PA2/PA3 | `3079/0/832` | `392eaa3bb107f17a0fef0bc7e9f29bfedd0980c04204b1b67eb5504318581bee` |
| E230x8 USART0 PA9/PA10 | `3083/0/832` | `21bcd0a64904fd5a86f1c840590bfc8f02137ec881f859344c8055cba233a78e` |

这证明软件构建闭环，不等同于实机电气和 Flash 擦写验证。

## 首次安装和恢复

Katapult 替换原厂 Bootloader 后，首次写入必须使用 SWD/DAPLink。写入前应完整备份 MCU Flash、选项字节和读保护状态。保留 SWD，不启用彻底关闭调试口的选项，以便 CAN 启动失败时恢复。

Klipper 应用必须选择与原厂应用 ABI 一致的 F303 目标和通讯接口，并以
`0x08002000` 为链接入口，输出普通 Katapult 应用 BIN，不能附加原厂 CRC
尾。F009 的 V57 `mcu0_140_G31-mcu0_022_000.bin` 内嵌字典明确报告
`MCU=gd32f303xc`，而实物丝印已确认为 GD32F303RCT6。RCT6 的 `R` 是 64 引脚
封装、`C` 是 256 KiB 容量等级，两项证据一致，因此协议字典和 Flash 边界都
保持 xC，不能再使用早期误记的 xE/RET6 配置。

F009 原厂主运动 MCU 实际通过 `/dev/ttyS2`、230400 baud 与 T113 通讯；MCU 固件配置为 GD32 USART1 PA2/PA3。因而串口版本是主版本。Klipper 串口应用同样使用 PA2/PA3、230400 baud 和 `0x08002000`；CAN版本仅作为改板或额外收发器条件下的可选方案。Katapult的一份固件只选择一种主通讯接口，因此分别生成串口版与CAN版，不能把两种传输直接混成同一镜像。

USB版本使用PA11/PA12和GD32F303扩展USB分频器，将120 MHz PLL按2.5分频得到48 MHz。它同样是独立镜像，不能与串口或CAN传输混为一份。F009原厂主机并未通过该USB链路连接主运动MCU，因此USB版本仅用于核心板、改板或直接引出USB数据线的场景。与 Klipper 端共用的 PMA 双缓冲发送路径在 CCT6 上出现过长 identify 后继续应答失稳，Katapult 发布配置因此同步改为单缓冲；双缓冲源码保留在 `CONFIG_GD32_USB_DOUBLE_BUFFER_TX` 中，只有显式实验配置才启用。

串口升级前必须停止正在占用 `/dev/ttyS2` 的 Klipper 服务，然后执行：

```sh
python3 scripts/flashtool.py \
  -d /dev/ttyS2 -b 230400 \
  -f ../Official_Klipper_GD32/build-gd32/f009-serial/klipper.bin
```

正常运行中的 Klipper 支持通过命令请求进入 Katapult；如果应用损坏，则可利用 Katapult 的双击复位窗口，或用 SWD 复位/重新写入。首次安装 Katapult 仍需 SWD，串口升级能力从首次安装成功后开始生效。

## 尚需实机验证

- F009 是否确为 8 MHz HXTAL。
- PB8/PB9 外部收发器的使能/待机脚是否由额外 GPIO 控制。
- CAN 总线终端、电平与现有节点是否匹配。
- 读保护解除是否会触发整片擦除。

## GD32E230串口升级

已增加独立的GD32E230x6/x8 Cortex-M23后端，不复用F303寄存器层。包含：

- 8 MHz HXTAL、72 MHz系统时钟；
- E230 GPIO和复用功能配置；
- TIMER2 16位计数器扩展为Katapult 32位时基；
- 1 KiB Flash页擦除和32位编程；
- USART1 PA2/PA3与USART0 PA9/PA10两种230400 baud构建；
- Katapult位于`0x08000000`，Klipper应用位于`0x08002000`。

F009量产调平板已由完整 Flash 内嵌字典确认使用 GD32E230F8P6、USART0 PA9/PA10、230400 baud；PA2/PA3 仅保留为平台开发/改板变体。原厂完整镜像在 `0x0000` 与 `0x3000` 均有合法向量表，应用区又与预打包固件逐段对应，因此保留原厂 Bootloader 时应用入口应为 `0x08003000`；使用本仓库公版 Katapult 时才是 `0x08002000`，两种布局不可混用。

注意：E230 Flash擦写与时钟代码目前完成编译和静态链接验证，但尚未在核心板执行擦写回读。首次试验必须通过SWD安装并保留完整原固件，不能直接在唯一的原厂调平板上首刷。
