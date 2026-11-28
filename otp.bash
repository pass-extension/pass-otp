#!/usr/bin/env bash
# pass otp - Password Store Extension (https://pass-extension.org/otp/)
# Copyright (C) 2017 Tad Fisher
# Copyright (C) 2026 Alexandre PUJOL <alexandre@pujol.io>.
# SPDX-License-Identifier: GPL-3.0-or-later

set -o pipefail

readonly EXTENSION_VERSION="1.2.0"
OATH=$(command -v oathtool)
OTPTOOL=$(command -v otptool)
readonly OATH OTPTOOL
readonly PASSAGE="${PASSAGE:-0}"

if [[ $PASSAGE == 1 ]]; then
  EXT="age"
else
  EXT="gpg"
fi

# Percent-encode a string, byte by byte (UTF-8 safe)
# $1: String to encode
# Return 0
# Print the encoded string on stdout
urlencode() {
  local LC_ALL=C i c
  for (( i = 0 ; i < ${#1} ; i++ )); do
    c=${1:i:1}
    case "$c" in
      [a-zA-Z0-9.~_-]) printf "%c" "$c";;
      *) printf '%%%.2X' "'$c"
    esac
  done
}

# Decode %XX sequences only: '+' and backslashes are kept as is, and an
# invalid '%' is left untouched
# $1: String to decode
# Return 0
# Print the decoded string on stdout
urldecode() {
  local LC_ALL=C s="$1" out="" byte i
  for (( i = 0 ; i < ${#s} ; i++ )); do
    if [[ ${s:i:3} =~ ^%[0-9A-Fa-f]{2}$ ]]; then
      printf -v byte '%b' "\\x${s:i+1:2}"
      out+="$byte"
      (( i += 2 ))
    else
      out+="${s:i:1}"
    fi
  done
  printf '%s' "$out"
}

# Parse a Key URI per: https://github.com/google/google-authenticator/wiki/Key-Uri-Format
# Vars are consumed by caller
# shellcheck disable=SC2034
otp_parse_uri() {
  local uri="$1" param
  otp_uri="" otp_type="" otp_secret="" otp_digits="" otp_algorithm=""
  otp_period="" otp_counter="" otp_issuer="" otp_accountname=""

  local pattern='^otpauth:\/\/(totp|hotp)(\/(([^:?]+)?(:([^:?]*))?)(:([0-9]+))?)?\?(.+)$'
  [[ "$uri" =~ $pattern ]] || die "Cannot parse OTP key URI"

  otp_uri=${BASH_REMATCH[0]}
  otp_type=${BASH_REMATCH[1]}

  otp_accountname=$(urldecode "${BASH_REMATCH[6]}")
  [[ -z $otp_accountname ]] && otp_accountname=$(urldecode "${BASH_REMATCH[4]}") || otp_issuer=$(urldecode "${BASH_REMATCH[4]}")
  [[ -z $otp_accountname ]] && die "Invalid key URI (missing accountname)"

  local p=${BASH_REMATCH[9]}
  local params
  local IFS=\&; read -r -a params <<< "$p" ; unset IFS

  pattern='^([^=]+)=(.+)$'
  for param in "${params[@]}"; do
    if [[ "$param" =~ $pattern ]]; then
      case ${BASH_REMATCH[1]} in
        secret) otp_secret=$(urldecode "${BASH_REMATCH[2]}") ;;
        digits) otp_digits=${BASH_REMATCH[2]} ;;
        algorithm) otp_algorithm=${BASH_REMATCH[2]} ;;
        period) otp_period=${BASH_REMATCH[2]} ;;
        counter) otp_counter=${BASH_REMATCH[2]} ;;
        issuer) otp_issuer=$(urldecode "${BASH_REMATCH[2]//+/ }") ;; # '+' is a space in a query
        *) ;;
      esac
    fi
  done

  [[ -z "$otp_secret" ]] && die "Invalid key URI (missing secret)"
  [[ "$otp_secret" =~ ^[A-Za-z2-7\ ]+=*$ ]] || die "Invalid key URI (secret is not base32)"

  pattern='^[0-9]+$'
  [[ "$otp_type" == 'hotp' ]] && [[ ! "$otp_counter" =~ $pattern ]] && die "Invalid key URI (missing counter)"
  [[ -z "$otp_digits" || "$otp_digits" =~ ^[1-9][0-9]*$ ]] || die "Invalid key URI (digits must be a positive number)"
  [[ -z "$otp_period" || "$otp_period" =~ ^[1-9][0-9]*$ ]] || die "Invalid key URI (period must be a positive number)"
  [[ -z "$otp_algorithm" || "${otp_algorithm^^}" =~ ^SHA(1|256|512)$ ]] || die "Invalid key URI (algorithm must be SHA1, SHA256 or SHA512)"
  return 0
}

otp_read_uri() {
  local uri prompt="$1" echo="$2"

  if [[ -t 0 ]]; then
    if [[ $echo -eq 0 ]]; then
      read -r -p "Enter otpauth:// URI for $prompt: " -s uri || exit 1
      echo
      read -r -p "Retype otpauth:// URI for $prompt: " -s uri_again || exit 1
      echo
      [[ "$uri" == "$uri_again" ]] || die "Error: the entered URIs do not match."
    else
      read -r -p "Enter otpauth:// URI for $prompt: " -e uri
    fi
  else
    read -r uri
  fi

  otp_parse_uri "$uri"
}

otp_read_secret() {
  local uri prompt="$1" echo="$2" issuer accountname separator
  [ ! "$3" = false ] && issuer="$(urlencode "$3")"
  [ ! "$4" = false ] && accountname="$(urlencode "$4")"
  [ -n "$issuer" ] && [ -n "$accountname" ] && separator=":"

  if [[ -t 0 ]]; then
    if [[ $echo -eq 0 ]]; then
      read -r -p "Enter secret for $prompt: " -s secret || exit 1
      echo
      read -r -p "Retype secret for $prompt: " -s secret_again || exit 1
      echo
      [[ "$secret" == "$secret_again" ]] || die "Error: the entered secrets do not match."
    else
        read -r -p "Enter secret for $prompt: " -e secret
    fi
  else
      read -r secret
  fi

  secret=$(printf '%s' "${secret//[[:space:]]/}" | tr '[:lower:]' '[:upper:]')
  secret=${secret%%=*} # Key URI Format: base32 padding should be omitted
  uri="otpauth://totp/${issuer}${separator}${accountname}?secret=${secret}"
  [ -n "$issuer" ] && uri="${uri}&issuer=${issuer}"
  otp_parse_uri "$uri"
}

# Replace the first otpauth:// line of a passfile content
# $1: Passfile content
# $2: New otpauth:// URI, appended when $1 has no otpauth:// line
# Return 0
# Print the new content on stdout, other lines (blank ones included) kept verbatim
otp_replace_uri() {
  local line out="" found=0
  while IFS= read -r line; do
    if [[ $found -eq 0 && "$line" == otpauth://* ]]; then
      line="$2"
      found=1
    fi
    out+="$line"$'\n'
  done < <(printf '%s\n' "$1")
  [[ $found -eq 0 ]] && out+="$2"$'\n'
  printf '%s' "${out%$'\n'}"
}

# Decrypt a passfile into the global otp_contents, die on failure
# $1: pass-name
otp_show() {
  local path="${1%/}"
  local passfile="$PREFIX/$path.$EXT"

  check_sneaky_paths "$path"
  [[ -f $passfile ]] || die "$path: passfile not found."
  if [[ $PASSAGE == 1 ]]; then
    otp_contents=$($AGE -d -i "$IDENTITIES_FILE" "$passfile") || die "$path: decryption failed."
  else
    otp_contents=$($GPG -d "${GPG_OPTS[@]}" "$passfile") || die "$path: decryption failed."
  fi
}

# Encrypt contents into a passfile and commit it, die on failure
# $1: pass-name, $2: contents, $3: commit message, $4: 1 to silence git
otp_insert() {
  local path="${1%/}" contents="$2" message="$3" quiet="$4"
  local passfile="$PREFIX/$path.$EXT"

  check_sneaky_paths "$path"
  set_git "$passfile"

  mkdir -p "$PREFIX/$(dirname "$path")"
  if [[ $PASSAGE == 1 ]]; then
    set_age_recipients "$(dirname "$path")"
    printf '%s\n' "$contents" | $AGE -e "${AGE_RECIPIENT_ARGS[@]}" -o "$passfile" || die "OTP secret encryption aborted"
  else
    set_gpg_recipients "$(dirname "$path")"
    printf '%s\n' "$contents" | $GPG -e "${GPG_RECIPIENT_ARGS[@]}" -o "$passfile" "${GPG_OPTS[@]}" || die "OTP secret encryption aborted."
  fi

  if [[ "$quiet" -eq 1 ]]; then
    git_add_file "$passfile" "$message" 1>/dev/null
  else
    git_add_file "$passfile" "$message"
  fi
}

cmd_otp_version() {
    cat <<-_EOF
$PROGRAM $COMMAND $EXTENSION_VERSION - Manage one-time-password (OTP) tokens.
_EOF
}

cmd_otp_usage() {
	cmd_otp_version
    echo
    cat <<-_EOF
Usage:

    $PROGRAM $COMMAND [code] [--clip,-c] pass-name
        Generate an OTP code and optionally put it on the clipboard.
        If put on the clipboard, it will be cleared in $CLIP_TIME seconds.

    $PROGRAM $COMMAND insert [--force,-f] [--echo,-e]
            [[--secret, -s] [--issuer,-i issuer] [--account,-a account]]
            [--path,-p path-name | pass-name]
        Prompt for and insert a new OTP key.

        If 'secret' is specified, prompt for the OTP secret, assuming SHA1
        algorithm, 30-second period, and 6 OTP digits; one of 'issuer' or
        'account' is also required. Otherwise, prompt for a key URI; if
        'pass-name' is not supplied, use the URI label, under 'path-name' if
        given.

        Optionally, echo the input. Prompt before overwriting existing URI
        unless forced. This command accepts input from stdin.

    $PROGRAM $COMMAND append [--force,-f] [--echo,-e]
            [[--secret, -s] [--issuer,-i issuer] [--account,-a account]]
            pass-name
        Appends an OTP key URI to an existing password file.

        If 'secret' is specified, prompt for the OTP secret, assuming SHA1
        algorithm, 30-second period, and 6 OTP digits; one of 'issuer' or
        'account' is also required. Otherwise, prompt for a key URI.

        Optionally, echo the input. Prompt before overwriting an existing URI
        unless forced. This command accepts input from stdin.

    $PROGRAM $COMMAND uri [--clip,-c] [--qrcode,-q] pass-name
        Display the key URI stored in pass-name. Optionally, put it on the
        clipboard, or display a QR code.

    $PROGRAM $COMMAND validate uri
        Test if the given URI is a valid OTP key URI.

More information may be found in the pass-otp(1) man page.
_EOF
  exit 0
}

cmd_otp_insert() {
  local opts force=0 echo=0 from_secret=0 issuer account path_prefix
  opts="$($GETOPT -o fesi:a:p: -l force,echo,secret,issuer:,account:,path: -n "$PROGRAM" -- "$@")"
  local err=$?
  eval set -- "$opts"
  while true; do case $1 in
    -f|--force) force=1; shift ;;
    -e|--echo) echo=1; shift ;;
    -s|--secret) from_secret=1; shift;;
    -i|--issuer) issuer=$2; shift; shift;;
    -a|--account) account=$2;  shift; shift;;
    -p|--path) path_prefix=$2;  shift; shift;;
    --) shift; break ;;
  esac done

  [[ $err -ne 0 || $# -gt 1 ]] && die "Usage: $PROGRAM $COMMAND insert [--force,-f] [--echo,-e] [--secret, -s] [--issuer,-i issuer] [--account,-a account] [--path,-p path-name | pass-name]"
  [[ -n "$path_prefix" && $# -eq 1 ]] && die "Error: --path only applies to the path built from the URI label, not to a pass-name."

  local prompt path uri
  if [[ $# -eq 1 ]]; then
    path="${1%/}"
    prompt="$path"
  else
    prompt="this token"
  fi

  if [[ $from_secret -eq 1 ]]; then
    [ -z "$issuer" ] && issuer=false
    [ -z "$account" ] && account=false

    [ "$issuer" = false ] && [ "$account" = false ] && die "Missing one of either '--issuer' or '--account'"

    otp_read_secret "$prompt" $echo "$issuer" "$account"
  else
    otp_read_uri "$prompt" $echo
  fi

  if [[ -z "$path" ]]; then
    [[ -n "$otp_issuer" ]] && path+="$otp_issuer/"
    path+="$otp_accountname"
    if [ -n "$path_prefix" ]; then
      path="${path_prefix%/}/$path"
    fi
  fi
  check_sneaky_paths "$path"
  [[ $# -eq 0 ]] && yesno "Insert into $path?"

  local passfile="$PREFIX/$path.$EXT"
  [[ $force -eq 0 && -e $passfile ]] && yesno "An entry already exists for $path. Overwrite it?"

  otp_insert "$path" "$otp_uri" "Add OTP secret for $path to store."
}

cmd_otp_append() {
  local opts force=0 echo=0 from_secret=0
  opts="$($GETOPT -o fesi:a: -l force,echo,secret,issuer:,account: -n "$PROGRAM" -- "$@")"
  local err=$?
  eval set -- "$opts"
  while true; do case $1 in
    -f|--force) force=1; shift ;;
    -e|--echo) echo=1; shift ;;
    -s|--secret) from_secret=1; shift;;
    -i|--issuer) issuer=$2; shift; shift;;
    -a|--account) account=$2;  shift; shift;;
    --) shift; break ;;
  esac done

  [[ $err -ne 0 || $# -ne 1 ]] && die "Usage: $PROGRAM $COMMAND append [--force,-f] [--echo,-e] [--secret, -s] [--issuer,-i issuer] [--account,-a account] pass-name"

  local uri
  local path="${1%/}"
  local prompt="$path"
  otp_show "$path"

  local existing=0
  [[ $'\n'"$otp_contents" == *$'\n'otpauth://* ]] && existing=1

  [[ $force -eq 0 && $existing -eq 1 ]] && yesno "An OTP secret already exists for $path. Overwrite it?"

  if [[ $from_secret -eq 1 ]]; then
    [ -z "$issuer" ] && issuer=false
    [ -z "$account" ] && account=false

    [ "$issuer" = false ] && [ "$account" = false ] && die "Missing one of either '--issuer' or '--account'"

    otp_read_secret "$prompt" $echo "$issuer" "$account"
  else
    otp_read_uri "$prompt" $echo
  fi

  local replaced
  replaced=$(otp_replace_uri "$otp_contents" "$otp_uri")

  local message
  if [[ $existing -eq 1 ]]; then
    message="Replace OTP secret for $path."
  else
    message="Append OTP secret for $path."
  fi

  otp_insert "$path" "$replaced" "$message"
}

cmd_otp_code() {
  [[ -z "$OATH" && -z "$OTPTOOL" ]] && die "Failed to generate OTP code: oathtool or otptool is not installed."

  local opts clip=0 quiet=0
  opts="$($GETOPT -o cq -l clip,quiet -n "$PROGRAM" -- "$@")"
  local err=$?
  eval set -- "$opts"
  while true; do case $1 in
    -c|--clip) clip=1; shift ;;
    -q|--quiet) quiet=1; shift ;;
    --) shift; break ;;
  esac done

  [[ $err -ne 0 || $# -ne 1 ]] && die "Usage: $PROGRAM $COMMAND [--clip,-c] [--quiet,-q] pass-name"

  local path="${1%/}" line
  otp_show "$path"
  while IFS= read -r line; do
    if [[ "$line" == otpauth://* ]]; then
      otp_parse_uri "$line"
      break
    fi
  done < <(printf '%s\n' "$otp_contents")

  # Select the generator: oathtool for stdin secrets, else otptool
  local generator=oath-argv
  if [[ -n "$OATH" ]] && "$OATH" - <<< 00 >/dev/null 2>&1; then
    generator=oath-stdin
  elif [[ -n "$OTPTOOL" ]]; then
    generator=otptool
  fi

  local cmd uri="$otp_uri" counter
  case "$otp_type" in
    totp)
      cmd=("$OATH" --base32)
      [[ -z "$otp_algorithm" ]] && cmd+=(--totp)
      [[ -n "$otp_algorithm" ]] && cmd+=(--totp="${otp_algorithm,,}")
      [[ -n "$otp_period" ]] && cmd+=(--time-step-size="$otp_period"s)
      [[ -n "$otp_digits" ]] && cmd+=(--digits="$otp_digits")
      ;;

    hotp)
      counter=$((10#$otp_counter + 1)) # base 10: a leading zero is not octal
      # Same counter for every generator: otptool reads it from the URI
      [[ "$uri" =~ ^(.*[?\&]counter=)[0-9]+(.*)$ ]] && uri="${BASH_REMATCH[1]}$counter${BASH_REMATCH[2]}"
      cmd=("$OATH" --base32 --hotp --counter="$counter")
      [[ -n "$otp_digits" ]] && cmd+=(--digits="$otp_digits")
      ;;

    *)
      die "$path: OTP secret not found."
      ;;
  esac

  local out
  case "$generator" in
    oath-stdin) out=$(printf '%s\n' "$otp_secret" | "${cmd[@]}" -) ;;
    oath-argv) out=$("${cmd[@]}" "$otp_secret") ;;
    otptool) out=$("$OTPTOOL" "$uri") ;;
  esac || die "$path: failed to generate OTP code."

  if [[ "$otp_type" == "hotp" ]]; then
    # Increment HOTP counter in-place
    local replaced
    replaced=$(otp_replace_uri "$otp_contents" "$uri")

    otp_insert "$path" "$replaced" "Increment HOTP counter for $path." "$quiet"
  fi

  if [[ $clip -ne 0 ]]; then
    clip "$out" "OTP code for $path"
  else
    echo "$out"
  fi
}

cmd_otp_uri() {
  local qrcode=0 clip=0
  opts="$($GETOPT -o cq -l clip,qrcode -n "$PROGRAM" -- "$@")"
  local err=$?
  eval set -- "$opts"
  while true; do case $1 in
    -q|--qrcode) qrcode=1; shift ;;
    -c|--clip) clip=1; shift ;;
    --) shift; break ;;
  esac done

  [[ $err -ne 0 || $# -ne 1 ]] && die "Usage: $PROGRAM $COMMAND uri [--clip,-c | --qrcode,-q] pass-name"

  local path="${1%/}"
  otp_show "$path"

  while IFS= read -r line; do
    if [[ "$line" == otpauth://* ]]; then
      otp_parse_uri "$line"
      break
    fi
  done < <(printf '%s\n' "$otp_contents")
  [[ -z "$otp_uri" ]] && die "$path: OTP secret not found."

  if [[ $clip -eq 1 ]]; then
    clip "$otp_uri" "OTP key URI for $path"
  elif [[ $qrcode -eq 1 ]]; then
    qrcode "$otp_uri" "OTP key URI for $path"
  else
    echo "$otp_uri"
  fi
}

cmd_otp_validate() {
  otp_parse_uri "$1"
}

case "$1" in
  help|--help|-h) shift; cmd_otp_usage "$@" ;;
  version|--version) shift; cmd_otp_version "$@" ;;
  insert|add)     shift; cmd_otp_insert "$@" ;;
  append)         shift; cmd_otp_append "$@" ;;
  uri)            shift; cmd_otp_uri "$@" ;;
  validate)       shift; cmd_otp_validate "$@" ;;
  code|show)      shift; cmd_otp_code "$@" ;;
  *)                     cmd_otp_code "$@" ;;
esac
exit 0
