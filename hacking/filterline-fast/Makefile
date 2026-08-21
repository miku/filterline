SHELL = /bin/bash
TARGETS = filterline-fast

# IN_CAP/OUT_CAP are tunable; anything >= 64K is equivalent on a warm cache,
# larger only helps cold reads via readahead. See notes/2026-08-21-perf.md.
filterline-fast: filterline.c
	cc -Wall -Wextra -O3 -o filterline-fast filterline.c

.PHONY: sanitize
sanitize: filterline.c
	cc -Wall -Wextra -O1 -g -fsanitize=address,undefined -o filterline-fast-san filterline.c

.PHONY: fmt
fmt:
	clang-format -i -style="{BasedOnStyle: WebKit, IndentWidth: 4}" filterline.c

.PHONY: clean
clean:
	rm -f filterline-fast filterline-fast-san
	rm -rf filterline-fast-san.dSYM

# Differential test against the released implementation. Requires ../../filterline.
.PHONY: check
check: $(TARGETS)
	@$(MAKE) -C ../.. filterline >/dev/null
	@for flag in "" "-v"; do \
		if ../../filterline $$flag ../../fixtures/L ../../fixtures/F \
			| cmp -s - <(./filterline-fast $$flag ../../fixtures/L ../../fixtures/F); then \
			echo "ok   fixtures $${flag:-keep}"; \
		else \
			echo "FAIL fixtures $${flag:-keep}"; exit 1; \
		fi; \
	done
	@echo "note: fixtures are too small to catch buffer-boundary bugs;"
	@echo "      diff against a multi-GB file before trusting a change."
