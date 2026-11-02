#!/bin/bash
# scripts/check_test_count.sh — Fail if the GUT run did not actually run tests.
#
# Usage: bash scripts/check_test_count.sh <junit-report-file>
#
# This check cannot be a test, which is the whole reason it exists.
# addons/gut/gut_cmdln.gd calls quit(0) when GUT's own class_names are missing
# from the global script class cache — before any test runs. A test asserting
# the cache is warm therefore never executes, and the run exits 0 with an empty
# suite. A green badge then means nothing. See issue #6.
#
# Two distinct failures, and the second is the one a naive check misses:
#   * The report exists and reports zero tests — an empty or fully-skipped suite.
#   * The report does not exist at all — the cold-cache quit(0) case, where GUT
#     never reaches the point of writing -gjunit_xml_file. Treating a missing
#     report as "nothing to check" would restore exactly the hole this closes.
#
# Exits 1 on either, 0 when at least one test ran.

set -euo pipefail

REPORT_FILE="${1:?Usage: $0 <junit-report-file>}"

if [[ ! -f "$REPORT_FILE" ]]; then
  echo "::error::No GUT report at '$REPORT_FILE' — the suite never ran"
  echo "GUT exited without writing a report. The usual cause is a cold global"
  echo "script class cache: gut_cmdln.gd calls quit(0) before running anything."
  echo "Run 'bash scripts/import.sh' to rebuild the cache, then re-run the suite."
  exit 1
fi

# Sum the tests="N" attribute of every <testsuite> (one per test script).
# The <testsuites> wrapper carries its own total, but "<testsuite " with a
# trailing space does not match "<testsuites ", so the wrapper is skipped and
# nothing is double counted. A report with no <testsuite> elements sums to 0,
# which is the empty-suite failure below.
# Done in one awk rather than a grep pipeline on purpose: under `set -o
# pipefail` a grep that matches nothing fails the whole pipeline, which would
# abort this script before it could report the empty-suite case it exists to
# report -- exiting non-zero with no diagnostic at all.
TEST_COUNT="$(
  awk '
    {
      line = $0
      while (match(line, /<testsuite [^>]*tests="[0-9]+"/)) {
        seg = substr(line, RSTART, RLENGTH)
        line = substr(line, RSTART + RLENGTH)
        if (match(seg, /tests="[0-9]+"/)) {
          total += substr(seg, RSTART + 7, RLENGTH - 8)
        }
      }
    }
    END { print total + 0 }
  ' "$REPORT_FILE"
)"

if [[ "${TEST_COUNT:-0}" -eq 0 ]]; then
  echo "::error::The GUT report at '$REPORT_FILE' contains no tests"
  echo "A suite that runs nothing passes, which makes a green build meaningless."
  exit 1
fi

echo "check_test_count: $TEST_COUNT test(s) ran."
