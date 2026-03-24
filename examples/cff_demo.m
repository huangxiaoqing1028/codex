#import <Foundation/Foundation.h>

int demo(int value) {
// OBF_CFF_BEGIN
value += 3;
value ^= 0x55;
printf("%d", value);
// OBF_CFF_END
return value;
}
