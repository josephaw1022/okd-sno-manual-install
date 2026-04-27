---
trigger: always_on
description: Rule enforcing that all bash scripts and ansible playbooks must be run through the Makefile.
---

Do not run bash scripts directly and do not run ansible playbooks via the ansible cli directly. Everything should be done through the makefile (e.g., `okd/makefile`).
