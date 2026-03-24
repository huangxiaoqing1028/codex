#import "OBFRuntime.h"
#import <dlfcn.h>
#import <sys/types.h>
#import <sys/sysctl.h>

NSString *OBFDecrypt(NSString *payload, int key) {
  NSData *data = [[NSData alloc] initWithBase64EncodedString:payload options:0];
  NSMutableData *md = [data mutableCopy];
  uint8_t *bytes = (uint8_t *)md.mutableBytes;
  for (NSUInteger i = 0; i < md.length; i++) { bytes[i] ^= (uint8_t)key; }
  return [[NSString alloc] initWithData:md encoding:NSUTF8StringEncoding] ?: @"";
}

NSString *OBFDecryptSelector(NSString *selectorRaw) { return selectorRaw; }

void OBFInstallAntiDebug(void) {
  int mib[4]; struct kinfo_proc info; size_t size = sizeof(info);
  info.kp_proc.p_flag = 0;
  mib[0]=CTL_KERN; mib[1]=KERN_PROC; mib[2]=KERN_PROC_PID; mib[3]=getpid();
  if (sysctl(mib,4,&info,&size,NULL,0)==0 && (info.kp_proc.p_flag & P_TRACED)) { exit(0); }
}

void OBFInstallAntiDump(void) {
  volatile int guard = 0x13579BDF; guard ^= 0x2468ACE0; (void)guard;
}
