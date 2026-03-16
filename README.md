# AI 证件照 App（Objective-C）

一个基于 UIKit + AVFoundation + Vision + CoreImage 的证件照应用示例：

- 首页自拍拍照（前置摄像头）
- 拍完进入编辑页
- 人像抠图 + 背景色替换（白/蓝/红）
- 保证自拍拍摄结果不镜像反转
- 美白强度可调
- 支持常见证件照尺寸（含一寸、二寸、护照、签证等）

## 目录

- `PhotoIDApp/HomeViewController.*`：拍照主页与相机会话
- `PhotoIDApp/EditorViewController.*`：抠图、背景替换、美白、尺寸裁切
- `PhotoIDApp/SizePreset.*`：通用尺寸预设与按比例裁切

## 关键实现点

1. 使用 `AVCaptureDevicePositionFront` 进行自拍拍照。
2. 在预览层与拍照连接上都设置 `videoMirrored = NO`，避免自拍反转。
3. 使用 `VNGeneratePersonSegmentationRequest` 进行人像分割。
4. 使用 `CIBlendWithMask` 合成人像与纯色背景。
5. 通过 `CIExposureAdjust` 实现轻量美白增强。
