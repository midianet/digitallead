# Arquitetura Geral da Plataforma Digitalead

**Projeto:** Plataforma Digitalead
**Documento:** Arquitetura 01
**Versão:** 1.0
**Status:** Aprovado
**Última atualização:** 2026-07-16

## 1. Objetivo

Este documento apresenta a arquitetura geral da Plataforma Digitalead, seus componentes, responsabilidades, ambientes e estratégia de evolução.

A plataforma foi projetada para atender à fase inicial da startup com baixo custo, mantendo compatibilidade com Kubernetes e permitindo crescimento gradual.

## 2. Visão geral

A plataforma será executada inicialmente em uma única VPS dedicada na Contabo.

```text
Internet
   │
   ▼
Cloudflare DNS
   │
   ▼
Firewall Contabo
   │
   ▼
217.216.55.208
   │
   ▼
Ubuntu Server 24.04 LTS
   │
   ▼
K3s single-node
```

O mesmo nó executa:

* control plane;
* worker;
* datastore;
* runtime de containers;
* componentes de infraestrutura;
* aplicações;
* bancos de dados;
* monitoramento;
* logs.

## 3. Infraestrutura física

| Item                | Configuração            |
| ------------------- | ----------------------- |
| Provedor            | Contabo                 |
| Hostname            | `dl-platform-01`        |
| CPU                 | 8 vCPU                  |
| Memória             | 24 GB                   |
| Disco               | 200 GB                  |
| Sistema operacional | Ubuntu Server 24.04 LTS |
| IPv4                | `217.216.55.208`        |
| Kubernetes          | K3s                     |
| Datastore do K3s    | SQLite                  |
| Runtime             | containerd              |

## 4. Domínios

Registros DNS:

```text
app.digitallead.com.br
*.app.digitallead.com.br
```

Ambos apontam para:

```text
217.216.55.208
```

Domínios planejados:

| Serviço                     | Domínio                           |
| --------------------------- | --------------------------------- |
| Frontend de produção        | `app.digitallead.com.br`          |
| Frontend de QA              | `qa.app.digitallead.com.br`       |
| Frontend de desenvolvimento | `dev.app.digitallead.com.br`      |
| API de produção             | `api.app.digitallead.com.br`      |
| API de QA                   | `api-qa.app.digitallead.com.br`   |
| API de desenvolvimento      | `api-dev.app.digitallead.com.br`  |
| Headlamp                    | `headlamp.app.digitallead.com.br` |
| pgAdmin                     | `pgadmin.app.digitallead.com.br`  |
| Keycloak                    | `keycloak.app.digitallead.com.br` |
| Grafana                     | `grafana.app.digitallead.com.br`  |
| Graylog                     | `graylog.app.digitallead.com.br`  |

## 5. Camadas da plataforma

```text
┌────────────────────────────────────────────────────┐
│ Aplicações                                         │
│ Frontend • Backend • Serviços de IA                │
├────────────────────────────────────────────────────┤
│ Identidade                                         │
│ Keycloak                                           │
├────────────────────────────────────────────────────┤
│ Dados                                              │
│ PostgreSQL • MongoDB • OpenSearch                  │
├────────────────────────────────────────────────────┤
│ Observabilidade                                    │
│ Prometheus • Grafana • Graylog                     │
├────────────────────────────────────────────────────┤
│ Serviços de plataforma                             │
│ Headlamp • cert-manager • Backup • SMTP externo    │
├────────────────────────────────────────────────────┤
│ Kubernetes                                         │
│ K3s • Traefik • CoreDNS • Metrics Server           │
├────────────────────────────────────────────────────┤
│ Sistema operacional                                │
│ Ubuntu • systemd • firewall • storage local        │
├────────────────────────────────────────────────────┤
│ Infraestrutura física                              │
│ Contabo VPS • CPU • memória • disco • rede         │
└────────────────────────────────────────────────────┘
```

## 6. Núcleo Kubernetes

O núcleo da plataforma é composto por:

```text
K3s
├── Kubernetes API Server
├── Scheduler
├── Controller Manager
├── Kubelet
├── Kube Proxy
├── containerd
├── CoreDNS
├── Traefik
├── ServiceLB
├── Metrics Server
└── Local Path Provisioner
```

## 7. Entrada de tráfego

```text
Internet
   │
   ▼
Cloudflare DNS
   │
   ▼
Firewall Contabo
   │
   ▼
Portas 80 e 443
   │
   ▼
ServiceLB
   │
   ▼
Traefik
   │
   ▼
Ingress
   │
   ▼
Service ClusterIP
   │
   ▼
Pod
```

Somente as portas públicas necessárias deverão ser permitidas:

|   Porta | Finalidade                  |
| ------: | --------------------------- |
|  22/TCP | SSH administrativo restrito |
|  80/TCP | HTTP e desafio ACME         |
| 443/TCP | HTTPS                       |

Serviços internos como PostgreSQL, Prometheus e API Kubernetes não deverão ser expostos indiscriminadamente.

## 8. Certificados

O cert-manager administra certificados TLS emitidos pelo Let's Encrypt.

Fluxo:

```text
Ingress
   │
   ▼
cert-manager
   │
   ▼
Let's Encrypt
   │
   ▼
Secret kubernetes.io/tls
   │
   ▼
Traefik
```

Inicialmente será utilizado um certificado individual por serviço.

Exemplos:

```text
headlamp.app.digitallead.com.br
pgadmin.app.digitallead.com.br
keycloak.app.digitallead.com.br
```

## 9. Namespaces

```text
dl-prod
dl-qa
dl-dev
dl-infra
dl-database
dl-monitoring
dl-logging
cert-manager
kube-system
```

Responsabilidades:

| Namespace       | Responsabilidade               |
| --------------- | ------------------------------ |
| `dl-prod`       | Aplicações de produção         |
| `dl-qa`         | Aplicações de homologação      |
| `dl-dev`        | Aplicações de desenvolvimento  |
| `dl-infra`      | Serviços compartilhados        |
| `dl-database`   | Bancos de dados                |
| `dl-monitoring` | Métricas, dashboards e alertas |
| `dl-logging`    | Coleta e armazenamento de logs |
| `cert-manager`  | Gestão de certificados         |
| `kube-system`   | Componentes internos do K3s    |

Namespace oferece separação lógica, mas não isolamento físico completo.

## 10. Serviços compartilhados

### Headlamp

Responsável pela administração visual do Kubernetes.

```text
headlamp.app.digitallead.com.br
```

A autenticação inicial utiliza token Kubernetes.

Futuramente utilizará Keycloak e OIDC.

### cert-manager

Responsável por:

* emissão de certificados;
* renovação automática;
* criação de Secrets TLS;
* desafios ACME.

### SMTP

Será utilizado um serviço SMTP externo.

A plataforma não operará inicialmente um servidor SMTP próprio.

## 11. Módulo de dados

```text
Data
├── PostgreSQL
├── MongoDB
└── OpenSearch
```

### PostgreSQL

Será utilizado por:

* Keycloak;
* backend de produção;
* backend de QA;
* backend de desenvolvimento;
* outros serviços relacionais.

Arquitetura inicial:

```text
PostgreSQL standalone
   │
   ▼
PVC
   │
   ▼
StorageClass dl-local-retain
   │
   ▼
Disco local da VPS
```

### MongoDB

Será utilizado principalmente pelo Graylog para metadados.

### OpenSearch

Será utilizado pelo Graylog para armazenamento e pesquisa de mensagens.

## 12. Administração do PostgreSQL

O pgAdmin será utilizado como interface web administrativa.

```text
Internet
   │
   ▼
pgadmin.app.digitallead.com.br
   │
   ▼
Traefik
   │
   ▼
pgAdmin
   │
   ▼
PostgreSQL ClusterIP
```

A porta `5432` não será exposta à internet.

## 13. Identidade e acesso

O Keycloak será o provedor central de identidade.

Arquitetura futura:

```text
Keycloak
   │
   ├── Headlamp
   ├── pgAdmin
   ├── Grafana
   ├── Graylog
   ├── Frontend
   └── Backend
```

Recursos planejados:

* OpenID Connect;
* Single Sign-On;
* MFA;
* usuários;
* grupos;
* roles;
* auditoria;
* integração com RBAC.

## 14. Observabilidade

```text
Observabilidade
├── Prometheus
├── Grafana
├── Metrics Server
└── Graylog
```

### Metrics Server

Fornece métricas básicas para:

* `kubectl top`;
* Headlamp;
* Horizontal Pod Autoscaler.

### Prometheus

Será responsável por métricas históricas.

### Grafana

Será responsável por dashboards e visualização.

### Graylog

Será responsável pela centralização e pesquisa de logs.

## 15. Persistência

StorageClasses:

| StorageClass      | Política | Uso                |
| ----------------- | -------- | ------------------ |
| `local-path`      | `Delete` | dados descartáveis |
| `dl-local-retain` | `Retain` | dados importantes  |

Local físico dos volumes:

```text
/var/lib/rancher/k3s/storage
```

A política `Retain` não substitui backup.

## 16. Backup

O backup deverá ser armazenado fora da VPS.

```text
PostgreSQL
   │
   ▼
CronJob Kubernetes
   │
   ▼
pg_dump / pg_dumpall
   │
   ▼
Compressão
   │
   ▼
Object Storage S3
```

Alternativas de Object Storage:

* Contabo Object Storage;
* Cloudflare R2;
* Backblaze B2;
* Wasabi;
* AWS S3.

O backup deverá possuir:

* retenção;
* criptografia;
* monitoramento;
* alerta de falha;
* teste periódico de restauração.

## 17. Aplicações

```text
Applications
├── Frontend
├── Backend
└── Serviços de IA
```

Cada ambiente possuirá:

* Deployment próprio;
* Service próprio;
* ConfigMap própria;
* Secret próprio;
* domínio próprio;
* banco próprio;
* recursos próprios.

## 18. Fluxo da aplicação

```text
Usuário
   │
   ▼
Frontend
   │
   ▼
Backend
   │
   ├── Keycloak
   ├── PostgreSQL
   ├── SMTP
   └── Serviços de IA
```

## 19. Separação dos ambientes

```text
Produção
├── app.digitallead.com.br
├── api.app.digitallead.com.br
└── database digitallead_prod

QA
├── qa.app.digitallead.com.br
├── api-qa.app.digitallead.com.br
└── database digitallead_qa

Desenvolvimento
├── dev.app.digitallead.com.br
├── api-dev.app.digitallead.com.br
└── database digitallead_dev
```

## 20. Recursos iniciais

Distribuição estimada:

| Componente                 | Memória estimada |
| -------------------------- | ---------------: |
| K3s e componentes internos |          1–2 GiB |
| PostgreSQL                 |          1–4 GiB |
| Keycloak                   |          1–2 GiB |
| pgAdmin                    |    256 MiB–1 GiB |
| Prometheus                 |          1–2 GiB |
| Grafana                    |      256–512 MiB |
| Graylog                    |          2–4 GiB |
| MongoDB                    |    512 MiB–1 GiB |
| OpenSearch                 |          2–4 GiB |
| Aplicações                 |         variável |

A VPS possui 24 GB e deverá ser monitorada continuamente.

## 21. Limitações aceitas

A fase inicial possui:

* uma única VPS;
* ponto único de falha;
* armazenamento local;
* ausência de replicação;
* indisponibilidade em reinicializações;
* ambientes compartilhando recursos;
* banco sem alta disponibilidade.

Essas limitações são aceitas conscientemente devido ao estágio e orçamento da startup.

## 22. Evolução

### Fase 1

```text
1 VPS
K3s single-node
Namespaces compartilhados
Storage local
```

### Fase 2

```text
Produção separada de QA e desenvolvimento
Banco em VPS ou serviço separado
Backup automatizado externo
```

### Fase 3

```text
3 servidores K3s
Embedded etcd
Distribuição de workloads
Storage distribuído
```

### Fase 4

```text
AKS, EKS, GKE ou outro Kubernetes gerenciado
```

## 23. Componentes planejados

| Módulo       | Componente             | Status        |
| ------------ | ---------------------- | ------------- |
| Core         | K3s                    | Concluído     |
| Core         | Traefik                | Concluído     |
| Core         | cert-manager           | Concluído     |
| Core         | Headlamp               | Concluído     |
| Storage      | Local Path Provisioner | Concluído     |
| Storage      | `dl-local-retain`      | Concluído     |
| Data         | PostgreSQL             | Em preparação |
| Data         | pgAdmin                | Planejado     |
| Identity     | Keycloak               | Planejado     |
| Monitoring   | Prometheus             | Planejado     |
| Monitoring   | Grafana                | Planejado     |
| Logging      | Graylog                | Planejado     |
| Logging      | MongoDB                | Planejado     |
| Logging      | OpenSearch             | Planejado     |
| Backup       | Object Storage         | Planejado     |
| Applications | Backend                | Planejado     |
| Applications | Frontend               | Planejado     |
| Applications | Serviço de IA          | Planejado     |

## 24. Histórico

| Versão | Data       | Descrição                                  |
| ------ | ---------- | ------------------------------------------ |
| 1.0    | 2026-07-16 | Criação da arquitetura geral da plataforma |

