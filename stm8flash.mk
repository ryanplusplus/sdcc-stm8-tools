.PHONY: upload
upload: $(BUILD_DIR)/$(TARGET).hex
	@$(__sdcc_stm8_tools_stm8flash_path)/stm8flash -c $(STLINK) -p $(DEVICE) -w $<

.PHONY: erase
erase:
	@mkdir -p $(BUILD_DIR)
	@echo "AA" | xxd -r -p > $(BUILD_DIR)/rop.bin
	@$(__sdcc_stm8_tools_stm8flash_path)/stm8flash -c $(STLINK) -p $(DEVICE) -s opt -w $(BUILD_DIR)/rop.bin
	@$(__sdcc_stm8_tools_stm8flash_path)/stm8flash -c $(STLINK) -p $(DEVICE) -u
