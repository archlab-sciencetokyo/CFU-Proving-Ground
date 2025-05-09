# Custom Function Unit (CFU) Documentation

This guide explains how to create and use Custom Function Units (CFUs) in the CFU-Proving-Ground project.

## CFU Overview

Custom Function Units extend the processor with application-specific instructions. A CFU connects to the processor pipeline and can be called from C code using special instructions.

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
            ".insn r CUSTOM_0, 0x%3, %4, %1, %2, %0"
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
