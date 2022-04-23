include $(dir $(realpath $(lastword $(MAKEFILE_LIST))))paths.mk

ASFLAGS := \
  -loff

CPPFLAGS := \
  -mstm8 \
  --nolospre \
  --debug \
  --Werror \
  --std-c11 \
  --disable-warning 126 \
  --disable-warning 110 \
  --opt-code-size \

CFLAGS := \

LDFLAGS := \
  --nostdlib \
  --lib-path $(__sdcc_stm8_tools_lib_path) \

DEFINES += \
  $(DEVICE_TYPE)

ifeq ($(TOOLCHAIN_VERSION),4.2.0)
CFLAGS += --no-peep --peep-file $(call current_path)patch/4.2.0-patched-peeph.def
endif
