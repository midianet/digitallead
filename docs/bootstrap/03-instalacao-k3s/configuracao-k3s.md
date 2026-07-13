# Configuração Declarativa do K3s

**Projeto:** Plataforma Digitalead
**Documento:** Bootstrap 03 — Configuração do K3s
**Versão:** 1.0
**Status:** Aprovado
**Última atualização:** 2026-07-13

## Objetivo

Documentar a configuração declarativa utilizada pelo servidor K3s da Plataforma Digitalead.

A fonte de verdade da configuração é:

```text
infrastructure/k3s/config.yaml
```

Durante o bootstrap, esse arquivo será copiado para:

```text
/etc/rancher/k3s/config.yaml
```

O K3s carrega automaticamente esse arquivo durante sua inicialização.

## Decisão arquitetural

A configuração do cluster não será mantida exclusivamente no sistema operacional.

Ela será versionada no Git para permitir:

* auditoria;
* revisão por diff;
* reprodução do ambiente;
* recuperação de desastre;
* criação futura de novos servidores;
* registro das decisões técnicas.

O arquivo versionado não deverá conter:

* token de entrada do cluster;
* senhas;
* chaves privadas;
* credenciais;
* kubeconfig;
* dados sensíveis.

## Configuração adotada

```yaml
node-name: dl-platform-01

secrets-encryption: true

write-kubeconfig-mode: "0600"

tls-san:
  - "217.216.55.208"
  - "dl-platform-01"

node-label:
  - "digitallead.com.br/platform=core"
  - "digitallead.com.br/environment=shared"
  - "digitallead.com.br/provider=contabo"

cluster-cidr: "10.42.0.0/16"
service-cidr: "10.43.0.0/16"
cluster-dns: "10.43.0.10"
cluster-domain: "cluster.local"

data-dir: "/var/lib/rancher/k3s"
```

## Explicação das propriedades

### `node-name`

Define o nome pelo qual o nó será conhecido no Kubernetes.

Valor:

```text
dl-platform-01
```

### `secrets-encryption`

Habilita criptografia em repouso para Secrets armazenados no datastore do Kubernetes.

Essa configuração não elimina a necessidade de proteger:

* o acesso ao servidor;
* o diretório de dados do K3s;
* os backups;
* as chaves de criptografia;
* o token do cluster.

### `write-kubeconfig-mode`

Define as permissões do kubeconfig administrativo gerado pelo K3s.

O valor `0600` permite leitura e escrita apenas para o proprietário do arquivo, normalmente `root`.

### `tls-san`

Adiciona nomes ou endereços ao certificado TLS da API Kubernetes.

Foram adicionados:

```text
217.216.55.208
dl-platform-01
```

Isso não significa que a API Kubernetes será exposta publicamente. A exposição da porta `6443/TCP` continuará controlada pelo firewall.

### `node-label`

Adiciona metadados ao nó.

Labels adotadas:

```text
digitallead.com.br/platform=core
digitallead.com.br/environment=shared
digitallead.com.br/provider=contabo
```

O uso do domínio da organização como prefixo reduz o risco de conflito com labels de terceiros.

### `cluster-cidr`

Rede reservada para endereços IP dos Pods:

```text
10.42.0.0/16
```

### `service-cidr`

Rede virtual reservada para Services Kubernetes:

```text
10.43.0.0/16
```

### `cluster-dns`

Endereço virtual do serviço DNS interno do cluster:

```text
10.43.0.10
```

Esse endereço pertence ao CIDR de Services.

### `cluster-domain`

Sufixo DNS interno dos Services:

```text
cluster.local
```

Exemplo de nome completo:

```text
backend.dl-prod.svc.cluster.local
```

### `data-dir`

Diretório principal de estado do K3s:

```text
/var/lib/rancher/k3s
```

Esse diretório deve ser incluído na estratégia de recuperação da plataforma.

## Componentes mantidos

A configuração não desabilita componentes empacotados do K3s.

Permanecerão habilitados:

* Traefik;
* ServiceLB;
* CoreDNS;
* Metrics Server;
* Local Path Provisioner.

### Motivo para manter o ServiceLB

O Traefik padrão do K3s utiliza um Service do tipo `LoadBalancer`.

O ServiceLB permite que esse Service utilize as portas `80` e `443` do host.

Como a VPS é dedicada ao K3s, esse comportamento atende diretamente à arquitetura planejada.

## Aplicação da configuração

Antes da instalação do K3s:

```bash
sudo mkdir -p /etc/rancher/k3s

sudo install \
  -o root \
  -g root \
  -m 600 \
  infrastructure/k3s/config.yaml \
  /etc/rancher/k3s/config.yaml
```

O comando `install` foi escolhido porque permite copiar o arquivo e definir proprietário e permissões na mesma operação.

## Validação

```bash
sudo ls -l /etc/rancher/k3s/config.yaml
sudo cat /etc/rancher/k3s/config.yaml
```

Permissão esperada:

```text
-rw------- root root
```

Após a instalação do K3s:

```bash
sudo k3s kubectl get node dl-platform-01 --show-labels
sudo k3s secrets-encrypt status
```

## Rollback

Antes da instalação do K3s, a configuração pode ser removida com:

```bash
sudo rm /etc/rancher/k3s/config.yaml
```

Após a instalação, alterações no arquivo exigem análise individual e reinicialização controlada do serviço:

```bash
sudo systemctl restart k3s
```

Esse restart não deverá ser realizado sem validar previamente a opção alterada.

## Histórico de alterações

| Versão | Data       | Descrição                                   |
| ------ | ---------- | ------------------------------------------- |
| 1.0    | 2026-07-13 | Criação da configuração declarativa inicial |

