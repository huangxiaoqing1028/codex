#ifndef OBF_DECRYPT_H
#define OBF_DECRYPT_H

#import <Foundation/Foundation.h>

NS_INLINE NSData *obf_decrypt_data(const unsigned char *cipher, NSUInteger len, uint8_t key) {
    if (cipher == NULL || len == 0) {
        return [NSData data];
    }
    NSMutableData *plain = [NSMutableData dataWithLength:len];
    uint8_t *outBytes = (uint8_t *)plain.mutableBytes;
    for (NSUInteger i = 0; i < len; i++) {
        outBytes[i] = (uint8_t)(cipher[i] ^ key);
    }
    return plain;
}

NS_INLINE NSString *obf_decrypt_nsstring(const unsigned char *cipher, NSUInteger len, uint8_t key) {
    NSData *plain = obf_decrypt_data(cipher, len, key);
    NSString *decoded = [[NSString alloc] initWithData:plain encoding:NSUTF8StringEncoding];
    if (decoded == nil) {
        decoded = [[NSString alloc] initWithData:plain encoding:NSASCIIStringEncoding];
    }
    return decoded ?: @"";
}

#define DECRYPT_OBJC_STRING(cipher_bytes, cipher_len, xor_key) \
({ \
    const unsigned char *__obf_cipher = (cipher_bytes); \
    obf_decrypt_nsstring(__obf_cipher, (cipher_len), (uint8_t)(xor_key)); \
})

#endif // OBF_DECRYPT_H
