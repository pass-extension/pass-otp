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

test_expect_success 'Fails on a passfile that does not decrypt' '
    test_pass_init &&
    echo garbage > "$PASSWORD_STORE_DIR/passfile.gpg" &&
    test_must_fail _pass otp uri passfile 2> err &&
    grep -q "decryption failed" err
    '

test_expect_success 'Shows the stored URI unchanged, quotes and backticks included' '
    uri="otpauth://totp/Ex\"am\`ple:alice@google.com?secret=JBSWY3DPEHPK3PXP"

    test_pass_init &&
    _pass otp insert passfile <<< "$uri" &&
    [[ $(_pass otp uri passfile) == "$uri" ]]
    '


test_expect_success 'Copies the key URI to the clipboard' '
    uri="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"

    test_pass_init &&
    _pass otp insert passfile <<< "$uri" &&
    DISPLAY=fake WAYLAND_DISPLAY= PASSWORD_STORE_CLIP_TIME=1 _pass otp uri -c passfile > out &&
    grep -qxF "$uri" "$FAKE_CLIPBOARD" &&
    ! grep -q otpauth out
    '

test_expect_success QRENCODE 'Displays the key URI as a QR code' '
    uri="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"

    test_pass_init &&
    _pass otp insert passfile <<< "$uri" &&
    (unset DISPLAY WAYLAND_DISPLAY; _pass otp uri -q passfile > out) &&
    [[ $(cat out) == "$(printf %s "$uri" | qrencode -t utf8)" ]]
    '

test_expect_success 'Fails on usage errors' '
    test_pass_init &&
    test_must_fail _pass otp uri &&
    test_must_fail _pass otp uri a b
    '

test_done
