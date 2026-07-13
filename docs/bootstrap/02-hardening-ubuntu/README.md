# Bootstrap 02 — Preparação e hardening do Ubuntu

**Projeto:** Plataforma Digitalead
**Documento:** Bootstrap 02
**Versão:** 1.0
**Status:** Em implantação
**Última atualização:** 2026-07-13

---

## 1. Objetivo

Preparar e proteger o sistema operacional Ubuntu que hospedará o cluster K3s da Plataforma Digitalead.

Ao final desta etapa, o servidor deverá possuir:

* hostname padronizado;
* timezone `America/Sao_Paulo`;
* relógio sincronizado por NTP;
* sistema operacional atualizado;
* ferramentas administrativas básicas;
* acesso SSH validado;
* política de firewall definida;
* ausência de serviços desnecessários;
* estado do servidor registrado e reproduzível.

A instalação do K3s será realizada apenas no Bootstrap 03.

---

## 2. Informações do servidor

| Item                | Valor                     |
| ------------------- | ------------------------- |
| Provedor            | Contabo                   |
| Hostname inicial    | `vmi3434902`              |
| Hostname definitivo | `dl-platform-01`          |
| Sistema operacional | Ubuntu Server 24.04.4 LTS |
| Kernel inicial      | Linux 6.8.0-134-generic   |
| CPU                 | 8 vCPU                    |
| Memória             | 24 GB                     |
| Disco               | 200 GB                    |
| IPv4 público        | `217.216.55.208`          |
| Interface de rede   | `eth0`                    |
| Timezone inicial    | `Europe/Berlin`           |
| Timezone definitivo | `America/Sao_Paulo`       |

---

## 3. Decisões arquiteturais

### 3.1 Hostname

O servidor utilizará:

```text
dl-platform-01
```

O nome não contém referência exclusiva a produção porque a VPS hospedará os ambientes:

* produção;
* QA;
* desenvolvimento;
* infraestrutura;
* monitoramento;
* logging.

Em uma futura expansão, os próximos servidores poderão ser nomeados:

```text
dl-platform-02
dl-platform-03
```

### 3.2 Timezone

O timezone do sistema será:

```text
America/Sao_Paulo
```

Essa configuração será usada para:

* logs do sistema operacional;
* registros de auditoria;
* execução de scripts;
* backups;
* CronJobs;
* análise de incidentes.

O relógio de hardware continuará usando UTC.

### 3.3 Sincronização de horário

O servidor deverá manter:

```text
System clock synchronized: yes
NTP service: active
RTC in local TZ: no
```

O timezone altera apenas a apresentação local do horário. A referência interna do relógio continuará baseada em UTC.

### 3.4 Swap

O servidor será mantido inicialmente sem swap.

Estado esperado:

```text
Swap: 0B
```

Essa decisão poderá ser revisada após análise do comportamento dos workloads e da configuração do kubelet.

### 3.5 Firewall

A segurança de entrada será realizada inicialmente pelo firewall da Contabo.

Portas públicas permitidas:

| Porta | Protocolo | Origem                          | Finalidade                    |
| ----: | --------- | ------------------------------- | ----------------------------- |
|    22 | TCP       | IPs administrativos autorizados | SSH                           |
|    80 | TCP       | Internet                        | HTTP e desafio de certificado |
|   443 | TCP       | Internet                        | HTTPS                         |

O UFW permanecerá desativado durante a instalação inicial do K3s.

Motivo: o K3s utiliza redes internas para Pods e Services e modifica regras de rede no host. Um firewall local configurado incorretamente pode impedir a comunicação interna do cluster.

Redes padrão previstas do K3s:

| Rede     | CIDR padrão    |
| -------- | -------------- |
| Pods     | `10.42.0.0/16` |
| Services | `10.43.0.0/16` |

Caso o UFW seja ativado futuramente, essas redes precisarão ser explicitamente autorizadas.

A API Kubernetes na porta `6443/TCP` não deverá ficar aberta para toda a Internet.

### 3.6 SSH

O acesso SSH será endurecido em uma subetapa separada.

Antes de desabilitar autenticação por senha ou acesso direto do usuário `root`, será obrigatório:

1. criar um usuário administrativo;
2. instalar sua chave pública SSH;
3. validar uma segunda sessão SSH;
4. confirmar que o usuário possui acesso por `sudo`;
5. manter a sessão atual aberta durante o teste.

Nenhuma alteração capaz de bloquear o acesso remoto será aplicada sem validação prévia.

### 3.7 Atualizações

A imagem fornecida pelo provedor deverá ser atualizada antes da instalação do K3s.

Serão executadas:

* atualização do índice de pacotes;
* instalação das atualizações disponíveis;
* remoção de dependências não utilizadas;
* verificação de necessidade de reboot.

### 3.8 Versões

Não serão utilizados componentes identificados apenas como `latest`.

As versões relevantes serão registradas na documentação e fixadas sempre que tecnicamente possível.

---

## 4. Alterações previstas

Esta etapa alterará:

```text
/etc/hostname
/etc/machine-info
/etc/localtime
```

Também poderá atualizar:

```text
/etc/hosts
```

Serão instalados pacotes administrativos por meio do APT.

A configuração SSH somente será modificada após a criação e validação do usuário administrativo.

---

## 5. Procedimento

### 5.1 Confirmar o diretório do repositório

```bash
cd /opt/digitallead
git status
```

### 5.2 Configurar o timezone

```bash
sudo timedatectl set-timezone America/Sao_Paulo
```

Essa alteração não modifica manualmente o relógio; ela altera a forma como o horário é apresentado pelo sistema.

### 5.3 Validar timezone e sincronização

```bash
timedatectl
```

Resultado esperado:

```text
Time zone: America/Sao_Paulo (-03, -0300)
System clock synchronized: yes
NTP service: active
RTC in local TZ: no
```

### 5.4 Configurar o hostname

```bash
sudo hostnamectl set-hostname dl-platform-01
```

### 5.5 Validar o hostname

```bash
hostname
hostnamectl
```

Resultado esperado:

```text
dl-platform-01
```

### 5.6 Verificar `/etc/hosts`

```bash
cat /etc/hosts
```

Deve existir uma resolução local para o hostname. A linha recomendada é:

```text
127.0.1.1 dl-platform-01
```

Se ainda houver referência ao hostname antigo, editar o arquivo:

```bash
sudoedit /etc/hosts
```

Não remover as entradas de `localhost` ou IPv6.

### 5.7 Atualizar o sistema operacional

```bash
sudo apt update
sudo apt full-upgrade -y
sudo apt autoremove -y
```

### 5.8 Verificar necessidade de reinicialização

```bash
if [ -f /var/run/reboot-required ]; then
  echo "REBOOT_REQUIRED=yes"
  cat /var/run/reboot-required.pkgs 2>/dev/null || true
else
  echo "REBOOT_REQUIRED=no"
fi
```

### 5.9 Instalar ferramentas administrativas

```bash
sudo apt install -y \
  ca-certificates \
  curl \
  dnsutils \
  git \
  htop \
  jq \
  net-tools \
  tree \
  unzip \
  vim \
  wget
```

### 5.10 Confirmar o firewall local

```bash
sudo ufw status verbose
```

Resultado esperado nesta fase:

```text
Status: inactive
```

### 5.11 Confirmar serviços e portas

```bash
sudo ss -lntup
```

Antes da instalação do K3s, espera-se somente o SSH exposto publicamente.

### 5.12 Reiniciar, se necessário

Executar somente se `/var/run/reboot-required` existir:

```bash
sudo reboot
```

Após a reinicialização, reconectar por SSH.

---

## 6. Validação final

Executar:

```bash
echo "=== HOSTNAME ==="
hostnamectl

echo
echo "=== TIMEZONE ==="
timedatectl

echo
echo "=== SISTEMA ==="
cat /etc/os-release
uname -r

echo
echo "=== MEMÓRIA E SWAP ==="
free -h
swapon --show

echo
echo "=== DISCO ==="
df -hT /

echo
echo "=== FIREWALL LOCAL ==="
sudo ufw status verbose

echo
echo "=== PORTAS ==="
sudo ss -lntup

echo
echo "=== PACOTES COM ATUALIZAÇÃO PENDENTE ==="
apt list --upgradable 2>/dev/null
```

Critérios de aceite:

* hostname igual a `dl-platform-01`;
* timezone igual a `America/Sao_Paulo`;
* relógio sincronizado;
* NTP ativo;
* swap desativada;
* UFW inativo nesta fase;
* nenhuma atualização crítica pendente;
* SSH funcional;
* nenhuma aplicação desconhecida escutando portas públicas.

---

## 7. Rollback

### 7.1 Restaurar o timezone anterior

```bash
sudo timedatectl set-timezone Europe/Berlin
```

### 7.2 Restaurar o hostname anterior

```bash
sudo hostnamectl set-hostname vmi3434902
```

Também restaurar a referência correspondente em:

```text
/etc/hosts
```

### 7.3 Desinstalar uma ferramenta administrativa

```bash
sudo apt remove NOME_DO_PACOTE
```

Os upgrades do sistema operacional não devem ser revertidos sem análise individual dos pacotes afetados.

---

## 8. Troubleshooting

### O terminal ainda mostra o hostname antigo

Abra uma nova sessão SSH ou execute:

```bash
exec bash
```

### O comando `sudo` informa que não consegue resolver o hostname

Verifique:

```bash
cat /etc/hostname
cat /etc/hosts
```

O hostname definido em `/etc/hostname` deve possuir uma entrada correspondente em `/etc/hosts`.

### A conexão SSH caiu após reiniciar

Verifique pelo console da Contabo:

```bash
systemctl status ssh
ss -lntp | grep ':22'
```

### O relógio não está sincronizado

Verifique:

```bash
timedatectl
systemctl status systemd-timesyncd
```

---

## 9. Referências

* Ubuntu Server — gerenciamento de horário com `timedatectl`;
* Ubuntu Security — firewall e Netfilter;
* K3s — requisitos de rede e firewall.

---

## 10. Histórico de alterações

| Versão | Data       | Descrição                                         |
| ------ | ---------- | ------------------------------------------------- |
| 1.0    | 2026-07-13 | Criação do procedimento de preparação e hardening |

