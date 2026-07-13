# Padrão de documentação da Plataforma Digitalead

## Objetivo

Definir a estrutura mínima que deve ser utilizada nos documentos técnicos e operacionais da Plataforma Digitalead.

## Estrutura obrigatória

Cada procedimento de instalação, configuração ou operação deve conter as seguintes seções.

### 1. Objetivo

Descrever o resultado esperado ao final do procedimento.

### 2. Pré-requisitos

Informar recursos, acessos, versões e dependências necessárias.

### 3. Decisões arquiteturais

Registrar por que determinada solução ou configuração foi adotada.

### 4. Alterações realizadas

Listar os arquivos, serviços, portas e recursos que serão modificados.

### 5. Procedimento

Apresentar os comandos em ordem de execução.

Cada comando deve ser acompanhado por uma explicação objetiva.

### 6. Validação

Apresentar comandos ou testes capazes de confirmar que o procedimento foi concluído corretamente.

### 7. Rollback

Explicar como desfazer a alteração ou retornar ao estado anterior.

### 8. Troubleshooting

Registrar erros conhecidos, sintomas e formas de diagnóstico.

### 9. Referências

Incluir links para documentações oficiais utilizadas como referência.

### 10. Histórico de alterações

Utilizar o seguinte formato:

| Versão | Data       | Descrição       |
| ------ | ---------- | --------------- |
| 1.0    | AAAA-MM-DD | Criação inicial |

## Regras

* Não armazenar senhas, tokens ou chaves privadas.
* Não utilizar versões `latest`.
* Não registrar comandos destrutivos sem aviso explícito.
* Todo comando deve ser reproduzível.
* Todo procedimento deve possuir uma etapa de validação.
* Operações críticas devem possuir rollback ou estratégia de recuperação.
* Horários e datas operacionais devem usar o timezone `America/Sao_Paulo`.

