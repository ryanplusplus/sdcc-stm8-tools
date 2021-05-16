ifndef $(__sdcc_stm8_tools_path_mk_included)

__sdcc_stm8_tools_path := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
__sdcc_stm8_tools_tools_path := $(__sdcc_stm8_tools_path)tools/$(shell uname)
__sdcc_stm8_tools_toolchain_path := $(__sdcc_stm8_tools_tools_path)sdcc-$(TOOLCHAIN_VERSION)
__sdcc_stm8_tools_stm8flash_path := $(__sdcc_stm8_tools_tools_path)stm8flash/bin
__sdcc_stm8_tools_binutils_path := $(__sdcc_stm8_tools_tools_path)stm8-binutils-gdb/bin
__sdcc_stm8_tools_openocd_path := $(__sdcc_stm8_tools_tools_path)openocd
__sdcc_stm8_tools_bin_path := $(__sdcc_stm8_tools_toolchain_path)/bin
__sdcc_stm8_tools_lib_path := $(__sdcc_stm8_tools_toolchain_path)/share/sdcc/lib/stm8

__sdcc_stm8_tools_path_mk_included := 1

endif
