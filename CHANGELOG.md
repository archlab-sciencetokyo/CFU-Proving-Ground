# Changelog
2025-11-10 Ver 1.8.6:
- Update color definitions in st7789.h

2025-10-31 Ver 1.8.5:
- Combine multiple vmems into one vmem

2025-10-23 Ver 1.8.4:
- Format files
- Add CHANGELOG.md

2025-10-23 Ver 1.8.3:
- Refactor clock signal definitions in XDC files: remove redundant create_clock commands

2025-10-22 Ver 1.8.2:
- Fix a performance counter bug
- Add debug dumps

2025-10-21 Ver 1.8.1:
- Remove unused dbus_ren_o output from cpu module and clean up related assignments

2025-10-20 Ver 1.8.0:
- Architectural improvements to the CPU pipeline and memory subsystem

2025-10-16 Ver 1.7.10:
- Refactor divider module and update store_unit address calculation

2025-10-10 Ver 1.7.9:
- Add `fflush()` to ensure output is flushed during simulation

2025-10-09 Ver 1.7.8:
- Add bitstream configuration to `cmod_a7.xdc` and `nexys_a7.xdc`

2025-10-08 Ver 1.7.7:
- Update perf.c

2025-10-07 Ver 1.7.6:
- Update Nexys example

2025-10-02 Ver 1.7.5:
- Make target has been added.

2025-07-25 Ver 1.7.4:
- Configuration bug has been fixed.

2025-07-09 Ver 1.7.3:
- Divider bug has been fixed.

2025-07-02 Ver 1.7.2:
- IMEM/DMEM memory size bug has been fixed.

2025-06-16 Ver 1.7.1:
- Fixed a bug in the ALU.

2025-06-04 Ver 1.7:
- Verilog files have been formatted.
- CFU supported HLS.

2025-06-03 Ver 1.6:
- Revised some descriptions for VCC.

2025-05-09 Ver 1.5:
- Improved RVProc clock speed to 180 MHz.
- Added CFU.md describing how to use the cfu.v.

2025-05-01 Ver 1.4:
- Fixed a bug in the branch predictor.
- Improved Fmax of RVProc from 160MHz to 175MHz.

2025-04-24 Ver 1.3:
- Default configuration of `IMEM_SIZE` has been changed 64KiB to 32KiB.
- We have improved BRAM that was deleted during optimization.
- Jitter Optimization of the clocking wizard has been changed.

2025-04-11 Ver 1.2:
- The tcl script has been modified so that the operating frequency can be set from config.vh.
- A script that automatically writes the bitstream to the board has been added (`Make conf`).

2025-04-07 Ver 1.1:
- CFU now supports stall_o signals.

2025-03-31 Ver 1.0:
- CFU Proving Ground has been published.

2025-03-26 Ver 0.5:
- The function names in the Proving Ground library have been changed.
- The timing of writing to data memory has been changed from the MA stage to the EX stage.

2025-03-24 Ver 0.4:
- The memory map has been changed.
- We changed from Princeton architecture to Harvard architecture.
- The timing of writing to data memory has been changed from the EX stage to the MA stage.
- `perf_instret()` has been removed.

2025-03-04 Ver 0.3:
- The default application has been changed.
- Changed vmem to 3bit RGB.

2025-03-03 Ver 0.2:
- Fixed to allow changing display direction in `config.vh`.
- We have decided not to support transparent colors.
- Removed `st7789_printf()` and added `LCD_prints()`.
- The method was changed to specify the absolute path in the `Makefile`.
- The g++ compiler is now supported.
- When generating bitstream, the existence of `sample1.txt` is checked.
- Moved `build.tcl` to the home directory.
- The directory `prog` has been changed to `app`.
- Added license file.
- Added a brief explanation to the README.md.
- Changed to use the display emulation with `make drun`.
- In addition to the Nexys A7, we now support the Arty A7.
- Changed Nexys A7 and Arty A7 to not use Clock Wizard.

2025-02-20 Ver.0.1:
- initial version
