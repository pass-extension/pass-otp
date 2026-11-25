# Sharness test framework.
#
# Copyright (c) 2011-2012 Mathias Lafeldt
# Copyright (c) 2005-2012 Git project
# Copyright (c) 2005-2012 Junio C Hamano
# Copyright (c) 2019-2023 Felipe Contreras
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses/ .

if test -n "${ZSH_VERSION-}"
then
	# shellcheck disable=SC2296
	SHARNESS_SOURCE=${(%):-%x}
	emulate sh -o POSIX_ARGZERO
else
	# shellcheck disable=SC3028
	SHARNESS_SOURCE=${BASH_SOURCE-$0}
fi

# Public: Current version of Sharness.
SHARNESS_VERSION="1.2.1"
export SHARNESS_VERSION

: "${SHARNESS_TEST_EXTENSION:=t}"
# Public: The file extension for tests.  By default, it is set to "t".
export SHARNESS_TEST_EXTENSION

: "${SHARNESS_TEST_DIRECTORY:=$(dirname "$0")}"
# ensure that SHARNESS_TEST_DIRECTORY is an absolute path so that it
# is valid even if the current working directory is changed
SHARNESS_TEST_DIRECTORY=$(cd "$SHARNESS_TEST_DIRECTORY" && pwd) || exit 1
# Public: Root directory containing tests. Tests can override this variable,
# e.g. for testing Sharness itself.
export SHARNESS_TEST_DIRECTORY

: "${SHARNESS_TEST_SRCDIR:=$(cd "$(dirname "$SHARNESS_SOURCE")" && pwd)}"
# Public: Source directory of test code and sharness library.
# This directory may be different from the directory in which tests are
# being run.
export SHARNESS_TEST_SRCDIR

: "${SHARNESS_TEST_OUTDIR:=$SHARNESS_TEST_DIRECTORY}"
# Public: Directory where the output of the tests should be stored (i.e.
# trash directories).
export SHARNESS_TEST_OUTDIR

#  Reset TERM to original terminal if found, otherwise save original TERM
[ -z "$SHARNESS_ORIG_TERM" ] &&
		SHARNESS_ORIG_TERM="$TERM" ||
		TERM="$SHARNESS_ORIG_TERM"
# Public: The unsanitized TERM under which sharness is originally run
export SHARNESS_ORIG_TERM

# Export SHELL_PATH
: "${SHELL_PATH:=/bin/sh}"
export SHELL_PATH

# if --tee was passed, write the output not only to the terminal, but
# additionally to the file test-results/$BASENAME.out, too.
case "$SHARNESS_TEST_TEE_STARTED, $* " in
done,*)
	# do not redirect again
	;;
*' --tee '*|*' --verbose-log '*)
	mkdir -p "$SHARNESS_TEST_OUTDIR/test-results"
	BASE="$SHARNESS_TEST_OUTDIR/test-results/$(basename "$0" ".$SHARNESS_TEST_EXTENSION")"

	# Make this filename available to the sub-process in case it is using
	# --verbose-log.
	SHARNESS_TEST_TEE_OUTPUT_FILE="$BASE.out"
	export SHARNESS_TEST_TEE_OUTPUT_FILE

	# Truncate before calling "tee -a" to get rid of the results
	# from any previous runs.
	: >"$SHARNESS_TEST_TEE_OUTPUT_FILE"

	(SHARNESS_TEST_TEE_STARTED="done" ${SHELL_PATH} "$0" "$@" 2>&1;
	 echo $? >"$BASE.exit") | tee -a "$SHARNESS_TEST_TEE_OUTPUT_FILE"
	test "$(cat "$BASE.exit")" = 0
	exit
	;;
esac

# For repeatability, reset the environment to a known state.
# TERM is sanitized below, after saving color control sequences.
LANG=C
LC_ALL=C
PAGER="cat"
TZ=UTC
EDITOR=:
export LANG LC_ALL PAGER TZ EDITOR
unset VISUAL CDPATH GREP_OPTIONS

[ "x$TERM" != "xdumb" ] && (
		[ -t 1 ] &&
		tput bold >/dev/null 2>&1 &&
		tput setaf 1 >/dev/null 2>&1 &&
		tput sgr0 >/dev/null 2>&1
	) &&
	color=t

while test "$#" -ne 0; do
	case "$1" in
	-d|--d|--de|--deb|--debu|--debug)
		debug=t; shift ;;
	-i|--i|--im|--imm|--imme|--immed|--immedi|--immedia|--immediat|--immediate)
		immediate=t; shift ;;
	-l|--l|--lo|--lon|--long|--long-|--long-t|--long-te|--long-tes|--long-test|--long-tests)
		TEST_LONG=t; export TEST_LONG; shift ;;
	--in|--int|--inte|--inter|--intera|--interac|--interact|--interacti|--interactiv|--interactive|--interactive-|--interactive-t|--interactive-te|--interactive-tes|--interactive-test|--interactive-tests):
		TEST_INTERACTIVE=t; export TEST_INTERACTIVE; verbose=t; shift ;;
	-h|--h|--he|--hel|--help)
		help=t; shift ;;
	-v|--v|--ve|--ver|--verb|--verbo|--verbos|--verbose)
		verbose=t; shift ;;
	-q|--q|--qu|--qui|--quie|--quiet)
		# Ignore --quiet under a TAP::Harness. Saying how many tests
		# passed without the ok/not ok details is always an error.
		test -z "$HARNESS_ACTIVE" && quiet=t; shift ;;
	--chain-lint)
		chain_lint=t; shift ;;
	--no-chain-lint)
		chain_lint=; shift ;;
	--no-color)
		color=; shift ;;
	--tee)
		shift ;; # was handled already
	--root=*)
		root=$(expr "z$1" : 'z[^=]*=\(.*\)')
		shift ;;
	-x)
		trace=t
		shift ;;
	--verbose-log)
		verbose_log=t
		shift ;;
	*)
		echo "error: unknown test option '$1'" >&2; exit 1 ;;
	esac
done

if test -n "$color"; then
	# Save the color control sequences now rather than run tput
	# each time say_color() is called.  This is done for two
	# reasons:
	#   * TERM will be changed to dumb
	#   * HOME will be changed to a temporary directory and tput
	#     might need to read ~/.terminfo from the original HOME
	#     directory to get the control sequences
	# Note:  This approach assumes the control sequences don't end
	# in a newline for any terminal of interest (command
	# substitutions strip trailing newlines).  Given that most
	# (all?) terminals in common use are related to ECMA-48, this
	# shouldn't be a problem.
	say_color_error=$(tput bold; tput setaf 1) # bold red
	say_color_skip=$(tput setaf 4) # blue
	say_color_warn=$(tput setaf 3) # brown/yellow
	say_color_pass=$(tput setaf 2) # green
	say_color_info=$(tput setaf 6) # cyan
	say_color_reset=$(tput sgr0)
	say_color_raw="" # no formatting for normal text
	say_color() {
		test -z "$1" && test -n "$quiet" && return
		case "$1" in
			error) say_color_color=$say_color_error ;;
			skip) say_color_color=$say_color_skip ;;
			warn) say_color_color=$say_color_warn ;;
			pass) say_color_color=$say_color_pass ;;
			info) say_color_color=$say_color_info ;;
			*) say_color_color=$say_color_raw ;;
		esac
		shift
		printf '%s%s%s\n' "$say_color_color" "$*" "$say_color_reset"
	}
else
	say_color() {
		test -z "$1" && test -n "$quiet" && return
		shift
		printf '%s\n' "$*"
	}
fi

: "${test_untraceable:=}"
# Public: When set to a non-empty value, the current test will not be
# traced, unless it's run with a Bash version supporting
# BASH_XTRACEFD, i.e. v4.1 or later.
export test_untraceable

if test -n "$trace" && test -n "$test_untraceable"
then
	# '-x' tracing requested, but this test script can't be reliably
	# traced, unless it is run with a Bash version supporting
	# BASH_XTRACEFD (introduced in Bash v4.1).
	#
	# Perform this version check _after_ the test script was
	# potentially re-executed with $TEST_SHELL_PATH for '--tee' or
	# '--verbose-log', so the right shell is checked and the
	# warning is issued only once.
	if test -n "$BASH_VERSION" && eval '
	     test ${BASH_VERSINFO[0]} -gt 4 || {
	       test ${BASH_VERSINFO[0]} -eq 4 &&
	       test ${BASH_VERSINFO[1]} -ge 1
	     }
	   '
	then
		: Executed by a Bash version supporting BASH_XTRACEFD.  Good.
	else
		echo >&2 "warning: ignoring -x; '$0' is untraceable without BASH_XTRACEFD"
		trace=
	fi
fi
if test -n "$trace" && test -z "$verbose_log"
then
	verbose=t
fi

TERM=dumb
export TERM

error() {
	say_color error "error: $*"
	EXIT_OK=t
	exit 1
}

say() {
	say_color info "$*"
}

test -n "${test_description:-}" || error "Test script did not set test_description."

if test "$help" = "t"; then
	echo "$test_description"
	exit 0
fi

exec 5>&1
exec 6<&0
if test "$verbose_log" = "t"
then
	exec 3>>"$SHARNESS_TEST_TEE_OUTPUT_FILE" 4>&3
elif test "$verbose" = "t"
then
	exec 4>&2 3>&1
else
	exec 4>/dev/null 3>/dev/null
fi

# Send any "-x" output directly to stderr to avoid polluting tests
# which capture stderr. We can do this unconditionally since it
# has no effect if tracing isn't turned on.
#
# Note that this sets up the trace fd as soon as we assign the variable, so it
# must come after the creation of descriptor 4 above. Likewise, we must never
# unset this, as it has the side effect of closing descriptor 4, which we
# use to show verbose tests to the user.
#
# Note also that we don't need or want to export it. The tracing is local to
# this shell, and we would not want to influence any shells we exec.
BASH_XTRACEFD=4

# Public: The current test number, starting at 0.
SHARNESS_TEST_NB=0
export SHARNESS_TEST_NB

die() {
	code=$?
	if test -n "$EXIT_OK"; then
		exit $code
	else
		echo >&5 "FATAL: Unexpected exit with code $code"
		exit 1
	fi
}

EXIT_OK=
trap 'die' EXIT

test_prereq=
missing_prereq=

test_failure=0
test_fixed=0
test_broken=0
test_success=0

if test -e "$SHARNESS_TEST_SRCDIR/lib-sharness/functions.sh"
then
	. "$SHARNESS_TEST_SRCDIR/lib-sharness/functions.sh"
fi

# You are not expected to call test_ok_ and test_failure_ directly, use
# the text_expect_* functions instead.

test_ok_() {
	test_success=$((test_success + 1))
	say_color "" "ok $SHARNESS_TEST_NB - $*"
}

test_failure_() {
	test_failure=$((test_failure + 1))
	say_color error "not ok $SHARNESS_TEST_NB - $1"
	shift
	echo "$@" | sed -e 's/^/#	/'
	test "$immediate" = "" || { EXIT_OK=t; exit 1; }
}

test_known_broken_ok_() {
	test_fixed=$((test_fixed + 1))
	say_color error "ok $SHARNESS_TEST_NB - $* # TODO known breakage vanished"
}

test_known_broken_failure_() {
	test_broken=$((test_broken + 1))
	say_color warn "not ok $SHARNESS_TEST_NB - $* # TODO known breakage"
}

want_trace () {
	test "$trace" = t && {
		test "$verbose" = t || test "$verbose_log" = t
	}
}

# This is a separate function because some tests use
# "return" to end a test_expect_success block early
# (and we want to make sure we run any cleanup like
# "set +x").
test_eval_inner_ () {
	# Do not add anything extra (including LF) after '$*'
	eval "
		want_trace && set -x
		$*"
}

test_eval_x_ () {
	# If "-x" tracing is in effect, then we want to avoid polluting stderr
	# with non-test commands. But once in "set -x" mode, we cannot prevent
	# the shell from printing the "set +x" to turn it off (nor the saving
	# of $? before that). But we can make sure that the output goes to
	# /dev/null.
	#
	# There are a few subtleties here:
	#
	#   - we have to redirect descriptor 4 in addition to 2, to cover
	#     BASH_XTRACEFD
	#
	#   - the actual eval has to come before the redirection block (since
	#     it needs to see descriptor 4 to set up its stderr)
	#
	#   - likewise, any error message we print must be outside the block to
	#     access descriptor 4
	#
	#   - checking $? has to come immediately after the eval, but it must
	#     be _inside_ the block to avoid polluting the "set -x" output
	#

	test_eval_inner_ "$@" </dev/null >&3 2>&4
	{
		test_eval_ret_=$?
		if want_trace
		then
			set +x
		fi
	} 2>/dev/null 4>&2

	if test "$test_eval_ret_" != 0 && want_trace
	then
		say_color error >&4 "error: last command exited with \$?=$test_eval_ret_"
	fi
	return $test_eval_ret_
}

test_eval_() {
	case ",$test_prereq," in
	*,INTERACTIVE,*)
		eval "$*"
		;;
	*)
		test_eval_x_ "$@"
		;;
	esac
}

test_run_() {
	test_cleanup=:
	expecting_failure=$2
	test_eval_ "$1"
	eval_ret=$?

	if test "$chain_lint" = "t"; then
		# turn off tracing for this test-eval, as it simply creates
		# confusing noise in the "-x" output
		trace_tmp=$trace
		trace=
		# 117 is magic because it is unlikely to match the exit
		# code of other programs
		test_eval_ "(exit 117) && $1"
		if test "$?" != 117; then
			error "bug in the test script: broken &&-chain: $1"
		fi
		trace=$trace_tmp
	fi

	if test -z "$immediate" || test $eval_ret = 0 ||
	   test -n "$expecting_failure" && test "$test_cleanup" != ":"
	then
		test_eval_ "$test_cleanup"
	fi
	if test "$verbose" = "t" && test -n "$HARNESS_ACTIVE"; then
		echo ""
	fi
	return "$eval_ret"
}

test_skip_() {
	SHARNESS_TEST_NB=$((SHARNESS_TEST_NB + 1))
	to_skip=
	for skp in $SKIP_TESTS; do
		# shellcheck disable=SC2254
		case $this_test.$SHARNESS_TEST_NB in
		$skp)
			to_skip=t
			break
		esac
	done
	if test -z "$to_skip" && test -n "$test_prereq" && ! test_have_prereq "$test_prereq"; then
		to_skip=t
	fi
	case "$to_skip" in
	t)
		of_prereq=
		if test "$missing_prereq" != "$test_prereq"; then
			of_prereq=" of $test_prereq"
		fi

		say_color skip >&3 "skipping test: $*"
		say_color skip "ok $SHARNESS_TEST_NB # skip $1 (missing $missing_prereq${of_prereq})"
		: true
		;;
	*)
		false
		;;
	esac
}

remove_trash_() {
	test -d "$remove_trash" && (
		cd "$(dirname "$remove_trash")" &&
			rm -rf "$(basename "$remove_trash")"
	)
}

# Public: Run test commands and expect them to succeed.
#
# When the test passed, an "ok" message is printed and the number of successful
# tests is incremented. When it failed, a "not ok" message is printed and the
# number of failed tests is incremented.
#
# With --immediate, exit test immediately upon the first failed test.
#
# Usually takes two arguments:
# $1 - Test description
# $2 - Commands to be executed.
#
# With three arguments, the first will be taken to be a prerequisite:
# $1 - Comma-separated list of test prerequisites. The test will be skipped if
#      not all of the given prerequisites are set. To negate a prerequisite,
#      put a "!" in front of it.
# $2 - Test description
# $3 - Commands to be executed.
#
# Examples
#
#   test_expect_success \
#       'git-write-tree should be able to write an empty tree.' \
#       'tree=$(git-write-tree)'
#
#   # Test depending on one prerequisite.
#   test_expect_success TTY 'git --paginate rev-list uses a pager' \
#       ' ... '
#
#   # Multiple prerequisites are separated by a comma.
#   test_expect_success PERL,PYTHON 'yo dawg' \
#       ' test $(perl -E 'print eval "1 +" . qx[python -c "print 2"]') == "4" '
#
# Returns nothing.
test_expect_success() {
	test "$#" = 3 && { test_prereq=$1; shift; } || test_prereq=
	test "$#" = 2 || error "bug in the test script: not 2 or 3 parameters to test_expect_success"
	export test_prereq
	if ! test_skip_ "$@"; then
		say >&3 "expecting success: $2"
		if test_run_ "$2"; then
			test_ok_ "$1"
		else
			test_failure_ "$@"
		fi
	fi
	echo >&3 ""
}

# Public: Run test commands and expect them to fail. Used to demonstrate a known
# breakage.
#
# This is NOT the opposite of test_expect_success, but rather used to mark a
# test that demonstrates a known breakage.
#
# When the test passed, an "ok" message is printed and the number of fixed tests
# is incremented. When it failed, a "not ok" message is printed and the number
# of tests still broken is incremented.
#
# Failures from these tests won't cause --immediate to stop.
#
# Usually takes two arguments:
# $1 - Test description
# $2 - Commands to be executed.
#
# With three arguments, the first will be taken to be a prerequisite:
# $1 - Comma-separated list of test prerequisites. The test will be skipped if
#      not all of the given prerequisites are set. To negate a prerequisite,
#      put a "!" in front of it.
# $2 - Test description
# $3 - Commands to be executed.
#
# Returns nothing.
test_expect_failure() {
	test "$#" = 3 && { test_prereq=$1; shift; } || test_prereq=
	test "$#" = 2 || error "bug in the test script: not 2 or 3 parameters to test_expect_failure"
	export test_prereq
	if ! test_skip_ "$@"; then
		say >&3 "checking known breakage: $2"
		if test_run_ "$2" expecting_failure; then
			test_known_broken_ok_ "$1"
		else
			test_known_broken_failure_ "$1"
		fi
	fi
	echo >&3 ""
}

# Public: Run test commands and expect anything from them. Used when a
# test is not stable or not finished for some reason.
#
# When the test passed, an "ok" message is printed, but the number of
# fixed tests is not incremented.
#
# When it failed, a "not ok ... # TODO known breakage" message is
# printed, and the number of tests still broken is incremented.
#
# Failures from these tests won't cause --immediate to stop.
#
# Usually takes two arguments:
# $1 - Test description
# $2 - Commands to be executed.
#
# With three arguments, the first will be taken to be a prerequisite:
# $1 - Comma-separated list of test prerequisites. The test will be skipped if
#      not all of the given prerequisites are set. To negate a prerequisite,
#      put a "!" in front of it.
# $2 - Test description
# $3 - Commands to be executed.
#
# Returns nothing.
test_expect_unstable() {
	test "$#" = 3 && { test_prereq=$1; shift; } || test_prereq=
	test "$#" = 2 || error "bug in the test script: not 2 or 3 parameters to test_expect_unstable"
	export test_prereq
	if ! test_skip_ "$@"; then
		say >&3 "checking unstable test: $2"
		if test_run_ "$2" unstable; then
			test_ok_ "$1"
		else
			test_known_broken_failure_ "$1"
		fi
	fi
	echo >&3 ""
}

# Public: Summarize test results and exit with an appropriate error code.
#
# Must be called at the end of each test script.
#
# Can also be used to stop tests early and skip all remaining tests. For this,
# set skip_all to a string explaining why the tests were skipped before calling
# test_done.
#
# Examples
#
#   # Each test script must call test_done at the end.
#   test_done
#
#   # Skip all remaining tests if prerequisite is not set.
#   if ! test_have_prereq PERL; then
#       skip_all='skipping perl interface tests, perl not available'
#       test_done
#   fi
#
# Returns 0 if all tests passed or 1 if there was a failure.
# shellcheck disable=SC2154,SC2034
test_done() {
	EXIT_OK=t

	if test -z "$HARNESS_ACTIVE"; then
		test_results_dir="$SHARNESS_TEST_OUTDIR/test-results"
		mkdir -p "$test_results_dir"
		test_results_path="$test_results_dir/$this_test.$$.counts"

		cat >>"$test_results_path" <<-EOF
		total $SHARNESS_TEST_NB
		success $test_success
		fixed $test_fixed
		broken $test_broken
		failed $test_failure

		EOF
	fi

	if test "$test_fixed" != 0; then
		say_color error "# $test_fixed known breakage(s) vanished; please update test(s)"
	fi
	if test "$test_broken" != 0; then
		say_color warn "# still have $test_broken known breakage(s)"
	fi
	if test "$test_broken" != 0 || test "$test_fixed" != 0; then
		test_remaining=$((SHARNESS_TEST_NB - test_broken - test_fixed))
		msg="remaining $test_remaining test(s)"
	else
		test_remaining=$SHARNESS_TEST_NB
		msg="$SHARNESS_TEST_NB test(s)"
	fi

	case "$test_failure" in
	0)
		# Maybe print SKIP message
		check_skip_all_
		if test "$test_remaining" -gt 0; then
			say_color pass "# passed all $msg"
		fi
		say "1..$SHARNESS_TEST_NB$skip_all"

		test_eval_ "$final_cleanup"

		remove_trash_

		exit 0 ;;

	*)
		say_color error "# failed $test_failure among $msg"
		say "1..$SHARNESS_TEST_NB"

		exit 1 ;;

	esac
}

: "${SHARNESS_BUILD_DIRECTORY:="$SHARNESS_TEST_DIRECTORY/.."}"
# Public: Build directory that will be added to PATH. By default, it is set to
# the parent directory of SHARNESS_TEST_DIRECTORY.
export SHARNESS_BUILD_DIRECTORY
PATH="$SHARNESS_BUILD_DIRECTORY:$PATH"
export PATH

# Public: Path to test script currently executed.
SHARNESS_TEST_FILE="$0"
export SHARNESS_TEST_FILE

# Prepare test area.
SHARNESS_TRASH_DIRECTORY="trash directory.$(basename "$SHARNESS_TEST_FILE" ".$SHARNESS_TEST_EXTENSION")"
test -n "$root" && SHARNESS_TRASH_DIRECTORY="$root/$SHARNESS_TRASH_DIRECTORY"
case "$SHARNESS_TRASH_DIRECTORY" in
/*) ;; # absolute path is good
 *) SHARNESS_TRASH_DIRECTORY="$SHARNESS_TEST_OUTDIR/$SHARNESS_TRASH_DIRECTORY" ;;
esac
test "$debug" = "t" || remove_trash="$SHARNESS_TRASH_DIRECTORY"
rm -rf "$SHARNESS_TRASH_DIRECTORY" || {
	EXIT_OK=t
	echo >&5 "FATAL: Cannot prepare test area"
	exit 1
}


#
#  Load any extensions in $testdir/sharness.d/*.sh
#
if test -d "${SHARNESS_TEST_DIRECTORY}/sharness.d"
then
	for file in "${SHARNESS_TEST_DIRECTORY}"/sharness.d/*.sh
	do
		# Ensure glob was not an empty match:
		test -e "${file}" || break

		if test -n "$debug"
		then
			echo >&5 "sharness: loading extensions from ${file}"
		fi
		# shellcheck disable=SC1090
		. "${file}"
		if test $? != 0
		then
			echo >&5 "sharness: Error loading ${file}. Aborting."
			exit 1
		fi
	done
fi

# Public: Empty trash directory, the test area, provided for each test. The HOME
# variable is set to that directory too.
export SHARNESS_TRASH_DIRECTORY

HOME="$SHARNESS_TRASH_DIRECTORY"
export HOME

# shellcheck disable=SC3028
if [ "$OSTYPE" = msys ]; then
	USERPROFILE="$SHARNESS_TRASH_DIRECTORY"
	export USERPROFILE
fi

mkdir -p "$SHARNESS_TRASH_DIRECTORY" || exit 1
# Use -P to resolve symlinks in our working directory so that the cwd
# in subprocesses like git equals our $PWD (for pathname comparisons).
cd -P "$SHARNESS_TRASH_DIRECTORY" || exit 1

check_skip_all_() {
	if test -n "$skip_all" && test $SHARNESS_TEST_NB -gt 0; then
		error "Can't use skip_all after running some tests"
	fi
	[ -z "$skip_all" ] || skip_all=" # SKIP $skip_all"
}

this_test=${SHARNESS_TEST_FILE##*/}
this_test=${this_test%".$SHARNESS_TEST_EXTENSION"}
for skp in $SKIP_TESTS; do
	# shellcheck disable=SC2254
	case "$this_test" in
	$skp)
		say_color info >&3 "skipping test $this_test altogether"
		skip_all="skip all tests in $this_test"
		test_done
	esac
done

test -n "$TEST_LONG" && test_set_prereq EXPENSIVE
test -n "$TEST_INTERACTIVE" && test_set_prereq INTERACTIVE

# Make sure this script ends with code 0
:

# vi: set ts=4 sw=4 noet :
