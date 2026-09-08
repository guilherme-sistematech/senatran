-- SENATRAN mock — physical infraction relationships approved for the sandbox.
-- Driver identity is the natural pair (cpf, numero_registro). The relationship
-- is optional: MATCH SIMPLE leaves an infraction unlinked when either child key
-- component is null.

begin;

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
  add constraint fk_infracao_veiculo_placa
  foreign key (placa)
  references senatran.veiculo (placa)
  on update no action
  on delete restrict
  not valid;

alter table senatran.infracao
  validate constraint fk_infracao_condutor_cpf_registro;

alter table senatran.infracao
  validate constraint fk_infracao_veiculo_placa;

commit;
