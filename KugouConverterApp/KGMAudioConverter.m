#import "KGMAudioConverter.h"
#include <spawn.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <TargetConditionals.h>

extern char **environ;

static const uint8_t kKeyStream[] = {0x7C,0x8E,0x9A,0xB3,0xD1,0x4F,0xA7,0xC6,0xE8,0x39,0x5D,0x7F,0x91,0xB2,0xD4,0x66};

@interface KGMAudioConverter ()
@property (atomic, copy) NSString *latestDecryptCandidateInfoInternal;
@end

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
        [candidates addObject:[documents.path stringByAppendingPathComponent:@"ffmpeg"]];
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

    [fm removeItemAtPath:runtimePath error:nil];
    if (![fm copyItemAtPath:originalPath toPath:runtimePath error:nil]) {
        return nil;
    }

    if (chmod(runtimePath.UTF8String, 0755) != 0) {
        return nil;
    }

    return access(runtimePath.UTF8String, X_OK) == 0 ? runtimePath : nil;
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

- (NSString *)shellQuoted:(NSString *)raw {
    if (raw.length == 0) {
        return @"''";
    }
    NSString *escaped = [raw stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];
    return [NSString stringWithFormat:@"'%@'", escaped];
}

- (NSString *)formatHintForData:(NSData *)data fallbackExtension:(NSString *)extension {
    if (data.length >= 4) {
        const uint8_t *b = data.bytes;
        if (b[0] == 'I' && b[1] == 'D' && b[2] == '3') return @"mp3";
        if (b[0] == 0xFF && (b[1] & 0xE0) == 0xE0) return @"mp3";
        if (b[0] == 'f' && b[1] == 'L' && b[2] == 'a' && b[3] == 'C') return @"flac";
        if (b[0] == 'O' && b[1] == 'g' && b[2] == 'g' && b[3] == 'S') return @"ogg";
        if (b[0] == 'R' && b[1] == 'I' && b[2] == 'F' && b[3] == 'F') return @"wav";
        if (b[0] == 0x4D && b[1] == 0x34 && b[2] == 0x41 && b[3] == 0x20) return @"m4a";
    }
    if ([extension isEqualToString:@"mp3"] || [extension isEqualToString:@"flac"] || [extension isEqualToString:@"ogg"] || [extension isEqualToString:@"wav"] || [extension isEqualToString:@"m4a"] || [extension isEqualToString:@"aac"]) {
        return extension;
    }
    return @"bin";
}

- (NSArray<NSNumber *> *)headerCandidatesForExtension:(NSString *)ext {
    if ([ext isEqualToString:@"kgg"] || [ext isEqualToString:@"kmg"]) {
        return @[@1024, @16, @0, @4096, @2048];
    }
    return @[@16, @1024, @0, @4096];
}

- (int)runBundledFFmpegWithInput:(NSURL *)inputURL
                          output:(NSURL *)outputURL
                     assumedType:(NSString *)assumedType
                         logPath:(NSString * _Nullable * _Nullable)logPath {
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
    if (logPath) {
        *logPath = stderrLogPath;
    }

    NSString *ffmpegInvocation = useShellWrapper ? [NSString stringWithFormat:@"/bin/sh %@", [self shellQuoted:ffmpegPath]] : [self shellQuoted:ffmpegPath];

    NSArray<NSString *> *inputModes;
    if ([assumedType isEqualToString:@"bin"] || assumedType.length == 0) {
        inputModes = @[
            @"",
            @"-f s16le -ar 44100 -ac 2",
            @"-f s16le -ar 48000 -ac 2",
            @"-f s16le -ar 44100 -ac 1",
            @"-f u8 -ar 44100 -ac 2"
        ];
    } else {
        inputModes = @[[NSString stringWithFormat:@"-f %@", assumedType]];
    }

    NSArray<NSDictionary<NSString *, NSString *> *> *encodeModes = @[
        @{@"codec": @"libmp3lame", @"extra": @"-q:a 2"},
        @{@"codec": @"mp3", @"extra": @"-b:a 320k"},
        @{@"codec": @"libmp3lame", @"extra": @"-ar 44100 -ac 2 -b:a 192k"},
        @{@"codec": @"mp3", @"extra": @"-ar 44100 -ac 2 -b:a 192k"}
    ];

    NSUInteger attemptIndex = 0;
    for (NSString *inputMode in inputModes) {
        for (NSDictionary *encode in encodeModes) {
            attemptIndex += 1;
            NSString *codec = encode[@"codec"];
            NSString *extra = encode[@"extra"];

            NSString *cmd = [NSString stringWithFormat:@"%@ -y -hide_banner -loglevel info -analyzeduration 100M -probesize 100M %@ -i %@ -vn -codec:a %@ %@ %@",
                             ffmpegInvocation,
                             inputMode,
                             [self shellQuoted:inputURL.path],
                             codec,
                             extra,
                             [self shellQuoted:outputURL.path]];

        if (stderrLogPath.length > 0) {
            NSString *section = [NSString stringWithFormat:@"\n===== ffmpeg attempt #%lu codec=%@ type=%@ inputMode=%@ =====\n%@\n", (unsigned long)attemptIndex, codec, assumedType ?: @"", inputMode.length > 0 ? inputMode : @"auto", cmd];
            NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:stderrLogPath];
            if (!fh) {
                [section writeToFile:stderrLogPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            } else {
                [fh seekToEndOfFile];
                [fh writeData:[section dataUsingEncoding:NSUTF8StringEncoding]];
                [fh closeFile];
            }
        }

        const char *argv[] = {"/bin/sh", "-c", cmd.UTF8String, NULL};

        posix_spawn_file_actions_t fileActions;
        posix_spawn_file_actions_init(&fileActions);
        if (stderrLogPath.length > 0) {
            posix_spawn_file_actions_addopen(&fileActions, STDERR_FILENO, stderrLogPath.UTF8String, O_WRONLY | O_CREAT | O_APPEND, 0644);
            posix_spawn_file_actions_addopen(&fileActions, STDOUT_FILENO, stderrLogPath.UTF8String, O_WRONLY | O_CREAT | O_APPEND, 0644);
        }

        pid_t pid;
        int spawnStatus = posix_spawn(&pid, "/bin/sh", &fileActions, NULL, (char *const *)argv, environ);
        posix_spawn_file_actions_destroy(&fileActions);
        if (spawnStatus != 0) {
            return spawnStatus;
        }

        int waitStatus = 0;
        if (waitpid(pid, &waitStatus, 0) < 0) {
            return -1002;
        }

        if (WIFEXITED(waitStatus) && WEXITSTATUS(waitStatus) == 0) {
            return 0;
        }
        }
    }

    return 1;
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
        NSURL *finalMP3URL = [outputDir URLByAppendingPathComponent:[baseName stringByAppendingPathExtension:@"mp3"]];
        [[NSFileManager defaultManager] removeItemAtURL:finalMP3URL error:nil];

        NSString *ext = inputURL.pathExtension.lowercaseString;
        BOOL isKugouEncrypted = [ext isEqualToString:@"kgm"] || [ext isEqualToString:@"kmg"] || [ext isEqualToString:@"kgg"] || [ext isEqualToString:@"vpr"];

        NSMutableArray<NSURL *> *tempInputs = [NSMutableArray array];
        NSMutableArray<NSString *> *typeHints = [NSMutableArray array];
        NSMutableString *candidateDiagnostics = [NSMutableString stringWithFormat:@"input=%@\next=%@\n", inputURL.lastPathComponent ?: @"", ext ?: @""];

        if (isKugouEncrypted) {
            NSData *raw = [NSData dataWithContentsOfURL:inputURL options:0 error:&error];
            if (!raw || error) {
                dispatch_async(dispatch_get_main_queue(), ^{ completion(nil, error); });
                return;
            }

            NSArray<NSNumber *> *headerCandidates = [self headerCandidatesForExtension:ext];
            NSUInteger idx = 0;
            for (NSNumber *header in headerCandidates) {
                NSData *decrypted = [self decryptKugouData:raw headerSize:header.unsignedIntegerValue];
                NSString *hint = [self formatHintForData:decrypted fallbackExtension:nil];
                [candidateDiagnostics appendFormat:@"candidate#%lu header=%@ bytes=%lu hint=%@\n", (unsigned long)idx, header, (unsigned long)decrypted.length, hint];

                if (decrypted.length == 0) {
                    idx += 1;
                    continue;
                }

                NSURL *tempURL = [outputDir URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.candidate%lu.%@", baseName, (unsigned long)idx, hint]];
                [[NSFileManager defaultManager] removeItemAtURL:tempURL error:nil];
                if ([decrypted writeToURL:tempURL options:NSDataWritingAtomic error:nil]) {
                    [tempInputs addObject:tempURL];
                    [typeHints addObject:hint];
                    [candidateDiagnostics appendFormat:@"  -> accepted temp=%@\n", tempURL.lastPathComponent ?: @"(null)"];
                } else {
                    [candidateDiagnostics appendString:@"  -> rejected (write failed)\n"];
                }
                idx += 1;
            }
        } else {
            NSData *sourceData = [NSData dataWithContentsOfURL:inputURL options:0 error:&error];
            if (!sourceData || error) {
                dispatch_async(dispatch_get_main_queue(), ^{ completion(nil, error); });
                return;
            }
            NSString *hint = [self formatHintForData:sourceData fallbackExtension:ext];
            NSURL *tempURL = [outputDir URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.source.%@", baseName, hint]];
            [[NSFileManager defaultManager] removeItemAtURL:tempURL error:nil];
            if (![sourceData writeToURL:tempURL options:NSDataWritingAtomic error:&error] || error) {
                dispatch_async(dispatch_get_main_queue(), ^{ completion(nil, error); });
                return;
            }
            [tempInputs addObject:tempURL];
            [typeHints addObject:hint];
            [candidateDiagnostics appendFormat:@"source-pass-through bytes=%lu hint=%@ file=%@\n", (unsigned long)sourceData.length, hint, tempURL.lastPathComponent ?: @"(null)"];
        }

        if (tempInputs.count == 0) {
            NSError *e = [NSError errorWithDomain:@"KugouConverter" code:100 userInfo:@{NSLocalizedDescriptionKey:@"解密后没有可用音频数据：已尝试多种头部策略（16/1024/4096/0）"}];
            dispatch_async(dispatch_get_main_queue(), ^{ completion(nil, e); });
            return;
        }

        int ffmpegCode = 1;
        NSString *ffmpegLogPath = nil;
        NSURL *documents = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
        if (documents) {
            NSString *logPath = [documents.path stringByAppendingPathComponent:@"ffmpeg_last_error.log"];
            [[NSFileManager defaultManager] removeItemAtPath:logPath error:nil];
        }

        for (NSUInteger i = 0; i < tempInputs.count; i++) {
            [candidateDiagnostics appendFormat:@"ffmpeg candidate try #%lu file=%@ type=%@\n", (unsigned long)(i + 1), tempInputs[i].lastPathComponent ?: @"", typeHints[i] ?: @""];
            ffmpegCode = [self runBundledFFmpegWithInput:tempInputs[i] output:finalMP3URL assumedType:typeHints[i] logPath:&ffmpegLogPath];
            if (ffmpegCode == 0) {
                break;
            }
        }

        self.latestDecryptCandidateInfoInternal = [candidateDiagnostics copy];

        for (NSURL *tempURL in tempInputs) {
            [[NSFileManager defaultManager] removeItemAtURL:tempURL error:nil];
        }

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
                if (logText.length > 1200) {
                    logText = [logText substringFromIndex:logText.length - 1200];
                }
                message = [NSString stringWithFormat:@"ffmpeg 转码失败：已尝试多头部解密 + 多编码器参数回退 + 原始PCM兜底，退出码: %d\n%@", ffmpegCode, logText];
            }
            NSError *e = [NSError errorWithDomain:@"KugouConverter" code:101 userInfo:@{NSLocalizedDescriptionKey: message}];
            dispatch_async(dispatch_get_main_queue(), ^{ completion(nil, e); });
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{ completion(finalMP3URL, nil); });
    });
}

- (NSString *)latestDecryptCandidateInfo {
    return self.latestDecryptCandidateInfoInternal ?: @"";
}

@end
