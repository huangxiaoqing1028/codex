int add(int a, int b) { return a + b; }
int sub(int a, int b) { return a - b; }
int mix(int x) {
  int y = add(x, 3);
  return sub(y, 1);
}
