#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2016,SC2164

export test_description="pass otp: append"
cd tests
source ./commons

test_expect_success 'Reads non-terminal input' '
    existing="foo bar baz"
    uri="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Foo"

    test_pass_init &&
    _pass insert -e passfile <<< "$existing" &&
    _pass otp append -e passfile <<< "$uri" &&
    [[ $(_pass otp uri passfile) == "$uri" ]]
    '

test_expect_success 'Read secret non-terminal input' '
    existing="foo bar baz"
    secret=JBSWY3DPEHPK3PXP
    uri="otpauth://totp/Example:alice%40google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"

    test_pass_init &&
    _pass insert -e passfile <<< "$existing" &&
    _pass otp append -s -i Example -a alice@google.com -e passfile <<< "$secret" &&
    [[ $(_pass otp uri passfile) == "$uri" ]]
    '

test_expect_success 'Reads terminal input in noecho mode' '
    existing="foo bar baz"
    uri="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"

    test_pass_init &&
    _pass insert -e passfile <<< "$existing" &&
    { expect <<EOD
      set timeout 30
      spawn {*}{$PASS_SPAWN} otp append passfile
      expect {
        timeout { exit 1 }
        "Enter" {
          send "$uri\r"
          exp_continue
        }
        "Retype" {
          send "$uri\r"
          exp_continue
        }
        eof
      }
EOD
    } &&
    [[ $(_pass otp uri passfile) == "$uri" ]]
    '

test_expect_success 'Reads terminal input in echo mode' '
    existing="foo bar baz"
    uri="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"

    test_pass_init &&
    _pass insert -e passfile <<< "$existing" &&
    {
      expect <<EOD
        set timeout 30
        spawn {*}{$PASS_SPAWN} otp append -e passfile
        expect {
          timeout { exit 1 }
          "Enter" {
            send "$uri\r"
            exp_continue
          }
          eof
        }
EOD
    } &&
    [[ $(_pass otp uri passfile) == "$uri" ]]
    '

test_expect_success 'Insert secret containing lowercase letters and spaces' '
    existing="foo bar baz"
    secret="jbsw y3dp ehpk 3pxp"
    uri="otpauth://totp/Example:alice%40google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"

    test_pass_init &&
    _pass insert -e passfile <<< "$existing" &&
    {
      expect <<EOD
        set timeout 30
        spawn {*}{$PASS_SPAWN} otp append -s -i Example -a alice@google.com -e passfile
        expect {
          timeout { exit 1 }
          "Enter" {
            send "$secret\r"
            exp_continue
          }
          eof
        }
EOD
    } &&
    [[ $(_pass otp uri passfile) == "$uri" ]]
    '

test_expect_success 'Prompts before overwriting key URI' '
    existing="foo bar baz"
    uri1="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Foo"
    uri2="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Bar"

    test_pass_init &&
    _pass insert -e passfile <<< "$existing" &&
    _pass otp append -e passfile <<< "$uri1" &&
    {
      expect <<EOD
        set timeout 30
        spawn {*}{$PASS_SPAWN} otp append -e passfile
        expect {
          timeout { exit 1 }
          "Enter" {
            send "$uri2\r"
            exp_continue
          }
          "An OTP secret already exists" {
            send "n\r"
            exp_continue
          }
          eof
        }
EOD
    } &&
    [[ $(_pass otp uri passfile) == "$uri1" ]]
    '

test_expect_success 'Force overwrites key URI' '
    existing="foo bar baz"
    uri1="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Foo"
    uri2="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Bar"

    test_pass_init &&
    _pass insert -e passfile <<< "$existing" &&
    _pass otp append -e passfile <<< "$uri1" &&
    {
      expect <<EOD
        set timeout 30
        spawn {*}{$PASS_SPAWN} otp append -ef passfile
        expect {
          timeout { exit 1 }
          "Enter" {
            send "$uri2\r"
            exp_continue
          }
          "An OTP secret already exists" {
            send "n\r"
            exp_continue
          }
          eof
        }
EOD
    } &&
    [[ $(_pass otp uri passfile) == "$uri2" ]]
    '

test_expect_success 'Preserves multiline contents' '
    uri1="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Foo"
    uri2="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Bar"

    read -r -d "" existing <<EOF
foo bar baz
zab rab oof
$uri1
baz bar foo
EOF

    read -r -d "" expected <<EOF
foo bar baz
zab rab oof
$uri2
baz bar foo
EOF

    test_pass_init &&
    _pass insert -mf passfile <<< "$existing" &&
    _pass otp append -ef passfile <<< "$uri2" &&
    [[ $(_pass show passfile) == "$expected" ]]
    '

test_expect_success 'Replaces only the first otpauth line' '
    uri1="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Foo"
    uri2="otpauth://totp/Other:bob@example.com?secret=GEZDGNBVGY3TQOJQ"
    new="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Bar"

    test_pass_init &&
    _pass insert -mf passfile <<< "$(printf "pw\n%s\n%s" "$uri1" "$uri2")" &&
    _pass otp append -f passfile <<< "$new" &&
    [[ $(_pass show passfile) == "$(printf "pw\n%s\n%s" "$new" "$uri2")" ]]
    '

test_expect_success 'Preserves an empty first line (#207)' '
    uri="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Foo"

    test_pass_init &&
    _pass insert -mf passfile <<< "$(printf "\nUsername: foobar")" &&
    _pass otp append passfile <<< "$uri" &&
    [[ $(_pass show passfile) == "$(printf "\nUsername: foobar\n%s" "$uri")" ]]
    '

test_expect_success 'Keeps a password that looks like an echo option' '
    uri="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Foo"

    test_pass_init &&
    _pass insert -m passfile <<< "-e" &&
    _pass otp append passfile <<< "$uri" &&
    [[ $(_pass show passfile) == "$(printf -- "-e\n%s" "$uri")" ]]
    '

test_expect_success 'Keep original password' '
    existing="foo bar baz"
    uri="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Foo"

    test_pass_init &&
    _pass insert -e passfile <<< "$existing" &&
    _pass otp append -e passfile <<< "$uri" &&
    [[ $(_pass show passfile | head -1) == "$existing" ]]
    '

test_expect_success 'Keeps a passfile that does not decrypt' '
    uri="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Foo"

    test_pass_init &&
    echo garbage > "$PASSWORD_STORE_DIR/passfile.gpg" &&
    cp "$PASSWORD_STORE_DIR/passfile.gpg" before &&
    test_must_fail _pass otp append passfile <<< "$uri" 2> err &&
    grep -q "decryption failed" err &&
    cmp before "$PASSWORD_STORE_DIR/passfile.gpg"
    '

test_expect_success 'Commits append and replace' '
    uri1="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Foo"
    uri2="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Bar"

    test_pass_git_init &&
    _pass insert -e passfile <<< "password" &&
    _pass otp append passfile <<< "$uri1" &&
    [[ $(git log -1 --format=%s) == "Append OTP secret for passfile." ]] &&
    _pass otp append -f passfile <<< "$uri2" &&
    [[ $(git log -1 --format=%s) == "Replace OTP secret for passfile." ]]
    '

test_expect_success 'Fails on a missing passfile' '
    uri="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Foo"

    test_pass_init &&
    test_must_fail _pass otp append missing <<< "$uri" 2> err &&
    grep -q "passfile not found" err &&
    [[ ! -e "$PASSWORD_STORE_DIR/missing.gpg" ]]
    '

test_expect_success 'Fails for --secret without --issuer or --account' '
    test_pass_init &&
    _pass insert -e passfile <<< "password" &&
    test_must_fail _pass otp append -s passfile <<< "JBSWY3DPEHPK3PXP" 2> err &&
    grep -q "Missing one of" err &&
    [[ $(_pass show passfile) == "password" ]]
    '

test_expect_success 'Fails on usage errors' '
    test_pass_init &&
    test_must_fail _pass otp append &&
    test_must_fail _pass otp append a b
    '

test_done
