Run GUT tests for the project.

Usage: /test [dir_or_file]
- With a directory name: runs tests in `test/unit/<dir>/`
- With a file path (contains `.gd`): runs that single test file
- Without arguments: runs all tests under `test/unit/`

Steps:
1. Run: `bash scripts/test.sh $ARGUMENTS`
2. Report the test results (pass/fail counts and any errors).
3. If tests fail with "Class not found" or unrecognized type errors, advise the user to run `/import` first to rebuild the class cache, then retry.
