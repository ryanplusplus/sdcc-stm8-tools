worker_path := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
tools_path := $(worker_path)tools/$(shell uname)
toolchain_path := $(tools_path)/sdcc-$(TOOLCHAIN_VERSION)
stm8flash_path := $(tools_path)/stm8flash/bin
binutils_path := $(tools_path)/stm8-binutils-gdb/bin
openocd_path := $(tools_path)/openocd
bin_path := $(toolchain_path)/bin
lib_path := $(toolchain_path)/share/sdcc/lib/stm8

DEFINES += $(DEVICE_TYPE)

SRCS := $(SRC_FILES)

ifneq ($(SRC_DIRS),)
SRCS += $(shell find $(SRC_DIRS) -not -wholename $(MAIN) -and -name *.c -or -name *.s)
endif

LIB_SRCS := $(LIB_FILES)

ifneq ($(LIB_DIRS),)
LIB_SRCS += $(shell find $(LIB_DIRS) -name *.c -or -name *.s)
endif

OBJS := $(SRCS:%=$(BUILD_DIR)/%.rel)
DEPS := $(SRCS:%=$(BUILD_DIR)/%.d)
LIB_OBJS := $(LIB_SRCS:%=$(BUILD_DIR)/%.rel)
LIB_DEPS := $(LIB_SRCS:%=$(BUILD_DIR)/%.d)

DEBUG_OBJS := $(SRCS:%=$(BUILD_DIR)/%.debug.rel)
DEBUG_DEPS := $(SRCS:%=$(BUILD_DIR)/%.debug.d)
DEBUG_LIB_OBJS := $(LIB_SRCS:%=$(BUILD_DIR)/%.debug.rel)
DEBUG_LIB_DEPS := $(LIB_SRCS:%=$(BUILD_DIR)/%.debug.d)

INC_DIRS += $(worker_path)/lib/stm8/inc

ifneq ($(SRC_DIRS),)
INC_DIRS += $(shell find $(SRC_DIRS) -type d)
endif

ifneq ($(LIB_DIRS),)
INC_DIRS += $(shell find $(LIB_DIRS) -type d)
endif

INC_FLAGS := $(addprefix -I,$(INC_DIRS))
DEFINE_FLAGS := $(addprefix -D,$(DEFINES))

ASFLAGS += \
  -loff

CFLAGS += \
  -mstm8 \
  --debug \
  --Werror \
  --std-c99 \
  --disable-warning 126 \
  $(INC_FLAGS) \
  $(DEFINE_FLAGS) \
  --opt-code-size \

LDFLAGS += \
  --nostdlib \
  --lib-path $(lib_path) \
  -lstm8 \
  $(CFLAGS) \

CC := $(bin_path)/sdcc
AS := $(bin_path)/sdasstm8
LD := $(bin_path)/sdcc
AR := $(bin_path)/sdar

define fix_deps
	@sed -i '1s:^$1:$@:' $2
	@echo "" >> $2
	@grep -o ' [^ \:][^ \:]*' $2 | while read -r dep ; do echo "$$dep:\n" >> $2; done
endef

.PHONY: all
all: $(BUILD_DIR)/$(TARGET).hex

$(BUILD_DIR)/arm-none-eabi-gdb:
	@mkdir -p $(dir $@)
	@-ln -s $(binutils_path)/stm8-gdb $@

$(BUILD_DIR)/arm-none-eabi-objdump:
	@mkdir -p $(dir $@)
	@-ln -s $(binutils_path)/stm8-objdump $@

$(BUILD_DIR)/openocd:
	@mkdir -p $(dir $@)
	@-ln -s $(openocd_path) $@

$(BUILD_DIR)/openocd.cfg:
	@cp $(OPENOCD_CFG) $@

.PHONY: debug-deps
debug-deps: erase $(BUILD_DIR)/$(TARGET)-debug.elf $(BUILD_DIR)/arm-none-eabi-gdb $(BUILD_DIR)/arm-none-eabi-objdump $(BUILD_DIR)/openocd $(BUILD_DIR)/openocd.cfg

.PHONY: upload
upload: $(BUILD_DIR)/$(TARGET).hex
	@$(stm8flash_path)/stm8flash -c $(STLINK) -p $(DEVICE) -w $<

.PHONY: erase
erase:
	@mkdir -p $(BUILD_DIR)
	@echo "AA" | xxd -r -p > $(BUILD_DIR)/rop.bin
	@$(stm8flash_path)/stm8flash -c $(STLINK) -p $(DEVICE) -s opt -w $(BUILD_DIR)/rop.bin
	@$(stm8flash_path)/stm8flash -c $(STLINK) -p $(DEVICE) -u

TARGET_HEX_DEPS := $(MAIN) $(OBJS) $(BUILD_DIR)/$(TARGET).lib
$(BUILD_DIR)/$(TARGET).hex: $(TARGET_HEX_DEPS)
	@echo Linking $(notdir $@)...
	@mkdir -p $(dir $@)
	@$(LD) $(LDFLAGS) -MM --out-fmt-ihx $(TARGET_HEX_DEPS) -o $@.d
	@$(call fix_deps,[^:]*,$@.d)
	@$(LD) $(LDFLAGS) --out-fmt-ihx $(TARGET_HEX_DEPS) -o $@

TARGET_DEBUG_ELF_DEPS := $(MAIN) $(DEBUG_OBJS) $(BUILD_DIR)/$(TARGET)-debug.lib
$(BUILD_DIR)/$(TARGET)-debug.elf: $(TARGET_DEBUG_ELF_DEPS)
	@echo Linking $(notdir $@)...
	@mkdir -p $(dir $@)
	@$(LD) $(LDFLAGS) -MM --out-fmt-elf $(TARGET_DEBUG_ELF_DEPS) -o $@.d
	@$(call fix_deps,[^:]*,$@.d)
	@$(LD) $(LDFLAGS) --out-fmt-elf $(TARGET_DEBUG_ELF_DEPS) -o $@

$(BUILD_DIR)/$(TARGET).lib: $(LIB_OBJS)
	@echo Building $(notdir $@)...
	@mkdir -p $(dir $@)
	@$(AR) -rc $@ $(LIB_OBJS)

$(BUILD_DIR)/$(TARGET)-debug.lib: $(DEBUG_LIB_OBJS)
	@echo Building $(notdir $@)...
	@mkdir -p $(dir $@)
	@$(AR) -rc $@ $(DEBUG_LIB_OBJS)

$(BUILD_DIR)/%.s.rel: %.s
	@echo Assembling $(notdir $@)...
	@mkdir -p $(dir $@)
	@$(AS) $(ASFLAGS) $@ $<

$(BUILD_DIR)/%.s.debug.rel: %.s
	@echo Assembling $(notdir $@)...
	@mkdir -p $(dir $@)
	@$(AS) $(ASFLAGS) $@ $<

$(BUILD_DIR)/%.c.rel: %.c
	@echo Compiling $(notdir $@)...
	@mkdir -p $(dir $@)
	@$(CC) $(CFLAGS) -MM -c $< -o $(@:%.rel=%.d)
	@$(call fix_deps,$(notdir $(@:%.c.rel=%.rel)),$(@:%.rel=%.d))
	@$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.c.debug.rel: %.c
	@echo Compiling $(notdir $@)...
	@mkdir -p $(dir $@)
	@$(CC) $(CFLAGS) -MM -c $< -o $(@:%.rel=%.d)
	@$(call fix_deps,$(notdir $(@:%.c.debug.rel=%.rel)),$(@:%.rel=%.d))
	@$(CC) $(CFLAGS) -c $< --out-fmt-elf -o $@

.PHONY: clean
clean:
	@echo Cleaning...
	@$(RM) -rf $(BUILD_DIR)

-include $(DEPS) $(DEBUG_DEPS) $(LIB_DEPS) $(DEBUG_LIB_DEPS)
-include $(BUILD_DIR)/$(TARGET).hex.d
-include $(BUILD_DIR)/$(TARGET)-debug.elf.d
