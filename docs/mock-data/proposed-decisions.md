# Decisões técnicas propostas

## Escopo desta análise

Este documento registra **recomendações**, não decisões já aceitas. A única decisão
tratada como previamente aprovada é a precedência do data model na divergência de
chave e unicidades de `senatran.veiculo`: `chassi` como PK e `placa` e
`codigo_renavam` como `UNIQUE`.

As evidências foram conferidas nos cinco arquivos de `docs/raw-investigation/` e
no checkout local do repositório SENATRAN, branch `main`, commit
`b39e8d0b425a8f8aa6622d82fdf0a45e10fe8101`. O caminho citado na solicitação,
`docs/mock-data/raw-investigation/`, não existe neste workspace; as fontes estão
em `docs/raw-investigation/`.

---

### DEC-CANDIDATE-001 — Preservar `veiculo.id` como cursor técnico

**Problema**

O data model promove `chassi` a PK, mas o serviço de paginação, as views, o
contrato e os testes dependem de um cursor numérico crescente chamado
`idUltimoRegistro` derivado de `veiculo.id`.

**Evidência**

- `docs/framework/arch/data-model.md`, seção `veiculo`: `chassi` como PK;
- `database/ddl/10-senatran-entities.sql`: `id bigserial primary key`;
- `domain/shared/api/src/common/read.service.ts`: `id > cursor`, `order by id` e
  leitura de `id,payload`;
- `database/ddl/90-contract-read.sql` e `tools/scripts/generate-views.ts`:
  `max(id)` e `jsonb_agg(payload order by id)`;
- `docs/framework/contracts/openapi.yaml`: `idUltimoRegistro` é `int64`;
- testes `read.service.spec.ts` e `tests/e2e/pagination.e2e.spec.ts`.

**Alternativas**

A. Remover `id` e paginar por `chassi`, alterando a semântica e o tipo do cursor.  
B. Manter `id bigserial NOT NULL UNIQUE` como chave técnica e tornar `chassi` a
PK.  
C. Criar uma nova coluna de cursor e migrar serviço, views e contrato.

**Recomendação**

Alternativa B. `chassi` passa a ser a identidade da entidade; `id` continua
gerado pelo banco, não é exposto como identidade de domínio e serve somente para
ordenação/paginação estável. A implementação deve omitir `id` nos inserts.

**Motivo**

É a única alternativa que cumpre a decisão de PK sem criar uma mudança de
contrato desnecessária. Também preserva o comportamento já testado de página
posterior vazia com HTTP 200.

**Impacto**

Alteração futura da constraint de `id`, manutenção da sequência e do índice
único, revisão do gerador de views e testes de regressão. Os índices simples de
`placa` e `codigo_renavam` tornam-se redundantes quando suas constraints
`UNIQUE` forem criadas.

**Risco**

Médio.

**Confiança**

Alta.

**Precisa de decisão humana?**

Sim.

---

### DEC-CANDIDATE-002 — Limitar a precedência do data model à divergência explicitamente decidida

**Problema**

Além de PK e unicidades, o data model diverge do DDL/código em nomes físicos,
tipos de códigos, tabelas de referência, FKs e estruturas auxiliares. Aplicá-lo
literalmente conflita com decisões posteriores de armazenamento por
`payload jsonb` e, em alguns pontos, com o OpenAPI.

**Evidência**

- `data-model.md` usa `numero_identificacao_proprietario`,
  `codigo_tipo_proprietario` e `ind_sinistro_*`; DDL, views, controllers,
  gerador e CDT usam `id_proprietario`, `tipo_proprietario`, `ind_media_monta`,
  `ind_grande_monta` e `ind_recuperado`;
- `data-model.md` lista referências e FKs ausentes e descreve vários códigos
  como `int`;
- `openapi.yaml` declara os códigos de `Veiculo` como `string`, e
  `05-senatran-ref.sql` usa `text`;
- `DESIGN-DECISIONS.md` (`D-0002` e `D-0010`) e
  `design-consolidation.md` registram refinamentos posteriores ao desenho P2;
- o próprio `data-model.md` ainda informa “no DDL written yet”.

**Alternativas**

A. Aplicar todo o data model literalmente.  
B. Aplicar nesta correção apenas `chassi` PK e unicidade de placa/RENAVAM,
preservando a realização física posterior.  
C. Suspender a implementação até reescrever integralmente o data model.

**Recomendação**

Alternativa B. Preservar, neste incremento, nomes físicos atuais, códigos `text`,
estrutura `chaves + payload` e ausência das FKs/referências que não existem no
DDL. Registrar separadamente a dívida de atualização do data model.

**Motivo**

Resolve a divergência explicitamente decidida sem transformar o seeder em uma
migração arquitetural ampla. Quando houver conflito de tipo de resposta, o
OpenAPI continua sendo a referência do contrato.

**Impacto**

O preflight do populador deve reconhecer o schema físico preservado, acrescido
somente das novas constraints de Veículo e da nova função de `id`.

**Risco**

Alto se o alcance não for explicitado; baixo após a delimitação.

**Confiança**

Alta.

**Precisa de decisão humana?**

Sim.

---

### DEC-CANDIDATE-003 — Separar core e auxiliares diretas em dois marcos

**Problema**

“Popular Veículos e Condutores” pode significar apenas as tabelas principais ou
dar resposta positiva a todos os 32 endpoints dos dois controllers. As fontes
históricas sustentam os dois entendimentos.

**Evidência**

- `# Especificação de população.md` limita a Fase 1a a 10.000 Condutores,
  10.000 Veículos e catálogos;
- `levantamento-tabelas-auxiliares.md` identifica sete auxiliares necessárias à
  cobertura completa;
- os controllers confirmam dependência de `condutor_imagem`,
  `condutor_infracao_item`, `csv_seguranca`, `comunicacao_venda`,
  `endereco_possuidor`, `multa_interestadual` e `recall`.

**Alternativas**

A. Entregar somente o core.  
B. Tornar as sete auxiliares obrigatórias no mesmo comando/incremento.  
C. Entregar Fase 1a (core) e Fase 1b (sete auxiliares diretas), com critérios
independentes.

**Recomendação**

Alternativa C. O core desbloqueia rapidamente a massa de 10.000; a Fase 1b deve
ser a condição explícita para declarar cobertura dos 20 endpoints de Veículos e
12 de Condutores. Infrações, ConsultaCSV, restrições, roubo/furto e domínios
transacionais ficam fora desse marco.

**Motivo**

Evita confundir volume das entidades principais com cobertura funcional, sem
ampliar o escopo para todos os domínios do mock.

**Impacto**

Ordem de população: referências → Condutores → Veículos → auxiliares de Condutor
→ auxiliares de Veículo. As auxiliares devem ser derivadas das entidades já
geradas.

**Risco**

Médio.

**Confiança**

Alta.

**Precisa de decisão humana?**

Sim, para definir se a entrega atual termina na Fase 1a ou inclui a Fase 1b.

---

### DEC-CANDIDATE-004 — Definir o contrato mínimo do `payload jsonb`

**Problema**

`jsonb NOT NULL` aceita escalares, arrays ou objetos incompletos e não garante
igualdade entre payload e colunas de busca. O OpenAPI lista propriedades, mas não
declara `required` para `Condutor` e `Veiculo`.

**Evidência**

- DDL de `condutor` e `veiculo`: `payload jsonb NOT NULL`, sem `CHECK` de tipo;
- `D-0010`: payload é o objeto exato do contrato;
- `openapi.yaml`: componentes sem lista `required`;
- `generate-seed.ts`: percorre todas as propriedades e sobrescreve âncoras;
- as views retornam o payload persistido sem reconstruí-lo ou validá-lo.

**Alternativas**

A. Gerar somente as propriedades usadas pelos endpoints.  
B. Gerar todas as propriedades do componente e validar tipo mais âncoras.  
C. Adicionar validação de schema dentro do PostgreSQL.

**Recomendação**

Alternativa B. Gerar todas as propriedades aplicáveis conforme a estratégia já
existente; validar `jsonb_typeof(payload) = 'object'`, tipos OpenAPI e igualdade
de todas as âncoras coluna/payload. Quando um lookup anulável estiver ausente,
omitir sua propriedade opcional do JSON, em vez de emitir `null` onde o schema
aceita apenas `string`.

**Motivo**

Mantém respostas úteis e detecta contradições sem introduzir um validador de
schema no banco.

**Impacto**

O builder precisa distinguir propriedade ausente de string vazia e validar antes
do insert/commit. Nenhuma alteração de DDL é necessária para o populador.

**Risco**

Médio.

**Confiança**

Alta.

**Precisa de decisão humana?**

Não.

---

### DEC-CANDIDATE-005 — Unicidade lógica da massa sem novas constraints de Condutor

**Problema**

CPF, registro CNH e RENACH são lookups indexados, mas não únicos no schema. A
especificação histórica pede unicidade na massa; as views aceitam múltiplos
resultados por chave.

**Evidência**

- `10-senatran-entities.sql`: índices não únicos em todos os lookups de
  `condutor`;
- `data-model.md`: não define `UNIQUE` para esses campos;
- views `v_condutores_by_*`: agregam todos os payloads da mesma chave;
- documentos históricos discordam entre “não presumir unicidade” e “unicidade
  semântica”.

**Alternativas**

A. Adicionar constraints `UNIQUE` ao DDL.  
B. Permitir duplicidades aleatórias.  
C. Manter o DDL e gerar, por padrão, CPF, registro e RENACH únicos; duplicidades
somente em perfil de teste explícito.

**Recomendação**

Alternativa C. Aplicar a mesma não repetição aos identificadores opcionais
quando preenchidos, apenas como política da massa, sem alegar que seja regra de
domínio.

**Motivo**

Produz consultas previsíveis para a massa padrão e preserva a capacidade do
schema/contrato de representar homônimos ou duplicidades controladas.

**Impacto**

Conjuntos de valores usados, checagem contra o banco e retry determinístico;
nenhuma nova constraint de Condutor.

**Risco**

Médio.

**Confiança**

Alta.

**Precisa de decisão humana?**

Sim, porque define o critério de conflito e aceite da massa de Condutores.

---

### DEC-CANDIDATE-006 — Corrigir os RENAVAMs estáveis antes da validação estrita

**Problema**

Os três RENAVAMs fixos publicados pelo projeto não passam no algoritmo de dígito
verificador que o próprio repositório usa. A nova unicidade também impede
simplesmente corrigir apenas o último dígito dos três, pois eles compartilham os
mesmos dez primeiros dígitos.

**Evidência**

- `generate-seed.ts` fixa `00123456780`, `00123456781` e `00123456782`;
- `br.ts` calcula o dígito com pesos `3,2,9,8,7,6,5,4,3,2`;
- por esse algoritmo, os valores publicados são inválidos;
- `seed-formats.spec.ts` verifica somente `^\d{11}$` para RENAVAM, não o dígito;
- os valores aparecem no manifesto, cenários, OpenAPI, testes e dados
  transacionais/cross-domain.

**Alternativas**

A. Corrigir os fixtures e todas as referências internas/consumidores em uma
mudança coordenada.  
B. Preservar os fixtures inválidos e exigir validade somente dos novos dados.  
C. Remover a exigência de dígito verificador.

**Recomendação**

Alternativa A, antes de liberar o novo populador. Criar três bases distintas com
dígitos válidos, atualizar manifesto e referências de forma atômica e comunicar
a quebra de fixtures aos consumidores.

**Motivo**

As alternativas B e C perpetuam uma violação da decisão `D-0006` e impedem um
critério simples de “todo RENAVAM é válido”.

**Impacto**

Mudança futura ampla, porém mecânica, nos seeds, testes, exemplos e vínculos de
RENAEST/RENAINF/SNE/CDT que usam esses fixtures. Deve existir teste real do
dígito verificador.

**Risco**

Alto.

**Confiança**

Alta.

**Precisa de decisão humana?**

Sim, por quebrar identificadores estáveis publicados a outros repositórios.

---

### DEC-CANDIDATE-007 — Reutilizar geradores regulados e isolar Faker por entidade

**Problema**

A especificação histórica escolhe Faker, mas ele não está instalado; o gerador
atual usa listas próprias e um único stream global de RNG. Introduzir Faker sem
disciplina pode quebrar reprodutibilidade e acoplar a sequência de Veículos à de
Condutores.

**Evidência**

- `package.json` não contém `@faker-js/faker`;
- `generate-seed.ts` usa um único `new Rng(MASTER_SEED)` para todo o arquivo;
- `br.ts` já possui RNG e geradores de CPF, CNPJ, placa, chassi e RENAVAM;
- a especificação pede Faker `pt_BR` apenas para dados humanos não regulados e
  streams independentes.

**Alternativas**

A. Não usar Faker.  
B. Usar Faker para todos os campos.  
C. Usar Faker somente para nomes/endereços/textos humanos e manter os geradores
existentes para identificadores e catálogos.

**Recomendação**

Alternativa C. Fixar a versão da dependência e derivar seeds/streams separados
para `condutor`, `veiculo` e cada auxiliar. O resultado determinístico garantido
é o conteúdo e a ordem dos candidatos para a mesma versão/configuração; IDs do
banco só se repetem quando o estado inicial e a sequence também forem iguais.

**Motivo**

Combina variedade de dados humanos com os validadores já testados, sem tratar
Faker como fonte de formatos brasileiros regulados.

**Impacto**

Extração de módulos compartilhados e testes que provem que variar `--rows` de
uma entidade não altera a sequência inicial da outra.

**Risco**

Baixo.

**Confiança**

Alta.

**Precisa de decisão humana?**

Não.

---

### DEC-CANDIDATE-008 — Fixar 10.000 como volume de aceite, sem substituir o seed estático

**Problema**

Há três volumes concorrentes: 120/80 no gerador atual, aproximadamente 500/300
em `mock-data.md` e 10.000/10.000 na especificação histórica mais recente.

**Evidência**

- `generate-seed.ts`: `VEH = 120` e `DRV = 80`;
- `docs/framework/arch/mock-data.md`: metas antigas de ~500/~300;
- `# Especificação de população.md`: 10.000 para cada entidade;
- o seed estático e seu `manifest.json` são consumidos por testes e projetos
  irmãos.

**Alternativas**

A. Aumentar o seed estático para 10.000.  
B. Manter o seed estático e usar 10.000 somente como aceite da nova CLI.  
C. Manter apenas os volumes atuais.

**Recomendação**

Alternativa B. A CLI é aditiva e parametrizável; o gerador estático continua
pequeno, versionado e com fixtures estáveis.

**Motivo**

Evita inflar o repositório e alterar IDs/fixtures de testes enquanto atende o
objetivo de carga volumétrica.

**Impacto**

Dois fluxos explícitos: `seed:generate` para fixtures e `populate` para carga
direta. O teste de volume deve usar banco descartável, não arquivos SQL
comitados.

**Risco**

Baixo.

**Confiança**

Alta.

**Precisa de decisão humana?**

Sim, para confirmar que 10.000 é o volume vigente de aceite.

---

### DEC-CANDIDATE-009 — Definir `--rows` como candidatos e conflito `skip` como redução explícita

**Problema**

No modo `skip`, não está definido se `--rows` significa candidatos processados
ou quantidade líquida inserida. Também não há teto definido. Em 10.000 linhas,
colisões por geração precisam de retry: identificadores com somente sete
dígitos, como motor/câmbio e alguns lookups de Condutor, têm colisão altamente
provável sem deduplicação.

**Evidência**

- interface histórica: `--rows`, `--on-conflict error|skip` e limite
  configurável, sem semântica completa;
- `br.ts`/`generate-seed.ts`: vários valores usam `rng.digits(7)` e não há
  detecção explícita de colisões;
- `placa` e `codigo_renavam` serão `UNIQUE` no banco.

**Alternativas**

A. `--rows` é meta líquida, com geração ilimitada até inserir N.  
B. `--rows` é número de candidatos únicos gerados; conflitos com o banco reduzem
o total inserido em `skip`.  
C. Criar duas opções de contagem.

**Recomendação**

Alternativa B. Colisões internas durante a construção de candidatos devem sofrer
retry determinístico com limite; colisões contra dados preexistentes seguem
`error` ou `skip`. No primeiro incremento, aceitar `1..10000`; ampliar o teto
somente após medição.

**Motivo**

É simples, termina de forma previsível e preserva o significado usual de
`ON CONFLICT DO NOTHING`. O relatório elimina ambiguidade ao mostrar candidatos,
inseridos, ignorados e tentativas.

**Impacto**

`skip` pode concluir com menos linhas que o solicitado e deve informar isso sem
ser tratado como falha. A meta de 10.000 inseridos exige banco compatível/vazio
ou modo `error` sem colisões.

**Risco**

Baixo.

**Confiança**

Alta.

**Precisa de decisão humana?**

Não.

---

### DEC-CANDIDATE-010 — Fazer preflight curado, sem completar o data model

**Problema**

Os catálogos não têm FKs para as entidades; parte dos catálogos citados no data
model nem existe no DDL. Gerar códigos livremente ou criar referências ausentes
silenciosamente produz drift.

**Evidência**

- `05-senatran-ref.sql` cria 13 referências; o data model lista outras seis;
- `ref_municipio.uf` não possui FK para `ref_uf`;
- `refdata.ts` contém listas curadas usadas pelo seed atual;
- as views retornam o payload pronto, sem joins que corrijam código/descrição.

**Alternativas**

A. Criar todas as referências do data model.  
B. Ignorar referências porque não há FK.  
C. Validar/preencher idempotentemente somente as referências existentes e
necessárias aos payloads deste incremento.

**Recomendação**

Alternativa C. Para código ausente, inserir a lista curada; para descrição
divergente, abortar; para município, validar também o par UF. Não criar tabela,
coluna ou código desconhecido pelo preflight.

**Motivo**

Garante coerência suficiente para mock/teste e mantém o populador fora da função
de migrador de schema.

**Impacto**

Catálogos antes das entidades e dentro da mesma transação do comando quando
houver escrita. `--dry-run` apenas relata diferenças.

**Risco**

Baixo.

**Confiança**

Alta.

**Precisa de decisão humana?**

Não, condicionado à aprovação do alcance em `DEC-CANDIDATE-002`.

---

### DEC-CANDIDATE-011 — Não compensar no seed os filtros incompletos dos endpoints

**Problema**

Há parâmetros de rota que não participam da consulta e dois endpoints de
proprietário não discriminam o tipo. Além disso, chaves de proprietário chegam
ao `ReadService` como `id_proprietario`, que não está mapeado para cenários
forçados.

**Evidência**

- `VeiculosController.csvByCpf/csvByCnpj` não recebem nem enviam CPF/CNPJ ao
  `ReadService`, apesar de as views exporem as colunas;
- `byProprietarioCpf/byProprietarioCnpj` filtram somente `id_proprietario`, não
  `tipo_proprietario`;
- `ReadService.COL_KIND` não contém `id_proprietario`;
- `generate-views.ts` gera as views CPF/CNPJ de proprietário com as mesmas
  colunas, sem predicado de tipo;
- os códigos curados são `1 = PESSOA FISICA` e `2 = PESSOA JURIDICA`.

**Alternativas**

A. Modelar a massa para esconder os defeitos.  
B. Aceitar formalmente que os parâmetros/tipos não são validados.  
C. Corrigir depois, no repositório SENATRAN, para que todos os parâmetros de rota
participem da seleção e do scenario check.

**Recomendação**

Alternativa C. O seeder deve apenas gerar documento e tipo coerentes. A Fase 1a
pode prosseguir, mas a Fase 1b não deve declarar cobertura correta dos endpoints
de segurança CRV até a consulta usar CPF/CNPJ. A correção deve continuar fora
desta tarefa de decisões.

**Motivo**

Dados artificiais não devem mascarar erro de roteamento. CPF e CNPJ válidos têm
comprimentos diferentes, mas isso não corrige o parâmetro ignorado nem o cenário
forçado ausente.

**Impacto**

Cria dependência de aplicação/testes antes do aceite de cobertura total; não
bloqueia a geração das duas tabelas principais.

**Risco**

Médio.

**Confiança**

Alta.

**Precisa de decisão humana?**

Sim, pois amplia o trabalho além do populador e pode exigir coordenação com o
owner do mock SENATRAN.

---

### DEC-CANDIDATE-012 — Derivar auxiliares e indicadores de uma única entidade principal

**Problema**

As relações entre entidades principais e auxiliares não têm FK. É possível gerar
placa/RENAVAM/documento/chassi contraditórios ou indicador positivo sem o recurso
correspondente.

**Evidência**

- DDL das auxiliares possui apenas índices/PKs locais;
- `levantamento-tabelas-auxiliares.md` mapeia as relações lógicas;
- `mock-data.md` exige coerência cross-domain;
- o gerador atual deriva subconjuntos de `vehicles` e `drivers`, mas vários
  campos internos dos payloads auxiliares ainda são preenchidos genericamente.

**Alternativas**

A. Gerar cada tabela independentemente.  
B. Derivar chaves e campos equivalentes do mesmo objeto principal, sem FK.  
C. Adicionar FKs para todas as relações.

**Recomendação**

Alternativa B. A mesma placa, RENAVAM, chassi e documento/tipo deve ser copiada
para colunas e payload auxiliar. Só ativar indicadores cuja semântica esteja
coberta no escopo; quando uma auxiliar correspondente fizer parte da Fase 1b,
gerá-la a partir do mesmo perfil.

**Motivo**

É suficiente para um mock coerente e evita alteração estrutural excessiva.

**Impacto**

Veículo depende logicamente do universo determinístico de Condutores quando um
CPF for reutilizado; auxiliares dependem dos objetos principais já gerados.

**Risco**

Médio.

**Confiança**

Alta.

**Precisa de decisão humana?**

Não.

---

### DEC-CANDIDATE-013 — Usar casos mínimos determinísticos em vez de percentuais não fundamentados

**Problema**

Somente algumas distribuições possuem valores explícitos. Não há percentuais
aprovados para PGU, PID, impedimento, proprietário compartilhado, campos
opcionais ou cada indicador de Veículo.

**Evidência**

- especificação histórica fixa 70/30 para placa e uma distribuição para situação
  de CNH;
- `generate-seed.ts` usa probabilidades próprias e preenche PGU, PID,
  impedimento, motor e câmbio em todos os registros principais;
- `open-questions.md` registra os percentuais restantes como indefinidos.

**Alternativas**

A. Inventar percentuais completos.  
B. Gerar tudo preenchido.  
C. Garantir um conjunto pequeno e determinístico de casos positivos/ausentes e
deixar os demais pesos como defaults configuráveis, sem critério estatístico de
aceite.

**Recomendação**

Alternativa C. Manter somente 70/30 de placas como contagem exata e a distribuição
de CNH já especificada. Para o restante, o aceite verifica presença de cada
perfil relevante, não percentual.

**Motivo**

Evita transformar preferências sem fonte em regras de domínio e reduz testes
estatísticos frágeis.

**Impacto**

Perfis de borda são emitidos primeiro e documentados; defaults podem ser
ajustados durante a implementação sem mudar o contrato externo.

**Risco**

Baixo.

**Confiança**

Alta.

**Precisa de decisão humana?**

Não.

---

### DEC-CANDIDATE-014 — Proibir execução em produção no primeiro incremento

**Problema**

A especificação exige autorização explícita em produção, mas não define como
detectar o ambiente nem a flag de override. Heurísticas de hostname/nome do banco
são inseguras.

**Evidência**

- `AGENTS.md` define o projeto como mock somente de desenvolvimento;
- `configuration.ts` expõe `NODE_ENV`, `DATABASE_URL`, `DB_*`, SSL e timeout;
- `apply.sh`/`seed.sh` usam apenas `DB_*`, enquanto a aplicação prioriza
  `DATABASE_URL`;
- não existe hoje flag de autorização para população em produção.

**Alternativas**

A. Criar override por variável/flag.  
B. Usar heurística de host/database.  
C. Recusar sempre quando `NODE_ENV=production` no primeiro incremento.

**Recomendação**

Alternativa C. Reutilizar a resolução de conexão da aplicação e falhar antes de
qualquer escrita quando `NODE_ENV=production`. Se um uso legítimo surgir, ele
deve ser aprovado como nova decisão com mecanismo não interativo auditável.

**Motivo**

É a política fail-closed mais simples e coerente com a finalidade declarada do
repositório.

**Impacto**

Sem flag de override inicialmente. Cada comando usa uma transação única,
rollback integral, queries parametrizadas e logs sem credenciais.

**Risco**

Baixo.

**Confiança**

Alta.

**Precisa de decisão humana?**

Sim, para confirmar que não existe caso autorizado de uso em produção.

---

### DEC-CANDIDATE-015 — Fixar uma data-base versionada para regras temporais

**Problema**

Idade, validade e cronologia dependem de uma referência temporal, mas usar o dia
da execução quebra a reprodutibilidade. A data-base ainda não está definida.

**Evidência**

- a especificação exige Condutores entre 18 e 80 anos “na data-base”;
- `generate-seed.ts` e `br.ts` usam faixas de anos fixas, incluindo limites em
  2024/2025;
- a mesma especificação proíbe `Date.now()` e exige resultado determinístico.

**Alternativas**

A. Usar a data corrente.  
B. Fixar e versionar uma data-base UTC na configuração da geração.  
C. Gerar datas sem validar idade/ordem temporal.

**Recomendação**

Alternativa B. Adotar `2025-01-01T00:00:00Z` como data-base inicial, registrá-la
no relatório e derivar dela nascimento, emissão e validade. Uma futura troca da
data-base deve ser mudança explícita da versão/configuração da massa.

**Motivo**

Torna idade e cronologia verificáveis sem introduzir dependência do relógio.

**Impacto**

Helpers temporais recebem a referência fixa; testes deixam de depender do ano em
que forem executados.

**Risco**

Baixo.

**Confiança**

Alta.

**Precisa de decisão humana?**

Não.

---

## Resumo executivo

### 1. Decisões obrigatórias antes da implementação

- `DEC-CANDIDATE-001`: papel de `id` e preservação de `idUltimoRegistro`;
- `DEC-CANDIDATE-002`: alcance exato da precedência do data model;
- `DEC-CANDIDATE-005`: unicidade lógica dos lookups de Condutor;
- `DEC-CANDIDATE-006`: tratamento dos RENAVAMs estáveis inválidos;
- `DEC-CANDIDATE-008`: confirmação do volume de 10.000 por entidade;
- `DEC-CANDIDATE-009`: semântica de `--rows`/`skip` e retry de colisões;
- `DEC-CANDIDATE-014`: bloqueio de produção.

`DEC-CANDIDATE-003` é obrigatória antes de prometer cobertura integral dos 32
endpoints, mas não bloqueia a Fase 1a limitada às tabelas principais.

### 2. Decisões de baixo impacto que podem ser tomadas durante a implementação

- contrato de payload e representação de propriedades opcionais
  (`DEC-CANDIDATE-004`);
- isolamento de RNG/Faker (`DEC-CANDIDATE-007`);
- preflight dos catálogos existentes (`DEC-CANDIDATE-010`);
- derivação das relações auxiliares (`DEC-CANDIDATE-012`);
- uso de casos mínimos em vez de percentuais inventados
  (`DEC-CANDIDATE-013`);
- data-base versionada (`DEC-CANDIDATE-015`).

### 3. Riscos relevantes

- remover ou deixar de indexar `veiculo.id` quebra paginação, views e testes;
- interpretar “data model prevalece” de forma ampla conflita com o OpenAPI e com
  decisões posteriores de armazenamento;
- corrigir os RENAVAMs publicados quebra fixtures consumidas por outros domínios
  e possivelmente por repositórios irmãos;
- 10.000 registros sem deduplicação/retry terão colisões prováveis, sobretudo em
  identificadores de sete dígitos e placas;
- payload divergente das colunas é devolvido diretamente pela API;
- os filtros incompletos de segurança CRV/proprietário podem produzir falso
  positivo mesmo com massa coerente;
- chamar a Fase 1a de “cobertura completa” deixará sete grupos de endpoints sem
  dados positivos.

### 4. Pontos que realmente precisam da aprovação do owner

- manter `id` como chave técnica `UNIQUE NOT NULL` após `chassi` virar PK;
- restringir a precedência do data model às constraints de Veículo já decididas;
- decidir se a entrega atual inclui a Fase 1b de auxiliares diretas;
- aprovar a política de unicidade lógica de Condutor;
- autorizar a troca coordenada dos RENAVAMs estáveis;
- confirmar 10.000 como volume vigente de aceite;
- decidir se os defeitos de filtro serão corrigidos antes da cobertura total;
- confirmar que a CLI deve recusar produção sem override.

Nenhuma recomendação acima autoriza alteração de DDL, código, contratos ou
documentação final nesta etapa.
