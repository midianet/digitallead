# Headlamp

## Objetivo

Instalar o Headlamp como interface web administrativa do cluster K3s da Plataforma Digitalead.

## Versão

| Item            | Valor                                         |
| --------------- | --------------------------------------------- |
| Repositório     | `https://kubernetes-sigs.github.io/headlamp/` |
| Chart           | `headlamp/headlamp`                           |
| Versão do chart | `0.43.0`                                      |
| Release         | `headlamp`                                    |
| Namespace       | `dl-infra`                                    |

## Arquivos

```text
infrastructure/helm/headlamp/
├── README.md
├── values.yaml
└── version.env
```

## Decisões

* instalação pelo chart oficial;
* uma única réplica;
* Service do tipo `ClusterIP`;
* Ingress desabilitado inicialmente;
* acesso inicial somente por `port-forward`;
* operações Helm pela interface desabilitadas;
* autenticação automática com o token do Pod desabilitada;
* execução como usuário não root;
* filesystem raiz somente leitura;
* capabilities Linux removidas;
* recursos de CPU e memória definidos.

## Segurança

O chart cria inicialmente um `ClusterRoleBinding` associado ao papel `cluster-admin`.

Essa configuração será utilizada somente durante a validação inicial e deverá ser revisada antes da publicação do Headlamp na internet.

O Headlamp não será publicado sem:

* HTTPS;
* autenticação;
* revisão de RBAC;
* política de acesso administrativo.

## Validação

```bash
sudo k3s kubectl get pods -n dl-infra
sudo k3s kubectl get services -n dl-infra
sudo k3s kubectl get serviceaccounts -n dl-infra
sudo k3s kubectl get clusterrolebinding | grep headlamp
```

## Acesso temporário

```bash
sudo k3s kubectl port-forward \
  --address 127.0.0.1 \
  --namespace dl-infra \
  service/headlamp \
  8080:80
```

O acesso deverá ser feito por túnel SSH, sem abrir a porta 8080 no firewall.

## Remoção

```bash
helm uninstall headlamp --namespace dl-infra
```

A remoção da release não remove o namespace `dl-infra`.

## Histórico

| Versão | Data       | Descrição                        |
| ------ | ---------- | -------------------------------- |
| 1.0    | 2026-07-13 | Configuração inicial do Headlamp |

