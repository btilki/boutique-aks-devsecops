# Integration smoke tests

End-to-end validation scripts run after deployment topics complete.

| Script | When | Validates |
|--------|------|-----------|
| `dev-smoke.sh` | Topic 10 | `dev-boutique.biroltilki.art` health + pods |
| `promotion-smoke.sh` | Topic 12 | Stage/prod HTTPS health checks |
| `rollback-smoke.sh` | Topic 12 | Post-revert health verification |

## dev-smoke.sh

```bash
chmod +x tests/integration/dev-smoke.sh
./tests/integration/dev-smoke.sh
```

Optional environment variables:

| Variable | Default |
|----------|---------|
| `BOUTIQUE_DEV_HOST` | `dev-boutique.biroltilki.art` |
| `BOUTIQUE_NAMESPACE` | `boutique-dev` |
| `KUBE_CONTEXT` | current kubectl context |

Prerequisites: DNS resolves to ingress IP, TLS certificate Ready, Boutique pods Running.
