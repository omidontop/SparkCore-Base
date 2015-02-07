# This file is a makefile included from the top level makefile which
# defines the sources built for the target.

# Add tropicssl include to all objects built for this target
INCLUDE_DIRS += /system/diag/include

# C source files included in this build.
CSRC += $(call target_files,/system/diag/,*.c)

# C++ source files included in this build.
CPPSRC += $(call target_files,/system/diag/,*.cpp)

# ASM source files included in this build.
ASRC += $(call target_files,/system/diag/,*.s)