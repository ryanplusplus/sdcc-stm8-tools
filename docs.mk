HARDWARE_MANUAL_URL := https://www.st.com/resource/en/reference_manual/cd00190271-stm8s-series-and-stm8af-series-8bit-microcontrollers-stmicroelectronics.pdf
DATASHEET_URL := https://www.st.com/resource/en/datasheet/$(DEVICE).pdf

hardware_manual:
	xdg-open $(HARDWARE_MANUAL_URL)

.PHONY: datasheet
datasheet:
	xdg-open $(DATASHEET_URL)
