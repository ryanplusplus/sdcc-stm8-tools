__sdcc_stm8_tools_setup_included := Y

__sdcc_stm8_tools_path := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

include $(__sdcc_stm8_tools_path)utils/utils.mk
