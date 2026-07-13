# Arquitetura da Plataforma Digitalead

Esta seção documenta as decisões arquiteturais, os componentes e os princípios utilizados na construção da Plataforma Digitalead.

Os documentos desta pasta explicam **por que** determinada solução foi adotada e **como os componentes se relacionam**.

Os procedimentos de instalação ficam separados em:

```text
docs/bootstrap/
```

Os procedimentos de manutenção e operação ficam em:

```text
docs/operations/
```

## Documentos

| Ordem | Documento                                                  | Objetivo                                                             | Status    |
| ----: | ---------------------------------------------------------- | -------------------------------------------------------------------- | --------- |
|    00 | [Princípios arquiteturais](00-principios-arquiteturais.md) | Definir as regras que orientam as decisões da plataforma             | Concluído |
|    01 | [Visão da plataforma](01-plataforma.md)                    | Apresentar a arquitetura geral e seus objetivos                      | Pendente  |
|    02 | [Kubernetes](02-kubernetes.md)                             | Explicar o papel do Kubernetes na plataforma                         | Pendente  |
|    03 | [Arquitetura interna do K3s](03-k3s.md)                    | Explicar como o K3s funciona e por que foi escolhido                 | Concluído |
|    04 | [Rede](04-network.md)                                      | Documentar DNS, firewall, Traefik, Ingress, Services e rede dos Pods | Pendente  |
|    05 | [Persistência](05-storage.md)                              | Documentar StorageClass, volumes, PostgreSQL e retenção              | Pendente  |
|    06 | [Segurança](06-security.md)                                | Documentar RBAC, Secrets, TLS, firewall e políticas de rede          | Pendente  |
|    07 | [Observabilidade](07-observability.md)                     | Documentar métricas, dashboards, logs e alertas                      | Pendente  |
|    08 | [CI/CD](08-ci-cd.md)                                       | Documentar build, registry, deploy e futura adoção de GitOps         | Pendente  |
|    09 | [Backup e recuperação](09-backup-disaster-recovery.md)     | Documentar backup, restore e recuperação de desastre                 | Pendente  |

## Separação entre arquitetura e execução

### Arquitetura

Responde perguntas como:

* Por que usamos K3s?
* Por que os ambientes usam namespaces?
* Como o tráfego chega até uma aplicação?
* Quais são os riscos do single-node?
* Como a solução poderá evoluir?

### Bootstrap

Responde perguntas como:

* Quais comandos devem ser executados?
* Quais arquivos devem ser criados?
* Como validar uma instalação?
* Como desfazer uma alteração?

### Operação

Responde perguntas como:

* Como atualizar o K3s?
* Como renovar certificados?
* Como investigar um Pod com falha?
* Como restaurar o PostgreSQL?
* Como recuperar o cluster?

## Arquitetura inicial

```text
Internet
   │
   ▼
DNS
app.digitallead.com.br
*.app.digitallead.com.br
   │
   ▼
Firewall da Contabo
   │
   ▼
VPS Ubuntu
dl-platform-01
   │
   ▼
K3s single-node
   │
   ├── Traefik
   ├── CoreDNS
   ├── Metrics Server
   ├── ServiceLB
   ├── Local Path Provisioner
   │
   ├── dl-prod
   ├── dl-qa
   ├── dl-dev
   ├── dl-infra
   ├── dl-monitoring
   └── dl-logging
```

## Evolução prevista

### Fase 1

```text
1 VPS
1 nó K3s
Datastore SQLite
Ambientes separados por namespaces
```

### Fase 2

```text
Produção separada de QA e desenvolvimento
Backups externos automatizados
Maior isolamento de recursos
```

### Fase 3

```text
3 servidores K3s
Control plane altamente disponível
Embedded etcd
Storage e workloads distribuídos
```

### Fase 4

Caso o crescimento justifique:

```text
AKS, EKS, GKE ou outro Kubernetes gerenciado
```

A plataforma deverá ser construída evitando dependências desnecessárias da Contabo ou do K3s, facilitando uma futura migração.

## Regra de manutenção

Sempre que uma decisão arquitetural mudar:

1. atualizar o documento correspondente;
2. registrar a motivação;
3. atualizar manifests, Helm values ou scripts;
4. validar a alteração;
5. registrar a mudança no Git.

