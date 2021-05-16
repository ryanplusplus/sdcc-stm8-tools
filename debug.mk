$(BUILD_DIR)/stm8-gdb:
	@mkdir -p $(dir $@)
	@-ln -s $(__sdcc_stm8_tools_binutils_path)/stm8-gdb $@

$(BUILD_DIR)/stm8-objdump:
	@mkdir -p $(dir $@)
	@-ln -s $(__sdcc_stm8_tools_binutils_path)/stm8-objdump $@

$(BUILD_DIR)/openocd:
	@mkdir -p $(dir $@)
	@-ln -s $(__sdcc_stm8_tools_openocd_path) $@

$(BUILD_DIR)/openocd.cfg: $(BUILD_DEPS)
	@cp $(OPENOCD_CFG) $@

$(BUILD_DIR)/$(TARGET).svd: $(SVD)
	@mkdir -p $(dir $@)
	@cp $(SVD) $@

.PHONY: debug-deps
debug-deps: \
	erase \
	$(BUILD_DIR)/$(TARGET)-debug.elf \
	$(BUILD_DIR)/stm8-gdb \
	$(BUILD_DIR)/stm8-objdump \
	$(BUILD_DIR)/openocd \
	$(BUILD_DIR)/openocd.cfg \
	$(BUILD_DIR)/$(TARGET).svd

.PHONY: debug
debug: debug-deps
	@echo "target extended-remote | $(BUILD_DIR)/openocd/bin/openocd -c \"gdb_port pipe\" -f $(BUILD_DIR)/openocd.cfg\nlayout asm\nlayout regs\nwinheight regs 12\nwinheight asm 50\nload\nbreak main\ncontinue" > $(BUILD_DIR)/.gdbinit
	@$(BUILD_DIR)/stm8-gdb $(BUILD_DIR)/$(TARGET)-debug.elf --tui -x $(BUILD_DIR)/.gdbinit
