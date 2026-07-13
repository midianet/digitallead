# Uso do Helm na Plataforma Digitalead

**Projeto:** Plataforma Digitalead
**Documento:** Arquitetura 10
**Versão:** 1.0
**Status:** Aprovado
**Última atualização:** 2026-07-13

## 1. Objetivo

Definir como e quando o Helm será utilizado na Plataforma Digitalead.

## 2. Decisão arquitetural

A plataforma utilizará uma estratégia híbrida:

* YAML Kubernetes para recursos simples e controlados diretamente pelo time;
* Helm para componentes externos que possuem instalação complexa ou charts oficiais mantidos pela comunidade.

## 3. Recursos mantidos em YAML

Exemplos:

* Namespace;
* ResourceQuota;
* LimitRange;
* NetworkPolicy;
* ServiceAccount;
* RBAC próprio;
* Ingress;
* ConfigMap da aplicação;
* Services e Deployments das aplicações Digitalead.

## 4. Componentes instalados com Helm

Exemplos previstos:

* Headlamp;
* cert-manager;
* Prometheus;
* Grafana;
* Loki ou Graylog;
* Keycloak, caso seja adotado um chart adequado;
* componentes de terceiros com chart oficial ou amplamente mantido.

## 5. Fonte de verdade

As configurações utilizadas pelo Helm serão armazenadas em:

```text
infrastructure/helm/
```

Cada componente deverá possuir uma pasta própria:

```text
infrastructure/helm/
├── headlamp/
├── cert-manager/
├── monitoring/
└── outros-componentes/
```

Cada pasta deverá conter, quando aplicável:

```text
README.md
version.env
values.yaml
values-prod.yaml
values-qa.yaml
values-dev.yaml
```

## 6. Versões

Nenhuma instalação deverá depender implicitamente da versão mais recente do chart.

Cada componente deverá registrar:

* repositório Helm;
* nome do chart;
* versão do chart;
* versão da aplicação;
* data da validação;
* namespace de instalação.

## 7. Comandos reproduzíveis

Não serão executados comandos Helm sem que os parâmetros estejam documentados.

O padrão será:

```bash
helm upgrade --install RELEASE REPOSITORY/CHART \
  --namespace NAMESPACE \
  --create-namespace=false \
  --version VERSAO \
  --values infrastructure/helm/COMPONENTE/values.yaml
```

O uso de `upgrade --install` torna o comando idempotente:

* instala quando a release ainda não existe;
* atualiza quando a release já existe.

## 8. Validação antes da instalação

Antes de aplicar um chart:

```bash
helm lint
helm template
kubectl apply --dry-run=server
```

Quando `helm lint` não for aplicável diretamente a charts externos, deverão ser utilizados:

```bash
helm show values
helm template
```

## 9. Secrets

Senhas, tokens e certificados privados não deverão ser armazenados em `values.yaml`.

Os Secrets deverão ser:

* criados separadamente;
* injetados por mecanismo seguro;
* documentados sem conteúdo sensível;
* futuramente integrados a uma solução adequada de gestão de segredos.

## 10. Rollback

Antes de atualizar uma release:

```bash
helm history RELEASE -n NAMESPACE
```

Para retornar a uma revisão anterior:

```bash
helm rollback RELEASE REVISAO -n NAMESPACE
```

A existência do rollback do Helm não substitui backup de dados persistentes.

## 11. Histórico de alterações

| Versão | Data       | Descrição                              |
| ------ | ---------- | -------------------------------------- |
| 1.0    | 2026-07-13 | Definição da estratégia de uso do Helm |

