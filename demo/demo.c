int add(int a, int b) { return a + b; }
int sub(int a, int b) { return a - b; }
const char *secret(void) { return "OBF_SECRET_DEMO"; }
int mix(int x) {
  int y = add(x, 3);
  return sub(y, secret()[0] & 1);
}
