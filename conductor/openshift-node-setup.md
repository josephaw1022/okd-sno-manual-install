# Objective
Create a new Gemini CLI skill named `openshift-node-setup` to document how the 3-node OKD cluster VMs are provisioned, managed, and destroyed on the `desktop-server` host in the homelab.

# Key Files & Context
- `okd/makefile`: Contains the core targets for managing the cluster's lifecycle (`create-vms`, `destroy-vms`, `watch-all`, etc.).
- `okd/ansible/create-vms.yml`: Details the libvirt topology (3 nodes: `.22, .23, .24` with 30GB RAM), macvtap bridged networking, and the use of the Agent-Based Installer without a separate bootstrap VM.
- `okd/ansible/destroy-vms.yml`: Details the VM and qcow2 disk teardown.
- `okd/ansible/copy-iso.yml`: Details copying the Agent ISO to the libvirt server.
- New File: `.agents/skills/openshift-node-setup/SKILL.md`

# Implementation Steps
1. Create the skill directory at `.agents/skills/openshift-node-setup/`.
2. Write the skill's Markdown document (`SKILL.md`) following the `creating-skills` specification. The document will include:
   - **Frontmatter**: Required `name` (`openshift-node-setup`) and `description` (e.g., "Use when you need to understand how the OKD nodes (VMs) are created, managed, and destroyed on the desktop-server libvirt host in the homelab.").
   - **Topology Overview**: An explanation of the 3-node master cluster. It will explicitly mention that the VMs are running on the `desktop-server` libvirt host. It will note that `master-0` is the rendezvous host and there is no standalone bootstrap VM.
   - **Node Provisioning Workflow**: A section documenting how to generate the ISO (`make agent-iso`), copy it (`make copy-iso`), and create/start the VMs (`make create-vms`).
   - **Management & Monitoring**: A section covering power management (`make start-vms`, `make reboot-non-bootstrap`) and installation tracking (`make watch-all`, `make wait-install`).
   - **Teardown Workflow**: A section explaining the `make destroy-vms` command for full node deletion.
   - **Gotchas**: A section highlighting troubleshooting steps, specifically the `make clean-known-hosts` command for SSH issues.

# Verification & Testing
- Ensure the frontmatter is formatted correctly and free of trailing hyphens or other invalid characters.
- Review the `SKILL.md` content to verify that the term `desktop-server` is explicitly referenced as the host system.
- Confirm all makefile targets accurately reflect the provided okd repository scripts.