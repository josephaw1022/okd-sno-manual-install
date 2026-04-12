# Load Balancer Service Mapping

Traffic to `192.168.1.20` is distributed to the master nodes (`192.168.1.22-24`).

| Port | Service | Description |
|------|---------|-------------|
| 6443 | API | Kubernetes API Server |
| 22623 | MCS | Machine Config Server |
| 80 | HTTP | Ingress Traffic |
| 443 | HTTPS | Ingress Traffic |
