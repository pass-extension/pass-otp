#!/usr/bin/env bash

export test_description='Tests pass otp code generation'

. ./setup.sh

test_expect_success 'Fails for missing secret' '
  test_pass_init &&
  _pass insert passfile <<< "12345"
  test_expect_code 1 _pass otp passfile
'

test_expect_success 'Generates TOTP code' '
  uri="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"

  test_pass_init &&
  _pass otp insert passfile <<< "$uri" &&
  code=$(_pass otp passfile) &&
  [[ ${#code} -eq 6 ]]
'

test_expect_success 'Generates HOTP code and increments counter' '
  uri="otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&counter=10&issuer=Example"
  inc="otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&counter=11&issuer=Example"

  test_pass_init &&
  _pass otp insert passfile <<< "$uri" &&
  code=$(_pass otp passfile) &&
  [[ ${#code} -eq 6 ]] &&
  [[ $(_pass otp uri passfile) == "$inc" ]]
'

test_expect_success 'Increments HOTP counter when it is the first parameter' '
  uri="otpauth://hotp/Example:alice@google.com?counter=10&secret=JBSWY3DPEHPK3PXP&issuer=Example"
  inc="otpauth://hotp/Example:alice@google.com?counter=11&secret=JBSWY3DPEHPK3PXP&issuer=Example"

  test_pass_init &&
  _pass otp insert passfile <<< "$uri" &&
  _pass otp passfile &&
  [[ $(_pass otp uri passfile) == "$inc" ]]
'

test_expect_success 'Generates HOTP code quietly' '
  uri="otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&counter=10&issuer=Example"
  inc="otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&counter=11&issuer=Example"

  test_pass_git_init &&
  _pass otp insert passfile <<< "$uri" &&
  code=$(_pass otp -q passfile) &&
  [[ ${#code} -eq 6 ]] &&
  [[ $(_pass otp uri passfile) == "$inc" ]]
'

test_expect_success 'HOTP counter increments and preserves multiline contents' '
  uri="otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&counter=10&issuer=Example"
  inc="otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&counter=11&issuer=Example"

  read -r -d "" existing <<EOF
foo bar baz
zab rab oof
$uri
baz bar foo
EOF

  read -r -d "" expected <<EOF
foo bar baz
zab rab oof
$inc
baz bar foo
EOF

  test_pass_init &&
  _pass insert -mf passfile <<< "$existing" &&
  _pass otp code passfile &&
  [[ $(_pass show passfile) == "$expected" ]]
'

test_expect_success 'Generates TOTP code for URI with port number' '
  uri="otpauth://totp/Example:alice@domain.com:443?secret=JBSWY3DPEHPK3PXP&issuer=Example"

  test_pass_init &&
  _pass otp insert passfile <<< "$uri" &&
  code=$(_pass otp passfile) &&
  [[ ${#code} -eq 6 ]]
'

test_expect_success 'Generates HOTP code for URI with port number' '
  uri="otpauth://hotp/Example:alice@google.com:443?secret=JBSWY3DPEHPK3PXP&counter=10&issuer=Example"
  inc="otpauth://hotp/Example:alice@google.com:443?secret=JBSWY3DPEHPK3PXP&counter=11&issuer=Example"

  test_pass_init &&
  _pass otp insert passfile <<< "$uri" &&
  code=$(_pass otp passfile) &&
  [[ ${#code} -eq 6 ]] &&
  [[ $(_pass otp uri passfile) == "$inc" ]]
'

test_done
