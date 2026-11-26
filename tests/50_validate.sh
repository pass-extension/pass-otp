#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2016,SC2164

export test_description="pass otp: validate"
cd tests
source ./commons

test_expect_success 'Parses a basic TOTP URI' '
    _pass otp validate "otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"
    echo $otp_type
    '

test_expect_success 'Parses a complex TOTP URI' '
    _pass otp validate "otpauth://totp/ACME%20Co:john.doe@email.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME%20Co&algorithm=SHA1&digits=6&period=30"
    '

test_expect_success 'Parses a basic HOTP URI' '
    _pass otp validate  "otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&counter=10&issuer=Example"
    '

test_expect_success 'Fails for bogus URL' '
    test_must_fail _pass otp validate https://www.google.com/
    '

test_expect_success 'Fails for missing secret' '
    test_must_fail _pass otp validate "otpauth://totp/ACME%20Co:john.doe@email.com?issuer=ACME%20Co&algorithm=SHA1&digits=6&period=30"
    '

test_expect_success 'Fails for missing counter' '
    test_must_fail _pass otp validate "otpauth://hotp/Example:alice@google.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ"
    '

test_expect_success 'Fails for unencoded colon in issuer (#194)' '
    test_must_fail _pass otp validate "otpauth://totp/NotABug.org:%20Free%20code%20hosting:no@mail.com?secret=JBSWY3DPEHPK3PXP&issuer=NotABug.org%3A+Free+code+hosting"
    '

test_expect_success 'Parses TOTP URI with port number' '
    _pass otp validate "otpauth://totp/Example:alice@google.com:443?secret=JBSWY3DPEHPK3PXP&issuer=Example"
    '

test_expect_success 'Parses a complex TOTP URI with port number' '
    _pass otp validate "otpauth://totp/ACME%20Co:john.doe@email.com:443?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME%20Co&algorithm=SHA1&digits=6&period=30"
    '

test_expect_success 'Parses a HOTP URI with port umber' '
    _pass otp validate  "otpauth://hotp/Example:alice@google.com:443?secret=JBSWY3DPEHPK3PXP&counter=10&issuer=Example"
    '

test_done
