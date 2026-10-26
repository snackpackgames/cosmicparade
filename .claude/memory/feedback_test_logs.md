---
name: feedback-test-logs
description: Save test output to logs/test_run.log and grep from there rather than re-running the suite
metadata:
  type: feedback
---

Save test results to the gitignored `logs/` directory and search the file rather than re-running the suite for each query.

**Why:** Re-running a full GUT suite is slow and gets slower as the suite grows. Saving to a log file lets you grep multiple times against a single run.

**How to apply:** Run `bash scripts/test.sh 2>&1 | tee logs/test_run.log` to capture output, then use `grep` against `logs/test_run.log` for follow-up searches.
