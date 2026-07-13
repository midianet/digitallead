# Bootstrap 03 — Instalação do K3s

**Projeto:** Plataforma Digitalead
**Documento:** Bootstrap 03
**Versão:** 1.0
**Status:** Em implantação
**Última atualização:** 2026-07-13

## 1. Objetivo

Instalar o K3s single-node da Plataforma Digitalead de maneira documentada, versionada e reproduzível.

Ao final desta etapa, o servidor deverá possuir:

* K3s instalado como serviço systemd;
* nó `dl-platform-01` em estado `Ready`;
* containerd funcionando;
* datastore SQLite inicializado;
* Traefik instalado;
* ServiceLB instalado;
* CoreDNS instalado;
* Metrics Server instalado;
* Local Path Provisioner instalado;
* criptografia de Secrets habilitada;
* kubeconfig administrativo gerado.

## 2. Versão aprovada

A versão inicial aprovada é:

```text
v1.35.6+k3s1
```

A versão está registrada em:

```text
infrastructure/k3s/version.env
```

Não será utilizada uma versão indeterminada ou a tag `latest`.

## 3. Fontes de verdade

### Versão

```text
infrastructure/k3s/version.env
```

### Configuração do servidor

```text
infrastructure/k3s/config.yaml
```

### Script de instalação

```text
scripts/server/install-k3s.sh
```

### Destino da configuração

```text
/etc/rancher/k3s/config.yaml
```

## 4. Pré-requisitos

Antes da instalação:

* Ubuntu Server 24.04 LTS atualizado;
* hostname `dl-platform-01`;
* timezone `America/Sao_Paulo`;
* acesso de root ou sudo;
* DNS configurado;
* portas públicas 80 e 443 disponíveis;
* nenhum Docker ou Kubernetes anterior instalado;
* configuração do K3s versionada;
* alterações já enviadas ao Git.

Validações:

```bash
hostname
timedatectl
sudo ss -lntup
git status
```

## 5. Decisões arquiteturais

### Distribuição

Será utilizado K3s em modo single-node.

### Datastore

Será utilizado SQLite embarcado.

### Runtime

Será utilizado containerd fornecido pelo K3s.

Docker não será instalado.

### Ingress Controller

O Traefik empacotado pelo K3s será mantido.

### ServiceLB

O ServiceLB será mantido porque permitirá ao Service `LoadBalancer` do Traefik utilizar as portas 80 e 443 da VPS.

### Persistência inicial

O Local Path Provisioner será mantido para utilização do disco local.

### Criptografia

A criptografia de Secrets em repouso será habilitada desde a criação do cluster.

## 6. Procedimento

### 6.1 Acessar o repositório

```bash
cd /opt/digitallead
```

### 6.2 Validar a configuração versionada

```bash
cat infrastructure/k3s/version.env
cat infrastructure/k3s/config.yaml
bash -n scripts/server/install-k3s.sh
```

### 6.3 Executar a instalação

```bash
sudo ./scripts/server/install-k3s.sh
```

O script:

1. valida se está sendo executado como root;
2. carrega a versão aprovada;
3. valida o hostname;
4. copia o `config.yaml`;
5. baixa o instalador oficial;
6. fixa a versão por `INSTALL_K3S_VERSION`;
7. instala e inicia o serviço;
8. aguarda o nó ficar `Ready`;
9. valida os componentes principais.

## 7. Arquivos criados pelo K3s

### Binário

```text
/usr/local/bin/k3s
```

### Serviço systemd

```text
/etc/systemd/system/k3s.service
```

### Variáveis do serviço

```text
/etc/systemd/system/k3s.service.env
```

### Configuração

```text
/etc/rancher/k3s/config.yaml
```

### Kubeconfig

```text
/etc/rancher/k3s/k3s.yaml
```

### Dados

```text
/var/lib/rancher/k3s
```

### Script de remoção

```text
/usr/local/bin/k3s-uninstall.sh
```

O kubeconfig e o diretório de dados não devem ser armazenados no Git.

## 8. Validação

### Serviço

```bash
sudo systemctl status k3s --no-pager
sudo systemctl is-enabled k3s
sudo systemctl is-active k3s
```

### Versão

```bash
sudo k3s --version
```

### Nó

```bash
sudo k3s kubectl get nodes -o wide
```

Resultado esperado:

```text
dl-platform-01   Ready
```

### Pods de sistema

```bash
sudo k3s kubectl get pods -n kube-system -o wide
```

Os Pods podem levar alguns minutos para ficar prontos porque as imagens precisam ser baixadas.

### Services

```bash
sudo k3s kubectl get services -n kube-system
```

### StorageClass

```bash
sudo k3s kubectl get storageclass
```

Resultado esperado:

```text
local-path
```

### Métricas

Após o Metrics Server ficar pronto:

```bash
sudo k3s kubectl top node
sudo k3s kubectl top pods -n kube-system
```

### Criptografia

```bash
sudo k3s secrets-encrypt status
```

O resultado deverá indicar que a criptografia está habilitada.

### Portas

```bash
sudo ss -lntup
```

Após a instalação, devem aparecer, entre outras:

* `6443/TCP` — API Kubernetes;
* `80/TCP` — entrada HTTP do Traefik/ServiceLB;
* `443/TCP` — entrada HTTPS do Traefik/ServiceLB.

A exposição externa dessas portas continuará sendo controlada pelo firewall da Contabo.

## 9. Logs

Logs do serviço:

```bash
sudo journalctl -u k3s --no-pager -n 200
```

Logs em tempo real:

```bash
sudo journalctl -u k3s -f
```

Eventos Kubernetes:

```bash
sudo k3s kubectl get events \
  --all-namespaces \
  --sort-by='.metadata.creationTimestamp'
```

## 10. Reinicialização

Teste de reinicialização:

```bash
sudo reboot
```

Após reconectar:

```bash
sudo systemctl is-active k3s
sudo k3s kubectl get nodes
sudo k3s kubectl get pods -A
```

O nó deve retornar automaticamente ao estado `Ready`.

## 11. Rollback

Como esta ainda é a instalação inicial e não existem workloads, o K3s pode ser removido com:

```bash
sudo /usr/local/bin/k3s-uninstall.sh
```

Atenção: esse script remove o cluster e seus dados locais.

Depois da existência de aplicações ou dados persistentes, ele não deverá ser executado sem backup e plano de recuperação.

Após a remoção, validar:

```bash
systemctl status k3s || true
ls -la /etc/rancher/k3s || true
ls -la /var/lib/rancher/k3s || true
```

A configuração versionada permanecerá no Git.

## 12. Troubleshooting

### Serviço não iniciou

```bash
sudo systemctl status k3s --no-pager
sudo journalctl -u k3s --no-pager -n 200
```

### Nó permanece `NotReady`

```bash
sudo k3s kubectl describe node dl-platform-01
sudo k3s kubectl get pods -A
sudo journalctl -u k3s --no-pager -n 200
```

### Pods em `ImagePullBackOff`

```bash
sudo k3s kubectl describe pod \
  NOME_DO_POD \
  -n NAMESPACE
```

Verificar:

* conectividade com a Internet;
* DNS;
* acesso aos registries;
* espaço em disco.

### Porta 80 ou 443 não está disponível

```bash
sudo ss -lntup | grep -E ':(80|443)\b'
```

Verificar se outro serviço está ocupando a porta.

### Configuração YAML inválida

```bash
sudo journalctl -u k3s --no-pager -n 100
sudo cat /etc/rancher/k3s/config.yaml
```

## 13. Critérios de aceite

A etapa estará concluída quando:

* serviço `k3s` estiver ativo e habilitado;
* versão instalada for `v1.35.6+k3s1`;
* nó estiver `Ready`;
* Pods do `kube-system` estiverem saudáveis;
* Traefik utilizar 80 e 443;
* `local-path` estiver disponível;
* Metrics Server responder;
* criptografia de Secrets estiver habilitada;
* cluster sobreviver a um reboot;
* documentação e scripts estiverem no Git.

## 14. Histórico de alterações

| Versão | Data       | Descrição                                    |
| ------ | ---------- | -------------------------------------------- |
| 1.0    | 2026-07-13 | Criação do procedimento de instalação do K3s |

