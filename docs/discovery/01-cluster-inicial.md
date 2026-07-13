# Estado Inicial do Cluster K3s

Data: 2026-07-13

## Nó

| Item | Valor |
|---|---|
| Nome | dl-platform-01 |
| Status | Ready |
| Papel | control-plane e worker |
| Kubernetes | v1.35.6+k3s1 |
| Sistema | Ubuntu 24.04.4 LTS |
| Kernel | 6.8.0-134-generic |
| Runtime | containerd 2.2.5-k3s2 |
| IP | 217.216.55.208 |

## Consumo inicial

| Recurso | Consumo |
|---|---:|
| CPU | 341m / 4% |
| Memória | 814 MiB / 3% |

## Componentes instalados

- CoreDNS
- Traefik
- ServiceLB
- Metrics Server
- Local Path Provisioner

## Resultado

O cluster foi validado com sucesso e encontra-se pronto para receber a estrutura lógica da Plataforma Digitalead.
