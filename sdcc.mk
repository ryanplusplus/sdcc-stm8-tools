CC := $(__sdcc_stm8_tools_bin_path)/sdcc
AS := $(__sdcc_stm8_tools_bin_path)/sdasstm8
LD := $(__sdcc_stm8_tools_bin_path)/sdcc
AR := $(__sdcc_stm8_tools_bin_path)/sdar

SRCS := $(SRC_FILES)

ifneq ($(SRC_DIRS),)
SRCS += $(shell find $(SRC_DIRS) -maxdepth 1 -name *.cpp -or -name *.c -or -name *.s)
endif

SRCS := $(subst $(MAIN),,$(SRCS))

SRCS := $(sort $(SRCS))
OBJS := $(SRCS:%=$(BUILD_DIR)/%.rel)
DEPS := $(SRCS:%=$(BUILD_DIR)/%.d)

DEBUG_OBJS := $(SRCS:%=$(BUILD_DIR)/%.debug.rel)
DEBUG_DEPS := $(SRCS:%=$(BUILD_DIR)/%.debug.d)

DEPS += $(DEBUG_DEPS)

INC_DIRS += $(SRC_DIRS)
INC_DIRS += $(__sdcc_stm8_tools_path)lib/stm8/inc
INC_FLAGS := $(addprefix -I,$(INC_DIRS) $(SYS_INC_DIRS))

CPPFLAGS := \
  $(INC_FLAGS) \
  $(CPPFLAGS) \
  $(addprefix -D,$(DEFINES)) \

DEBUG_LIBS_DEPS := \
  $(foreach _lib,$(LIBS),$(BUILD_DIR)/$(_lib)-debug.lib) \

DEBUG_LDLIBS := \
  $(DEBUG_LIBS_DEPS) \
  $(LDLIBS) \
  -lstm8 \

LIBS_DEPS := \
  $(foreach _lib,$(LIBS),$(BUILD_DIR)/$(_lib).lib) \

LDLIBS := \
  $(LIBS_DEPS) \
  $(LDLIBS) \
  -lstm8 \

define fix_deps
	@sed -i '1s:^$1:$@:' $2
	@echo "" >> $2
	@grep -o ' [^ \:][^ \:]*' $2 | while read -r dep ; do echo "$$dep:\n" >> $2; done
endef

# $1 filename
# $2 flags to capture
define capture_flags
$(shell mkdir -p $(dir $(1)))
$(shell echo $(foreach flag,$(2),$(flag) $($(flag))) > $(1).next)
$(shell if cmp -s $(1).next $(1); then rm $(1).next; else mv $(1).next $(1); fi)
endef

# $1 filename
# $2 ASFLAGS
# $3 CPPFLAGS
# $4 CFLAGS
# $5 build deps
define generate_build_rule

ifeq ($(suffix $(1)),.s)
$$(BUILD_DIR)/$(1).rel: $(1) $(5) $(lastword $(MAKEFILE_LIST))
	@echo Assembling $$(notdir $$@)...
	@mkdir -p $$(dir $$@)
	@$$(AS) $(2) $$@ $$<

$$(BUILD_DIR)/$(1).debug.rel: $(1) $(5) $(lastword $(MAKEFILE_LIST))
	@echo Assembling $$(notdir $$@)...
	@mkdir -p $$(dir $$@)
	@$$(AS) $(2) $$@ $$<
endif

ifeq ($(suffix $(1)),.c)
$$(BUILD_DIR)/$(1).rel: $(1) $(5) $(lastword $(MAKEFILE_LIST))
	@echo Compiling $$(notdir $$@)...
	@mkdir -p $$(dir $$@)
	@$$(CC) $(3) $(4) -MM -c $$< -o $$(@:%.rel=%.d)
	@$$(call fix_deps,$$(notdir $$(@:%.c.rel=%.rel)),$$(@:%.rel=%.d))
	@$$(CC) $(3) $(4) -c $$< -o $$@

$$(BUILD_DIR)/$(1).debug.rel: $(1) $(5) $(lastword $(MAKEFILE_LIST))
	@echo Compiling $$(notdir $$@)...
	@mkdir -p $$(dir $$@)
	@$$(CC) $(3) $(4) -MM -c $$< -o $$(@:%.rel=%.d)
	@$$(call fix_deps,$$(notdir $$(@:%.c.debug.rel=%.rel)),$$(@:%.rel=%.d))
	@$$(CC) $(3) $(4) -c $$< --out-fmt-elf -o $$@
endif

endef

# $1 lib name
define generate_lib

$(1)_INC_DIRS += $$($(1)_SRC_DIRS)
$(1)_INC_DIRS += $(__sdcc_stm8_tools_path)lib/stm8/inc
$(1)_INC_FLAGS := $$(addprefix -I,$$($(1)_INC_DIRS) $$($(1)_SYS_INC_DIRS))

$(1)_CPPFLAGS := \
  $$($(1)_INC_FLAGS) \
  $$($(1)_CPPFLAGS) \
  $$(addprefix -D,$$($(1)_DEFINES)) \

$(1)_LIB_SRCS := $$($(1)_SRC_FILES)

ifneq ($$($(1)_SRC_DIRS),)
$(1)_LIB_SRCS += $$(shell find $$($(1)_SRC_DIRS) -maxdepth 1 -name *.cpp -or -name *.c -or -name *.s)
endif

$(1)_LIB_SRCS := $$(sort $$($(1)_LIB_SRCS))
$(1)_LIB_OBJS := $$($(1)_LIB_SRCS:%=$$(BUILD_DIR)/%.rel)
$(1)_LIB_DEPS := $$($(1)_LIB_SRCS:%=$$(BUILD_DIR)/%.d)

$(1)_DEBUG_LIB_OBJS := $$($(1)_LIB_SRCS:%=$$(BUILD_DIR)/%.debug.rel)
$(1)_DEBUG_LIB_DEPS := $$($(1)_LIB_SRCS:%=$$(BUILD_DIR)/%.debug.d)

DEPS := $(DEPS) $$($(1)_LIB_DEPS) $$($(1)_DEBUG_LIB_DEPS)

$$(BUILD_DIR)/$(1).lib: $$($1_LIB_OBJS)
	@echo Building $$(notdir $$@)...
	@mkdir -p $$(dir $$@)
	@$$(AR) rcs $$@ $$^

$$(BUILD_DIR)/$(1)-debug.lib: $$($1_DEBUG_LIB_OBJS)
	@echo Building $$(notdir $$@)...
	@mkdir -p $$(dir $$@)
	@$$(AR) -rc $$@ $$^

unused := $$(call capture_flags,$$(BUILD_DIR)/lib_$(1).build_flags,__sdcc_stm8_tools_bin_path $(1)_ASFLAGS $(1)_CPPFLAGS $(1)_CFLAGS $(1)_CXXFLAGS)

unused := $$(foreach _src,$$($(1)_LIB_SRCS),$$(eval $$(call generate_build_rule,$$(_src),$$($(1)_ASFLAGS),$$($(1)_CPPFLAGS),$$($(1)_CFLAGS),$$(BUILD_DIR)/lib_$(1).build_flags)))

endef

.PHONY: all
all: $(BUILD_DIR)/$(TARGET).hex
	@$(__sdcc_stm8_tools_path)size.sh $(BUILD_DIR)/$(TARGET).map

$(foreach _lib,$(LIBS),$(eval $(call generate_lib,$(_lib))))

unused := $(call capture_flags,$(BUILD_DIR)/hex_link_flags,__sdcc_stm8_tools_bin_path CPPFLAGS LDFLAGS TARGET_HEX_DEPS LDLIBS)

TARGET_HEX_DEPS := $(MAIN) $(OBJS) $(LIBS_DEPS)
$(BUILD_DIR)/$(TARGET).hex: $(TARGET_HEX_DEPS) $(BUILD_DEPS) $(BUILD_DIR)/hex_link_flags
	@echo Linking $(notdir $@)...
	@mkdir -p $(dir $@)
	@$(LD) $(CPPFLAGS) $(LDFLAGS) -MM --out-fmt-ihx $(TARGET_HEX_DEPS) -o $@.d $(LDLIBS)
	@$(call fix_deps,[^:]*,$@.d)
	@$(LD) $(CPPFLAGS) $(LDFLAGS) --out-fmt-ihx $(TARGET_HEX_DEPS) -o $@ $(LDLIBS)

unused := $(call capture_flags,$(BUILD_DIR)/debug_elf_link_flags,__sdcc_stm8_tools_bin_path CPPFLAGS LDFLAGS TARGET_DEBUG_ELF_DEPS DEBUG_LDLIBS)

TARGET_DEBUG_ELF_DEPS := $(MAIN) $(DEBUG_OBJS) $(DEBUG_LIBS_DEPS)
$(BUILD_DIR)/$(TARGET)-debug.elf: $(TARGET_DEBUG_ELF_DEPS) $(BUILD_DEPS) $(BUILD_DIR)/debug_elf_link_flags
	@echo Linking $(notdir $@)...
	@mkdir -p $(dir $@)
	@$(LD) $(CPPFLAGS) $(LDFLAGS) -MM --out-fmt-elf $(TARGET_DEBUG_ELF_DEPS) -o $@.d $(DEBUG_LDLIBS)
	@$(call fix_deps,[^:]*,$@.d)
	@$(LD) $(CPPFLAGS) $(LDFLAGS) --out-fmt-elf $(TARGET_DEBUG_ELF_DEPS) -o $@ $(DEBUG_LDLIBS)

unused := $(call capture_flags,$(BUILD_DIR)/build_flags,__sdcc_stm8_tools_bin_path ASFLAGS CPPFLAGS CFLAGS CXXFLAGS)

unused := $(foreach _src,$(SRCS),$(eval $(call generate_build_rule,$(_src),$(ASFLAGS),$(CPPFLAGS),$(CFLAGS),$(BUILD_DIR)/build_flags)))

.PHONY: clean
clean:
	@echo Cleaning...
	@rm -rf $(BUILD_DIR)

-include $(DEPS)
-include $(BUILD_DIR)/$(TARGET).hex.d
-include $(BUILD_DIR)/$(TARGET)-debug.elf.d
