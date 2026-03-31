SHELL     := /bin/bash
LATEX     := lualatex
BIBER     := biber
FLAGS     := -interaction=nonstopmode -halt-on-error
LOGDIR    := logs
PLAIN_DIR := plain
SPIN      := ./mk/compile.sh

# TEXINPUTS for plain CV — finds settings.sty inside plain/
TEX_PLAIN := TEXINPUTS=./$(PLAIN_DIR):

# Set LOGS=1 to keep log files after compilation:  make LOGS=1 [target]
# Shorthand:  make logs
LOGS ?= 0

# ----- Output PDFs ---------------------------------------------------------
DARK_PDF  := cv_dark.pdf
LIGHT_PDF := cv_light.pdf
PLAIN_EN  := cv_plain_en.pdf
PLAIN_ES  := cv_plain_es.pdf
PLAIN_FR  := cv_plain_fr.pdf

COOL_PDFS  := $(DARK_PDF) $(LIGHT_PDF)
PLAIN_PDFS := $(PLAIN_EN) $(PLAIN_ES) $(PLAIN_FR)
ALL_PDFS   := $(COOL_PDFS) $(PLAIN_PDFS)

PLAIN_DEPS := $(PLAIN_DIR)/cv_plain.tex $(PLAIN_DIR)/settings.sty \
              $(wildcard $(PLAIN_DIR)/data/*.tex) \
              $(wildcard $(PLAIN_DIR)/data/*.bib)

# ----- Cleanup helpers -----------------------------------------------------
# Aux/ancillary files per jobname
_aux = $(1).aux $(1).out $(1).bbl $(1).bcf $(1).blg $(1).run.xml $(1).listing

# Conditionally wipe log files (skipped when LOGS=1)
define _clean_logs
	@[ "$(LOGS)" = "1" ] || rm -f $(1).log $(LOGDIR)/$(2)
endef

# ----- Phony targets -------------------------------------------------------
.PHONY: all dark light plain plain-en plain-es plain-fr logs clean

all: $(ALL_PDFS)
	@rm -f $(call _aux,cv_dark) $(call _aux,cv_light) \
	       $(call _aux,cv_plain_en) $(call _aux,cv_plain_es) $(call _aux,cv_plain_fr)
	@[ "$(LOGS)" = "1" ] || { rm -f *.log; rm -rf $(LOGDIR); }
	@printf "\n  \033[32mAll CVs compiled successfully.\033[0m\n\n"

dark: $(DARK_PDF)
	@rm -f $(call _aux,cv_dark)
	$(call _clean_logs,cv_dark,darkmode.log)
	@[ "$(LOGS)" = "1" ] || rm -rf $(LOGDIR)

light: $(LIGHT_PDF)
	@rm -f $(call _aux,cv_light)
	$(call _clean_logs,cv_light,light.log)
	@[ "$(LOGS)" = "1" ] || rm -rf $(LOGDIR)

plain: plain-en plain-es plain-fr

plain-en: $(PLAIN_EN)
	@rm -f $(call _aux,cv_plain_en)
	$(call _clean_logs,cv_plain_en,plain_en.log)
	@[ "$(LOGS)" = "1" ] || rm -rf $(LOGDIR)

plain-es: $(PLAIN_ES)
	@rm -f $(call _aux,cv_plain_es)
	$(call _clean_logs,cv_plain_es,plain_es.log)
	@[ "$(LOGS)" = "1" ] || rm -rf $(LOGDIR)

plain-fr: $(PLAIN_FR)
	@rm -f $(call _aux,cv_plain_fr)
	$(call _clean_logs,cv_plain_fr,plain_fr.log)
	@[ "$(LOGS)" = "1" ] || rm -rf $(LOGDIR)

# Keep logs — shorthand for: make LOGS=1 all
logs:
	@$(MAKE) LOGS=1 all

# ----- Dark mode -----------------------------------------------------------
$(DARK_PDF): darkmode.tex
	@mkdir -p $(LOGDIR)
	@$(SPIN) "Dark mode CV" "$(LOGDIR)/darkmode.log" \
	  "$(LATEX) $(FLAGS) -jobname=cv_dark darkmode.tex" \
	  "cv_dark.log"

# ----- Light mode ----------------------------------------------------------
$(LIGHT_PDF): light.tex
	@mkdir -p $(LOGDIR)
	@$(SPIN) "Light mode CV" "$(LOGDIR)/light.log" \
	  "$(LATEX) $(FLAGS) -jobname=cv_light light.tex" \
	  "cv_light.log"

# ----- Plain CVs (lualatex → biber → lualatex) ----------------------------
$(PLAIN_EN): $(PLAIN_DEPS)
	@mkdir -p $(LOGDIR)
	@$(SPIN) "Plain CV [English]" "$(LOGDIR)/plain_en.log" \
	  "$(TEX_PLAIN) $(LATEX) $(FLAGS) -jobname=cv_plain_en '\def\cvlang{en}\input{$(PLAIN_DIR)/cv_plain}' \
	   && $(BIBER) cv_plain_en \
	   && $(TEX_PLAIN) $(LATEX) $(FLAGS) -jobname=cv_plain_en '\def\cvlang{en}\input{$(PLAIN_DIR)/cv_plain}'" \
	  "cv_plain_en.log"

$(PLAIN_ES): $(PLAIN_DEPS)
	@mkdir -p $(LOGDIR)
	@$(SPIN) "Plain CV [Español]" "$(LOGDIR)/plain_es.log" \
	  "$(TEX_PLAIN) $(LATEX) $(FLAGS) -jobname=cv_plain_es '\def\cvlang{es}\input{$(PLAIN_DIR)/cv_plain}' \
	   && $(BIBER) cv_plain_es \
	   && $(TEX_PLAIN) $(LATEX) $(FLAGS) -jobname=cv_plain_es '\def\cvlang{es}\input{$(PLAIN_DIR)/cv_plain}'" \
	  "cv_plain_es.log"

$(PLAIN_FR): $(PLAIN_DEPS)
	@mkdir -p $(LOGDIR)
	@$(SPIN) "Plain CV [Français]" "$(LOGDIR)/plain_fr.log" \
	  "$(TEX_PLAIN) $(LATEX) $(FLAGS) -jobname=cv_plain_fr '\def\cvlang{fr}\input{$(PLAIN_DIR)/cv_plain}' \
	   && $(BIBER) cv_plain_fr \
	   && $(TEX_PLAIN) $(LATEX) $(FLAGS) -jobname=cv_plain_fr '\def\cvlang{fr}\input{$(PLAIN_DIR)/cv_plain}'" \
	  "cv_plain_fr.log"

# ----- Clean (removes everything except PDF) ---------------------------
clean:
	@printf "  Removing all build artefacts... "
	@rm -f *.aux *.log *.out *.bbl *.bcf *.blg *.run.xml *.listing
	@rm -rf $(LOGDIR)
	@printf "\033[32m✓\033[0m\n"
