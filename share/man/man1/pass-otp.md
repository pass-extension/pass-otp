% pass-otp(1)
% pass otp was written by Tad Fisher (tadfisher@gmail.com)
% November 2026

# NAME

pass-otp — A **pass**(1) extension for managing one-time-password (OTP) tokens.

# SYNOPSIS

**pass otp** [*command*] [*options…*] [*args…*]

# DESCRIPTION

**pass otp** extends the **pass**(1) utility with the **otp** command for adding OTP secrets, generating OTP codes, and displaying secret key URIs using the standard *otpauth://* scheme.

The token is the first line of the passfile that starts with *otpauth://*, optionally after an *otpauth:* or *otp:* key, as in *otp: otpauth://totp/...*. Other lines are kept unchanged.

If no *command* is specified, *command* defaults to **code**.

# COMMANDS

**pass otp code** [ `--clip`, `-c` ] [ `--quiet`, `-q` ] *pass-name*

: Generate and print an OTP code from the secret key stored in *pass-name* using **oathtool**(1). If `--clip` or `-c` is specified, do not print the code but instead copy it to the clipboard using **xclip**(1) and then restore the clipboard after 45 (or *PASSWORD_STORE_CLIP_TIME*) seconds. If `--quiet` or `-q` is specified, do not print the git update message to standard out. This command is alternatively named **show**.

**pass otp insert** [ `--force`, `-f` ] [ `--echo`, `-e` ] [ [ `--secret`, `-s` ] [ `--issuer`, `-i` *issuer* ] [ `--account`, `-a` *account* ] ] [ `--path`, `-p` *path-name* | *pass-name* ]

: Prompt for and insert a new OTP secret into the password store at *pass-name*.

  If `--secret` is specified, prompt for the *secret* value, assuming SHA1 algorithm, 30-second period, and 6 OTP digits. One or both of *issuer* and *account* must also be specified.

  If `--secret` is not specified, prompt for a key URI; see the documentation at <https://github.com/google/google-authenticator/wiki/Key-Uri-Format> for the key URI specification.

  The secret is consumed from stdin; specify `--echo` or `-e` to echo input when running this command interactively. If *pass-name* is not specified, convert the *issuer:accountname* URI label to a path in the form of *issuer/accountname*. Prompt before overwriting an existing secret, unless `--force` or `-f` is specified. This command is alternatively named **add**.

  `--path` specifies a path prefix to the generated path from the URI label. It cannot be combined with *pass-name*.

**pass otp append** [ `--force`, `-f` ] [ `--echo`, `-e` ] [ [ `--secret`, `-s` ] [ `--issuer`, `-i` *issuer* ] [ `--account`, `-a` *account* ] ] *pass-name*

: Append an OTP secret to the password stored in *pass-name*, preserving any existing lines.

  If `--secret` is specified, prompt for the *secret* value, assuming SHA1 algorithm, 30-second period, and 6 OTP digits. One or both of *issuer* and *account* must also be specified.

  If `--secret` is not specified, prompt for a key URI; see the documentation at <https://github.com/google/google-authenticator/wiki/Key-Uri-Format> for the key URI specification.

  The URI is consumed from stdin; specify `--echo` or `-e` to echo input when running this command interactively. Prompt before overwriting an existing secret, unless `--force` or `-f` is specified.

**pass otp uri** [ `--clip`, `-c` | `--qrcode`, `-q` ] *pass-name*

: Print the key URI stored in *pass-name* to stdout. If `--clip` or `-c` is specified, do not print the URI but instead copy it to the clipboard using **xclip**(1) and then restore the clipboard after 45 (or *PASSWORD_STORE_CLIP_TIME*) seconds. If `--qrcode` or `-q` is specified, do not print the URI but instead display a QR code using **qrencode**(1) either to the terminal or graphically if supported.

**pass otp validate** *uri*

: Test a URI string for validity according to the Key Uri Format: a label, a base32 *secret*, a *counter* for HOTP, and, when given, a positive *digits* and *period* and an *algorithm* among SHA1, SHA256 and SHA512. For more information about this format, see the documentation at <https://github.com/google/google-authenticator/wiki/Key-Uri-Format>.

# OPTIONS

**`version`, `--version`**

: Show version information.

**`help`, `-h`, `--help`**

: Show usage message.

# SEE ALSO

`pass(1)`, `qrencode(1)`, `zbarimg(1)`, `pass-import(1)`, `pass-update(1)`, `pass-audit(1)`

# COPYING

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
