# Ansible playbook guide

- Do not run `ansible-playbook` directly. Playbooks are invoked only through `okd/makefile` targets.
- Playbooks must be idempotent. Re-running a target should converge, not fail or duplicate resources.
- Teardown playbooks (`uninstall-*`, `destroy-*`, `delete-*`) must tolerate the resource already being gone.
- Mark secret-handling tasks with `no_log: true`.
- Share logic via `tasks/` or `templates/` rather than copy-pasting between playbooks (see `tasks/configure-keycloak-idp.yml`).
- Run `make ansible-deps` if a collection is missing.
- Before adding a playbook, check whether an existing one already covers it.

