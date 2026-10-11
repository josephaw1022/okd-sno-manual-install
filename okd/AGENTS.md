# okd/ directory guide

This directory holds the makefile, Ansible playbooks, cluster manifests, and scripts. It is the only place `make` should be run from.

## Layout

- `makefile`: the single entry point. `make help` lists targets by section.
- `ansible/`: one playbook per action (`install-*`, `uninstall-*`, `create-*`, `destroy-*`, `setup-*`, `configure-*`). `templates/`, `tasks/`, and `files/` hold shared pieces.
- `cluster-setup/`: manifests and Helm values applied to the cluster.
- `dnsmasq/`: Pi-hole records (`okd.conf`, `homelab.conf`).
- `scripts/`: helpers invoked by makefile targets. Never run these directly.

## Conventions

- Add new functionality as a playbook plus a documented makefile target (`## description` comment, placed in the right `##@` section, `.PHONY`).
- Every `install-*` should have a matching `uninstall-*`, and aggregate targets (`*-all`) should run pieces in dependency order.
- Secrets and tokens come from `ansible/group_vars/all.yml`. Never hardcode or print them.
- After adding or changing a target, update the matching skill in `.agents/skills/`.
- Keep `.agents/skills/*` in sync with target names, because skills reference them verbatim.

