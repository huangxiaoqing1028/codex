# Objective-C 实现证件照

本仓库提供了一个简单可复用的 Objective-C 工具类 `IDPhotoProcessor`，用于将任意输入图片处理为常见证件照尺寸。

## 功能

- 支持常见规格：一寸、二寸、小二寸
- 支持自定义像素尺寸
- 自动等比缩放并中心裁剪
- 支持背景色填充（白/蓝/红都可）

## 使用示例

```objective-c
UIImage *origin = [UIImage imageNamed:@"person"];
UIImage *idPhoto = [IDPhotoProcessor generateIDPhotoFromImage:origin
                                                         spec:IDPhotoSpecOneInch
                                              customPixelSize:CGSizeZero
                                              backgroundColor:UIColor.whiteColor
                                                          dpi:300];

// 保存到相册（示例）
if (idPhoto) {
    UIImageWriteToSavedPhotosAlbum(idPhoto, nil, nil, nil);
}
```

## 核心思路

1. 按证件照规格（毫米）和 DPI 计算目标像素尺寸。
2. 将原图按比例放大/缩小到“至少覆盖目标画布”。
3. 居中绘制并裁剪到最终尺寸。
4. 先填充背景色，再绘制人物图像。

> 提示：如果你需要更标准的人像证件照（如自动抠图、换底、头顶留白比例校验），可以在这份基础上接入人像分割模型或系统 API。
