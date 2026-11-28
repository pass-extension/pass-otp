#!/usr/bin/make -f

MAKEFLAGS += --silent

EXT ?= otp
PREFIX ?= /usr/local
LIBDIR ?= ${PREFIX}/lib
MANDIR ?= ${PREFIX}/share/man
SYSTEM_EXTENSION_DIR ?= ${LIBDIR}/password-store/extensions
BASHCOMPDIR ?= ${PREFIX}/share/bash-completion/completions
ZSHCOMPDIR ?= ${PREFIX}/share/zsh/site-functions

INSTALL ?= install
INSTALL_DATA ?= $(INSTALL) -m 0644
INSTALL_PROGRAM ?= $(INSTALL) -m 0755

all:
	@echo "pass-${EXT} is a shell script and does not need compilation, it can be simply executed."
	@echo "To install it try \"make install\" instead."

install_share:
	${INSTALL_DATA} -D share/bash-completion/completions/pass-${EXT} "${DESTDIR}${BASHCOMPDIR}/pass-${EXT}"
	${INSTALL_DATA} -D share/zsh/site-functions/_pass-${EXT} "${DESTDIR}${ZSHCOMPDIR}/_pass-${EXT}"
ifneq (,$(wildcard ./share/man/man1/pass-${EXT}.1))
	${INSTALL_DATA} -D share/man/man1/pass-${EXT}.1 "${DESTDIR}${MANDIR}/man1/pass-${EXT}.1"
endif

install: install_share
	${INSTALL_PROGRAM} -D ${EXT}.bash "${DESTDIR}${SYSTEM_EXTENSION_DIR}/${EXT}.bash"
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
