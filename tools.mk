ifndef __sdcc_stm8_tools_setup_included
$(error setup.mk must be included before tools.mk)
endif

include $(__sdcc_stm8_tools_path)paths.mk

include $(__sdcc_stm8_tools_path)sdcc.mk
include $(__sdcc_stm8_tools_path)docs.mk
include $(__sdcc_stm8_tools_path)debug.mk
include $(__sdcc_stm8_tools_path)stm8flash.mk
