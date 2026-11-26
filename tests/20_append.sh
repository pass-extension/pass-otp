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
    { expect -d <<EOD
      spawn "$PASS" otp append passfile
      expect {
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
        spawn "$PASS" otp append -e passfile
        expect {
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
        spawn "$PASS" otp append -s -i Example -a alice@google.com -e passfile
        expect {
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
      expect -d <<EOD
        spawn "$PASS" otp append -e passfile
        expect {
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
    _pass otp append -ef passfile <<< "$uri2" &&
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

test_done
