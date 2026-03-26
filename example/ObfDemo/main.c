#include <stdio.h>

static int add(int a, int b) { return a + b; }
static int sub(int a, int b) { return a - b; }

int main(void) {
    int x = add(20, 22);
    int y = sub(100, 58);
    printf("add=%d sub=%d\n", x, y);
    return 0;
}
