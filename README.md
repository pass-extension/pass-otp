# pass-otp

[![][workflow]][action] [![][release]][release-link]

**A [pass] extension for managing one-time-password (OTP) tokens.**

## Description

`pass otp` extends the pass utility with an `otp` command for managing OTP tokens:
adding secrets, generating codes and displaying key URIs in the standard
[Key Uri Format][key-uri]. It supports both time-based (TOTP) and counter-based (HOTP)
tokens.

The token is stored as an `otpauth://` line inside a regular password file, so it can
live in its own entry or next to the password it protects. The HOTP counter is updated
(and committed when the store is a git repository) each time a code is generated.

Codes are generated with [oathtool]. `pass otp` works with both `pass` (GPG) and
[passage] (age).

Pass otp is compatible with browser extensions: [passff] fills OTP fields with codes
from `pass otp`, and [browserpass] generates TOTP codes from the same `otpauth://` line.

## Usage

```
pass otp 1.2.0 - Manage one-time-password (OTP) tokens.

Usage:

    pass otp [code] [--clip,-c] pass-name
        Generate an OTP code and optionally put it on the clipboard.
        If put on the clipboard, it will be cleared in 45 seconds.

    pass otp insert [--force,-f] [--echo,-e]
            [[--secret, -s] [--issuer,-i issuer] [--account,-a account] [--path,-p path-name]]
            [pass-name]
        Prompt for and insert a new OTP key.

        If 'secret' is specified, prompt for the OTP secret, assuming SHA1
        algorithm, 30-second period, and 6 OTP digits; one of 'issuer' or
        'account' is also required. Otherwise, prompt for a key URI; if
        'pass-name' is not supplied, use the URI label.

        Optionally, echo the input. Prompt before overwriting existing URI
        unless forced. This command accepts input from stdin.

    pass otp append [--force,-f] [--echo,-e]
            [[--secret, -s] [--issuer,-i issuer] [--account,-a account]]
            pass-name
        Appends an OTP key URI to an existing password file.

        If 'secret' is specified, prompt for the OTP secret, assuming SHA1
        algorithm, 30-second period, and 6 OTP digits; one of 'issuer' or
        'account' is also required. Otherwise, prompt for a key URI.

        Optionally, echo the input. Prompt before overwriting an existing URI
        unless forced. This command accepts input from stdin.

    pass otp uri [--clip,-c] [--qrcode,-q] pass-name
        Display the key URI stored in pass-name. Optionally, put it on the
        clipboard, or display a QR code.

    pass otp validate uri
        Test if the given URI is a valid OTP key URI.

More information may be found in the pass-otp(1) man page.
```

## Examples

**Prompt for an OTP token, hiding input**
```
$ pass otp insert totp-secret
Enter otpauth:// URI for totp-secret:
Retype otpauth:// URI for totp-secret:
```

**Prompt for an OTP token, echoing input**
```
$ pass otp insert -e totp-secret
Enter otpauth:// URI for totp-secret: otpauth://totp/totp-secret?secret=AAAAAAAAAAAAAAAA&issuer=totp-secret
```

**Pipe an `otpauth://` URI into a passfile**
```
$ pass otp insert totp-secret < totp-secret.txt
```

**Use [zbar](https://github.com/mchehab/zbar) to decode a QR image or webcam shot into a passfile**
```
$ zbarimg -q --raw qrcode.png | pass otp insert totp-secret
```

To use your webcam:

```
$ zbarcam -q --raw | pass otp insert totp-secret
```

The same, but appending to an existing passfile:

```
$ zbarimg -q --raw google-qrcode.png | pass otp append google/example@gmail.com
```

You can also select "Copy Image" in your favorite browser or take a
screenshot of the QR code and run:

* With Wayland:

  ```
  $ wl-paste | zbarimg -q --raw - | pass otp append google/example@gmail.com
  ```

* With X11:

  ```
  $ xclip -selection clipboard -o -target image/png | zbarimg -q --raw - | pass otp append google/example@gmail.com
  ```

* On MacOS, use `pngpaste -`

**Generate a 2FA code using this token**

```
$ pass otp totp-secret
698816
```

**Display a QR code for an OTP token**

```
$ pass otp uri -q totp-secret
█████████████████████████████████████
█████████████████████████████████████
████ ▄▄▄▄▄ ██▄▄ ▀█  ▀  █▀█ ▄▄▄▄▄ ████
████ █   █ █▀▄  █▀▀▄▀▀██ █ █   █ ████
████ █▄▄▄█ █▄▀ █▄▄▄ █▀▀▄ █ █▄▄▄█ ████
████▄▄▄▄▄▄▄█▄▀▄█ ▀ █▄█ ▀▄█▄▄▄▄▄▄▄████
████▄▄▀██▄▄ ▀▄ █▄█▀ ▀▄▀▀▄▀█▀ ▄▀██████
████  ▀▄▀ ▄▀ ▄▀ ▄▄ ▄ ███ ██ █ ███████
████▀▀ ▄▄█▄▄▄▄ █ █ ▀███▀▄▀  ▀▀█  ████
████▀▄▀ ▀ ▄█▀▄██ ▀▀▄██▀█▀▄▀▀  ▀█▀████
████▀ █▀ ▄▄██ █▀▄▄▄   ▄▀ ▄▀ ▀ ▄▀▀████
████ ▄ ▀█ ▄█▄ ▀ ▄██▄▀██▄ ▀▀▀█ ▄▀ ████
████▄█▄▄▄█▄▄ █▄▄ ▀█ █▄█▀ ▄▄▄ █▄█▄████
████ ▄▄▄▄▄ █ ▄▀▀▀▀▄ █▄▄  █▄█ ███▀████
████ █   █ ██▀▄ █▄█ ▀█▀   ▄▄▄█▀▄ ████
████ █▄▄▄█ █▀▄ █  █  ██▄▄▀ ▀▄█ ▄▀████
████▄▄▄▄▄▄▄█▄█▄▄███▄█▄█▄█▄█▄██▄██████
█████████████████████████████████████
█████████████████████████████████████
```

## Migrating from pass-otp 0.1

`pass-otp` has switched to storing OTP tokens in the
standard
[Key Uri Format](https://github.com/google/google-authenticator/wiki/Key-Uri-Format).
You'll need to edit any saved tokens and change them to this format. For
example:

```
$ pass edit totp-secret
```

Old format:

```
otp_secret: AAAAAAAAAAAAAAAA
otp_type: totp
otp_algorithm: sha1
otp_period: 30
otp_digits: 6
```

New format:

```
otpauth://totp/totp-secret?secret=AAAAAAAAAAAAAAAA&issuer=totp-secret
```

Note that the following default values do not need to be specified in the URI:

| parameter | default |
| --------- | ------- |
| algorithm | sha1    |
| period    | 30      |
| digits    | 6       |

## Migrating from Google Authenticator

**Warning:** This method is provided as a means to transport your TOTP tokens to
other devices, disconnected from your single factor authentication part. If you
add those secrets into the same basket of eggs, you will be defeating the whole
purpose of the [multi factor
authentication](https://en.wikipedia.org/wiki/Multi-factor_authentication)
mantra. Please think it through before running this migration.

If you read the warning paragraph above, [keep calm and move on with the
migration](https://github.com/tadfisher/pass-otp/wiki/How-to-migrate-your-Google-Authenticator-database-to-pass-otp%3F).

## Installation

<table align="right">
  <tr><td><a href="https://repology.org/project/pass-otp/versions"><img alt="Arch" src="https://repology.org/badge/version-for-repo/arch/pass-otp.svg?header=Arch"></a></td></tr>
  <tr><td><a href="https://repology.org/project/pass-otp/versions"><img alt="Debian" src="https://repology.org/badge/version-for-repo/debian_unstable/pass-otp.svg?header=Debian"></a></td></tr>
  <tr><td><a href="https://repology.org/project/pass-otp-unclassified/versions"><img alt="NixOS" src="https://repology.org/badge/version-for-repo/nix_unstable/pass-otp-unclassified.svg?header=NixOS"></a></td></tr>
  <tr><td><a href="https://repology.org/project/pass-otp/versions"><img alt="Ubuntu" src="https://repology.org/badge/version-for-repo/ubuntu_26_04/pass-otp.svg?header=Ubuntu%2026.04"></a></td></tr>
  <tr><td><a href="https://repology.org/project/pass-otp/versions"><img alt="Fedora" src="https://repology.org/badge/version-for-repo/fedora_rawhide/pass-otp.svg?header=Fedora"></a></td></tr>
  <tr><td><a href="https://repology.org/project/pass-otp/versions"><img alt="Gentoo" src="https://repology.org/badge/version-for-repo/gentoo/pass-otp.svg?header=Gentoo"></a></td></tr>
  <tr><td><a href="https://repology.org/project/pass-otp/versions"><img alt="Alpine" src="https://repology.org/badge/version-for-repo/alpine_edge/pass-otp.svg?header=Alpine"></a></td></tr>
  <tr><td><a href="https://repology.org/project/pass-otp/versions"><img alt="Homebrew" src="https://repology.org/badge/version-for-repo/homebrew/pass-otp.svg?header=Homebrew"></a></td></tr>
  <tr><td><a href="https://repology.org/project/pass-otp/versions"><img alt="FreeBSD" src="https://repology.org/badge/version-for-repo/freebsd/pass-otp.svg?header=FreeBSD"></a></td></tr>
  <tr><td><a href="https://repology.org/project/pass-otp/versions"><img alt="OpenBSD" src="https://repology.org/badge/version-for-repo/openbsd/pass-otp.svg?header=OpenBSD"></a></td></tr>
  <tr><td><a href="https://repology.org/project/pass-otp/versions"><img alt="Void" src="https://repology.org/badge/version-for-repo/void_x86_64/pass-otp.svg?header=Void"></a></td></tr>
</table>

**Requirements**

* `pass 1.7.0` or greater.
* `oathtool` or `Pass::OTP` to generate codes.
* `qrencode` to display QR codes.

**ArchLinux**

```sh
pacman -S pass-otp
```

**Debian/Ubuntu**

```sh
apt install pass-otp
```

**Fedora**

```sh
dnf install pass-otp
```

**Gentoo**

```sh
emerge app-admin/pass-otp
```

**NixOS**

```nix
pass.withExtensions (exts: [ exts.pass-otp ])
```

**openSUSE**

```sh
zypper install pass-otp
```

**OSX**

```sh
brew install pass-otp  # or: sudo port install pass-otp
```

**From git**

```sh
git clone https://github.com/pass-extension/pass-otp/
cd pass-otp
sudo make install  # For OSX: make install PREFIX=$(brew --prefix)
```

To use with [passage], install into one of passage's extension directories:
```sh
sudo make install SYSTEM_EXTENSION_DIR=/usr/lib/passage/extensions
```

## Contribution

Feedback, contributors, pull requests are all very welcome.

[github-link]: https://github.com/pass-extension/pass-otp
[workflow]: https://img.shields.io/endpoint.svg?url=https%3A%2F%2Factions-badge.atrox.dev%2Fpass-extension%2Fpass-otp%2Fbadge%3Fref%3Dmain&style=flat-square
[action]: https://actions-badge.atrox.dev/pass-extension/pass-otp/goto?ref=main
[release]: https://img.shields.io/github/release/pass-extension/pass-otp.svg?maxAge=600&style=flat-square
[release-link]: https://github.com/pass-extension/pass-otp/releases/latest
[repology-link]: https://repology.org/project/pass-otp/versions

[pass]: https://www.passwordstore.org/
[key-uri]: https://github.com/google/google-authenticator/wiki/Key-Uri-Format
[oathtool]: https://www.nongnu.org/oath-toolkit/
[passage]: https://github.com/FiloSottile/passage
[passff]: https://github.com/passff/passff
[browserpass]: https://github.com/browserpass/browserpass-extension
