include Makefile.builtem

all: $(call exe,lemmatize)

$(call exe,lemmatize): $(call obj,lemmatize morphodita unicode utf8)
	$(call link_exe,$@,$^,$(call win_subsystem,console))

.PHONY: clean
clean:
	@$(call rm,.build $(call all_exe,lemmatize))
