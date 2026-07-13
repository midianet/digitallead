# cert-manager

## Objetivo

Instalar e administrar certificados TLS da Plataforma Digitalead dentro do Kubernetes.

O cert-manager será responsável por:

* solicitar certificados ao Let's Encrypt;
* criar Secrets TLS;
* acompanhar a validade dos certificados;
* renovar certificados automaticamente;
* administrar recursos ACME, Orders e Challenges.

## Versão adotada

| Item      | Valor                                        |
| --------- | -------------------------------------------- |
| Chart     | `oci://quay.io/jetstack/charts/cert-manager` |
| Versão    | `v1.21.0`                                    |
| Release   | `cert-manager`                               |
| Namespace | `cert-manager`                               |

## Decisões

* instalação pelo chart OCI oficial;
* versão fixada;
* CRDs instalados pelo Helm;
* namespace exclusivo `cert-manager`;
* integração com Prometheus desabilitada inicialmente;
* emissão ACME configurada somente após validar a instalação;
* primeiro teste com Let's Encrypt Staging;
* produção habilitada somente após o teste de homologação.

## Certificados

O DNS utiliza:

```text
app.digitallead.com.br
*.app.digitallead.com.br
```

O registro DNS curinga apenas direciona os subdomínios para a VPS.

Inicialmente, os certificados serão individuais:

```text
headlamp.app.digitallead.com.br
grafana.app.digitallead.com.br
keycloak.app.digitallead.com.br
```

Não será utilizado um certificado TLS curinga nesta fase.

Certificados individuais permitem usar o desafio HTTP-01, sem integração com a API do provedor DNS.

## Componentes esperados

* cert-manager controller;
* cert-manager webhook;
* cert-manager cainjector;
* startup API check;
* CRDs do cert-manager.

## Validação

```bash
kubectl get pods -n cert-manager
kubectl get deployments -n cert-manager
kubectl get crds | grep cert-manager
```

## Remoção

O cert-manager não deve ser removido enquanto existirem recursos:

* Certificate;
* CertificateRequest;
* Issuer;
* ClusterIssuer;
* Order;
* Challenge.

Antes de qualquer remoção:

```bash
kubectl get \
  issuers,clusterissuers,certificates,certificaterequests,orders,challenges \
  --all-namespaces
```

## Histórico

| Versão | Data       | Descrição            |
| ------ | ---------- | -------------------- |
| 1.0    | 2026-07-13 | Configuração inicial |

