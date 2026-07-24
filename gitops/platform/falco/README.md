# Falco (runtime security)

## Purpose

Syscall-level runtime detection on AKS via Falco (**modern eBPF**). Logs JSON to stdout for Promtail → Loki ([ADR-0015](../../../docs/adr/0015-falco-runtime-detection.md), [ADR-0012](../../../docs/adr/0012-loki-in-cluster-logging.md)).

## Contents

| File | Role |
|------|------|
| `Application.yaml` | Argo CD Helm app (chart `falco` @ `9.1.0`) |
| `values.yaml` | Driver, JSON output, resource caps |

## Prerequisites

- Argo CD + `platform-root` (Topic 05)
- Promtail/Loki for log search (Topic 11) — recommended
- AKS node kernel supporting modern eBPF (typical on current Azure Linux / Ubuntu node images)

## Usage

[docs/setup/18-runtime-security.md](../../../docs/setup/18-runtime-security.md)

## Timing

Topic 18 (Package 6). Sync-wave **40** (after Kyverno 35, with monitoring ~38–45).
