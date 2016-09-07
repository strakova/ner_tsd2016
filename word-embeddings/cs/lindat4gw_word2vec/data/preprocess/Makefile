include Makefile.builtem

all: $(call exe,preprocess)

$(call exe,preprocess): $(call obj,preprocess unicode uninorms utf8)
	$(call link_exe,$@,$^,$(call win_subsystem,console))

.PHONY: clean
clean:
	@$(call rm,.build $(call all_exe,preprocess))
