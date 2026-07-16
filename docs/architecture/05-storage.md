# Arquitetura de Persistência

**Projeto:** Plataforma Digitalead
**Documento:** Arquitetura 05
**Versão:** 1.0
**Status:** Aprovado
**Última atualização:** 2026-07-16

## 1. Objetivo

Documentar a estratégia inicial de armazenamento persistente da Plataforma Digitalead.

## 2. Contexto

A plataforma utiliza inicialmente:

* uma única VPS;
* um único nó K3s;
* um único disco de 200 GB;
* Local Path Provisioner fornecido pelo K3s.

Essa arquitetura não oferece replicação física dos volumes nem alta disponibilidade.

## 3. Caminho físico

O Local Path Provisioner está configurado para armazenar volumes em:

```text
/var/lib/rancher/k3s/storage
```

Fluxo:

```text
PersistentVolumeClaim
        ↓
StorageClass
        ↓
Local Path Provisioner
        ↓
PersistentVolume
        ↓
Diretório local
        ↓
Disco da VPS
```

## 4. StorageClass padrão

O K3s criou:

```text
local-path
```

Configuração observada:

| Propriedade       | Valor                   |
| ----------------- | ----------------------- |
| Provisioner       | `rancher.io/local-path` |
| ReclaimPolicy     | `Delete`                |
| VolumeBindingMode | `WaitForFirstConsumer`  |
| Expansão          | Não suportada           |
| Classe padrão     | Sim                     |

Essa StorageClass será utilizada apenas para volumes descartáveis ou de baixo risco.

## 5. StorageClass para dados persistentes

A plataforma adiciona:

```text
dl-local-retain
```

Configuração:

| Propriedade       | Valor                   |
| ----------------- | ----------------------- |
| Provisioner       | `rancher.io/local-path` |
| ReclaimPolicy     | `Retain`                |
| VolumeBindingMode | `WaitForFirstConsumer`  |
| Expansão          | Não suportada           |
| Classe padrão     | Não                     |

Ela deverá ser selecionada explicitamente:

```yaml
storageClassName: dl-local-retain
```

## 6. Utilização prevista

### `local-path`

Pode ser utilizada para:

* testes temporários;
* caches reconstruíveis;
* dados descartáveis;
* ambientes efêmeros.

### `dl-local-retain`

Deverá ser utilizada para:

* PostgreSQL;
* dados persistentes do Keycloak;
* armazenamento de logs;
* dados do monitoramento;
* outros workloads stateful importantes.

## 7. Significado de `Retain`

A política `Retain` reduz o risco de perda causada pela exclusão acidental de um PVC.

Quando o PVC é removido, o PV pode permanecer em estado `Released`, e os dados físicos não são automaticamente reciclados para outro PVC.

A recuperação e a limpeza passam a exigir procedimento manual.

`Retain` não substitui backup.

## 8. Limitações

A arquitetura atual possui as seguintes limitações:

* dados ligados ao único nó;
* indisponibilidade durante falha da VPS;
* ausência de replicação;
* ausência de expansão automática do PVC;
* perda potencial em caso de falha definitiva do disco;
* competição entre sistema operacional, containers, logs e volumes pelo mesmo disco.

## 9. Capacidade do disco

O disco possui aproximadamente 200 GB.

A plataforma deverá monitorar:

```text
/
```

e principalmente:

```text
/var/lib/rancher/k3s
/var/lib/rancher/k3s/storage
/var/lib/rancher/k3s/agent/containerd
```

O uso total não deverá ultrapassar 70% de forma sustentada.

## 10. Backup

O backup deverá ser armazenado fora da VPS.

Serão tratados separadamente:

1. backup lógico do PostgreSQL;
2. backup dos dados persistentes;
3. backup do datastore do K3s;
4. backup das chaves e configurações necessárias à recuperação.

Copiar apenas o diretório do volume enquanto o banco está em execução não será considerado estratégia suficiente de backup do PostgreSQL.

## 11. Evolução futura

Quando a plataforma migrar para múltiplos nós, o armazenamento deverá ser reavaliado.

Alternativas possíveis:

* disco dedicado;
* storage distribuído;
* Longhorn;
* banco de dados gerenciado;
* serviço de block storage do provedor;
* PostgreSQL fora do cluster.

A escolha dependerá de disponibilidade, desempenho, custo e capacidade operacional.

## 12. Histórico de alterações

| Versão | Data       | Descrição                                        |
| ------ | ---------- | ------------------------------------------------ |
| 1.0    | 2026-07-16 | Definição da estratégia inicial de armazenamento |

