/*
 * Linked into everything built with funkyenv. Each function gets its own
 * section (-ffunction-sections), so after --shuffle-sections their addresses
 * should no longer be in source order; verify-shuffle.sh checks for that.
 */

#define CANARY(n) \
  __attribute__((used, retain, noinline)) static int __funkyenv_canary_##n(void) { return n; }

CANARY(0) CANARY(1) CANARY(2) CANARY(3) CANARY(4) CANARY(5) CANARY(6) CANARY(7)
CANARY(8) CANARY(9) CANARY(10) CANARY(11) CANARY(12) CANARY(13) CANARY(14) CANARY(15)
CANARY(16) CANARY(17) CANARY(18) CANARY(19) CANARY(20) CANARY(21) CANARY(22) CANARY(23)
CANARY(24) CANARY(25) CANARY(26) CANARY(27) CANARY(28) CANARY(29) CANARY(30) CANARY(31)
