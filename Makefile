#!/usr/bin/make -f

MAKEFLAGS += --silent

EXT ?= otp
PREFIX ?= /usr/local
LIBDIR ?= ${PREFIX}/lib
MANDIR ?= ${PREFIX}/share/man
SYSTEM_EXTENSION_DIR ?= ${LIBDIR}/password-store/extensions
BASHCOMPDIR ?= ${PREFIX}/share/bash-completion/completions
ZSHCOMPDIR ?= ${PREFIX}/share/zsh/site-functions

all:
	@echo "pass-${EXT} is a shell script and does not need compilation, it can be simply executed."
	@echo "To install it try \"make install\" instead."

install_share:
	install -Dm0644 share/bash-completion/completions/pass-${EXT} "${DESTDIR}${BASHCOMPDIR}/pass-${EXT}"
	install -Dm0644 share/zsh/site-functions/_pass-${EXT} "${DESTDIR}${ZSHCOMPDIR}/_pass-${EXT}"
ifneq (,$(wildcard ./share/man/man1/pass-${EXT}.1))
	install -Dm0644 share/man/man1/pass-${EXT}.1 "${DESTDIR}${MANDIR}/man1/pass-${EXT}.1"
endif

install: install_share
	install -Dm0755 ${EXT}.bash "${DESTDIR}${SYSTEM_EXTENSION_DIR}/${EXT}.bash"
	@echo "pass-${EXT} is installed successfully"

COVERAGE ?= true
TMP ?= /tmp/tests/pass-${EXT}
PASS_TEST_OPTS ?= --verbose --immediate --root=/tmp/sharness
T = $(sort $(wildcard tests/*.sh))
export COVERAGE TMP
tests: $(T)
	tests/results
$(T):
	$@ $(PASS_TEST_OPTS)

lint:
	shellcheck --shell=bash ${EXT}.bash tests/commons tests/results tests/xclip tests/fake-* tests/*.sh

docs:
	pandoc -t man -s -o share/man/man1/pass-${EXT}.1 share/man/man1/pass-${EXT}.md

check: lint tests docs

.PHONY: install tests $(T) lint check
