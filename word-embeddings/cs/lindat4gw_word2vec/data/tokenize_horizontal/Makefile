include Makefile.builtem

all: $(call exe,tokenize_horizontal)

$(call exe,tokenize_horizontal): $(call obj,tokenize_horizontal morphodita)
	$(call link_exe,$@,$^,$(call win_subsystem,console))

.PHONY: clean
clean:
	@$(call rm,.build $(call all_exe,tokenize_horizontal))
