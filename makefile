################################################################################
# File Name: 	makefile
################################################################################
# Desription: 	The main makefile used by the GNU Make.
# 
#
# Copyright (C) 2015 by Omid Manikhi. All rights reserved...
################################################################################


################################################################################
# Functions
################################################################################

# Recursive wildcard function
rwildcard = $(wildcard $1$2) $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))

# enumerates files in the filesystem and returns their path relative to the project root
# $1 the directory relative to the project root
# $2 the pattern to match, e.g. *.cpp
target_files = $(patsubst $(SRC_DIR)/%,%,$(call rwildcard,$(SRC_DIR)/$1,$2))


################################################################################
# Directory Definitions
################################################################################

# by convention, all symbols referring to a directory end with a slash - this 
# allows directories to resolve to "" when equal to the working directory.
SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

# The project directory is the current directory where the makefile is placed.
PROJECT_DIR := $(SELF_DIR)

# Define the build path, this is where all of the dependancies and
# object files will be placed.
# Note: Currently set to <project>/build/obj directory and set relative to
# the dir which makefile is invoked.
BUILD_DIR = $(SELF_DIR)build
OBJ_DIR = $(BUILD_DIR)/obj

# Path to the root of source files, in this case root of the project to
# include ../src and ../lib dirs.
# Note: Consider relocating source files in lib to src, or build a
#       separate library.
SRC_DIR = src

TARGET ?= firmware
TARGETDIR ?= $(SELF_DIR)bin/

# ensure defined
USRSRC += ""

CSRC += $(call target_files,$(USRSRC),*.c)
CPPSRC += $(call target_files,$(USRSRC),*.cpp)

# Find all build.mk makefiles in each source directory in the src tree.
SRC_MAKEFILES := $(call rwildcard,$(SRC_DIR),build.mk)

# Put together a list of all the sub-directories inside $(SRC_DIR). This will be
# used in order to create the build directory structure.
SRC_DIRS := $(subst $(SRC_DIR)/,,$(sort $(dir $(wildcard $(SRC_DIR)/*/*/*))))


################################################################################
# Settings
################################################################################


################################################################################
# Inclusions
################################################################################

# Toolchains and platform specific commands.
include $(SELF_DIR)tools.mk

# Include all build.mk defines source files.
include $(SRC_MAKEFILES)


################################################################################
# Tool Flags
################################################################################

# Compiler flags
CCFLAGS =  -g -gdwarf-2 -Os -mcpu=cortex-m3 -mthumb 
CCFLAGS += -fsigned-char -fdata-sections -fno-move-loop-invariants
CCFLAGS += $(patsubst %,-I$(SRC_DIR)%,$(INCLUDE_DIRS)) -I.
CCFLAGS += -ffunction-sections -Wall -Wextra -fmessage-length=0

# Flag compiler error for [-Wdeprecated-declarations]
CCFLAGS += -Werror=deprecated-declarations

# Generate dependency files automatically.
CCFLAGS += -MMD -MP -MF $@.d

# Target specific defines
CCFLAGS += -DUSE_STDPERIPH_DRIVER
CCFLAGS += -DOS_USE_TRACE_ITM
CCFLAGS += -DHSE_VALUE=8000000
CCFLAGS += -DSTM32F10X_MD
CCFLAGS += -DTRACE
# CCFLAGS += -D__CORTEX_M3
# CCFLAGS += -D__CMSIS_RTOS

# C spefic flags
CFLAGS += -std=gnu11

# C++ specific flags
CPPFLAGS += -fno-rtti -fno-exceptions -std=gnu++11 -fabi-version=0 
CPPFLAGS += -fno-exceptions -fno-rtti -fno-use-cxa-atexit 
CPPFLAGS += -fno-threadsafe-statics 

# Linker flags
LDFLAGS += -T$(PROJECT_DIR)scripts/mem.ld
LDFLAGS += -T$(PROJECT_DIR)scripts/libs.ld
LDFLAGS += -T$(PROJECT_DIR)scripts/sections.ld -Xlinker
LDFLAGS += --gc-sections -Wl,-Map,$(TARGETDIR)$(TARGET).map
LDFLAGS += --specs=nano.specs -L"scripts"
LDFLAGS += -nostartfiles

# Assembler flags
ASFLAGS =  -g3 -gdwarf-2 -mcpu=cortex-m3 -mthumb 
ASFLAGS += -x assembler-with-cpp -fmessage-length=0

# Collect all object and dep files
ALLOBJ += $(addprefix $(OBJ_DIR), $(CSRC:.c=.o))
ALLOBJ += $(addprefix $(OBJ_DIR), $(CPPSRC:.cpp=.o))
ALLOBJ += $(addprefix $(OBJ_DIR), $(ASRC:.s=.o))

ALLDEPS += $(addprefix $(OBJ_DIR), $(CSRC:.c=.o.d))
ALLDEPS += $(addprefix $(OBJ_DIR), $(CPPSRC:.cpp=.o.d))
ALLDEPS += $(addprefix $(OBJ_DIR), $(ASRC:.s=.o.d))


################################################################################
# Targets
################################################################################

all: elf hex bin pdmacros size

elf: $(TARGETDIR)$(TARGET).elf

bin: $(TARGETDIR)$(TARGET).bin

hex: $(TARGETDIR)$(TARGET).hex

# Display size
size:
	@$(SIZE) $(TARGETDIR)$(TARGET).elf \
	 		 $(TARGETDIR)$(TARGET).hex \
	 		 --format=berkeley -d $<

pdmacros:
	@echo Saving PreDefMacros.txt...
	@echo | $(patsubst $@.d,$(OBJ_DIR)/$@.d,$(CC) $(CCFLAGS)) \
			-dM -E - > $(BUILD_DIR)/PreDefMacros.txt

# Create a hex file from ELF file
%.hex : %.elf
	@echo Building $(notdir $@)...
	@$(OBJCOPY) -O ihex $< $@

# Create a bin file from ELF file
%.bin : %.elf
	@echo Building $(notdir $@)...
	@$(OBJCOPY) -O binary $< $@

# Create an elf file
$(TARGETDIR)$(TARGET).elf : $(ALLOBJ)
	@echo Building $(notdir $@)...
	@$(CPP) $(CCFLAGS) $(ALLOBJ) --output $@ $(LDFLAGS)

clean:
	@echo Cleaning...
	@-$(RMDIR) $(call fixdir,$(TARGETDIR))
	@-$(RMDIR) $(call fixdir,$(OBJ_DIR))
	@-$(MKDIR) $(call fixdir,$(TARGETDIR))
	@-$(MKDIR) $(call fixdir,$(addprefix $(OBJ_DIR)/, $(SRC_DIRS)))


################################################################################
# Tool Invocations
################################################################################

# C compiler to build .o from .c in $(OBJ_DIR)
$(OBJ_DIR)%.o : $(SRC_DIR)%.c
	@echo Compiling $(notdir $<)...
	@$(CC) $(CCFLAGS) $(CFLAGS) -c -o $@ $<

# CPP compiler to build .o from .cpp in $(OBJ_DIR)
# Note: Calls standard $(CC) - gcc will invoke g++ if appropriate
$(OBJ_DIR)%.o : $(SRC_DIR)%.cpp
	@echo Compiling $(notdir $<)...
	@$(CPP) $(CCFLAGS) $(CPPFLAGS) -c -o $@ $<

# Assember to build .o from .s in $(OBJ_DIR)
$(OBJ_DIR)%.o : $(SRC_DIR)%.s
	@echo Assembling $(notdir $<)...
	@$(CC) $(ASFLAGS) -c -o $@ $<


.PHONY: all clean elf bin hex size pdmacros

.SECONDARY:

# Include auto generated dependency files
-include $(ALLDEPS)