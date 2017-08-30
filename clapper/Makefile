# The TARGET variable determines what target system the application is
# compiled for. It either refers to an XN file in the source directories
# or a valid argument for the --target option when compiling
ifeq ($(CONFIG),ETHERNET)
TARGET = MIC-ARRAY-1V0
else ifeq ($(CONFIG),SMART_MIC_4TILE)
TARGET = SMART-MIC-4-TILE-1V0
endif

# The APP_NAME variable determines the name of the final .xe file. It should
# not include the .xe postfix. If left blank the name will default to
# the project name
APP_NAME = clapper

# The USED_MODULES variable lists other module used by the application.
USED_MODULES = lib_i2c(>=4.0.0) lib_i2s(>=2.2.0) lib_mic_array(>=3.0.0) lib_mic_array_board_support(>=2.1.0)

# The flags passed to xcc when building the application
# You can also set the following to override flags for a particular language:
# XCC_XC_FLAGS, XCC_C_FLAGS, XCC_ASM_FLAGS, XCC_CPP_FLAGS
# If the variable XCC_MAP_FLAGS is set it overrides the flags passed to
# xcc for the final link (mapping) stage.
SHARED_FLAGS = -O2 -g -DDEBUG_PRINT_ENABLE=1 -fxscope

XCC_FLAGS_ETHERNET = $(SHARED_FLAGS) -DETHERNET=1
INCLUDE_ONLY_IN_ETHERNET =
XCC_FLAGS_SMART_MIC_4TILE = $(SHARED_FLAGS) -DSMART_MIC_4TILE=1
INCLUDE_ONLY_IN_SMART_MIC_4TILE =

# The XCORE_ARM_PROJECT variable, if set to 1, configures this
# project to create both xCORE and ARM binaries.
XCORE_ARM_PROJECT = 0

# The VERBOSE variable, if set to 1, enables verbose output from the make system.
VERBOSE = 0

XMOS_MAKE_PATH ?= ../..
-include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
