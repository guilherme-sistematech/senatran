-- Roll back database/ddl/13-senatran-infracao-condutor-registro.sql.

begin;

alter table senatran.infracao
  drop constraint if exists fk_infracao_condutor_numero_registro;

alter table senatran.condutor
  drop constraint if exists uq_condutor_numero_registro;

alter table senatran.condutor
  add constraint uq_condutor_cpf_numero_registro
  unique (cpf, numero_registro);

alter table senatran.infracao
  add constraint fk_infracao_condutor_cpf_registro
  foreign key (cpf, numero_registro_cnh)
  references senatran.condutor (cpf, numero_registro)
  match simple
  on update no action
  on delete restrict
  not valid;

alter table senatran.infracao
  validate constraint fk_infracao_condutor_cpf_registro;

commit;
