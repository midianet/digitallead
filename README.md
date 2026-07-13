# Plataforma Digitalead

Repositório responsável pela documentação, automação e infraestrutura da Plataforma Digitalead.

A plataforma será executada inicialmente em uma VPS dedicada, utilizando K3s como distribuição Kubernetes. Os ambientes de produção, QA e desenvolvimento serão separados logicamente por namespaces.

## Visão geral

A arquitetura inicial contempla:

* VPS dedicada na Contabo;
* Ubuntu Server 24.04 LTS;
* K3s single-node;
* Traefik como Ingress Controller;
* ambientes separados por namespaces;
* PostgreSQL;
* Keycloak;
* aplicações backend e frontend;
* observabilidade e centralização de logs;
* certificados TLS automatizados;
* backups armazenados fora da VPS.

## Infraestrutura inicial

| Recurso             | Configuração            |
| ------------------- | ----------------------- |
| Provedor            | Contabo                 |
| Sistema operacional | Ubuntu Server 24.04 LTS |
| CPU                 | 8 vCPU                  |
| Memória             | 24 GB                   |
| Disco               | 200 GB                  |
| IPv4 público        | 217.216.55.208          |
| Kubernetes          | K3s single-node         |
| Domínio             | digitallead.com.br      |

## Domínios planejados

| Ambiente ou serviço          | Domínio                           |
| ---------------------------- | --------------------------------- |
| Aplicação de produção        | `app.digitallead.com.br`          |
| Aplicação de QA              | `qa.app.digitallead.com.br`       |
| Aplicação de desenvolvimento | `dev.app.digitallead.com.br`      |
| Headlamp                     | `headlamp.app.digitallead.com.br` |
| Grafana                      | `grafana.app.digitallead.com.br`  |
| Keycloak                     | `keycloak.app.digitallead.com.br` |

Os seguintes registros DNS devem apontar para o IP público da VPS:

```text
A  app.digitallead.com.br    217.216.55.208
A  *.app.digitallead.com.br  217.216.55.208
```

## Estrutura do repositório

```text
digitallead/
├── docs/                 Documentação da plataforma
├── infrastructure/       Recursos declarativos do Kubernetes
├── scripts/              Scripts operacionais e de bootstrap
└── README.md              Ponto de entrada da documentação
```

### Documentação

```text
docs/
├── architecture/         Arquitetura e diagramas
├── backup/               Estratégia e procedimentos de backup
├── bootstrap/            Instalação inicial da plataforma
├── monitoring/           Monitoramento, métricas e alertas
├── operations/           Procedimentos operacionais
├── standards/            Padrões e convenções
└── troubleshooting/      Diagnóstico e resolução de problemas
```

### Infraestrutura Kubernetes

```text
infrastructure/
├── helm/                 Values e configurações de Helm
├── ingress/              Ingresses e middlewares
├── manifests/            Manifests Kubernetes gerais
├── monitoring/           Recursos de observabilidade
├── namespaces/           Namespaces, quotas e limites
├── security/             RBAC, políticas e secrets de referência
└── storage/              StorageClasses, PVCs e políticas de retenção
```

### Scripts

```text
scripts/
├── backup/               Execução de backups
├── restore/              Procedimentos de restauração
├── server/               Preparação da VPS
├── upgrade/              Atualizações da plataforma
└── utils/                Funções e utilitários compartilhados
```

## Documentação de bootstrap

A instalação da plataforma deve seguir a ordem abaixo:

1. [Provisionamento da VPS](docs/bootstrap/01-provisionamento-vps/README.md)
2. [Hardening do Ubuntu](docs/bootstrap/02-hardening-ubuntu/README.md)
3. [Instalação do K3s](docs/bootstrap/03-instalacao-k3s/README.md)

## Princípios

A Plataforma Digitalead segue os seguintes princípios:

1. Toda alteração deve ser documentada.
2. Toda configuração deve ser reproduzível.
3. Versões de componentes devem ser fixadas.
4. Secrets reais não devem ser armazenados no Git.
5. Mudanças devem ser validadas antes de serem aplicadas em produção.
6. Backups devem ser armazenados fora da VPS.
7. Todo procedimento crítico deve possuir instruções de validação e recuperação.

## Arquitetura inicial

```text
Internet
   │
   ▼
DNS: app.digitallead.com.br
   │
   ▼
Firewall Contabo
   │
   ▼
Ubuntu Server + UFW
   │
   ▼
K3s Single Node
   │
   ├── Traefik
   ├── dl-prod
   ├── dl-qa
   ├── dl-dev
   ├── dl-infra
   ├── dl-monitoring
   └── dl-logging
```

## Roadmap

* [x] Provisionar a VPS
* [x] Definir domínio e registros DNS
* [x] Criar repositório da plataforma
* [x] Documentar o provisionamento inicial
* [ ] Preparar e proteger o Ubuntu
* [ ] Instalar o K3s
* [ ] Configurar acesso administrativo
* [ ] Criar namespaces e limites de recursos
* [ ] Configurar Ingress e TLS
* [ ] Instalar Headlamp
* [ ] Configurar PostgreSQL
* [ ] Configurar Keycloak
* [ ] Publicar backend e frontend
* [ ] Configurar monitoramento
* [ ] Configurar logs
* [ ] Implementar backups e restauração
* [ ] Implementar CI/CD

## Repositório

Mantido no GitHub:

```text
midianet/digitallead
```

## Status

Plataforma em implantação.

