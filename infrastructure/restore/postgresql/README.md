# PostgreSQL Restore Validation

Valida os backups do PostgreSQL restaurando cada banco em uma base temporária.

## Comportamento

1. Localiza o backup mais recente.
2. Valida os checksums.
3. Valida o arquivo de objetos globais.
4. Cria um banco temporário para cada dump.
5. Executa o restore.
6. Valida conexão, schemas, tabelas e tamanho.
7. Remove os bancos temporários.

Nenhum banco de produção é sobrescrito.

## Executar

```bash
kubectl delete job postgresql-restore-validation \
  -n dl-database \
  --ignore-not-found

kubectl apply -k infrastructure/restore/postgresql
