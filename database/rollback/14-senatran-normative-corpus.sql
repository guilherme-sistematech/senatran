-- Reverte a estrutura do corpus. Os códigos remapeados permanecem; para
-- restaurar os valores aleatórios anteriores, recupere o backup pré-migração.
begin;

alter table senatran.infracao
  drop constraint if exists fk_infracao_codigo_normativo;

drop index if exists senatran.idx_infracao_pacote_codigo;

alter table senatran.infracao
  alter column codigo_infracao drop not null,
  drop column if exists pacote_normativo_id;

drop table if exists senatran.ref_codigo_infracao;
drop table if exists senatran.ref_pacote_normativo;

commit;
