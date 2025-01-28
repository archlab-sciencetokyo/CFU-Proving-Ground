#include <stdint.h>

#define CFU_FUNC(funct3, funct7) \
static inline uint32_t cfu##funct3##_##funct7(uint32_t rs1, uint32_t rs2) { \
    uint32_t ret = 0; \
    asm volatile ("cfu" #funct3 "." #funct7 " %0, %1, %2" : "=r"(ret) : "r"(rs1), "r"(rs2)); \
    return ret; \
}

// Generate all combinations
#define EXPAND_FUNCT7(funct3) \
CFU_FUNC(funct3, 0) \
CFU_FUNC(funct3, 1) \
CFU_FUNC(funct3, 2) \
CFU_FUNC(funct3, 3) \
CFU_FUNC(funct3, 4) \
CFU_FUNC(funct3, 5) \
CFU_FUNC(funct3, 6) \
CFU_FUNC(funct3, 7) \
CFU_FUNC(funct3, 8) \
CFU_FUNC(funct3, 9) \
CFU_FUNC(funct3, 10) \
CFU_FUNC(funct3, 11) \
CFU_FUNC(funct3, 12) \
CFU_FUNC(funct3, 13) \
CFU_FUNC(funct3, 14) \
CFU_FUNC(funct3, 15) \
CFU_FUNC(funct3, 16) \
CFU_FUNC(funct3, 17) \
CFU_FUNC(funct3, 18) \
CFU_FUNC(funct3, 19) \
CFU_FUNC(funct3, 20) \
CFU_FUNC(funct3, 21) \
CFU_FUNC(funct3, 22) \
CFU_FUNC(funct3, 23) \
CFU_FUNC(funct3, 24) \
CFU_FUNC(funct3, 25) \
CFU_FUNC(funct3, 26) \
CFU_FUNC(funct3, 27) \
CFU_FUNC(funct3, 28) \
CFU_FUNC(funct3, 29) \
CFU_FUNC(funct3, 30) \
CFU_FUNC(funct3, 31) \
CFU_FUNC(funct3, 32) \
CFU_FUNC(funct3, 33) \
CFU_FUNC(funct3, 34) \
CFU_FUNC(funct3, 35) \
CFU_FUNC(funct3, 36) \
CFU_FUNC(funct3, 37) \
CFU_FUNC(funct3, 38) \
CFU_FUNC(funct3, 39) \
CFU_FUNC(funct3, 40) \
CFU_FUNC(funct3, 41) \
CFU_FUNC(funct3, 42) \
CFU_FUNC(funct3, 43) \
CFU_FUNC(funct3, 44) \
CFU_FUNC(funct3, 45) \
CFU_FUNC(funct3, 46) \
CFU_FUNC(funct3, 47) \
CFU_FUNC(funct3, 48) \
CFU_FUNC(funct3, 49) \
CFU_FUNC(funct3, 50) \
CFU_FUNC(funct3, 51) \
CFU_FUNC(funct3, 52) \
CFU_FUNC(funct3, 53) \
CFU_FUNC(funct3, 54) \
CFU_FUNC(funct3, 55) \
CFU_FUNC(funct3, 56) \
CFU_FUNC(funct3, 57) \
CFU_FUNC(funct3, 58) \
CFU_FUNC(funct3, 59) \
CFU_FUNC(funct3, 60) \
CFU_FUNC(funct3, 61) \
CFU_FUNC(funct3, 62) \
CFU_FUNC(funct3, 63) \
CFU_FUNC(funct3, 64) \
CFU_FUNC(funct3, 65) \
CFU_FUNC(funct3, 66) \
CFU_FUNC(funct3, 67) \
CFU_FUNC(funct3, 68) \
CFU_FUNC(funct3, 69) \
CFU_FUNC(funct3, 70) \
CFU_FUNC(funct3, 71) \
CFU_FUNC(funct3, 72) \
CFU_FUNC(funct3, 73) \
CFU_FUNC(funct3, 74) \
CFU_FUNC(funct3, 75) \
CFU_FUNC(funct3, 76) \
CFU_FUNC(funct3, 77) \
CFU_FUNC(funct3, 78) \
CFU_FUNC(funct3, 79) \
CFU_FUNC(funct3, 80) \
CFU_FUNC(funct3, 81) \
CFU_FUNC(funct3, 82) \
CFU_FUNC(funct3, 83) \
CFU_FUNC(funct3, 84) \
CFU_FUNC(funct3, 85) \
CFU_FUNC(funct3, 86) \
CFU_FUNC(funct3, 87) \
CFU_FUNC(funct3, 88) \
CFU_FUNC(funct3, 89) \
CFU_FUNC(funct3, 90) \
CFU_FUNC(funct3, 91) \
CFU_FUNC(funct3, 92) \
CFU_FUNC(funct3, 93) \
CFU_FUNC(funct3, 94) \
CFU_FUNC(funct3, 95) \
CFU_FUNC(funct3, 96) \
CFU_FUNC(funct3, 97) \
CFU_FUNC(funct3, 98) \
CFU_FUNC(funct3, 99) \
CFU_FUNC(funct3, 100) \
CFU_FUNC(funct3, 101) \
CFU_FUNC(funct3, 102) \
CFU_FUNC(funct3, 103) \
CFU_FUNC(funct3, 104) \
CFU_FUNC(funct3, 105) \
CFU_FUNC(funct3, 106) \
CFU_FUNC(funct3, 107) \
CFU_FUNC(funct3, 108) \
CFU_FUNC(funct3, 109) \
CFU_FUNC(funct3, 110) \
CFU_FUNC(funct3, 111) \
CFU_FUNC(funct3, 112) \
CFU_FUNC(funct3, 113) \
CFU_FUNC(funct3, 114) \
CFU_FUNC(funct3, 115) \
CFU_FUNC(funct3, 116) \
CFU_FUNC(funct3, 117) \
CFU_FUNC(funct3, 118) \
CFU_FUNC(funct3, 119) \
CFU_FUNC(funct3, 120) \
CFU_FUNC(funct3, 121) \
CFU_FUNC(funct3, 122) \
CFU_FUNC(funct3, 123) \
CFU_FUNC(funct3, 124) \
CFU_FUNC(funct3, 125) \
CFU_FUNC(funct3, 126) \
CFU_FUNC(funct3, 127)

EXPAND_FUNCT7(0)
EXPAND_FUNCT7(1)
EXPAND_FUNCT7(2)
EXPAND_FUNCT7(3)
EXPAND_FUNCT7(4)
EXPAND_FUNCT7(5)
EXPAND_FUNCT7(6)
EXPAND_FUNCT7(7)
