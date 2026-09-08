-- Roll back database/ddl/11-senatran-relationships.sql.

begin;

alter table senatran.infracao
  drop constraint if exists fk_infracao_orgao_autuador;

alter table senatran.veiculo
  drop constraint if exists fk_veiculo_tipo_proprietario;

alter table senatran.ref_orgao_autuador
  drop constraint if exists fk_ref_orgao_autuador_uf;

alter table senatran.ref_municipio
  drop constraint if exists fk_ref_municipio_uf;

commit;
