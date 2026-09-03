# Investigação consolidada

Fatos úteis encontrados no repositório e nas fontes de
[`docs/raw-investigation/`](../raw-investigation/). Este documento descreve o
estado observado; decisões para a próxima etapa estão em `decisions.md`.

## Modelo e acesso aos dados

- As entidades de leitura combinam colunas SQL de busca com `payload jsonb`; as
  views retornam esse payload diretamente.
- `ReadService.one()` consulta views de `contract`. Listas autorizadas consultam
  `senatran`, ordenam por `id` e limitam a página a 100 registros.
- `idUltimoRegistro` é um cursor `int64` baseado no `id` crescente. Página depois
  do último registro retorna 200 com lista vazia e o cursor recebido.
- Não há RLS ou `tenant_id` nas tabelas consideradas pelo seeder.

## Tabelas principais

`senatran.veiculo` possui `id bigserial`, chaves de busca para chassi, placa,
RENAVAM, motor, câmbio e proprietário, nove indicadores booleanos e
`payload jsonb NOT NULL`. O DDL da branch já foi alterado para manter `id` como
cursor técnico e usar `chassi` como chave primária, com placa e RENAVAM únicos.

`senatran.condutor` possui `id bigserial`, CPF, registro CNH, RENACH, impedimento,
PGU, PID, nome/data de nascimento/nome da mãe e `payload jsonb NOT NULL`. Os
lookups não possuem constraints `UNIQUE`; a massa padrão deve evitar repetições.

As tabelas não validam o payload contra o OpenAPI. Portanto, o gerador precisa
garantir objeto JSON válido e igualdade entre as colunas de busca e seus campos no
payload.

## Catálogos

O DDL contém 13 tabelas `ref_*`. Para Condutor e Veículo, as referências relevantes
são UF, município, marca/modelo, cor, espécie, tipo de veículo, carroceria,
categoria, combustível, tipo de proprietário e situação da CNH. Há 27 UFs e oito
municípios curados. As relações são principalmente lógicas, sem FKs.

## Tabelas auxiliares diretamente relacionadas

| Tabela | Relação observada |
| --- | --- |
| `condutor_imagem` | CPF e registro de um Condutor |
| `condutor_infracao_item` | registro CNH de um Condutor |
| `csv_seguranca` | placa, RENAVAM e documento de um Veículo |
| `comunicacao_venda` | placa, RENAVAM e documento de um Veículo |
| `endereco_possuidor` | placa e, quando presente, RENAVAM de um Veículo |
| `multa_interestadual` | placa, RENAVAM e documento de um Veículo |
| `recall` | chassi de um Veículo |

Outros domínios, como infrações gerais, restrições judiciais, roubo/furto e
ConsultaCSV, não são dependências diretas da cobertura proposta para os controllers
de Condutores e Veículos.

## Formatos já encontrados

| Campo | Formato observado |
| --- | --- |
| CPF | 11 dígitos com verificadores mod-11 |
| CNPJ | 14 dígitos com verificadores mod-11 e matriz `0001` |
| placa Mercosul | `LLLNLNN`, sem `I`, `O` e `Q` |
| placa legada | `LLLNNNN`, sem `I`, `O` e `Q` |
| chassi | 17 caracteres do alfabeto VIN usado pelo projeto |
| RENAVAM | 11 dígitos, último calculado por mod-11 |
| motor/câmbio | `MOT`/`CAM` + 7 dígitos |
| registro CNH | 11 dígitos |
| RENACH | `RN` + 10 dígitos |
| PGU/PID/impedimento | prefixo `PGU`/`PID`/`IMP` + 7 dígitos |

Os três RENAVAMs históricos `00123456780`, `00123456781` e `00123456782` não
passavam no algoritmo do projeto. A branch já contém uma alteração coordenada das
fixtures; ela deve ser verificada, não refeita sem necessidade.

## Comportamentos relevantes

- O mapa de cenários reserva chaves para respostas 401, 402, 404 e 500. A massa
  normal não pode colidir com essas chaves.
- Consultas por proprietário historicamente não filtravam o tipo de proprietário,
  e consultas de segurança CRV ignoravam o CPF/CNPJ recebido na rota. A branch já
  contém alterações nesses filtros, ainda sujeitas a validação.
- A ordem lógica é: referências, Condutores, Veículos, auxiliares de Condutor e
  auxiliares de Veículo.
- Não há fonte de domínio para distribuições percentuais detalhadas. Casos mínimos
  determinísticos são preferíveis a probabilidades inventadas.

## Implementação encontrada

O commit atual já inclui uma implementação parcial em `tools/data-seeder/` com
CLI, RNG determinístico, catálogos, geradores, auxiliares, leitura do OpenAPI,
preflight, validação, persistência e orquestração. Também há mudanças relacionadas
em DDL, fixtures, scripts, dependências e testes.

A branch também contém `.tmp-seeder-pg/`, um cluster PostgreSQL temporário
versionado no commit de implementação. Ele foi preservado nesta reorganização; a
necessidade de mantê-lo deve ser avaliada separadamente antes de integrar a branch.

Essa implementação não foi continuada nesta reorganização. O próximo trabalho deve
comparar o que existe com a sequência de `generation-spec.md` antes de criar ou
substituir qualquer parte.
