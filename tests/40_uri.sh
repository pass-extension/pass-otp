#!/usr/bin/env bash

export test_description='Tests pass otp URI parsing'

. ./setup.sh

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

test_done
