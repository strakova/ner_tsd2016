include Makefile.builtem

all: $(call exe,tagger_lemmatizer)

$(call exe,tagger_lemmatizer): $(call obj,tagger_lemmatizer morphodita unicode utf8)
	$(call link_exe,$@,$^,$(call win_subsystem,console))

.PHONY: clean
clean:
	@$(call rm,.build $(call all_exe,tagger_lemmatizer))
