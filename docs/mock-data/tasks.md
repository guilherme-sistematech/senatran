# Tarefas

Fluxo previsto: `TODO → IN_PROGRESS → IMPLEMENTED → REVIEWED → APPROVED`. Quando houver findings, aplica-se o ciclo `IMPLEMENTED → CHANGES_REQUESTED → IMPLEMENTED` antes de nova revisão.

Todas as tarefas começam em `TODO`. Implementador e revisor devem preencher apenas resumos nas seções reservadas; evidência extensa pode ser vinculada em relatório separado.

## TASK-001 — Reconciliar o schema de Veículo

**Objetivo:** Aplicar o schema aprovado sem perder o cursor numérico nem a paginação existente.

**Status:** APPROVED

**Dependências:** nenhuma.

**Critérios de aceite:**

- [ ] `chassi` é PK; `placa` e `codigo_renavam` são `UNIQUE NOT NULL`;
- [ ] `id` é `bigserial NOT NULL UNIQUE`, não é identidade de domínio e continua gerado pelo banco;
- [ ] índices redundantes de placa/RENAVAM foram removidos ou justificados;
- [ ] views, consultas e contrato preservam `idUltimoRegistro` crescente por `id`;
- [ ] DDL sobe em banco vazio e duplicidades nas três chaves falham;
- [ ] nenhuma outra divergência do data model foi aplicada neste incremento.

### Implementação

Reconciliado `senatran.veiculo` com `chassi` como PK, `placa` e
`codigo_renavam` como `UNIQUE NOT NULL` e `id bigserial NOT NULL UNIQUE`; os
índices simples agora redundantes foram removidos. Alterados
`database/ddl/10-senatran-entities.sql` e
`tests/integration/vehicle-schema.integration.spec.ts`. Validações: DDL completo
e seeds aplicados em PostgreSQL 18 temporário; integração 18/18, unitários
119/119, typecheck, OpenAPI e lint/Prettier do teste novo passaram. O lint global
permanece bloqueado por finais CRLF preexistentes no checkout (12.165 erros fora
do escopo); paginação/views existentes continuam ordenando e calculando o cursor
por `id`.

### Revisão

Revisão independente aprovada sem findings. Confirmados no DDL e em PostgreSQL
18 temporário: PK exclusiva em `chassi`, `UNIQUE NOT NULL` para placa/RENAVAM,
`id bigint NOT NULL UNIQUE` com default de sequence e ausência dos índices
simples redundantes. DDL e seeds subiram do zero; integração 18/18 e E2E de
paginação 4/4 passaram. Views, serviço e OpenAPI preservam ordenação/cursor por
`id` e `idUltimoRegistro` como `int64`; o diff estrutural ficou restrito ao
escopo aprovado.

### Correções

## TASK-002 — Corrigir fixtures RENAVAM

**Objetivo:** Eliminar os três RENAVAMs estáveis inválidos antes da validação estrita.

**Status:** APPROVED

**Dependências:** nenhuma.

**Critérios de aceite:**

- [ ] três bases distintas produzem RENAVAMs com verificadores válidos e sem colisão;
- [ ] manifesto, cenários, exemplos, testes e vínculos entre domínios foram atualizados atomicamente;
- [ ] consumidores afetados e quebra de fixtures estão documentados;
- [ ] teste verifica o dígito, não apenas `11` dígitos;
- [ ] busca pelos valores antigos confirma que não restaram referências indevidas.

### Implementação

Substituídos atomicamente os três RENAVAMs estáveis por `00123456789`,
`00123456800` e `00123456908`, derivados de bases distintas, no gerador,
manifesto/seeds, contratos, cenários, exemplos, testes e vínculos RENAEST/audit.
Adicionados `renavamFromBase` e `isValidRenavam` em
`tools/scripts/lib/br.ts`; a quebra para consumidores com valores hardcoded foi
documentada em `docs/framework/contracts/scenarios.md`. Validações: geração
repetida com 11/11 hashes idênticos; unitários 120/120; OpenAPI; typecheck; lint
dos arquivos TypeScript tocados; DDL + 10 seeds em PostgreSQL temporário; E2E
20/20. Busca final deixou os valores antigos somente nos dois documentos
históricos e na nota explícita de compatibilidade.

### Revisão

Revisão independente aprovada sem findings. Recalculados separadamente os
verificadores das bases `0012345678`, `0012345680` e `0012345690`, confirmando
os dígitos 9, 0 e 8 e ausência de colisão. Gerador, manifesto, SQL, contratos,
testes, documentação operacional e vínculos RENAEST/audit usam os novos valores;
as ocorrências antigas restantes são apenas evidência histórica ou nota de
migração. Regeneração manteve 11/11 hashes idênticos e os três E2E consumidores
passaram 20/20 no banco temporário.

### Correções

## TASK-003 — Extrair geração determinística compartilhada

**Objetivo:** Reutilizar RNG, geradores brasileiros, catálogos e builder OpenAPI sem alterar o fluxo estático existente.

**Status:** IMPLEMENTED

**Dependências:** TASK-002.

**Critérios de aceite:**

- [ ] CPF, CNPJ, placas, chassi e RENAVAM reutilizam geradores/validadores existentes;
- [ ] Faker `pt_BR` tem versão fixada e é usado apenas para dados humanos não regulados;
- [ ] Condutor, Veículo e auxiliares usam streams derivados independentes;
- [ ] data-base `2025-01-01T00:00:00Z` é usada e reportada;
- [ ] não há `Math.random()` nem dependência do relógio na geração;
- [ ] mesma seed/configuração reproduz candidatos e alterar uma contagem não muda outra entidade;
- [ ] gerador estático e manifesto permanecem determinísticos.

### Implementação

Criado o núcleo determinístico compartilhado em
`tools/data-seeder/deterministic.ts`, com data-base fixa, streams derivados por
entidade, Faker `pt_BR` restrito a dados humanos e retry limitado de colisões.
Fixada a versão `@faker-js/faker@10.1.0` e adicionados testes em
`tests/unit/data-seeder-deterministic.spec.ts`. Validações: lint focal,
typecheck e unitários focais 9/9 passaram; `pnpm seed:generate` preservou os 11
arquivos estáticos byte-idênticos.

### Revisão

### Correções

## TASK-004 — Implementar contrato básico da CLI

**Objetivo:** Disponibilizar parsing, ajuda, conexão consistente e proteção de ambiente da Fase 1a.

**Status:** APPROVED

**Dependências:** nenhuma.

**Critérios de aceite:**

- [ ] `--help` funciona sem conexão;
- [ ] somente `senatran.condutor` e `senatran.veiculo` são aceitas na Fase 1a;
- [ ] `--rows` aceita inteiros `1..10000` e representa candidatos;
- [ ] `--seed`, `--batch-size` (default 250), `--dry-run` e `--on-conflict error|skip` são validados;
- [ ] argumentos inválidos falham antes de escrita;
- [ ] conexão prioriza `DATABASE_URL` e depois as mesmas variáveis `DB_*` da aplicação, incluindo SSL/timeout;
- [ ] `NODE_ENV=production` sempre falha antes de escrita, sem override;
- [ ] erros e logs não revelam credenciais.

### Implementação

Criado `node populate.js` com núcleo em `tools/data-seeder/cli.ts`, parsing estrito
para as duas tabelas da Fase 1a, `--rows` 1..10000, seed/default, batch 250,
dry-run e conflitos `error|skip`. A conexão reutiliza `loadConfig` e `pg`, com
precedência `DATABASE_URL`/`DB_*`, SSL e timeout; produção e argumentos inválidos
falham antes de criar pool, erros são sanitizados e a conexão fecha em sucesso ou
falha. Adicionado script `data:populate` e testes em
`tests/unit/data-seeder-cli.spec.ts`. Validações: comando real `--help` sem
conexão, lint/Prettier dos arquivos novos, typecheck, OpenAPI, diff check e
unitários 138/138. Nesta task a execução válida apenas confirma conectividade; a
geração/preflight/persistência pertencem às tasks dependentes.

### Revisão

Revisão independente aprovada sem findings. O parser cobre as duas tabelas,
limites/defaults e opções exigidas; help, argumentos inválidos e produção não
criam pool. Confirmadas diretamente a precedência do `loadConfig`, configuração
SSL/timeout, sanitização de falha contendo credencial e liberação do pool. O
comando real conectou ao PostgreSQL temporário com todas as opções (exit 0),
enquanto produção, tabela inválida e falha de conexão terminaram com exit 1 e
mensagens sem segredo. Lint focal, typecheck, OpenAPI e unitários 138/138
passaram. Geração/preflight/persistência permanecem corretamente fora desta
task.

### Correções

## TASK-005 — Implementar preflight de schema e catálogos

**Objetivo:** Recusar drift incompatível e garantir os catálogos curados antes da carga.

**Status:** IMPLEMENTED

**Dependências:** TASK-001, TASK-004.

**Critérios de aceite:**

- [ ] introspecção confere colunas, tipos, nulabilidade, defaults, serial/identity, PK, `UNIQUE`, FKs, `CHECK` e índices;
- [ ] papel de `veiculo.id` e componentes OpenAPI são conferidos;
- [ ] tabela/contrato ausente, tipo/constraint divergente e coluna obrigatória desconhecida abortam antes do insert;
- [ ] os 11 catálogos da spec são verificados contra listas curadas;
- [ ] código ausente é inserido idempotentemente, item igual é preservado e descrição divergente aborta;
- [ ] município e UF são validados como par;
- [ ] nenhuma estrutura/código desconhecido é criado;
- [ ] `--dry-run` relata diferenças sem escrita.

### Implementação

Implementado preflight fail-closed em `tools/data-seeder/preflight.ts` e
`catalogs.ts`: introspecção de colunas, tipos, nulabilidade, serial, PK,
unicidade, FKs/CHECKs e índices; verificação dos componentes OpenAPI; e
reconciliação idempotente dos 11 catálogos curados. Dry-run apenas relata
diferenças. Validado contra PostgreSQL 18 descartável, inclusive catálogo vazio
(85 diferenças) e segunda execução idempotente (zero diferenças).

### Revisão

### Correções

## TASK-006 — Implementar geração de Condutores

**Objetivo:** Produzir candidatos `Condutor` válidos, únicos e semanticamente coerentes.

**Status:** IMPLEMENTED

**Dependências:** TASK-003, TASK-005.

**Critérios de aceite:**

- [ ] formatos e unicidade lógica de CPF, registro, RENACH e opcionais seguem a spec;
- [ ] opcionais ausentes não viram string vazia e são refletidos corretamente no payload;
- [ ] idade de 18–80 anos e toda cronologia usam a data-base fixa;
- [ ] códigos/descrições e município/UF pertencem aos catálogos;
- [ ] âncoras relacionais coincidem com o payload `Condutor`;
- [ ] existem todas as categorias e casos com/sem restrição, impedimento, PGU e PID;
- [ ] em 10.000 candidatos, situações seguem exatamente `8000/1000/500/500`;
- [ ] chaves não colidem internamente, com o banco nem com `mock.scenario_key`;
- [ ] retries de colisão são determinísticos e limitados.

### Implementação

Implementada geração determinística de Condutores em
`tools/data-seeder/generators.ts`, com identificadores únicos, opcionais por
omissão, cronologia baseada em 2025-01-01, catálogos coerentes e perfis mínimos.
A distribuição modular produz exatamente 8000/1000/500/500 em 10.000
candidatos. Validações focais de geração, reprodução e invariantes passaram.

### Revisão

### Correções

## TASK-007 — Implementar geração de Veículos

**Objetivo:** Produzir candidatos `Veiculo` válidos e coerentes com o schema reconciliado e o universo de Condutores.

**Status:** IMPLEMENTED

**Dependências:** TASK-003, TASK-005, TASK-006.

**Critérios de aceite:**

- [ ] chassi, placa e RENAVAM são válidos e únicos na massa e contra o banco;
- [ ] motor/câmbio opcionais são únicos quando presentes;
- [ ] em 10.000 candidatos há exatamente 7.000 placas Mercosul e 3.000 legadas;
- [ ] proprietário e tipo concordam, há PF/PJ e parte dos PF reutiliza CPF de Condutor da mesma seed;
- [ ] ano, município/UF, catálogos e grandezas físicas são coerentes;
- [ ] há tipos, UFs, estados de circulação e perfis especiais exigidos;
- [ ] indicadores/combinações obedecem à spec e os dependentes de domínios fora do escopo ficam inativos;
- [ ] âncoras e indicadores coincidem entre colunas e payload;
- [ ] chaves não colidem com `mock.scenario_key` e retries são determinísticos/limitados;
- [ ] variar a quantidade de Condutores não muda a sequência inicial de Veículos.

### Implementação

Implementada geração determinística de Veículos com chassi/placa/RENAVAM
regulados, 70/30 de placas, proprietários PF/PJ, reutilização estável do universo
de Condutores, catálogos, grandezas físicas e perfis de dano não contraditórios.
Indicadores dependentes de domínios fora do escopo permanecem inativos. A
independência do stream de Veículos foi testada.

### Revisão

### Correções

## TASK-008 — Validar payloads e invariantes

**Objetivo:** Impedir commit de dados estrutural ou semanticamente inválidos.

**Status:** IMPLEMENTED

**Dependências:** TASK-006, TASK-007.

**Critérios de aceite:**

- [ ] todo payload é objeto e valida contra `Condutor` ou `Veiculo` do OpenAPI;
- [ ] todas as propriedades aplicáveis são geradas e opcionais ausentes seguem a regra de omissão;
- [ ] todas as âncoras coluna/payload são comparadas;
- [ ] verificadores, formatos, cronologia, catálogos, município/UF, proprietário/tipo e perfis são validados;
- [ ] qualquer erro produz código não zero antes do commit;
- [ ] testes negativos cobrem JSON escalar, tipo incorreto, âncora divergente e código/descrição incompatível.

### Implementação

Criados builder e validador OpenAPI em `tools/data-seeder/openapi.ts` e
validações semânticas em `validation.ts`, executadas antes da persistência.
Cobertos tipos, datas, verificadores, unicidade, âncoras, catálogos, relações,
cronologia, distribuições e indicadores. Testes negativos cobrem JSON escalar,
tipo incorreto, âncora divergente e descrição incompatível.

### Revisão

### Correções

## TASK-009 — Implementar persistência e relatório

**Objetivo:** Inserir candidatos de forma transacional, parametrizada e observável.

**Status:** IMPLEMENTED

**Dependências:** TASK-004 a TASK-008.

**Critérios de aceite:**

- [ ] inserts são parametrizados, em lotes, e nunca enviam IDs gerados pelo banco;
- [ ] preflight mutável e lotes usam uma transação por comando;
- [ ] `error` aborta/rollback na colisão; `skip` ignora sem reposição e contabiliza a diferença;
- [ ] erro intermediário ou SIGINT deixa zero alterações parciais;
- [ ] `--dry-run` não escreve, não altera catálogos nem avança sequences;
- [ ] nenhuma tabela é truncada/apagada por padrão;
- [ ] conexão fecha em sucesso, falha e interrupção;
- [ ] relatório contém alvo, seed, data-base, candidatos, tentativas, inseridos, ignorados, lotes, duração e validações, sem credenciais/payloads completos.

### Implementação

Implementada orquestração transacional e persistência parametrizada em lotes em
`orchestrator.ts` e `persistence.ts`, sem envio de IDs. Incluídos modos
`error|skip`, colisões lógicas contra banco/cenários, rollback, SIGINT, dry-run,
fechamento de conexão e relatório sanitizado com os campos exigidos. Validada
carga real de 100+100 linhas no PostgreSQL descartável.

### Revisão

### Correções

## TASK-010 — Validar a Fase 1a em volume e API

**Objetivo:** Demonstrar que o core atende integralmente ao contrato em banco descartável.

**Status:** IN_PROGRESS

**Dependências:** TASK-001 a TASK-009.

**Critérios de aceite:**

- [ ] os dois comandos de aceite inserem 10.000 linhas cada em banco compatível vazio;
- [ ] zero violações de constraints, formatos, unicidade, payload ou semântica;
- [ ] Condutores são encontrados por todos os lookups preenchidos;
- [ ] Veículos são encontrados por placa, chassi, RENAVAM, motor, câmbio e proprietário;
- [ ] paginação valida limite 100, total, cursor crescente e página vazia após o fim;
- [ ] determinismo, independência dos streams, `skip`, `dry-run`, rollback e bloqueio de produção têm testes;
- [ ] `pnpm check`, testes unitários, integração e E2E relevantes passam;
- [ ] nenhuma alegação de cobertura inclui as sete auxiliares ou domínios fora do escopo.

### Implementação

### Revisão

### Correções

## TASK-011 — Corrigir filtros dos endpoints

**Objetivo:** Remover falsos positivos antes do aceite de cobertura total da Fase 1b.

**Status:** IMPLEMENTED

**Dependências:** TASK-010.

**Critérios de aceite:**

- [ ] segurança CRV usa CPF/CNPJ recebido na rota além de código, RENAVAM e placa;
- [ ] consultas por proprietário discriminam PF/PJ pelo tipo;
- [ ] scenario check cobre as chaves de proprietário relevantes;
- [ ] testes provam que documento/tipo divergente não retorna o registro;
- [ ] testes existentes dos controllers continuam passando.

### Implementação

Os endpoints de segurança CRV agora encaminham CPF/CNPJ ao filtro; consultas por
proprietário incluem `tipo_proprietario`; e o scenario check infere CPF/CNPJ a
partir desse tipo. Atualizados controller, ReadService, gerador de views, DDL
gerado e testes de delegação. Testes unitários focais passaram.

### Revisão

### Correções

## TASK-012 — Popular auxiliares de Condutor

**Objetivo:** Cobrir imagens/retrato/validação e extrato com dados derivados de Condutores.

**Status:** IMPLEMENTED

**Dependências:** TASK-010.

**Critérios de aceite:**

- [ ] `condutor_imagem` copia CPF/registro do mesmo Condutor e mantém única a combinação com número de segurança;
- [ ] `condutor_infracao_item` usa registro de Condutor e mantém quantidade/ocorrências coerentes;
- [ ] payloads repetem as chaves relacionais;
- [ ] há casos positivos e casos determinísticos sem cada auxiliar;
- [ ] mesma seed/configuração reproduz seleção e conteúdo;
- [ ] endpoints de imagens, retrato, validação e extrato passam em E2E.

### Implementação

Implementadas `condutor_imagem` e `condutor_infracao_item` derivadas dos
Condutores do mesmo comando, com streams próprios, chaves/payload coerentes e
seleção modular que preserva casos positivos e ausentes. Carga real de 100
Condutores gerou 50 imagens e 34 itens de extrato no banco descartável.

### Revisão

### Correções

## TASK-013 — Popular auxiliares de Veículo

**Objetivo:** Cobrir segurança CRV, comunicação, endereço, multa e recall com dados derivados de Veículos.

**Status:** IMPLEMENTED

**Dependências:** TASK-010, TASK-011.

**Critérios de aceite:**

- [ ] as cinco tabelas usam placa/RENAVAM/chassi de um único Veículo existente;
- [ ] CPF/CNPJ e tipo de proprietário concordam em segurança, comunicação e multa;
- [ ] payloads repetem as chaves relacionais;
- [ ] há casos positivos e casos determinísticos sem cada auxiliar;
- [ ] nenhum identificador principal é gerado independentemente na auxiliar;
- [ ] mesma seed/configuração reproduz seleção e conteúdo;
- [ ] os nove endpoints especializados de Veículo passam em E2E.

### Implementação

Implementadas as cinco auxiliares de Veículo, sempre copiando chassi, placa,
RENAVAM e proprietário do candidato principal, com payload OpenAPI validado e
casos de ausência determinísticos. A carga real de 100 Veículos gerou 50 CSVs,
34 comunicações, 25 endereços, 20 multas e 17 recalls.

### Revisão

### Correções

## TASK-014 — Validar e documentar a Fase 1b

**Objetivo:** Fechar a cobertura dos controllers sem ampliar o escopo para outros domínios.

**Status:** TODO

**Dependências:** TASK-011, TASK-012, TASK-013.

**Critérios de aceite:**

- [ ] forma de acionar a Fase 1b está explícita no `--help` e na documentação operacional;
- [ ] execução é determinística, transacional, protegida de produção e reportada como na Fase 1a;
- [ ] os 20 endpoints de Veículos e 12 de Condutores são exercitados com chaves da massa;
- [ ] casos positivos, ausência e parâmetros divergentes são testados;
- [ ] documentação distingue Fase 1a, Fase 1b e domínios fora do escopo;
- [ ] checks e testes relevantes passam e o handoff contém comandos reproduzíveis.

### Implementação

### Revisão

### Correções
