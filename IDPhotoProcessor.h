#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, IDPhotoSpec) {
    /// 一寸（25mm x 35mm）
    IDPhotoSpecOneInch,
    /// 二寸（35mm x 49mm）
    IDPhotoSpecTwoInch,
    /// 小二寸（35mm x 45mm）
    IDPhotoSpecSmallTwoInch,
    /// 自定义尺寸（通过 `customPixelSize` 传入）
    IDPhotoSpecCustom,
};

@interface IDPhotoProcessor : NSObject

/// 根据规格生成证件照。
/// @param image 原图
/// @param spec 证件照规格
/// @param customPixelSize spec=IDPhotoSpecCustom 时生效
/// @param backgroundColor 画布背景颜色
/// @param dpi 像素密度（常用 300）
+ (nullable UIImage *)generateIDPhotoFromImage:(UIImage *)image
                                          spec:(IDPhotoSpec)spec
                               customPixelSize:(CGSize)customPixelSize
                               backgroundColor:(UIColor *)backgroundColor
                                           dpi:(CGFloat)dpi;

@end

NS_ASSUME_NONNULL_END
