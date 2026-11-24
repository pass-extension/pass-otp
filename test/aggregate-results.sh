#!/usr/bin/env bash
# pass otp - Password Store Extension (https://www.passwordstore.org/)
# Copyright (C) 2008-2012 Git project
# Copyright (C) 2017-2026 Alexandre PUJOL <alexandre@pujol.io>.
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Must be run from test/ after the test scripts.

# shellcheck disable=SC2094

_die() { echo "${@}" && exit 1; }
if [[ "$COVERAGE" == true ]]; then
	KCOV="$(command -v kcov)"
	[[ -e "$KCOV" ]] || _die "Could not find kcov command"
	mapfile -t COVERED < <(find "$TMP" -mindepth 1 -maxdepth 1 -type d -name '*.t')
	[[ ${#COVERED[@]} -gt 0 ]] || _die "No coverage data found in $TMP"
	"$KCOV" --merge "$TMP/kcov" "${COVERED[@]}"
	covered="$(jq -r '.percent_covered' "$TMP/kcov/kcov-merged/coverage.json")"
	printf "%s: %s%%\n" coverage "$covered"
fi

failed_tests=
fixed=0
success=0
failed=0
broken=0
total=0
for file in test-results/*.counts; do
	while read -r type value; do
		case $type in
		'')
			continue ;;
		fixed)
			fixed=$((fixed + value)) ;;
		success)
			success=$((success + value)) ;;
		failed)
			failed=$((failed + value))
			if test "$value" != 0; then
				test_name=$(expr "$file" : 'test-results/\(.*\)\.[0-9]*\.counts')
				failed_tests="$failed_tests $test_name"
			fi
			;;
		broken)
			broken=$((broken + value)) ;;
		total)
			total=$((total + value)) ;;
		esac
	done <"$file"
done

if test -n "$failed_tests"; then
	printf "\nfailed test(s):%s\n\n" "$failed_tests"
fi

printf "%-8s%d\n" fixed "$fixed"
printf "%-8s%d\n" success "$success"
printf "%-8s%d\n" failed "$failed"
printf "%-8s%d\n" broken "$broken"
printf "%-8s%d\n" total "$total"

# Fail the build on test failure
[[ "$failed" -eq 0 ]]
