# Arquitetura do Módulo Database

**Projeto:** Plataforma Digitalead
**Versão:** 1.0
**Status:** Aprovado
**Última atualização:** 2026-07-16

## 1. Objetivo

Definir a arquitetura inicial de banco de dados da Plataforma Digitalead.

## 2. Componentes

O módulo será formado por:

* PostgreSQL;
* pgAdmin;
* armazenamento persistente;
* Secrets;
* scripts de inicialização;
* backup e restore;
* monitoramento;
* documentação operacional.

## 3. PostgreSQL

Será utilizada inicialmente uma única instância PostgreSQL.

Essa instância hospedará bancos independentes para os serviços da plataforma.

Bancos planejados:

```text
postgres
keycloak
digitallead_prod
digitallead_qa
digitallead_dev
```

Cada banco deverá possuir usuário e senha próprios.

As aplicações não deverão utilizar o usuário administrativo `postgres`.

## 4. Distribuição

O PostgreSQL será instalado com o chart Helm Bitnami PostgreSQL.

A arquitetura inicial será standalone, sem replicação.

O banco ficará dentro do cluster K3s e utilizará armazenamento local persistente.

## 5. Persistência

O PVC deverá utilizar explicitamente:

```yaml
storageClassName: dl-local-retain
```

Capacidade inicial:

```text
30 GiB
```

A StorageClass utiliza `Retain`, reduzindo o risco de remoção automática dos dados após exclusão acidental do PVC.

Essa política não substitui backup.

## 6. Administração web

O pgAdmin 4 será utilizado como interface web administrativa.

O pgAdmin será instalado separadamente do PostgreSQL.

Isso permite administrar futuramente:

* PostgreSQL interno;
* PostgreSQL em outra VPS;
* PostgreSQL gerenciado em cloud;
* múltiplas instâncias de banco.

## 7. Exposição de rede

O PostgreSQL será publicado apenas como Service:

```text
ClusterIP
```

A porta `5432` não será aberta no firewall da Contabo nem publicada por Ingress.

O pgAdmin será publicado em:

```text
https://pgadmin.app.digitallead.com.br
```

Fluxo:

```text
Internet
   ↓
Traefik
   ↓
HTTPS
   ↓
pgAdmin
   ↓
PostgreSQL interno
```

## 8. Segurança

Senhas e credenciais não serão armazenadas no Git.

Serão criados Secrets Kubernetes para:

* senha administrativa do PostgreSQL;
* usuário inicial do pgAdmin;
* senha inicial do pgAdmin;
* usuários das aplicações.

O repositório conterá apenas templates sem valores reais.

O acesso ao pgAdmin utilizará inicialmente autenticação própria.

Futuramente será integrado ao Keycloak por OIDC.

## 9. Separação de responsabilidades

### PostgreSQL

Responsável por:

* armazenamento dos bancos;
* usuários e roles;
* conexões;
* transações;
* persistência.

### pgAdmin

Responsável por:

* administração visual;
* execução de SQL;
* inspeção de sessões;
* gerenciamento de objetos;
* operações administrativas.

### Aplicações

Responsáveis por suas próprias migrações de schema, utilizando ferramentas como:

* Flyway;
* Liquibase.

O pgAdmin não será utilizado como substituto das migrações versionadas das aplicações.

## 10. Backup

A estratégia deverá incluir:

* `pg_dump` para bancos individuais;
* `pg_dumpall` para roles e objetos globais;
* armazenamento externo à VPS;
* retenção definida;
* criptografia quando necessária;
* monitoramento dos backups;
* teste periódico de restauração.

Backup pela interface do pgAdmin poderá ser utilizado em operações pontuais, mas não substituirá o backup automatizado.

## 11. Recursos iniciais

### PostgreSQL

| Recurso | Request | Limit |
| ------- | ------: | ----: |
| CPU     |    250m |     2 |
| Memória |   1 GiB | 4 GiB |

Disco inicial:

```text
30 GiB
```

### pgAdmin

| Recurso | Request | Limit |
| ------- | ------: | ----: |
| CPU     |     50m |  500m |
| Memória | 256 MiB | 1 GiB |

Disco inicial:

```text
2 GiB
```

## 12. Limitações

A arquitetura atual não possui:

* replicação;
* failover;
* alta disponibilidade;
* expansão automática do PVC;
* separação física do banco;
* réplica de leitura.

Essas limitações são aceitas para a fase inicial da startup.

## 13. Evolução futura

A arquitetura deverá ser reavaliada quando:

* o banco se tornar crítico para SLAs;
* o uso de disco crescer significativamente;
* for necessário realizar manutenção sem indisponibilidade;
* clientes exigirem alta disponibilidade;
* a VPS atingir pressão constante de recursos.

Alternativas futuras:

* PostgreSQL em VPS dedicada;
* PostgreSQL gerenciado;
* CloudNativePG;
* PostgreSQL HA;
* réplica externa;
* armazenamento dedicado.

## 14. Histórico

| Versão | Data       | Descrição                            |
| ------ | ---------- | ------------------------------------ |
| 1.0    | 2026-07-16 | Definição inicial do módulo Database |

