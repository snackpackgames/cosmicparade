---
name: feedback-autofree-tests
description: Use GUT's autofree() helper instead of manual free()/queue_free() in test teardown
metadata:
  type: feedback
---

Prefer the `autofree()` pattern in GUT tests instead of explicit `after_each` teardown.

**Why:** Cleaner, less boilerplate, and GUT handles deferred cleanup correctly.

**How to apply:** Wrap node construction in `autofree()` in `before_each`. Remove `after_each` if the only purpose was cleanup.

```gdscript
func before_each() -> void:
    my_node = autofree(MyClass.new())
    add_child(my_node)
# No after_each needed
```

Works for Node subclasses. For RefCounted, let GC handle it or use `autoqfree()` if available.
