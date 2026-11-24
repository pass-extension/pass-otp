#!/usr/bin/env bash
# pass otp - Password Store Extension (https://www.passwordstore.org/)
# Copyright (C) 2017 Tad Fisher <tadfisher@gmail.com>.
# Copyright (C) 2017-2026 Alexandre PUJOL <alexandre@pujol.io>.
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file should be sourced by all test-scripts
#
# This scripts sets the following:
#   $PASS	Full path to password-store script to test
#   $GPG	Name of gpg executable
#   $KEY{1..5}	GPG key ids of testing keys
#   $TESTS_HOME	This folder
#   _pass	Run pass, under kcov when $COVERAGE is true
#

# shellcheck disable=SC1091,SC2034

# Project directory, we must be called from test/
TESTS_HOME="$(pwd)"
PROJECT_HOME="$(dirname "$TESTS_HOME")"

# Check dependencies
_die() { echo "${@}" && exit 1; }
PASS="$(command -v pass)"
GPG="$(command -v gpg)"
EXPECT="$(command -v expect)"
OATHTOOL="$(command -v oathtool)"
[[ -e "$PASS" ]] || _die "Could not find pass command"
[[ -e "$GPG" ]] || _die "Could not find gpg command"
[[ -e "$EXPECT" ]] || _die "Could not find expect command"
[[ -e "$OATHTOOL" ]] || _die "Could not find oathtool command"
if [[ "$COVERAGE" == true ]]; then
	KCOV="$(command -v kcov)"
	[[ -e "$KCOV" ]] || _die "Could not find kcov command"
	mkdir -p "$TMP"
	_pass() {
		"$KCOV" --include-path="$PROJECT_HOME/otp.bash" --exclude-path=/ \
			"$TMP/$(basename "$0")" "$PASS" "${@}"
	}
else
	_pass() { "$PASS" "${@}"; }
fi

# sharness config
export SHARNESS_TEST_DIRECTORY="$TESTS_HOME"
export SHARNESS_TEST_SRCDIR="$TESTS_HOME"
source ./lib-sharness/functions.sh
source ./sharness.sh

#  Prepare pass config vars
unset PASSWORD_STORE_DIR
unset PASSWORD_STORE_KEY
unset PASSWORD_STORE_GIT
unset PASSWORD_STORE_GPG_OPTS
unset PASSWORD_STORE_X_SELECTION
unset PASSWORD_STORE_CLIP_TIME
unset PASSWORD_STORE_UMASK
unset PASSWORD_STORE_GENERATED_LENGTH
unset PASSWORD_STORE_CHARACTER_SET
unset PASSWORD_STORE_CHARACTER_SET_NO_SYMBOLS
unset PASSWORD_STORE_ENABLE_EXTENSIONS
unset PASSWORD_STORE_EXTENSIONS_DIR
unset PASSWORD_STORE_SIGNING_KEY
unset GNUPGHOME
unset EDITOR

export PASSWORD_STORE_ENABLE_EXTENSIONS=true
export PASSWORD_STORE_EXTENSIONS_DIR="$PROJECT_HOME"
export PASSWORD_STORE_DIR="$SHARNESS_TRASH_DIRECTORY/test-store"
export GIT_DIR="$PASSWORD_STORE_DIR/.git"
export GIT_WORK_TREE="$PASSWORD_STORE_DIR"

# GnuPG config, the test keys are unencrypted
unset GPG_AGENT_INFO
export GNUPGHOME="$TESTS_HOME/gnupg/"
export KEY1="D4C78DB7920E1E27F5416B81CC9DB947CF90C77B"
export KEY2="70BD448330ACF0653645B8F2B4DDBFF0D774A374"
export KEY3="62EBE74BE834C2EC71E6414595C4B715EB7D54A8"
export KEY4="9378267629F989A0E96677B7976DD3D6E4691410"
export KEY5="4D2AFBDE67C60F5999D143AFA6E073D439E5020C"
chmod 700 "$GNUPGHOME"

# Test helpers

test_pass_init() {
	rm -rf "$PASSWORD_STORE_DIR"
	_pass init "$KEY1" "$KEY2" "$KEY3" "$KEY4" "$KEY5"
}

test_pass_git_init() {
	test_pass_init &&
		_pass git init &&
		_pass git config user.email "Pass-Automated-Testing-Suite@zx2c4.com" &&
		_pass git config user.name "Pass Automated Testing Suite"
}
