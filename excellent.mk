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

%/include.mk: %/Makefile ./.include.lock
	@echo 'ifndef ${subst /,_,${@D}}_dir' > $@
	@echo '${subst /,_,${@D}}_dir := ${@D}/' >> $@
	@sed -E -e 's/[^[:space:]"]+(\.|\/)/$${${subst /,_,${@D}}_dir}&/g' \
				 -e 's/patsubst \$$\{${subst /,_,${@D}}_dir\}/patsubst /g' \
				 -e '/excellent.mk$$/ d' \
				 $^ >> $@
	@echo '' >> $@
# Replace variables with namespaced versions.
# We detect something which looks like a variable definition,
# replace that definition with a namespaced version,
# and then replace all references to that definition (e.g. something like ${VAR})
	@for VAR in `grep -E "^[A-Z_]+\s*:?=" $< | cut -d= -f1 | tr -d "[^:alnum:]"`; do \
				sed -i -E "s/^$$VAR/${subst /,_,${@D}}_&/" $@; \
				sed -i -E "s/\\\$$(\(|\{)($$VAR)(\)|\})/\$$\1${subst /,_,${@D}}_\2\3/" $@; \
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

# Ensure that all the include.mks have been generated by this Makefile
# If not, this .include.lock will be out of date
# (either it won't exist as it has been deleted by a parent .include.lock being made
# or the child .include.lock will be newer)
./.include.lock: $(shell find */ -name ".include.lock")
	@find . -name "include.mk" | xargs -r rm
	@find . -name ".include.lock" | xargs -r rm
	@touch $@

EXCELLENT := true
endif
