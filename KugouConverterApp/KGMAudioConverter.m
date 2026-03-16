#import "KGMAudioConverter.h"
#include <spawn.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <TargetConditionals.h>

extern char **environ;

static const uint8_t kKeyStream[] = {0x7C,0x8E,0x9A,0xB3,0xD1,0x4F,0xA7,0xC6,0xE8,0x39,0x5D,0x7F,0x91,0xB2,0xD4,0x66};

@implementation KGMAudioConverter


- (NSString *)resolveFFmpegPath {
    NSMutableArray<NSString *> *candidates = [NSMutableArray array];

    NSString *bundleResource = [[NSBundle mainBundle] pathForResource:@"ffmpeg" ofType:nil];
    if (bundleResource.length > 0) {
        [candidates addObject:bundleResource];
    }

    NSString *bundleExecutableDir = [[[NSBundle mainBundle] executablePath] stringByDeletingLastPathComponent];
    if (bundleExecutableDir.length > 0) {
        [candidates addObject:[bundleExecutableDir stringByAppendingPathComponent:@"ffmpeg"]];
    }

    NSURL *documents = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    if (documents) {
        [candidates addObject:[[documents.path stringByAppendingPathComponent:@"ffmpeg"] copy]];
    }

#if TARGET_OS_SIMULATOR
    [candidates addObject:@"/opt/homebrew/bin/ffmpeg"];
    [candidates addObject:@"/usr/local/bin/ffmpeg"];
    [candidates addObject:@"/usr/bin/ffmpeg"];
#endif

    NSFileManager *fm = [NSFileManager defaultManager];
    for (NSString *path in candidates) {
        BOOL isDir = NO;
        if (path.length > 0 && [fm fileExistsAtPath:path isDirectory:&isDir] && !isDir) {
            return path;
        }
    }
    return nil;
}

- (NSString *)prepareExecutableFFmpegPath:(NSString *)originalPath {
    if (originalPath.length == 0) {
        return nil;
    }

    if (access(originalPath.UTF8String, X_OK) == 0) {
        return originalPath;
    }

    NSURL *documents = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    if (!documents) {
        return nil;
    }

    NSString *runtimePath = [documents.path stringByAppendingPathComponent:@"ffmpeg_runtime"];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *copyError = nil;

    [fm removeItemAtPath:runtimePath error:nil];
    BOOL copied = [fm copyItemAtPath:originalPath toPath:runtimePath error:&copyError];
    if (!copied || copyError) {
        return nil;
    }

    if (chmod(runtimePath.UTF8String, 0755) != 0) {
        return nil;
    }

    if (access(runtimePath.UTF8String, X_OK) == 0) {
        return runtimePath;
    }
    return nil;
}

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


- (BOOL)isShellScriptAtPath:(NSString *)path {
    if (path.length == 0) {
        return NO;
    }
    NSData *data = [NSData dataWithContentsOfFile:path options:0 error:nil];
    if (data.length < 2) {
        return NO;
    }
    const unsigned char *bytes = (const unsigned char *)data.bytes;
    return bytes[0] == '#' && bytes[1] == '!';
}

- (int)runBundledFFmpegWithInput:(NSURL *)inputURL output:(NSURL *)outputURL logPath:(NSString * _Nullable * _Nullable)logPath {
    NSString *resolvedPath = [self resolveFFmpegPath];
    if (resolvedPath.length == 0) {
        return -1001;
    }

    NSString *ffmpegPath = [self prepareExecutableFFmpegPath:resolvedPath];
    BOOL useShellWrapper = NO;
    if (ffmpegPath.length == 0 && [self isShellScriptAtPath:resolvedPath]) {
        ffmpegPath = resolvedPath;
        useShellWrapper = YES;
    }
    if (ffmpegPath.length == 0) {
        return -1004;
    }

    NSURL *documents = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    NSString *stderrLogPath = documents ? [documents.path stringByAppendingPathComponent:@"ffmpeg_last_error.log"] : nil;
    if (stderrLogPath.length > 0) {
        [[NSFileManager defaultManager] removeItemAtPath:stderrLogPath error:nil];
    }
    if (logPath) {
        *logPath = stderrLogPath;
    }

    const char *argvExec[] = {
        ffmpegPath.UTF8String,
        "-y",
        "-hide_banner",
        "-i",
        inputURL.path.UTF8String,
        "-vn",
        "-codec:a",
        "libmp3lame",
        "-b:a",
        "320k",
        outputURL.path.UTF8String,
        NULL
    };

    const char *argvShell[] = {
        "/bin/sh",
        ffmpegPath.UTF8String,
        "-y",
        "-hide_banner",
        "-i",
        inputURL.path.UTF8String,
        "-vn",
        "-codec:a",
        "libmp3lame",
        "-b:a",
        "320k",
        outputURL.path.UTF8String,
        NULL
    };

    const char *launchPath = useShellWrapper ? "/bin/sh" : ffmpegPath.UTF8String;
    char *const *argv = (char *const *)(useShellWrapper ? argvShell : argvExec);

    posix_spawn_file_actions_t fileActions;
    posix_spawn_file_actions_init(&fileActions);
    if (stderrLogPath.length > 0) {
        posix_spawn_file_actions_addopen(&fileActions, STDERR_FILENO, stderrLogPath.UTF8String, O_WRONLY | O_CREAT | O_TRUNC, 0644);
        posix_spawn_file_actions_addopen(&fileActions, STDOUT_FILENO, stderrLogPath.UTF8String, O_WRONLY | O_CREAT | O_APPEND, 0644);
    }

    pid_t pid;
    int spawnStatus = posix_spawn(&pid, launchPath, &fileActions, NULL, argv, environ);
    posix_spawn_file_actions_destroy(&fileActions);

    if (spawnStatus != 0) {
        return spawnStatus;
    }

    int waitStatus = 0;
    if (waitpid(pid, &waitStatus, 0) < 0) {
        return -1002;
    }

    if (WIFEXITED(waitStatus)) {
        return WEXITSTATUS(waitStatus);
    }
    return -1003;
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
        BOOL isKugouEncrypted = [ext isEqualToString:@"kgm"] || [ext isEqualToString:@"kmg"] || [ext isEqualToString:@"kgg"] || [ext isEqualToString:@"vpr"];

        if (isKugouEncrypted) {
            NSData *raw = [NSData dataWithContentsOfURL:inputURL options:0 error:&error];
            if (!raw || error) {
                dispatch_async(dispatch_get_main_queue(), ^{ completion(nil, error); });
                return;
            }

            NSData *decryptedMP3Bytes = [self decryptKugouData:raw headerSize:16];
            if (decryptedMP3Bytes.length == 0) {
                NSError *e = [NSError errorWithDomain:@"KugouConverter" code:100 userInfo:@{NSLocalizedDescriptionKey:@"KGM/KGG/VPR 解密失败或文件内容为空"}];
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

        NSString *ffmpegLogPath = nil;
        int ffmpegCode = [self runBundledFFmpegWithInput:tempMP3URL output:finalMP3URL logPath:&ffmpegLogPath];
        [[NSFileManager defaultManager] removeItemAtURL:tempMP3URL error:nil];

        if (ffmpegCode != 0) {
            NSString *message = nil;
            if (ffmpegCode == -1001) {
                message = @"未找到 ffmpeg 文件：请放入 App Bundle(文件名ffmpeg) 或 Documents/ffmpeg";
            } else if (ffmpegCode == -1004) {
                message = @"找到 ffmpeg 但不可执行：若为脚本请确保内容有效；若为二进制请检查架构与签名，或放置可执行的 Documents/ffmpeg";
            } else {
                NSString *logText = @"";
                if (ffmpegLogPath.length > 0) {
                    NSData *logData = [NSData dataWithContentsOfFile:ffmpegLogPath];
                    if (logData.length > 0) {
                        logText = [[NSString alloc] initWithData:logData encoding:NSUTF8StringEncoding] ?: @"";
                    }
                }
                if (logText.length > 800) {
                    logText = [logText substringFromIndex:logText.length - 800];
                }
                message = [NSString stringWithFormat:@"ffmpeg 转码失败，退出码: %d\n%@", ffmpegCode, logText];
            }
            NSError *e = [NSError errorWithDomain:@"KugouConverter" code:101 userInfo:@{NSLocalizedDescriptionKey: message}];
            dispatch_async(dispatch_get_main_queue(), ^{ completion(nil, e); });
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{ completion(finalMP3URL, nil); });
    });
}

@end
