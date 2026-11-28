#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2016,SC2164

export test_description="pass otp: code"
cd tests
source ./commons

# Generate a TOTP code with pass otp and check it against oathtool, before or
# after the call in case the time step changes in between
# $1: pass-name, other arguments are given to oathtool
test_totp() {
	local name="$1" before code after
	shift
	before="$("$OATHTOOL" "$@")" &&
		code="$(_pass otp "$name")" &&
		after="$("$OATHTOOL" "$@")" &&
		[[ $code == "$before" || $code == "$after" ]]
}

test_expect_success 'Fails for missing secret' '
    test_pass_init &&
    _pass insert -e passfile <<< "12345" &&
    test_expect_code 1 _pass otp passfile
    '

test_expect_success 'Generates TOTP code' '
    uri="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"

    test_pass_init &&
    _pass otp insert passfile <<< "$uri" &&
    test_totp passfile --base32 --totp JBSWY3DPEHPK3PXP
    '

test_expect_success 'Generates TOTP code with algorithm, digits and period' '
    uri="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&algorithm=SHA256&digits=8&period=60"

    test_pass_init &&
    _pass otp insert passfile <<< "$uri" &&
    test_totp passfile --base32 --totp=sha256 --digits=8 --time-step-size=60s JBSWY3DPEHPK3PXP
    '

test_expect_success 'Generates HOTP code and increments counter' '
    uri="otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&counter=10&issuer=Example"
    inc="otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&counter=11&issuer=Example"

    test_pass_init &&
    _pass otp insert passfile <<< "$uri" &&
    code=$(_pass otp passfile) &&
    [[ $code == "$("$OATHTOOL" --base32 --hotp --counter=11 JBSWY3DPEHPK3PXP)" ]] &&
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

test_expect_success 'Generates HOTP code with 8 digits' '
    uri="otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&counter=10&digits=8"

    test_pass_init &&
    _pass otp insert passfile <<< "$uri" &&
    [[ $(_pass otp passfile) == "$("$OATHTOOL" --base32 --hotp --digits=8 --counter=11 JBSWY3DPEHPK3PXP)" ]]
    '

test_expect_success 'Uses the first otpauth line' '
    first="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP"
    second="otpauth://totp/Other:bob@example.com?secret=GEZDGNBVGY3TQOJQ"

    test_pass_init &&
    _pass insert -m passfile < <(printf "pw\n%s\n%s\n" "$first" "$second") &&
    test_totp passfile --base32 --totp JBSWY3DPEHPK3PXP
    '

test_expect_success 'Commits the HOTP counter increment' '
    uri="otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&counter=10"

    test_pass_git_init &&
    _pass otp insert passfile <<< "$uri" &&
    _pass otp passfile &&
    [[ $(git log -1 --format=%s) == "Increment HOTP counter for passfile." ]]
    '

test_expect_success 'Copies the code to the clipboard' '
    uri="otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&counter=10"

    test_pass_init &&
    _pass otp insert passfile <<< "$uri" &&
    DISPLAY=fake WAYLAND_DISPLAY= PASSWORD_STORE_CLIP_TIME=1 _pass otp -c passfile > out &&
    grep -qxF "$("$OATHTOOL" --base32 --hotp --counter=11 JBSWY3DPEHPK3PXP)" "$FAKE_CLIPBOARD" &&
    ! grep -q "[0-9]\{6\}" out
    '

test_expect_success 'Show is an alias of code' '
    uri="otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&counter=10"

    test_pass_init &&
    _pass otp insert passfile <<< "$uri" &&
    [[ $(_pass otp show passfile) == "$("$OATHTOOL" --base32 --hotp --counter=11 JBSWY3DPEHPK3PXP)" ]]
    '

test_expect_success 'Fails on a missing passfile' '
    test_pass_init &&
    test_must_fail _pass otp code missing 2> err &&
    grep -q "passfile not found" err
    '

test_expect_success 'Fails on usage errors' '
    test_pass_init &&
    test_must_fail _pass otp code &&
    test_must_fail _pass otp code a b &&
    test_must_fail _pass otp code --bogus passfile
    '

test_expect_success 'Prints the version and the usage' '
    _pass otp version | grep -q "^pass otp [0-9.]* - " &&
    _pass otp help | grep -q "^Usage:"
    '

test_expect_success NO_OTPTOOL 'Passes the secret as argument to oathtool older than 2.6.5' '
    uri="otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&counter=10"
    inc="otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&counter=11"

    test_pass_init &&
    _pass otp insert passfile <<< "$uri" &&
    mkdir -p bin && cp "$TESTS_HOME/fake-oathtool" bin/oathtool &&
    code=$(PATH="$PWD/bin:$PATH" _pass otp passfile) &&
    [[ $code == "$("$OATHTOOL" --base32 --hotp --counter=11 JBSWY3DPEHPK3PXP)" ]] &&
    [[ $(_pass otp uri passfile) == "$inc" ]]
    '

test_expect_success 'Falls back to otptool with the incremented HOTP counter' '
    uri="otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&counter=10"
    inc="otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&counter=11"

    test_pass_init &&
    _pass otp insert passfile <<< "$uri" &&
    rm -f "$FAKE_OTPTOOL_LOG" &&
    mkdir -p bin && cp "$TESTS_HOME/fake-oathtool" bin/oathtool &&
    cp "$TESTS_HOME/fake-otptool" bin/otptool &&
    code=$(PATH="$PWD/bin:$PATH" _pass otp passfile) &&
    [[ $code == 123456 ]] &&
    [[ $(cat "$FAKE_OTPTOOL_LOG") == "$inc" ]] &&
    [[ $(_pass otp uri passfile) == "$inc" ]]
    '

test_expect_success 'Fails and keeps the counter when oathtool fails' '
    uri="otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&counter=10&digits=9"

    test_pass_init &&
    _pass otp insert passfile <<< "$uri" &&
    test_must_fail _pass otp passfile 2> err &&
    grep -q "failed to generate OTP code" err &&
    [[ $(_pass otp uri passfile) == "$uri" ]]
    '

test_expect_success 'Increments HOTP counter after an otp: key, keeping the key' '
    uri="otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&counter=10&issuer=Example"
    inc="otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&counter=11&issuer=Example"

    test_pass_init &&
    _pass insert -m passfile < <(printf "%s\n" password "otp: $uri" "login: alice") &&
    code=$(_pass otp passfile) &&
    [[ $code == "$("$OATHTOOL" --base32 --hotp --counter=11 JBSWY3DPEHPK3PXP)" ]] &&
    [[ $(_pass show passfile) == "$(printf "%s\n" password "otp: $inc" "login: alice")" ]]
    '

test_done
