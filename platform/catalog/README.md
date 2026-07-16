# Catálogo da Plataforma Digitalead

## Objetivo

Este diretório contém a descrição canônica dos serviços que compõem a Plataforma Digitalead.

Cada serviço possui um arquivo YAML do tipo:

```text
PlatformService
```

Esses arquivos descrevem o serviço independentemente da ferramenta utilizada para implantá-lo.

## Fonte de verdade

O catálogo registra informações como:

* identificador;
* finalidade;
* responsável;
* namespace;
* versão;
* método de implantação;
* domínio;
* portas;
* persistência;
* backup;
* observabilidade;
* dependências;
* consumidores;
* riscos;
* documentação.

Os manifests Kubernetes e arquivos Helm continuam sendo a fonte de verdade da implementação.

O catálogo é a fonte de verdade da visão arquitetural e operacional do serviço.

## Estrutura

```text
platform/catalog/
├── README.md
├── examples/
├── schemas/
├── services/
└── templates/
```

## Serviços cadastrados

| ID      | Serviço    | Domínio | Criticidade | Ciclo de vida |
| ------- | ---------- | ------- | ----------- | ------------- |
| PLT-101 | PostgreSQL | Data    | Critical    | Production    |

## Convenção de identificadores

| Faixa             | Categoria               |
| ----------------- | ----------------------- |
| PLT-001 a PLT-099 | Núcleo da plataforma    |
| PLT-100 a PLT-199 | Dados                   |
| PLT-200 a PLT-299 | Segurança e identidade  |
| PLT-300 a PLT-399 | Observabilidade         |
| PLT-400 a PLT-499 | Integração e mensageria |
| PLT-500 a PLT-599 | Backup e recuperação    |
| APP-001 em diante | Aplicações Digitalead   |

## Regras

* O identificador de um serviço não deve ser reutilizado.
* O nome técnico deve usar letras minúsculas e hífens.
* Credenciais e dados sensíveis não devem ser registrados.
* Caminhos de documentação devem ser relativos à raiz do repositório.
* Dependências devem preferencialmente referenciar o ID do serviço.
* Mudanças arquiteturais relevantes devem atualizar o catálogo.
* Serviços removidos devem usar o ciclo de vida `retired`, preservando seu histórico.

## Ciclos de vida

```text
planned
building
production
deprecated
retired
```

## Criticidade

```text
low
medium
high
critical
```

## Evolução prevista

O catálogo poderá futuramente alimentar:

* Backstage;
* LeanIX;
* geração de diagramas Draw.io;
* documentação automática;
* inventário de componentes;
* análise de dependências;
* MCP Server;
* consultas com inteligência artificial;
* relatórios de riscos e conformidade.

