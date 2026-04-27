---
trigger: glob
description: Highlights the most common and important workflow targets for the OKD makefile.
globs: "okd/makefile"
---

# Important Makefile Targets

When working with the OKD makefile, the most common workflows that will be run are:

- `make create-lb`
- `make update-dns`
- `make build`
- `make clean`
- `make use-kubeconfig`
- `make copy-iso`
- `make start-vms`

These are considered the really important targets for the makefile.
