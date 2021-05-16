include $(dir $(realpath $(lastword $(MAKEFILE_LIST))))paths.mk

include $(__sdcc_stm8_tools_path)sdcc.mk
include $(__sdcc_stm8_tools_path)docs.mk
include $(__sdcc_stm8_tools_path)debug.mk
include $(__sdcc_stm8_tools_path)stm8flash.mk
