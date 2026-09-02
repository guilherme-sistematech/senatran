# Investigação consolidada

Este documento contém fatos encontrados nas fontes históricas e no snapshot `b39e8d0b425a8f8aa6622d82fdf0a45e10fe8101` do repositório SENATRAN. Regras futuras e escolhas aprovadas estão em `decisions.md` e `generation-spec.md`.

## Arquitetura encontrada

- Stack: Node.js 24, TypeScript ESM, NestJS, PostgreSQL, `pg`, pnpm e Vitest.
- As entidades de leitura usam colunas SQL de busca e um `payload jsonb` com o objeto retornado pelo contrato.
- `ReadService.one()` consulta views de `contract`; `ReadService.list()` consulta diretamente uma tabela permitida de `senatran`, lê `id,payload`, ordena por `id` e limita a página a 100 linhas.
- Nas listas, ausência total gera 404; uma página após o último `id` retorna 200, lista vazia, total real e o cursor recebido. Cursor ausente, vazio ou não numérico não cria filtro.
- O OpenAPI declara `idUltimoRegistro` como `int64`, e o serviço converte o `bigint` do driver em `number`.
- O mapa de cenários cobre `placa`, `chassi`, `cpf`, `cnpj`, `renavam` e `codigo_renavam`, mas não `id_proprietario`.

## DDL atual

### `senatran.veiculo`

| Coluna | Tipo | Nulabilidade/default | Constraint/índice |
|---|---|---|---|
| `id` | `bigserial` | `NOT NULL`, sequência | PK |
| `chassi` | `text` | `NOT NULL` | `UNIQUE` |
| `placa` | `text` | `NOT NULL` | índice não único |
| `codigo_renavam` | `text` | `NOT NULL` | índice não único |
| `numero_motor` | `text` | anulável | índice não único |
| `numero_cambio` | `text` | anulável | índice não único |
| `id_proprietario` | `text` | anulável | índice composto com `tipo_proprietario` |
| `tipo_proprietario` | `text` | anulável | índice composto com `id_proprietario` |
| nove `ind_*` | `boolean` | `NOT NULL DEFAULT false` | sem `CHECK` adicional |
| `payload` | `jsonb` | `NOT NULL` | sem `CHECK` de tipo/schema |

Os nove indicadores são alarme, roubo/furto, transferência, licenciamento, circulação, penhora, média monta, grande monta e recuperado. Não há FK, RLS ou `tenant_id`. A PK e a constraint de chassi criam índices implícitos; os índices explícitos incluem placa, RENAVAM, motor, câmbio e proprietário/tipo.

### `senatran.condutor`

| Coluna | Tipo | Nulabilidade/default | Constraint/índice |
|---|---|---|---|
| `id` | `bigserial` | `NOT NULL`, sequência | PK |
| `cpf` | `text` | `NOT NULL` | índice não único |
| `numero_registro` | `text` | anulável | índice não único |
| `numero_formulario_renach` | `text` | anulável | índice não único |
| `numero_lista_impedimento` | `text` | anulável | índice não único |
| `numero_pgu` | `text` | anulável | índice não único |
| `numero_formulario_pid` | `text` | anulável | índice não único |
| `nome` | `text` | anulável | índice composto com nascimento e mãe |
| `data_nascimento` | `date` | anulável | índice composto com nome e mãe |
| `nome_mae` | `text` | anulável | índice composto com nome e nascimento |
| `payload` | `jsonb` | `NOT NULL` | sem `CHECK` de tipo/schema |

Não há `UNIQUE` nos lookups de Condutor, nem FK, RLS ou `tenant_id`.

## Payload e formatos encontrados

- Os componentes OpenAPI têm cerca de 120 propriedades para Condutor e 90 para Veículo, mas não declaram uma lista `required`.
- O gerador atual percorre todas as propriedades e sobrescreve as âncoras relacionais. Código e descrição são escolhidos em pares curados.
- Como as views retornam o JSON persistido, divergências entre coluna e payload chegam diretamente à API.

| Campo | Formato implementado/testado |
|---|---|
| CPF | 11 dígitos, verificadores mod-11 |
| CNPJ | 14 dígitos, verificadores mod-11, matriz `0001` |
| placa Mercosul | `LLLNLNN`, sem `I`, `O`, `Q` |
| placa legada | `LLLNNNN`, sem `I`, `O`, `Q` |
| chassi | 17 caracteres do alfabeto VIN do projeto, sem `I`, `O`, `Q` |
| RENAVAM | 11 dígitos, último calculado por mod-11 |
| motor/câmbio | `MOT`/`CAM` + 7 dígitos |
| registro CNH | 11 dígitos |
| RENACH | `RN` + 10 dígitos |
| PGU/PID/impedimento | `PGU`/`PID`/`IMP` + 7 dígitos |

Os testes existentes validam CPF, CNPJ, placas, chassi, RENAVAM gerado e determinismo, mas não unicidade em 10.000 linhas. Três RENAVAMs fixos usados em fixtures (`00123456780`, `00123456781`, `00123456782`) não passam no algoritmo de verificação do próprio projeto.

## Endpoints e views

### Veículos

O controller expõe 20 operações em `/v1/veiculos`:

- sete listas paginadas usam `senatran.veiculo`: placa, chassi, RENAVAM, motor, câmbio, proprietário CPF e proprietário CNPJ;
- quatro consultas combinadas usam views sobre `veiculo`: proprietário CPF/CNPJ + chassi/placa + RENAVAM;
- nove operações dependem diretamente de auxiliares: duas de segurança CRV, duas de comunicação de venda, duas de endereço do possuidor, duas de multa interestadual e uma de recall.

As listas dependem concretamente de `veiculo.id` (`id > cursor`, `order by id`, `limit 100`). Views geradas também usam `max(id)` e `jsonb_agg(payload order by id)`.

Os endpoints por proprietário filtram `id_proprietario`, mas não `tipo_proprietario`. Os endpoints de segurança CRV recebem CPF/CNPJ na URL, porém a consulta atual usa apenas código de segurança, RENAVAM e placa.

### Condutores

O controller expõe 12 operações em `/v1/condutores`:

- oito usam views derivadas de `senatran.condutor`: CPF; CPF + registro; RENACH; impedimento; nome + nascimento + mãe; PGU; PID; registro CNH;
- imagens, retrato e validação usam `senatran.condutor_imagem` pela combinação única `(cpf, numero_registro, numero_seguranca)`;
- extrato usa `senatran.condutor_infracao_item` por `numero_registro_cnh`, agregando quantidade e ocorrências.

As consultas de Condutor não recebem cursor e suas views podem agregar mais de um payload para a mesma chave.

## Tabelas auxiliares e relações observadas

As auxiliares relevantes têm `id bigserial` como PK e `payload jsonb NOT NULL`. Em geral, as relações abaixo são lógicas, sem FKs:

| Tabela | Relação usada pelo seed atual |
|---|---|
| `condutor_imagem` | CPF e registro de um Condutor |
| `condutor_infracao_item` | registro CNH de um Condutor |
| `csv_seguranca` | placa, RENAVAM e documento do proprietário de um Veículo |
| `comunicacao_venda` | placa, RENAVAM e documento coerente |
| `endereco_possuidor` | placa e, quando presente, RENAVAM do Veículo |
| `multa_interestadual` | placa, RENAVAM e documento coerente |
| `recall` | chassi do Veículo |
| `infracao` | placa de Veículo e, quando presente, CPF/registro de Condutor |
| `restricao_judicial_processo` | placa e RENAVAM do Veículo |
| `roubo_furto_ocorrencia` | placa e chassi de Veículo marcado |
| `consulta_csv` | placa e chassi do Veículo |

As últimas quatro, suas tabelas filhas e os demais domínios não são dependências diretas dos controllers de Veículos e Condutores.

## Catálogos e infraestrutura do mock

O DDL cria 13 tabelas `ref_*`. Os payloads principais usam:

- comuns: `ref_uf`, `ref_municipio`;
- Veículo: `ref_marca_modelo`, `ref_cor`, `ref_especie`, `ref_tipo_veiculo`, `ref_carroceria`, `ref_categoria`, `ref_combustivel`, `ref_tipo_proprietario`;
- Condutor: `ref_situacao_cnh`.

Os seeds possuem 27 UFs e oito municípios curados. A maioria dos códigos é `text`; `ref_uf.uf` é `char(2)`. Não há FK de município para UF nem das entidades para os catálogos.

`mock.usuario_autorizado` controla a allowlist simulada. `mock.scenario_key` reserva chaves que forçam respostas de erro; a massa normal pode colidir com elas se não houver verificação.

## Gerador e execução existentes

- `tools/scripts/generate-seed.ts` usa RNG mulberry32 com seed fixa `0x5e17a`, sem `Math.random()` ou `Date.now()`.
- Ele gera SQL estático em `database/seed/`, hoje com 120 Veículos, 80 Condutores e 250 infrações, além de subconjuntos auxiliares, e publica `manifest.json`.
- Há um único stream global de RNG; mudar uma quantidade pode alterar as sequências seguintes.
- Não há CLI de população direta, Faker, introspecção do banco ou detecção explícita de colisões.
- A aplicação prioriza `DATABASE_URL`; na ausência, usa `DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_SSL` e timeout. O shell de seed usa apenas `DB_*`.
- O repositório expõe geração/aplicação do seed, reset do banco, checks e testes. O CI exige que views e seeds regenerados não produzam diff.

A ordem semanticamente segura observada nas fontes é: referências e control plane; Condutores; Veículos; auxiliares de Condutor; auxiliares de Veículo; depois entidades cross-domain. Ela decorre das relações lógicas, não de FKs.

## Divergências encontradas

- O data model define `chassi` como PK de Veículo e placa/RENAVAM únicos; o DDL atual usa `id` como PK e índices não únicos para placa/RENAVAM.
- O data model usa nomes de proprietário/indicadores diferentes, prevê FKs/referências ausentes e alguns códigos `int`; DDL, controllers e OpenAPI usam a realização física descrita acima.
- O data model ainda se apresenta como anterior ao DDL, embora existam decisões e implementação posteriores baseadas em `payload jsonb`.
- A especificação histórica pede Faker, CLI, inserção direta, introspecção, streams separados e opcionais nulos; isso não existe no gerador atual.
- Há volumes documentados de 120/80, aproximadamente 500/300 e 10.000/10.000 para finalidades distintas.
- Documentação antiga afirma que a leitura não acessa `senatran.*`, mas as listas usam a tabela base.
- Os filtros incompletos de proprietário/segurança CRV permitem respostas semanticamente incorretas mesmo com dados coerentes.
