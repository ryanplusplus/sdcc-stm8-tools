$(BUILD_DIR)/$(TARGET).svd: $(SVD)
	@mkdir -p $(dir $@)
	@cp $(SVD) $@
