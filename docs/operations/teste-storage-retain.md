# Teste da StorageClass `dl-local-retain`

## Objetivo

Comprovar o funcionamento da StorageClass `dl-local-retain`, incluindo:

* provisionamento dinâmico;
* gravação e leitura de dados;
* localização física do volume;
* comportamento após exclusão do PVC;
* preservação do PV com política `Retain`.

## Recursos utilizados

* Namespace: `dl-infra`
* PVC: `retain-pvc-test`
* Pod: `retain-pvc-test`
* StorageClass: `dl-local-retain`
* Capacidade solicitada: `100Mi`

## Aplicação

```bash
sudo k3s kubectl apply \
  -f infrastructure/storage/tests/retain-pvc-test.yaml
```

## Validação inicial

```bash
sudo k3s kubectl get pod,pvc \
  -n dl-infra
```

O Pod deve ficar `Running` e o PVC deve ficar `Bound`.

## Identificação do PV

```bash
PV_NAME="$(
  sudo k3s kubectl get pvc retain-pvc-test \
    -n dl-infra \
    -o jsonpath='{.spec.volumeName}'
)"

echo "${PV_NAME}"
```

## Gravação de dados

```bash
sudo k3s kubectl exec \
  -n dl-infra \
  retain-pvc-test \
  -- sh -c '
    date --iso-8601=seconds > /data/teste.txt
    echo "Plataforma Digitalead" >> /data/teste.txt
    sync
  '
```

## Leitura dos dados

```bash
sudo k3s kubectl exec \
  -n dl-infra \
  retain-pvc-test \
  -- cat /data/teste.txt
```

## Localização física

```bash
sudo k3s kubectl get pv "${PV_NAME}" \
  -o jsonpath='{.spec.hostPath.path}{"\n"}'
```

Validar no host:

```bash
VOLUME_PATH="$(
  sudo k3s kubectl get pv "${PV_NAME}" \
    -o jsonpath='{.spec.hostPath.path}'
)"

sudo find "${VOLUME_PATH}" \
  -maxdepth 2 \
  -ls
```

## Teste de reinicialização do Pod

Excluir somente o Pod:

```bash
sudo k3s kubectl delete pod retain-pvc-test \
  -n dl-infra
```

Reaplicar o manifesto:

```bash
sudo k3s kubectl apply \
  -f infrastructure/storage/tests/retain-pvc-test.yaml
```

Após o Pod ficar `Running`, validar:

```bash
sudo k3s kubectl exec \
  -n dl-infra \
  retain-pvc-test \
  -- cat /data/teste.txt
```

O conteúdo deve continuar presente.

## Teste da política `Retain`

Primeiro remover o Pod:

```bash
sudo k3s kubectl delete pod retain-pvc-test \
  -n dl-infra
```

Depois remover somente o PVC:

```bash
sudo k3s kubectl delete pvc retain-pvc-test \
  -n dl-infra
```

Consultar o PV:

```bash
sudo k3s kubectl get pv "${PV_NAME}"
```

O PV deverá permanecer e normalmente apresentar:

```text
STATUS: Released
RECLAIM POLICY: Retain
```

## Verificação física após exclusão do PVC

```bash
sudo test -d "${VOLUME_PATH}" \
  && echo "Diretório preservado" \
  || echo "Diretório não encontrado"

sudo find "${VOLUME_PATH}" \
  -maxdepth 2 \
  -ls
```

O arquivo `teste.txt` deverá continuar no disco.

## Limpeza manual

A política `Retain` exige limpeza manual.

Somente após confirmar que os dados não são mais necessários:

```bash
sudo k3s kubectl delete pv "${PV_NAME}"
sudo rm -rf -- "${VOLUME_PATH}"
```

A exclusão manual é destrutiva e deve ser executada somente após validar o caminho apresentado.

## Resultado esperado

* PVC criado dinamicamente;
* PV associado ao disco local;
* dados preservados após recriação do Pod;
* PV preservado após exclusão do PVC;
* diretório físico preservado;
* limpeza realizada somente de forma manual e consciente.

