#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2016,SC2164

export test_description="pass otp: insert"
cd tests
source ./commons

test_expect_success 'Reads non-terminal input' '
    uri="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"

    test_pass_init &&
    _pass otp insert passfile <<< "$uri" &&
    [[ $(_pass show passfile) == "$uri" ]]
    '

test_expect_success 'Reads terminal input in noecho mode' '
    uri="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"

    test_pass_init &&
    expect <<EOD &&
      set timeout 30
      spawn "$PASS" otp insert passfile
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
    [[ $(_pass show passfile) == "$uri" ]]
    '

test_expect_success 'Reads terminal input in echo mode' '
    uri="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"

    test_pass_init &&
    expect <<EOD &&
      set timeout 30
      spawn "$PASS" otp insert -e passfile
      expect {
        timeout { exit 1 }
        "Enter" {
          send "$uri\r"
          exp_continue
        }
        eof
      }
EOD
    [[ $(_pass show passfile) == "$uri" ]]
    '

test_expect_success 'Prompts before overwriting key URI' '
    uri1="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Foo"
    uri2="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Bar"

    test_pass_init &&
    _pass otp insert passfile <<< "$uri1" &&
    expect <<EOD &&
      set timeout 30
      spawn "$PASS" otp insert -e passfile
      expect {
        timeout { exit 1 }
        "Enter" {
          send "$uri2\r"
          exp_continue
        }
        "An entry already exists" {
          send "n\r"
          exp_continue
        }
        eof
      }
EOD
    [[ $(_pass show passfile) == "$uri1" ]]
    '

test_expect_success 'Generates default pass-name from label' '
    uri="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"

    test_pass_init &&
    _pass otp insert <<< "$uri" &&
    [[ $(_pass show "Example/alice@google.com") == "$uri" ]]
    '

test_expect_success 'Prompts when inserting default pass-name from terminal' '
    uri="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"

    test_pass_init &&
    expect <<EOD &&
      set timeout 30
      spawn "$PASS" otp insert -e
      expect {
        timeout { exit 1 }
        "Enter" {
          send "$uri\r"
          exp_continue
        }
        "Insert into Example/alice@google.com?" {
          send "y\r"
          exp_continue
        }
        eof
      }
EOD
    [[ $(_pass show "Example/alice@google.com") == "$uri" ]]
    '

test_expect_success 'Force overwrites key URI' '
    uri1="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Foo"
    uri2="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Bar"

    test_pass_init &&
    _pass otp insert passfile <<< "$uri1" &&
    _pass otp insert -f passfile <<< "$uri2" &&
    [[ $(_pass show passfile) == "$uri2" ]]
    '

test_expect_success 'Insert passfile from secret with options(issuer, accountname)' '
    secret="JBSWY3DPEHPK3PXP"
    uri="otpauth://totp/Example:alice%40google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"

    test_pass_init &&
    _pass otp insert -s -i Example -a alice@google.com passfile <<< "$secret" &&
    [[ $(_pass show passfile) == "$uri" ]]
    '

test_expect_success 'Insert secret containing lowercase letters and spaces' '
    secret="$(printf "jbsw y3dp\tehpk 3pxp")"
    uri="otpauth://totp/Example:alice%40google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"

    test_pass_init &&
    _pass otp insert -s -i Example -a alice@google.com passfile <<< "$secret" &&
    [[ $(_pass show passfile) == "$uri" ]]
    '

test_expect_success 'Insert from secret without passfile' '
    secret="JBSWY3DPEHPK3PXP"
    uri="otpauth://totp/Example:alice%40google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"

    test_pass_init &&
    _pass otp insert -s -i Example -a alice@google.com <<< "$secret" &&
    [[ $(_pass show Example/alice@google.com) == "$uri" ]]
    '

test_expect_success 'Tolerates padding in secret' '
    secret="JBSWY3DPEHPK3PXP=="
    uri="otpauth://totp/Example:alice%40google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"

    test_pass_init &&
    _pass otp insert -s -i Example -a alice@google.com <<< "$secret" &&
    [[ $(_pass show Example/alice@google.com) == "$uri" ]]
    '

test_expect_success 'Allow path prefixes in insert' '
    secret="JBSWY3DPEHPK3PXP=="
    uri="otpauth://totp/Example:alice%40google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"

    test_pass_init &&
    _pass otp insert -s -p totp -i Example -a alice@google.com <<< "$secret" &&
    [[ $(_pass show totp/Example/alice@google.com) == "$uri" ]]
    '

test_expect_success 'Allow multiple levels in path prefix' '
    secret="JBSWY3DPEHPK3PXP=="
    uri="otpauth://totp/Example:alice%40google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"

    test_pass_init &&
    _pass otp insert -s -p totp/pass-test -i Example -a alice@google.com <<< "$secret" &&
    [[ $(_pass show totp/pass-test/Example/alice@google.com) == "$uri" ]]
    '

test_expect_success 'Keeps a literal + in the label' '
    uri="otpauth://totp/Example:alice+otp@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"

    test_pass_init &&
    _pass otp insert <<< "$uri" &&
    [[ $(_pass show "Example/alice+otp@google.com") == "$uri" ]]
    '

test_expect_success 'Decodes + as a space in the issuer parameter' '
    uri="otpauth://totp/alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=ACME+Co"

    test_pass_init &&
    _pass otp insert <<< "$uri" &&
    [[ $(_pass show "ACME Co/alice@google.com") == "$uri" ]]
    '

test_expect_success 'Keeps a decoded backslash literal' '
    uri="otpauth://totp/Example:a%5Cnb?secret=JBSWY3DPEHPK3PXP&issuer=Example"

    test_pass_init &&
    _pass otp insert <<< "$uri" &&
    [[ $(_pass show "Example/a\\nb") == "$uri" ]]
    '

test_expect_success 'Encodes spaces and UTF-8 from secret options' '
    secret="JBSWY3DPEHPK3PXP"
    uri="otpauth://totp/ACME%20Soci%C3%A9t%C3%A9:bob?secret=JBSWY3DPEHPK3PXP&issuer=ACME%20Soci%C3%A9t%C3%A9"

    test_pass_init &&
    _pass otp insert -s -i "ACME Société" -a bob <<< "$secret" &&
    [[ $(_pass show "ACME Société/bob") == "$uri" ]]
    '

test_expect_success 'Insert TOTP URI with port number' '
    uri="otpauth://totp/Example:alice@google.com:443?secret=JBSWY3DPEHPK3PXP&issuer=Example"

    test_pass_init &&
    _pass otp insert passfile <<< "$uri" &&
    [[ $(_pass show passfile) == "$uri" ]]
    '

test_expect_success 'Rejects a sneaky default pass-name before any prompt' '
    uri="otpauth://totp/..:passwd?secret=JBSWY3DPEHPK3PXP&issuer=.."

    test_pass_init &&
    touch "$PASSWORD_STORE_DIR/../passwd.gpg" &&
    expect <<EOD
      set timeout 30
      spawn "$PASS" otp insert -e
      expect {
        timeout { exit 1 }
        "Enter" {
          send "$uri\r"
          exp_continue
        }
        "Insert into" {
          send "y\r"
          exp_continue
        }
        "already exists" {
          exit 1
        }
        eof
      }
EOD
    '

test_expect_success 'Fails with more than one pass-name' '
    uri="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"

    test_pass_init &&
    test_must_fail _pass otp insert passfile extra <<< "$uri" &&
    [[ ! -e "$PASSWORD_STORE_DIR/passfile.gpg" ]] &&
    [[ ! -e "$PASSWORD_STORE_DIR/extra.gpg" ]]
    '

test_expect_success 'Fails with both --path and a pass-name' '
    uri="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"

    test_pass_init &&
    test_must_fail _pass otp insert -p totp passfile <<< "$uri" 2> err &&
    grep -q -- "--path" err &&
    [[ ! -e "$PASSWORD_STORE_DIR/passfile.gpg" ]]
    '

test_expect_success 'Commits the new entry' '
    uri="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"

    test_pass_git_init &&
    _pass otp insert passfile <<< "$uri" &&
    [[ $(git log -1 --format=%s) == "Add OTP secret for passfile to store." ]]
    '

test_expect_success 'Add is an alias of insert' '
    uri="otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"

    test_pass_init &&
    _pass otp add passfile <<< "$uri" &&
    [[ $(_pass show passfile) == "$uri" ]]
    '

test_expect_success 'Fails for --secret without --issuer or --account' '
    test_pass_init &&
    test_must_fail _pass otp insert -s passfile <<< "JBSWY3DPEHPK3PXP" 2> err &&
    grep -q "Missing one of" err &&
    [[ ! -e "$PASSWORD_STORE_DIR/passfile.gpg" ]]
    '

test_expect_success 'Fails for an unknown option' '
    test_pass_init &&
    test_must_fail _pass otp insert --bogus passfile <<< "otpauth://totp/a?secret=JBSWY3DPEHPK3PXP"
    '

test_done
