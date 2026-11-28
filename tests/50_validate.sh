#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2016,SC2164

export test_description="pass otp: validate"
cd tests
source ./commons

test_expect_success 'Parses a basic TOTP URI' '
    _pass otp validate "otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"
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

test_expect_success 'Parses a HOTP URI with port number' '
    _pass otp validate  "otpauth://hotp/Example:alice@google.com:443?secret=JBSWY3DPEHPK3PXP&counter=10&issuer=Example"
    '

test_expect_success 'Parses a TOTP URI with a lowercase algorithm and secret' '
    _pass otp validate "otpauth://totp/Example:alice@google.com?secret=jbswy3dpehpk3pxp&algorithm=sha256&digits=8&period=60"
    '

test_expect_success 'Fails for non numeric digits' '
    test_must_fail _pass otp validate "otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&digits=abc" 2> err &&
    grep -q "digits" err
    '

test_expect_success 'Fails for a zero period' '
    test_must_fail _pass otp validate "otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&period=0" 2> err &&
    grep -q "period" err
    '

test_expect_success 'Fails for an unknown algorithm' '
    test_must_fail _pass otp validate "otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&algorithm=MD5" 2> err &&
    grep -q "algorithm" err
    '

test_expect_success 'Fails for a secret that is not base32' '
    test_must_fail _pass otp validate "otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PX1" 2> err &&
    grep -q "base32" err
    '

test_expect_success 'Ignores unknown parameters' '
    _pass otp validate "otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&image=https%3A%2F%2Fexample.com%2Flogo.png"
    '

test_done
