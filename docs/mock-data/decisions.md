# Decisões consolidadas

Este documento registra as recomendações de `proposed-decisions.md` aprovadas pelo owner. Somente o conteúdo deste arquivo é normativo.

### DEC-001 — Preservar `veiculo.id` como cursor técnico

**Status:** Accepted

**Contexto**

O data model define `chassi` como identidade primária, enquanto paginação, views, contrato e testes dependem do `id` numérico crescente.

**Decisão**

`chassi` será a PK de `senatran.veiculo`. `id` permanecerá `bigserial NOT NULL UNIQUE`, gerado pelo banco e usado somente como cursor técnico estável. Inserts não fornecerão `id`.

**Consequências**

O DDL, as views e os testes devem preservar `idUltimoRegistro` como `int64`, ordenado por `id`. Índices simples de placa e RENAVAM devem ser revistos após as novas constraints.

### DEC-002 — Limitar a precedência do data model às constraints aprovadas

**Status:** Accepted

**Contexto**

O data model diverge da implementação também em nomes físicos, tipos, FKs, referências e estruturas auxiliares, algumas superadas por decisões posteriores de arquitetura.

**Decisão**

Neste incremento, a precedência do data model limita-se a `chassi` como PK e `placa` e `codigo_renavam` como `UNIQUE NOT NULL`. Permanecem os nomes físicos atuais, códigos `text`, o modelo de colunas de busca mais `payload jsonb` e a ausência das demais FKs/referências. Em conflito de tipo de resposta, prevalece o OpenAPI.

**Consequências**

O seeder não completará nem reinterpretará o data model. Sua introspecção reconhecerá o schema físico preservado com as três alterações de Veículo e o novo papel de `id`. A atualização ampla do data model é dívida separada.

### DEC-003 — Separar core e auxiliares diretas

**Status:** Accepted

**Contexto**

As tabelas principais atendem a maior parte das consultas, mas sete auxiliares são necessárias para respostas positivas em todos os endpoints dos dois controllers.

**Decisão**

A entrega será dividida em Fase 1a, com catálogos, Condutores e Veículos, e Fase 1b, com `condutor_imagem`, `condutor_infracao_item`, `csv_seguranca`, `comunicacao_venda`, `endereco_possuidor`, `multa_interestadual` e `recall`.

**Consequências**

Infrações, ConsultaCSV, restrições judiciais, roubo/furto e demais domínios ficam fora destas fases. A Fase 1a não pode ser apresentada como cobertura completa dos 32 endpoints.

### DEC-004 — Gerar payload completo orientado pelo OpenAPI

**Status:** Accepted

**Contexto**

`jsonb NOT NULL` não garante objeto válido nem igualdade entre payload e colunas, e as views devolvem o payload persistido diretamente.

**Decisão**

Gerar todas as propriedades aplicáveis dos componentes `Condutor` e `Veiculo`, validar o objeto contra o OpenAPI e exigir igualdade entre cada âncora relacional e sua propriedade JSON. Lookup anulável ausente será omitido do JSON quando o schema não aceitar `null`.

**Consequências**

A validação ocorre antes do commit e distingue ausência, string vazia e `null`. O populador não altera o contrato nem adiciona validação de schema ao PostgreSQL.

### DEC-005 — Aplicar unicidade lógica aos identificadores de Condutor

**Status:** Accepted

**Contexto**

Os lookups de Condutor têm índices não únicos; a massa padrão precisa produzir consultas previsíveis sem inventar regras estruturais de domínio.

**Decisão**

CPF, registro CNH e RENACH serão únicos na massa e contra o banco. Identificadores opcionais também não se repetirão quando presentes. Duplicidades somente poderão existir em perfil de teste explícito.

**Consequências**

A geração precisa detectar colisões e fazer novas tentativas determinísticas. Nenhuma constraint `UNIQUE` será adicionada a `senatran.condutor` por esta decisão.

### DEC-006 — Corrigir os RENAVAMs estáveis antes da validação estrita

**Status:** Accepted

**Contexto**

Os três RENAVAMs fixos existentes não passam no algoritmo de dígito verificador do projeto e não podem ser corrigidos apenas no último dígito sem colisão.

**Decisão**

Substituir os três fixtures por bases distintas e RENAVAMs válidos, atualizando atomicamente manifesto, cenários, exemplos, testes e referências entre domínios antes de liberar o novo populador.

**Consequências**

Há quebra coordenada de fixtures publicados. Um teste do dígito verificador passa a ser obrigatório; fixtures inválidos não terão exceção na validação.

### DEC-007 — Reutilizar geradores regulados e isolar Faker

**Status:** Accepted

**Contexto**

O repositório já tem RNG e geradores brasileiros testados; Faker é útil para dados humanos, mas não deve definir identificadores regulados nem acoplar entidades.

**Decisão**

Usar os geradores existentes para CPF, CNPJ, placa, chassi e RENAVAM. Usar `@faker-js/faker` com locale `pt_BR` somente para nomes, endereços e textos humanos. Fixar sua versão e usar streams derivados e independentes para Condutor, Veículo e cada auxiliar.

**Consequências**

A mesma seed, versão e configuração reproduzem conteúdo e ordem dos candidatos. Alterar a quantidade de uma entidade não altera a sequência inicial da outra; IDs do banco dependem também do estado inicial das sequences.

### DEC-008 — Usar 10.000 registros como volume de aceite da CLI

**Status:** Accepted

**Contexto**

O gerador estático, documentos antigos e a especificação de carga indicam volumes diferentes.

**Decisão**

O aceite da nova CLI usará 10.000 Condutores e 10.000 Veículos. O gerador SQL estático permanecerá pequeno, versionado e independente.

**Consequências**

Testes de volume usarão banco descartável; os arquivos SQL de fixtures não serão inflados nem substituídos pela CLI.

### DEC-009 — Definir `--rows` como quantidade de candidatos

**Status:** Accepted

**Contexto**

No modo de conflito `skip`, quantidade solicitada e inserida podem divergir.

**Decisão**

`--rows` define a quantidade de candidatos únicos produzidos. Colisões internas causam retry determinístico limitado; colisões com o banco causam erro em `error` ou reduzem os inseridos em `skip`. O primeiro incremento aceita de 1 a 10.000 candidatos.

**Consequências**

O relatório informa candidatos, tentativas, inseridos e ignorados. Obter 10.000 inseridos requer banco compatível sem colisões; `skip` com menos inserções não é falha.

### DEC-010 — Fazer preflight curado dos catálogos existentes

**Status:** Accepted

**Contexto**

As entidades não têm FKs para os catálogos, e parte das referências do data model não existe no DDL.

**Decisão**

Validar e preencher idempotentemente apenas as tabelas de referência existentes e necessárias ao incremento, usando as listas curadas. Inserir código ausente, preservar item idêntico, abortar diante de descrição divergente e validar município com sua UF.

**Consequências**

O populador não cria tabelas, colunas ou códigos desconhecidos. O preflight antecede as entidades e participa da transação quando houver escrita; em `--dry-run`, apenas relata diferenças.

### DEC-011 — Não mascarar filtros incompletos com dados artificiais

**Status:** Accepted

**Contexto**

Os endpoints de segurança CRV ignoram CPF/CNPJ da rota, e consultas por proprietário não filtram seu tipo.

**Decisão**

O seeder gerará documento e tipo coerentes, sem moldar a massa para esconder os defeitos. Os filtros e o mapeamento de cenários devem ser corrigidos na aplicação antes de declarar cobertura correta da Fase 1b.

**Consequências**

A correção da aplicação é uma tarefa separada e não bloqueia a Fase 1a. A cobertura completa não pode ser aceita enquanto todos os parâmetros semânticos da rota não participarem da seleção e do scenario check.

### DEC-012 — Derivar auxiliares e indicadores das entidades principais

**Status:** Accepted

**Contexto**

As relações lógicas não são protegidas por FKs e podem produzir respostas contraditórias.

**Decisão**

Cada auxiliar copiará suas chaves e valores equivalentes de um único Condutor ou Veículo já gerado. Indicadores somente serão ativados quando sua semântica estiver coberta pelo escopo; quando houver auxiliar correspondente na Fase 1b, ambos derivarão do mesmo perfil.

**Consequências**

Veículos podem depender logicamente do universo de Condutores da mesma seed, e auxiliares dependem dos objetos principais. Relações não serão geradas de forma independente.

### DEC-013 — Preferir casos mínimos determinísticos a percentuais sem fonte

**Status:** Accepted

**Contexto**

Não existem percentuais aprovados para todos os opcionais, vínculos e indicadores.

**Decisão**

Manter como distribuições normativas somente 70/30 para placas e 80/10/5/5 para situações de CNH. Para as demais variações, garantir casos mínimos determinísticos positivos e ausentes; pesos adicionais podem ser defaults configuráveis e não são critério estatístico de aceite.

**Consequências**

Os casos de borda são emitidos de forma previsível. A implementação não transforma preferências sem evidência em regras de domínio.

### DEC-014 — Proibir execução em produção

**Status:** Accepted

**Contexto**

O projeto é destinado a mock/desenvolvimento e não há mecanismo de autorização de produção definido.

**Decisão**

No primeiro incremento, qualquer execução com `NODE_ENV=production` será recusada antes de escrita, sem override.

**Consequências**

Não haverá heurística por host/banco nem flag de liberação. Um uso futuro em produção exige nova decisão e mecanismo auditável.

### DEC-015 — Fixar a data-base da geração

**Status:** Accepted

**Contexto**

Idade e cronologia precisam ser reproduzíveis e não podem depender do relógio da execução.

**Decisão**

Adotar `2025-01-01T00:00:00Z` como data-base versionada para nascimento, emissão, validade e demais regras temporais.

**Consequências**

O relatório registra a data-base e os testes não dependem do dia corrente. Alterá-la requer mudança explícita de configuração/versão da massa.
