TARGET := target_Name
BUILD_DIR := ./build
TOOLS_DIR := path/to/tools

DEVICE := stm8s103f3
DEVICE_TYPE := STM8S103
STLINK := stlinkv2
OPENOCD_CFG := $(TOOLS_DIR)/openocd/stm8s103.cfg
TOOLCHAIN_VERSION := 4.0.0

MAIN := path/to/main.c

SRC_FILES := \
  path/to/src \

SRC_DIRS := \

LIB_FILES := \

LIB_DIRS := \

INC_DIRS := \

.PHONY: default
default: size

include $(TOOLS_DIR)/makefile-worker.mk
