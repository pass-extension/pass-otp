#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2016,SC2164

export test_description="pass otp: uri"
cd tests
source ./commons

test_expect_success 'Shows key URI in single-line passfile' '
    uri="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"

    test_pass_init &&
    _pass otp insert passfile <<< "$uri" &&
    [[ $(_pass otp uri passfile) == "$uri" ]]
    '

test_expect_success 'Shows key URI in multi-line passfile' '
    uri="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"

    test_pass_init &&
    _pass insert -m passfile < <(echo -e "password\nfoo\n$uri\nbar") &&
    [[ $(_pass otp uri passfile) == "$uri" ]]
    '

test_expect_success 'Fails for missing secret' '
    test_pass_init &&
    _pass insert -e passfile <<< "password" &&
    test_must_fail _pass otp uri passfile
    '

test_done
