################################################################################
# Name: tools.mk
################################################################################
# Desription: 	The definition of platform-dependant tools used in the other 
# 				makefiles. 
#
# Copyright (C) 2015 by Omid Manikhi. All rights reserved...
################################################################################

################################################################################
# Configuration
################################################################################
 
################################################################################
# Platform Independant Tools
################################################################################

# Define the compiler/tools prefix
GCC_PREFIX ?= $(TOOLCHAIN_DIR)arm-none-eabi-

# Define tools
CC = $(GCC_PREFIX)gcc
CPP = $(GCC_PREFIX)g++
AR = $(GCC_PREFIX)ar
OBJCOPY = $(GCC_PREFIX)objcopy
SIZE = $(GCC_PREFIX)size


################################################################################
# Platform Dependant Tools
################################################################################

ifeq ($(OS),Windows_NT)
	
	# Windows-Based Platform
    RM := del /q /f
    RMDIR := rd /s /q
    MKDIR := mkdir
    
    # Set the Toolchain directory.
    TOOLCHAIN_DIR := \
    "E:\\DevTools\\GNU Tools ARM Embedded\\4.9 2014q4\\bin\\"
	
	# return the directory of the specified file replacing slashes with 
	# backslashes.
	fixdir = $(subst /,\,$(dir $1))

    # CCFLAGS += -D WIN32
    ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
        # CCFLAGS += -D AMD64
    endif
    ifeq ($(PROCESSOR_ARCHITECTURE),x86)
        # CCFLAGS += -D IA32
    endif
else

	# Unix-Based Platform
    RM := rm -f
    RMDIR := rm -f -r
    MKDIR := mkdir -p

	# Set the Toolchain directory.
    TOOLCHAIN_DIR := /usr/local/gcc_arm/gcc-arm-none-eabi-4_9-2014q4/bin/
	
	# return the directory of the specified file. This really only makes sense
	# for Windows and is here for compatibility reasons with other platforms.
	fixdir = $(dir $1)

	# Find the exact kernel type.
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
        # CCFLAGS += -D LINUX
    endif
    ifeq ($(UNAME_S),Darwin)
        # CCFLAGS += -D OSX
    endif
    UNAME_P := $(shell uname -p)
    ifeq ($(UNAME_P),x86_64)
        # CCFLAGS += -D AMD64
    endif
    ifneq ($(filter %86,$(UNAME_P)),)
        # CCFLAGS += -D IA32
    endif
    ifneq ($(filter arm%,$(UNAME_P)),)
        # CCFLAGS += -D ARM
    endif
endif