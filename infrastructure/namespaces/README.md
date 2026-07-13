# Namespaces da Plataforma Digitalead

## Objetivo

Documentar e versionar a separação lógica dos ambientes e componentes compartilhados da Plataforma Digitalead.

A plataforma utiliza inicialmente um único cluster K3s. Os ambientes são separados através de namespaces Kubernetes.

## Namespaces

| Namespace       | Finalidade                               |
| --------------- | ---------------------------------------- |
| `dl-prod`       | Aplicações e serviços de produção        |
| `dl-qa`         | Aplicações e serviços de homologação     |
| `dl-dev`        | Aplicações e serviços de desenvolvimento |
| `dl-infra`      | Componentes compartilhados da plataforma |
| `dl-monitoring` | Métricas, dashboards e alertas           |
| `dl-logging`    | Coleta, armazenamento e consulta de logs |

## Decisão arquitetural

Os ambientes estarão inicialmente no mesmo cluster para reduzir custos e simplificar a operação.

Namespace oferece separação lógica, mas não representa:

* isolamento físico;
* cluster independente;
* limite completo de segurança;
* isolamento automático de CPU e memória;
* isolamento automático de rede.

A separação será complementada progressivamente por:

* ResourceQuota;
* LimitRange;
* RBAC;
* NetworkPolicy;
* ServiceAccounts;
* Secrets independentes;
* domínios independentes;
* bancos de dados independentes.

## Convenção de nomes

Todos os namespaces pertencentes à plataforma utilizam o prefixo:

```text
dl-
```

Esse prefixo identifica recursos administrados pela Plataforma Digitalead.

## Labels organizacionais

Todos os namespaces recebem:

```yaml
app.kubernetes.io/part-of: digitallead-platform
app.kubernetes.io/managed-by: kubectl
```

Também recebem labels próprias da organização:

```yaml
digitallead.com.br/environment: VALOR
digitallead.com.br/purpose: VALOR
```

Essas labels poderão ser utilizadas para:

* consultas;
* relatórios;
* automação;
* políticas;
* identificação do ambiente;
* organização no Headlamp.

## Pod Security Admission

Nesta etapa, as políticas de segurança são aplicadas somente nos modos:

```text
warn
audit
```

O modo `warn` apresenta avisos ao usuário quando um recurso viola a política.

O modo `audit` registra violações nos eventos de auditoria da API.

Nenhuma política será aplicada em modo `enforce` nesta primeira etapa.

Configuração inicial:

```yaml
pod-security.kubernetes.io/warn: baseline
pod-security.kubernetes.io/warn-version: latest
pod-security.kubernetes.io/audit: restricted
pod-security.kubernetes.io/audit-version: latest
```

Essa estratégia permite identificar incompatibilidades antes de bloquear a instalação de componentes.

Depois da validação dos workloads, os namespaces de aplicação poderão evoluir para:

```yaml
pod-security.kubernetes.io/enforce: baseline
```

A adoção de `restricted` em modo `enforce` dependerá da compatibilidade de cada aplicação.

## Aplicação

Aplicar todos os namespaces:

```bash
sudo k3s kubectl apply -f infrastructure/namespaces/
```

O comando é declarativo e idempotente. Executá-lo novamente deverá manter os namespaces no estado definido nos arquivos.

## Validação

```bash
sudo k3s kubectl get namespaces \
  -l app.kubernetes.io/part-of=digitallead-platform \
  --show-labels
```

Também é possível consultar por ambiente:

```bash
sudo k3s kubectl get namespaces \
  -l digitallead.com.br/environment=production
```

Consultar por finalidade:

```bash
sudo k3s kubectl get namespaces \
  -l digitallead.com.br/purpose=monitoring
```

## Rollback

A exclusão de um namespace remove todos os recursos namespaced contidos nele.

Por esse motivo, não deve ser utilizado indiscriminadamente:

```bash
kubectl delete namespace NOME
```

Nesta fase inicial, enquanto os namespaces estiverem vazios, o rollback poderá ser executado individualmente:

```bash
sudo k3s kubectl delete namespace dl-prod
```

Depois da instalação de aplicações e dados, a remoção exigirá análise e backup.

## Histórico de alterações

| Versão | Data       | Descrição                      |
| ------ | ---------- | ------------------------------ |
| 1.0    | 2026-07-13 | Criação inicial dos namespaces |

