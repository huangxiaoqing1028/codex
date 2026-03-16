#import "KGMAudioConverter.h"
#import <ffmpegkit/FFmpegKit.h>
#import <ffmpegkit/FFmpegKitConfig.h>
#import <ffmpegkit/FFmpegSession.h>
#import <ffmpegkit/ReturnCode.h>

static const uint8_t kKeyStream[] = {0x7C,0x8E,0x9A,0xB3,0xD1,0x4F,0xA7,0xC6,0xE8,0x39,0x5D,0x7F,0x91,0xB2,0xD4,0x66};

@implementation KGMAudioConverter

- (NSData *)decryptKugouData:(NSData *)data headerSize:(NSUInteger)headerSize {
    if (data.length <= headerSize) {
        return [NSData data];
    }

    NSUInteger payloadLen = data.length - headerSize;
    NSMutableData *payload = [[data subdataWithRange:NSMakeRange(headerSize, payloadLen)] mutableCopy];
    uint8_t *bytes = (uint8_t *)payload.mutableBytes;
    NSUInteger keyLen = sizeof(kKeyStream) / sizeof(uint8_t);

    for (NSUInteger i = 0; i < payloadLen; i++) {
        bytes[i] = bytes[i] ^ kKeyStream[i % keyLen] ^ ((i * 31) & 0xFF);
    }
    return payload;
}

- (void)convertFileAtURL:(NSURL *)inputURL
              outputDir:(NSURL *)outputDir
                 format:(KGOutputFormat)format
             completion:(void (^)(NSURL * _Nullable outputURL, NSError * _Nullable error))completion {
    (void)format;

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtURL:outputDir withIntermediateDirectories:YES attributes:nil error:nil];

        NSString *baseName = inputURL.lastPathComponent.stringByDeletingPathExtension;
        NSURL *tempMP3URL = [outputDir URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.temp.mp3", baseName]];
        NSURL *finalMP3URL = [outputDir URLByAppendingPathComponent:[baseName stringByAppendingPathExtension:@"mp3"]];

        [[NSFileManager defaultManager] removeItemAtURL:tempMP3URL error:nil];
        [[NSFileManager defaultManager] removeItemAtURL:finalMP3URL error:nil];

        NSString *ext = inputURL.pathExtension.lowercaseString;
        if ([ext isEqualToString:@"kgm"] || [ext isEqualToString:@"vpr"]) {
            NSData *raw = [NSData dataWithContentsOfURL:inputURL options:0 error:&error];
            if (!raw || error) {
                dispatch_async(dispatch_get_main_queue(), ^{ completion(nil, error); });
                return;
            }

            NSData *decryptedMP3Bytes = [self decryptKugouData:raw headerSize:16];
            if (decryptedMP3Bytes.length == 0) {
                NSError *e = [NSError errorWithDomain:@"KugouConverter" code:100 userInfo:@{NSLocalizedDescriptionKey:@"KGM/VPR 解密失败或文件内容为空"}];
                dispatch_async(dispatch_get_main_queue(), ^{ completion(nil, e); });
                return;
            }

            BOOL ok = [decryptedMP3Bytes writeToURL:tempMP3URL options:NSDataWritingAtomic error:&error];
            if (!ok || error) {
                dispatch_async(dispatch_get_main_queue(), ^{ completion(nil, error); });
                return;
            }
        } else {
            NSData *sourceData = [NSData dataWithContentsOfURL:inputURL options:0 error:&error];
            if (!sourceData || error) {
                dispatch_async(dispatch_get_main_queue(), ^{ completion(nil, error); });
                return;
            }

            BOOL ok = [sourceData writeToURL:tempMP3URL options:NSDataWritingAtomic error:&error];
            if (!ok || error) {
                dispatch_async(dispatch_get_main_queue(), ^{ completion(nil, error); });
                return;
            }
        }

        NSString *command = [NSString stringWithFormat:@"-y -i '%@' -vn -codec:a libmp3lame -b:a 320k '%@'", tempMP3URL.path, finalMP3URL.path];

        [FFmpegKit executeAsync:command withCompleteCallback:^(FFmpegSession *session) {
            [[NSFileManager defaultManager] removeItemAtURL:tempMP3URL error:nil];

            ReturnCode *rc = [session getReturnCode];
            if ([ReturnCode isSuccess:rc]) {
                dispatch_async(dispatch_get_main_queue(), ^{ completion(finalMP3URL, nil); });
                return;
            }

            NSString *logs = [session getAllLogsAsString] ?: @"";
            NSError *e = [NSError errorWithDomain:@"KugouConverter"
                                             code:101
                                         userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"FFmpegKit 转码失败: %@", logs]}];
            dispatch_async(dispatch_get_main_queue(), ^{ completion(nil, e); });
        }];
    });
}

@end
