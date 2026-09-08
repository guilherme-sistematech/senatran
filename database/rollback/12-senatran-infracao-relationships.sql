-- Roll back database/ddl/12-senatran-infracao-relationships.sql.

begin;

alter table senatran.infracao
  drop constraint if exists fk_infracao_veiculo_placa;

alter table senatran.infracao
  drop constraint if exists fk_infracao_condutor_cpf_registro;

alter table senatran.condutor
  drop constraint if exists uq_condutor_cpf_numero_registro;

commit;
