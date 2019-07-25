ifndef EXCELLENT
# excellent.mk – an excellent way of recursing makefiles non-recursively
#
# Usage: include excellent.mk and then request `include.mk` from subdirectories
# e.g.
# 	include excellent.mk
# 	include subdir/include.mk
# `subdir/Makefile` will be included and its targets made available
# with relative names. Variables defined in the Makefile will be namespaced.
# Any targets declared .PHONY across multiple files will work as intended.
#
# Defines a named target `clean_include` just for deleting include.mks.
#
# Rules:
# 1. Strictly downwards including only. Don't include ../sibling/include.mk.
# 2. Don't add steps to common named targets (e.g. all), only prerequisites.
# 3. Clean includes before running make in subdirectories
# 	(e.g. running `make` then `make -C subdir` won't work)

%/include.mk: %/Makefile
	@echo 'ifndef ${subst /,_,${@D}}_dir' > $@
	@echo '${subst /,_,${@D}}_dir := ${@D}/' >> $@
	@sed -E -e 's/\S+(\.|\/)/$${${subst /,_,${@D}}_dir}&/g' \
				 -e 's/patsubst \$$\{${subst /,_,${@D}}_dir\}/patsubst /g' \
				 -e '/excellent.mk$$/ d' \
				 $^ >> $@
	@echo '' >> $@
	@for VAR in `grep -E "[A-Z]+\s*:?=" $< | cut -d= -f1 | tr -d "[^:alnum:]"`; do \
				sed -i -E "s/$$VAR/${subst /,_,${@D}}_&/" $@; \
				done
	@for PHONY in `grep .PHONY: $< | cut -f2 -d:`; do \
				sed -i -E "s/^$${PHONY}:/$${PHONY}: $${PHONY}_${subst /,_,${@D}}\n$${PHONY}_${subst /,_,${@D}}:/" $@; \
				echo ".PHONY: $${PHONY}_${subst /,_,${@D}}" >> $@; \
				done
	@(grep --quiet ^all_ $@ && echo '${@D}: all_${subst /,_,${@D}}' >> $@) || true
	@echo 'delete_${subst /,_,${@D}}:' >> $@
	@echo '	rm $@' >> $@
	@echo 'clean_include: delete_${subst /,_,${@D}}' >> $@
	@echo 'endif' >> $@

EXCELLENT := true
endif
