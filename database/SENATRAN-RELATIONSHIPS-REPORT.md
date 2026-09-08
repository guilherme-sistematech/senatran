# SENATRAN schema relationships — review report

Date: 2026-09-08  
Role: Engineer  
Target: local dev-only sandbox (`localhost:5433/senatran`)  
Method: static DDL/contract/design review plus SQL catalog and data audits.

## Executive decision

Eight relationships were installed and validated. Four are normalized reference
relationships:

1. `ref_municipio.uf -> ref_uf.uf`
2. `ref_orgao_autuador.uf -> ref_uf.uf`
3. `veiculo.tipo_proprietario -> ref_tipo_proprietario.codigo`
4. `infracao.codigo_orgao_autuador -> ref_orgao_autuador.codigo`

Two additional physical relationships were explicitly approved for the sandbox:

5. `infracao.placa -> veiculo.placa`
6. `infracao.numero_registro_cnh -> condutor.numero_registro`

The TEAT staging corpus adds two version-aware relationships:

7. `ref_codigo_infracao.pacote_normativo_id -> ref_pacote_normativo.id`
8. `(infracao.pacote_normativo_id, infracao.codigo_infracao) ->
   (ref_codigo_infracao.pacote_normativo_id, ref_codigo_infracao.codigo)`

This composite key is deliberate: the same displayed code can change meaning,
description or legal basis between normative packages. `codigo_renainf` remains
the 12-digit RENAINF identifier and is not related to the framing-code table.

The installed package is a dated snapshot of the 106 BackOffice staging fichas
provided for mock mass/corpus generation. It is not presented as the official,
complete national SENATRAN catalogue. The national list of enforcement agencies
also remains a separate sourcing task; the five existing agencies are fixtures.

The driver relationship adds `UNIQUE (numero_registro)` to `condutor` while
retaining `condutor.id` as the technical primary key and cursor key. An
infraction remains unlinked when its optional `numero_registro_cnh` is null.

The remaining vehicle-satellite, driver and AIT relationships remain conceptual.
`docs/framework/arch/data-model.md` states that cross-entity
referential coherence is enforced by the deterministic seed generator rather
than hard FKs across every denormalized lookup column. The two infraction links
are a consciously approved exception for this sandbox; promoting that exception
to project architecture still requires an Architect decision.

## Evidence reviewed

- `database/ddl/05-senatran-ref.sql`
- `database/ddl/10-senatran-entities.sql`
- `database/ddl/90-contract-read.sql`
- `docs/framework/contracts/openapi.yaml`
- `docs/framework/arch/data-model.md`
- `docs/framework/arch/mock-data.md`
- `tools/scripts/generate-seed.ts`
- TEAT staging BackOffice corpus (106 version-dependent fichas)
- the PostgreSQL catalog and current synthetic data

The live catalog initially contained 29 `senatran` tables and zero FKs in that
schema.

## Audit result

All checks returned zero violations, including:

- Wave 1 reference orphans;
- missing vehicle rows by plate, chassis or RENAVAM;
- inconsistent plate/chassis and plate/RENAVAM pairs;
- duplicate or incomplete AIT triples;
- duplicate driver CPF/registration identities;
- orphan driver images, extracts and infractions;
- infractions outside their selected normative package;
- divergence between relational framing code/description and the JSON payload.

Observed core volumes: 120 vehicles, 80 drivers, 250 infractions, 40 recalls,
one normative package and 106 framing fichas.

## Installed constraints

All eight foreign keys report `convalidated = true`:

```text
fk_ref_municipio_uf
fk_ref_orgao_autuador_uf
fk_veiculo_tipo_proprietario
fk_infracao_orgao_autuador
fk_infracao_veiculo_placa
fk_infracao_condutor_numero_registro
fk_ref_codigo_infracao_pacote
fk_infracao_codigo_normativo
```

They use `ON UPDATE NO ACTION` and `ON DELETE RESTRICT`. No cascade was added.

## Conceptual relationships retained for management review

```text
veiculo 1--N restricao_judicial       via placa / RENAVAM
veiculo 1--N roubo_furto_ocorrencia   via placa / chassi
veiculo 1--N consulta_csv             via placa / chassi
veiculo 1--N csv_seguranca            via placa / RENAVAM
veiculo 1--N comunicacao_venda        via placa / RENAVAM
veiculo 1--N endereco_possuidor       via placa / RENAVAM
veiculo 1--N multa_interestadual      via placa / RENAVAM
veiculo 1--N recall                   via chassi
infracao 1--N infracao_ocorrencia     via AIT triple
infracao 1--N infracao_pagamento      via AIT triple
condutor 1--N condutor_imagem         via CPF + CNH registration
condutor 1--N condutor_infracao_item  via CNH registration
```

These links may be promoted to physical FKs only through an explicit architecture
decision defining closed-world fixtures and canonical natural identities.

## Verification completed

- A pre-migration custom-format backup was taken at
  `database/.tmp-fk-review/senatran-before-normative-corpus-2026-09-08.dump`.
- Migration 14 passed first against a verification database restored from that
  backup.
- Clean DDL 00–92 plus all deterministic seeds passed from zero in
  `senatran_normative_fresh` using native Windows `psql`.
- The live sandbox `localhost:5433/senatran` was migrated and audited: 106
  fichas, 250 linked infractions, zero orphans and zero payload divergences.
- The relationship rollbacks removed the original six FKs and driver natural
  key; rollback 14 separately removed the corpus structures. Reapplication
  restored all eight validated FKs, 106 fichas and zero orphans.
- Integration: 21/21 passed against the migrated sandbox, including three new
  normative-corpus checks and rejection of an invalid code (`SQLSTATE 23503`).
- Unit: 152/152 passed.
- TypeScript typecheck: passed.
- OpenAPI check: 114 operations, no drift.
- Seed determinism: all 11 generated outputs were byte-identical after
  regeneration.
- `git diff --check`: passed.
- Aggregate `pnpm check`: blocked at lint by existing checkout-wide CRLF line
  endings (15,527 Prettier errors unrelated to this migration). The new test
  passes isolated lint. No mass reformatting was performed.

## Apply and rollback commands

From the repository root in PowerShell:

```powershell
$env:PGPASSWORD = 'postgres'
psql -X -v ON_ERROR_STOP=1 -h localhost -p 5433 -U postgres -d senatran `
  -f database/ddl/11-senatran-relationships.sql
psql -X -v ON_ERROR_STOP=1 -h localhost -p 5433 -U postgres -d senatran `
  -f database/ddl/12-senatran-infracao-relationships.sql
psql -X -v ON_ERROR_STOP=1 -h localhost -p 5433 -U postgres -d senatran `
  -f database/ddl/13-senatran-infracao-condutor-registro.sql
psql -X -v ON_ERROR_STOP=1 -h localhost -p 5433 -U postgres -d senatran `
  -f database/ddl/14-senatran-normative-corpus.sql
```

Rollback:

```powershell
$env:PGPASSWORD = 'postgres'
psql -X -v ON_ERROR_STOP=1 -h localhost -p 5433 -U postgres -d senatran `
  -f database/rollback/14-senatran-normative-corpus.sql
psql -X -v ON_ERROR_STOP=1 -h localhost -p 5433 -U postgres -d senatran `
  -f database/rollback/13-senatran-infracao-condutor-registro.sql
psql -X -v ON_ERROR_STOP=1 -h localhost -p 5433 -U postgres -d senatran `
  -f database/rollback/12-senatran-infracao-relationships.sql
psql -X -v ON_ERROR_STOP=1 -h localhost -p 5433 -U postgres -d senatran `
  -f database/rollback/11-senatran-relationships.sql
```

## IDE visualization

Connect to `localhost:5433`, database `senatran`, refresh the database metadata,
select the `senatran` schema and regenerate the ER diagram. The eight installed
FKs should appear as solid physical relationships, including `infracao` linked
to `veiculo`, `condutor` and the versioned infraction-code corpus. Use the
separate proposal visualization to discuss the conceptual relationships that
intentionally remain outside PostgreSQL.
