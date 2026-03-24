#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *OBFDecrypt(NSString *payload, int key);
FOUNDATION_EXPORT NSString *OBFDecryptSelector(NSString *selectorRaw);
FOUNDATION_EXPORT void OBFInstallAntiDebug(void);
FOUNDATION_EXPORT void OBFInstallAntiDump(void);
