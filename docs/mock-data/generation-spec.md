# Especificação de geração e população

Este documento é a fonte de verdade funcional para a implementação. “Deve” indica requisito de aceite; detalhes internos de código ficam a cargo do implementador.

## 1. Objetivo e entregas

Gerar e inserir dados sintéticos, determinísticos, válidos no contrato e coerentes entre colunas, payloads e relações lógicas.

- **Fase 1a — core:** preflight dos catálogos, 10.000 registros em `senatran.condutor` e 10.000 em `senatran.veiculo`.
- **Fase 1b — controllers:** dados derivados nas sete auxiliares necessárias aos endpoints especializados.

O gerador SQL estático existente permanece independente. Não fazem parte destas fases a população de infrações gerais, ConsultaCSV, restrições judiciais, ocorrências de roubo/furto, domínios RENACH/RENAINF/RENAEST/SNE/CDT nem uso em produção.

## 2. Pré-requisitos

Antes de liberar a carga:

1. o DDL de `senatran.veiculo` deve ter `chassi` como PK, `placa` e `codigo_renavam` como `UNIQUE NOT NULL`, e `id bigserial NOT NULL UNIQUE` como cursor técnico;
2. views, consultas e testes devem continuar usando `id` para `idUltimoRegistro` e paginação crescente;
3. os três RENAVAMs estáveis inválidos devem ser substituídos, com todas as referências e testes atualizados;
4. para aceitar a cobertura da Fase 1b, a aplicação deve usar CPF/CNPJ nos filtros de segurança CRV, discriminar o tipo nas consultas por proprietário e mapear as chaves relevantes para cenários.

Nenhuma outra divergência do data model autoriza mudança de DDL neste incremento.

## 3. Tabelas e ordem de população

### Catálogos da Fase 1a

`ref_uf`, `ref_municipio`, `ref_marca_modelo`, `ref_cor`, `ref_especie`, `ref_tipo_veiculo`, `ref_carroceria`, `ref_categoria`, `ref_combustivel`, `ref_tipo_proprietario` e `ref_situacao_cnh`.

### Entidades e auxiliares

1. catálogos;
2. `senatran.condutor`;
3. `senatran.veiculo`;
4. `senatran.condutor_imagem` e `senatran.condutor_infracao_item`;
5. `senatran.csv_seguranca`, `senatran.comunicacao_venda`, `senatran.endereco_possuidor`, `senatran.multa_interestadual` e `senatran.recall`.

A ordem é semântica: mesmo sem FKs, toda auxiliar deve nascer de uma entidade principal conhecida.

## 4. Preflight fail-closed

Antes do primeiro insert, a ferramenta deve:

- confirmar schema/tabela, colunas, tipos, nulabilidade, defaults, identity/serial, PK, `UNIQUE`, FKs, `CHECK` e índices esperados;
- confirmar o papel e o índice único de `veiculo.id`;
- confirmar a existência dos componentes OpenAPI aplicáveis;
- comparar os catálogos necessários com as listas curadas;
- verificar colisões com dados existentes e com as chaves de `mock.scenario_key`;
- recusar `NODE_ENV=production`, sem override;
- abortar diante de tabela ausente, drift incompatível, coluna obrigatória desconhecida, contrato ausente ou catálogo conflitante.

Nos catálogos, código ausente deve ser inserido idempotentemente, item idêntico deve ser preservado e descrição divergente deve abortar sem sobrescrita. Município e UF devem ser validados como par. O populador não cria estruturas desconhecidas.

## 5. Determinismo e Faker

- O mesmo alvo, seed, versão, data-base e configuração devem produzir os mesmos candidatos, na mesma ordem.
- A data-base é `2025-01-01T00:00:00Z`; relógio do sistema, `Date.now()` e `Math.random()` não participam da geração.
- Condutor, Veículo e cada auxiliar devem ter streams derivados independentes. Alterar a quantidade de uma entidade não pode mudar a sequência inicial de outra.
- Os geradores existentes são a fonte para CPF, CNPJ, placas, chassi e RENAVAM.
- `@faker-js/faker`, com versão fixada e locale `pt_BR`, limita-se a nomes, endereços e textos humanos não regulados.
- Listas curadas são a fonte para catálogos e pares código/descrição.
- Colisões internas sofrem novas tentativas determinísticas com limite; esgotar o limite aborta a execução.

Determinismo dos valores não garante os mesmos IDs gerados pelo banco se o estado inicial das sequences mudar.

## 6. Contrato comum de payload

Cada `payload` deve:

- ser objeto JSON, nunca SQL `NULL`, array ou escalar;
- conter todas as propriedades aplicáveis do componente OpenAPI da entidade;
- respeitar nomes, tipos, enums, formatos e estruturas do contrato;
- repetir exatamente os valores das colunas de busca correspondentes;
- usar pares código/descrição do mesmo item curado;
- omitir uma propriedade opcional quando seu lookup anulável estiver ausente e o schema não aceitar `null`;
- ser validado antes do commit.

String vazia não representa campo ausente. O populador não altera OpenAPI nem corrige payload durante a leitura.

## 7. Condutor

### Colunas e geração

| Campo | Requisito |
|---|---|
| `id` | gerado pelo banco; não enviar no insert |
| `cpf` | obrigatório; 11 dígitos com verificadores; único na massa e contra o banco |
| `numero_registro` | opcional no schema; 11 dígitos; único quando presente |
| `numero_formulario_renach` | opcional; `RN` + 10 dígitos; único quando presente |
| `numero_lista_impedimento` | opcional; `IMP` + 7 dígitos; presente apenas em perfil com impedimento; único quando presente |
| `numero_pgu` | opcional; `PGU` + 7 dígitos; único quando presente |
| `numero_formulario_pid` | opcional; `PID` + 7 dígitos; único quando presente |
| `nome` | opcional no schema, mas preenchido na massa padrão com nome sintético brasileiro |
| `data_nascimento` | opcional no schema, mas preenchida; idade entre 18 e 80 anos na data-base |
| `nome_mae` | opcional no schema, mas preenchido com nome sintético brasileiro |
| `payload` | obrigatório; componente `Condutor` |

As âncoras `cpf`, `numeroRegistro`, `numeroFormularioRenach`, `numeroListaImpedimento`, `numeroPgu`, `numeroFormularioPid`, `nome`, `dataNascimento` e `nomeMae` devem coincidir com as colunas.

### Coerência e cobertura

- primeira habilitação deve ser posterior ao nascimento e à idade mínima;
- emissão, validade e atualização devem ter ordem cronológica válida;
- município e UF de domínio, habilitação, documento e endereço devem concordar;
- situação/descrição e demais códigos/descrições devem vir das listas curadas;
- `ocorrencias` deve concordar com sua quantidade, inclusive zero;
- ausência de PGU, PID ou impedimento deve aparecer também no payload;
- a massa deve conter categorias `A`, `B`, `AB`, `C`, `D`, `E`, `AC`, `AD` e `AE`, além de casos com e sem restrição médica, impedimento, PID e PGU.

No aceite de 10.000 candidatos, a situação da CNH deve ter 8.000 ativos, 1.000 vencidos, 500 suspensos/bloqueados e 500 em outras situações válidas do catálogo. Não há percentual normativo para os demais opcionais.

## 8. Veículo

### Colunas e geração

| Campo | Requisito |
|---|---|
| `id` | gerado pelo banco; não enviar no insert |
| `chassi` | obrigatório e PK; 17 caracteres VIN-style, sem `I`, `O`, `Q`; único na massa e contra o banco |
| `placa` | obrigatória e `UNIQUE`; Mercosul `LLLNLNN` ou legada `LLLNNNN`, sem `I`, `O`, `Q`; única na massa e contra o banco |
| `codigo_renavam` | obrigatório e `UNIQUE`; 11 dígitos com verificador válido; único na massa e contra o banco |
| `numero_motor` | opcional; `MOT` + 7 dígitos; único quando presente |
| `numero_cambio` | opcional; `CAM` + 7 dígitos; único quando presente |
| `id_proprietario` | opcional; CPF ou CNPJ válido, conforme o tipo; não pode existir sem tipo |
| `tipo_proprietario` | opcional; código curado PF/PJ; não pode existir sem documento |
| nove `ind_*` | obrigatórios; booleanos, default físico `false` |
| `payload` | obrigatório; componente `Veiculo` |

As âncoras `chassi`, `placa`, `codigoRenavam`, `numeroMotor`, `numeroCambio`, `numeroIdentificacaoProprietario`, `codigoTipoProprietario`, `indicadorAlarme` e `indicadorRouboFurto` devem coincidir com as colunas. Os demais indicadores equivalentes também devem permanecer coerentes onde existirem no contrato.

### Coerência e cobertura

- no aceite de 10.000 candidatos, devem existir exatamente 7.000 placas Mercosul e 3.000 legadas;
- documento e tipo de proprietário devem concordar; devem existir PF e PJ, e parte dos PF deve reutilizar CPFs do universo determinístico de Condutores da mesma seed;
- `anoFabricacao <= anoModelo <= anoFabricacao + 1`;
- município, descrição e UF devem corresponder;
- marca/modelo, cor, espécie, tipo, carroceria, categoria e combustível devem usar pares curados;
- lotação, eixos, peso, potência e cilindrada devem ser plausíveis para o tipo;
- devem existir automóveis, motocicletas, caminhões e ônibus, diferentes UFs/catálogos, veículos em circulação e baixados e casos positivos/negativos para os perfis especiais cobertos;
- combinações contraditórias entre média monta, grande monta, recuperação e circulação são proibidas;
- indicadores que exigiriam um recurso fora do escopo, em especial roubo/furto e restrição judicial, devem permanecer inativos nestas fases.

Não há percentuais normativos além da divisão de placas. Defaults configuráveis podem variar desde que os casos mínimos e todas as invariantes permaneçam verdadeiros.

## 9. Auxiliares da Fase 1b

Cada tabela deve ter registros positivos suficientes para exercitar seu endpoint e, quando o endpoint admite ausência, ao menos um caso determinístico sem auxiliar. Quantidades adicionais não são critério de aceite.

| Auxiliar | Relação obrigatória |
|---|---|
| `condutor_imagem` | `cpf` e `numero_registro` do mesmo Condutor; combinação com `numero_seguranca` única |
| `condutor_infracao_item` | `numero_registro_cnh` de um Condutor; quantidade e `ocorrencias[]` coerentes |
| `csv_seguranca` | placa e RENAVAM do mesmo Veículo; CPF/CNPJ do seu proprietário |
| `comunicacao_venda` | placa e RENAVAM do mesmo Veículo; documento coerente |
| `endereco_possuidor` | placa e, quando presente, RENAVAM do mesmo Veículo |
| `multa_interestadual` | placa e RENAVAM do mesmo Veículo; documento coerente |
| `recall` | chassi de um Veículo |

Chaves e valores equivalentes devem ser copiados para colunas e payload da auxiliar. Nenhuma auxiliar pode inventar um Condutor, Veículo, proprietário, placa, chassi ou RENAVAM independente.

## 10. CLI e conexão

Comandos mínimos da Fase 1a:

```text
node populate.js --table senatran.condutor --rows 10000
node populate.js --table senatran.veiculo --rows 10000
```

| Opção | Contrato |
|---|---|
| `--table <schema.table>` | obrigatória; Fase 1a aceita somente as duas tabelas principais |
| `--rows <n>` | obrigatória; inteiro entre 1 e 10.000; quantidade de candidatos |
| `--seed <n>` | opcional; default estável e documentado |
| `--batch-size <n>` | opcional; inteiro positivo; default 250 |
| `--dry-run` | executa validações e relata plano/amostras sem escrever |
| `--on-conflict error|skip` | opcional; default `error` |
| `--help` | mostra contrato e termina sem conectar ao banco |

A forma de acionar a Fase 1b pode ser integrada à mesma CLI ou exposta por comando próprio, mas deve ser explícita, documentada no help e preservar todos os requisitos deste documento.

Argumento/tabela inválido deve terminar com código não zero antes de escrita. A conexão deve usar a mesma precedência da aplicação: `DATABASE_URL`; na ausência, `DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_SSL` e timeout. Credenciais nunca aparecem em logs.

## 11. Persistência, conflitos e relatório

- Todos os valores SQL devem ser parametrizados.
- Cada comando deve usar uma única transação para preflight mutável e lotes; erro ou interrupção provoca rollback integral.
- A ferramenta não apaga nem trunca dados por padrão.
- `error` aborta na primeira colisão com o banco; `skip` ignora a colisão e pode inserir menos que `--rows`, sem gerar substituto.
- `--dry-run` não abre transação de escrita nem altera catálogos/sequences.
- A conexão deve ser encerrada em sucesso, falha e interrupção.
- O resumo deve informar alvo/fase, seed, data-base, candidatos, tentativas, inseridos, ignorados, lotes, duração e resultado das validações, sem credenciais nem payloads completos.

## 12. Critérios de pronto

### Fase 1a

- schema-alvo, paginação e fixtures RENAVAM atendem aos pré-requisitos;
- em banco descartável compatível, os dois comandos de aceite inserem 10.000 linhas cada;
- constraints, nulabilidade, formatos, verificadores, unicidade, cronologia, catálogos, relações e igualdade coluna/payload passam;
- todos os payloads são objetos válidos contra o componente OpenAPI aplicável;
- endpoints encontram Condutores por todos os lookups preenchidos e Veículos por placa, chassi, RENAVAM, motor, câmbio e proprietário;
- paginação mantém limite 100, total real, cursor crescente e página vazia após o último item;
- mesma seed/configuração reproduz os candidatos e streams independentes são comprovados;
- drift, colisão em `error`, falha intermediária e interrupção deixam zero registros parciais;
- `skip`, `dry-run`, proteção de produção, relatório e encerramento da conexão são testados;
- o gerador estático/manifesto continuam determinísticos e os checks/testes relevantes passam.

### Fase 1b

- as sete auxiliares obedecem às relações da seção 9 e oferecem casos positivos e de ausência;
- os 20 endpoints de Veículos e 12 de Condutores são exercitados com chaves da massa;
- os filtros de aplicação listados nos pré-requisitos foram corrigidos e testados;
- nenhuma afirmação de cobertura inclui os domínios explicitamente fora do escopo.
