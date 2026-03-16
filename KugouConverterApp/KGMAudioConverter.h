#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, KGOutputFormat) {
    KGOutputFormatMP3
};

@interface KGMAudioConverter : NSObject

- (void)convertFileAtURL:(NSURL *)inputURL
              outputDir:(NSURL *)outputDir
                 format:(KGOutputFormat)format
             completion:(void (^)(NSURL * _Nullable outputURL, NSError * _Nullable error))completion;

- (NSData *)decryptKugouData:(NSData *)data headerSize:(NSUInteger)headerSize;

@end
