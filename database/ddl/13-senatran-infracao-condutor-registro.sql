-- SENATRAN mock — simplify the infraction-to-driver relationship.
-- numero_registro is the domain identity used by the infraction contract;
-- condutor.id remains the technical primary key and cursor ordering key.

begin;

alter table senatran.infracao
  drop constraint fk_infracao_condutor_cpf_registro;

alter table senatran.condutor
  drop constraint uq_condutor_cpf_numero_registro;

alter table senatran.condutor
  add constraint uq_condutor_numero_registro
  unique (numero_registro);

alter table senatran.infracao
  add constraint fk_infracao_condutor_numero_registro
  foreign key (numero_registro_cnh)
  references senatran.condutor (numero_registro)
  on update no action
  on delete restrict
  not valid;

alter table senatran.infracao
  validate constraint fk_infracao_condutor_numero_registro;

commit;
