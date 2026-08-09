SHELL     := /bin/bash
LATEX     := lualatex
FLAGS     := -interaction=nonstopmode -halt-on-error
LOGDIR    := logs
PLAIN_DIR := plain
GEN_DIR   := $(PLAIN_DIR)/gen
GEN       := /usr/bin/perl mk/gen.pl
SPIN      := ./mk/compile.sh

# TEXINPUTS for plain CV — finds settings.sty inside plain/
TEX_PLAIN := TEXINPUTS=./$(PLAIN_DIR):

# Set LOGS=1 to keep log files after compilation:  make LOGS=1 [target]
# Shorthand:  make logs
LOGS ?= 0

# ----- Languages -----------------------------------------------------------
LANGS := en es fr
LANGNAME_en := English
LANGNAME_es := Español
LANGNAME_fr := Français

# ----- Output PDFs ---------------------------------------------------------
DARK_PDF   := cv_dark.pdf
LIGHT_PDF  := cv_light.pdf
PLAIN_PDFS := $(LANGS:%=cv_plain_%.pdf)

COOL_PDFS := $(DARK_PDF) $(LIGHT_PDF)
ALL_PDFS  := $(COOL_PDFS) $(PLAIN_PDFS)

JSON_DATA  := $(wildcard $(PLAIN_DIR)/data/*.json)
PLAIN_DEPS := $(PLAIN_DIR)/cv_plain.tex $(PLAIN_DIR)/settings.sty

# ----- Cleanup helpers -----------------------------------------------------
# Aux/ancillary files per jobname
_aux = $(1).aux $(1).out $(1).listing

# Conditionally wipe log files (skipped when LOGS=1)
define _clean_logs
	@[ "$(LOGS)" = "1" ] || rm -f $(1).log $(LOGDIR)/$(2)
endef

# ----- Phony targets -------------------------------------------------------
.PHONY: all dark light plain logs clean $(LANGS:%=plain-%)

# keep generated bodies: they drive the per-language rebuild logic
.SECONDARY: $(LANGS:%=$(GEN_DIR)/body_%.tex)

all: $(ALL_PDFS)
	@rm -f $(foreach j,cv_dark cv_light $(LANGS:%=cv_plain_%),$(call _aux,$(j)))
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

plain: $(LANGS:%=plain-%)

$(LANGS:%=plain-%): plain-%: cv_plain_%.pdf
	@rm -f $(call _aux,cv_plain_$*)
	$(call _clean_logs,cv_plain_$*,plain_$*.log)
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

# ----- Plain CVs -----------------------------------------------------------
# gen.pl only rewrites body_<lang>.tex when its content changed, so a JSON
# edit touching one language recompiles only that language's PDF.
$(GEN_DIR)/body_%.tex: $(JSON_DATA) mk/gen.pl
	@$(GEN) $*

cv_plain_%.pdf: $(GEN_DIR)/body_%.tex $(PLAIN_DEPS)
	@mkdir -p $(LOGDIR)
	@$(SPIN) "Plain CV [$(LANGNAME_$*)]" "$(LOGDIR)/plain_$*.log" \
	  "$(TEX_PLAIN) $(LATEX) $(FLAGS) -jobname=cv_plain_$* '\def\cvlang{$*}\input{$(PLAIN_DIR)/cv_plain}'" \
	  "cv_plain_$*.log"

# ----- Clean (removes everything except PDF) -------------------------------
clean:
	@rm -f *.aux *.log *.out *.bbl *.blg *.listing
	@rm -rf $(LOGDIR) $(GEN_DIR)
	@printf "\033[32m✓\033[0m\n"
