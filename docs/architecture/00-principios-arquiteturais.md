# Princípios Arquiteturais da Plataforma Digitalead

**Projeto:** Plataforma Digitalead
**Documento:** Arquitetura 00
**Versão:** 1.0
**Status:** Aprovado
**Última atualização:** 2026-07-13

## 1. Objetivo

Este documento define os princípios que orientam as decisões técnicas e operacionais da Plataforma Digitalead.

Esses princípios funcionam como critérios para avaliar novas ferramentas, componentes, padrões e mudanças arquiteturais.

Uma decisão técnica não deve ser tomada apenas porque uma ferramenta é popular ou tecnicamente interessante. Ela deve resolver uma necessidade real e estar alinhada com os princípios aqui definidos.

## 2. Simplicidade antes da complexidade

A plataforma deve utilizar a solução mais simples capaz de atender adequadamente ao requisito.

Não serão adicionados componentes apenas porque são comuns em arquiteturas maiores.

Exemplos:

* iniciar com um único nó K3s em vez de três nós sem necessidade real;
* utilizar o Traefik fornecido pelo K3s em vez de instalar outro Ingress Controller imediatamente;
* utilizar SMTP externo em vez de operar um servidor próprio;
* evitar Rancher enquanto um único cluster puder ser administrado adequadamente com Headlamp, `kubectl` e documentação.

Simplicidade não significa ausência de qualidade. Significa reduzir componentes, dependências e pontos de falha desnecessários.

## 3. Custo proporcional à necessidade

A arquitetura deve acompanhar o estágio da startup.

A plataforma inicial não precisa oferecer a mesma disponibilidade de uma infraestrutura bancária, mas precisa permitir evolução sem reconstrução completa.

O investimento deverá crescer conforme aumentarem:

* número de usuários;
* volume de dados;
* receita;
* criticidade dos clientes;
* exigências de disponibilidade;
* requisitos regulatórios.

## 4. Git como fonte de verdade

Documentação, manifests, configurações não sensíveis, scripts e Helm values devem estar versionados no Git.

O estado desejado da plataforma deve poder ser compreendido analisando o repositório:

```text
midianet/digitallead
```

Alterações manuais emergenciais deverão ser posteriormente refletidas no repositório.

O Git não armazenará:

* senhas;
* tokens;
* chaves privadas;
* kubeconfigs administrativos;
* certificados privados;
* dumps de banco;
* dados pessoais;
* Secrets Kubernetes em texto puro.

## 5. Documentação antes da execução

Nenhuma alteração planejada deverá ser executada sem que estejam documentados:

1. objetivo;
2. justificativa;
3. arquivos e recursos afetados;
4. procedimento;
5. validação;
6. rollback ou estratégia de recuperação.

Em situações emergenciais, a alteração poderá ser aplicada primeiro para restabelecer o serviço, mas deverá ser documentada assim que o ambiente estiver estabilizado.

## 6. Infraestrutura reproduzível

A plataforma deverá poder ser reconstruída a partir de:

* uma nova VPS;
* repositório Git;
* backups externos;
* credenciais armazenadas em local seguro;
* documentação de bootstrap;
* scripts e manifests versionados.

Nenhum componente crítico poderá depender apenas da memória de um administrador.

## 7. Automação progressiva

Operações repetitivas devem ser automatizadas.

A evolução esperada é:

```text
Comando documentado
       ↓
Script reproduzível
       ↓
Manifest ou Helm
       ↓
Pipeline
       ↓
GitOps, quando necessário
```

A automação deverá ser adotada progressivamente, evitando criar uma plataforma excessivamente complexa antes de existir necessidade operacional.

## 8. Kubernetes padrão sempre que possível

Os recursos deverão utilizar APIs e conceitos padrões do Kubernetes:

* Deployment;
* StatefulSet;
* Service;
* Ingress;
* ConfigMap;
* Secret;
* PersistentVolumeClaim;
* NetworkPolicy;
* ResourceQuota;
* LimitRange;
* ServiceAccount;
* RBAC.

Recursos exclusivos de uma distribuição deverão ser utilizados apenas quando trouxerem benefício claro.

Esse princípio facilitará uma futura migração para K3s HA, AKS, EKS, GKE ou outra distribuição Kubernetes.

## 9. Segurança em camadas

A segurança não dependerá de um único componente.

As camadas previstas são:

```text
Provedor
   ↓
Firewall da Contabo
   ↓
Sistema operacional
   ↓
K3s e API Kubernetes
   ↓
Traefik e TLS
   ↓
Namespaces e RBAC
   ↓
NetworkPolicies
   ↓
Aplicações e autenticação
   ↓
Banco de dados e backups
```

A falha de uma camada não deve expor automaticamente todos os componentes seguintes.

## 10. Menor privilégio

Usuários, aplicações e pipelines devem receber somente as permissões necessárias.

Isso se aplica a:

* acesso SSH;
* ServiceAccounts;
* RBAC;
* credenciais de banco;
* tokens de CI/CD;
* permissões no GitHub;
* acesso ao Headlamp;
* acesso ao Grafana;
* administração do Keycloak.

Contas administrativas não devem ser utilizadas para operações rotineiras quando houver alternativa com menor privilégio.

## 11. Nenhuma porta sem justificativa

Somente portas com finalidade conhecida poderão ser expostas publicamente.

A configuração inicial permitirá:

|   Porta | Finalidade                      |
| ------: | ------------------------------- |
|  22/TCP | SSH administrativo restrito     |
|  80/TCP | HTTP e desafios de certificados |
| 443/TCP | HTTPS                           |

PostgreSQL, Prometheus, API do Kubernetes e serviços internos não deverão ser publicados indiscriminadamente.

## 12. Observabilidade desde o início

Todo componente relevante deverá permitir observar:

* disponibilidade;
* consumo de CPU;
* consumo de memória;
* uso de disco;
* erros;
* logs;
* latência;
* reinicializações;
* expiração de certificados;
* sucesso ou falha de backups.

A plataforma deverá permitir responder:

* O que falhou?
* Quando falhou?
* Qual foi o impacto?
* Qual recurso foi afetado?
* A falha está se repetindo?

## 13. Backup não é recuperação

A existência de um arquivo de backup não comprova que o ambiente pode ser recuperado.

Todo backup crítico deverá possuir:

* retenção definida;
* armazenamento externo;
* criptografia quando necessária;
* monitoramento de sucesso;
* procedimento de restauração;
* testes periódicos de restore.

O backup do PostgreSQL e o backup do estado do K3s são responsabilidades distintas.

## 14. Produção tem prioridade

Produção, QA e desenvolvimento estarão inicialmente no mesmo cluster, mas não terão a mesma prioridade.

Dev e QA deverão possuir limites capazes de evitar consumo excessivo de:

* CPU;
* memória;
* disco;
* conexões;
* retenção de logs.

Em situação de pressão de recursos, a capacidade de produção deverá ser preservada.

## 15. Ambientes separados logicamente

Os ambientes serão separados inicialmente por namespaces:

```text
dl-prod
dl-qa
dl-dev
```

Essa separação deverá ser complementada por:

* ResourceQuota;
* LimitRange;
* RBAC;
* Secrets independentes;
* ConfigMaps independentes;
* bancos ou schemas independentes;
* domínios distintos;
* políticas de rede quando aplicável.

Namespace não será tratado como isolamento físico ou como limite completo de segurança.

## 16. Versões fixadas

Não deverão ser utilizadas imagens ou dependências com a tag:

```text
latest
```

Serão fixadas versões para:

* K3s;
* imagens Docker;
* Helm charts;
* PostgreSQL;
* Keycloak;
* ferramentas de observabilidade;
* componentes adicionais.

Atualizações deverão ser planejadas, testadas e registradas.

## 17. Mudanças pequenas e reversíveis

Mudanças devem ser executadas em etapas pequenas.

Sempre que possível:

1. documentar;
2. aplicar;
3. validar;
4. observar;
5. commitar;
6. avançar para a próxima etapa.

Mudanças grandes e simultâneas dificultam troubleshooting e rollback.

## 18. Falhas devem ser esperadas

A plataforma será projetada considerando que componentes podem falhar.

Na fase single-node, a VPS inteira continuará sendo um ponto único de falha.

Essa limitação será aceita conscientemente durante a fase inicial e mitigada por:

* backups externos;
* documentação;
* scripts reproduzíveis;
* monitoramento;
* DNS controlado;
* plano de recuperação.

## 19. Evolução sem antecipação excessiva

A arquitetura deverá permitir crescimento, mas não deverá implementar antecipadamente todos os componentes de uma arquitetura futura.

Exemplos de tecnologias que serão avaliadas somente quando houver necessidade:

* Rancher;
* Argo CD;
* Longhorn;
* service mesh;
* cluster multi-node;
* PostgreSQL altamente disponível;
* Vault;
* operadores complexos;
* múltiplos clusters.

Preparar para evolução não significa operar hoje toda a complexidade do futuro.

## 20. Conhecimento pertence ao time

O conhecimento da plataforma deverá estar no repositório e ser compreensível por outros engenheiros.

A infraestrutura não poderá depender exclusivamente:

* de uma pessoa;
* de comandos armazenados no histórico do terminal;
* de configurações realizadas pela interface gráfica;
* de documentação privada não compartilhada;
* da memória de quem instalou o ambiente.

## 21. Critérios para adoção de uma ferramenta

Antes de adicionar uma nova ferramenta, deverão ser respondidas as seguintes perguntas:

1. Qual problema real ela resolve?
2. O problema já existe ou é apenas hipotético?
3. Existe solução mais simples?
4. Qual é o consumo de CPU, memória e disco?
5. Como será atualizada?
6. Como será feito backup?
7. Como será removida?
8. Quem será responsável pela manutenção?
9. Ela cria dependência proprietária?
10. Ela melhora a plataforma mais do que aumenta sua complexidade?

## 22. Histórico de alterações

| Versão | Data       | Descrição                            |
| ------ | ---------- | ------------------------------------ |
| 1.0    | 2026-07-13 | Criação dos princípios arquiteturais |

