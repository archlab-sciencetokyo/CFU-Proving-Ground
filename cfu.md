# Custom Function Unit (CFU) Documentation

This guide explains how to create and use Custom Function Units (CFUs) in the CFU-Proving-Ground project.

## CFU Overview

Custom Function Units extend the processor with application-specific instructions. A CFU connects to the processor pipeline and can be called from C code using custom instructions.

## Using CFUs in C Code

Using a CFU in C code involves:

1. Define operation codes as constants:
    ```c
    #define CFU_OP_ADD       0
    ```

1. Create a wrapper function for the CFU operation:
    ```c
    static inline unsigned int cfu_op(unsigned int funct7, unsigned int funct3,
                                    unsigned int rs1, unsigned int rs2) {
        unsigned int result;
        asm volatile(
            ".insn r CUSTOM_0, %3, %4, %0, %1, %2"
            : "=r"(result)
            : "r"(rs1), "r"(rs2), "i"(funct3), "i"(funct7)
            :
        );
        return result;
    }
    ```

1. Create a specific function for each CFU operation:
    ```c
    static inline unsigned int cfu_add(unsigned int a, unsigned int b) {
        return cfu_op(0, CFU_OP_ADD, a, b);
    }
    ```

1. Call the function in your code:
    ```c
    unsigned int add_result = cfu_add(test1, test2);
    ```
> [!NOTE]
> `.insn r` is a pseudo instruction for specifying an RISC-V instruction in R format.
> This instruction is used as follows:
> ```
> .insn r opcode, funct3, funct7, rd, rs1, rs2
> ```
>
> Let's look at a simple example:
> ```c
> #include <stdio.h>
>
> int main(){
> int rs1 = 1;
> int rs2 = 2;
>
> int result;
> asm volatile (
>              ".insn r 0x33, 0x0, 0x20, %0, %1, %2"
>              : "=r" (result)
>              : "r" (rs1) ,  "r" (rs2)
>              );
> printf("%d %d -> %d \n", rs1, rs2, result);
> return 0;
> ```
> This code specifies the instruction opcode=0x33, funct3=0x0, funct7=0x20.
> This is the `sub` instruction.
>
> Here's dump of this code, which appears to compile correctly as a `sub` instruction:
> ```
> 000100b4 <main>:
>   100b4:	ff010113          	addi	sp,sp,-16
>   100b8:	00112623          	sw	ra,12(sp)
>   100bc:	00100593          	li	a1,1
>   100c0:	00200793          	li	a5,2
>   100c4:	40f586b3          	sub	a3,a1,a5
>   100c8:	00021537          	lui	a0,0x21
>   100cc:	00078613          	mv	a2,a5
>   100d0:	ce850513          	addi	a0,a0,-792 # 20ce8 <__clzsi2+0x4c>
>   100d4:	05c000ef          	jal	10130 <printf>
>   100d8:	00c12083          	lw	ra,12(sp)
>   100dc:	00000513          	li	a0,0
>   100e0:	01010113          	addi	sp,sp,16
>   100e4:	00008067          	ret
> ```

## Key Implementation Requirements

When implementing a new CFU operation module, follow these rules:

1. **Stall Signal Management**:
   - Keep `stall_o` active (high) until the result is ready to be read.
   - This indicates to the processor that it should wait for the CFU to complete.

1. **Result Timing**:
   - After deactivating `stall_o`, the `rslt_o` should be valid for exactly 1 clock cycle.
   - Then immediately reset `rslt_o` to 0.
   - Failure to do this can break the caller's logic.

1. **Enable Signal Handling**:
   - The `en_i` signal is activated only once when the operation is requested.
   - Your module should detect this single pulse and begin its operation.

Other Notices:

- The internal implementation of your CFU is flexible.
- You can use as many clock cycles as needed for computation.
