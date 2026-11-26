#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2016,SC2164

export test_description="pass otp: code"
cd tests
source ./commons

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

test_expect_success 'HOTP counter increment keeps other otpauth lines' '
    hotp="otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&counter=10"
    inc="otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&counter=11"
    totp="otpauth://totp/Other:bob@example.com?secret=GEZDGNBVGY3TQOJQ"

    test_pass_init &&
    _pass insert -mf passfile <<< "$(printf "pw\n%s\n%s" "$hotp" "$totp")" &&
    _pass otp passfile &&
    [[ $(_pass show passfile) == "$(printf "pw\n%s\n%s" "$inc" "$totp")" ]]
    '

test_expect_success 'HOTP counter with a leading zero is decimal' '
    uri="otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&counter=09"
    inc="otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&counter=10"

    test_pass_init &&
    _pass otp insert passfile <<< "$uri" &&
    code=$(_pass otp passfile) &&
    [[ $code == "$("$OATHTOOL" --base32 --hotp --counter=10 JBSWY3DPEHPK3PXP)" ]] &&
    [[ $(_pass otp uri passfile) == "$inc" ]]
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

test_expect_success 'Fails on a passfile that does not decrypt' '
    test_pass_init &&
    echo garbage > "$PASSWORD_STORE_DIR/passfile.gpg" &&
    test_must_fail _pass otp passfile 2> err &&
    grep -q "decryption failed" err
    '

test_expect_success 'Ignores an indented HOTP line and leaves it untouched' '
    uri="otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&counter=1&issuer=Example"

    test_pass_init &&
    _pass insert -m passfile < <(printf "pw\n  %s\n" "$uri") &&
    test_must_fail _pass otp passfile &&
    [[ $(_pass show passfile | grep -c otpauth) -eq 1 ]]
    '

test_done
