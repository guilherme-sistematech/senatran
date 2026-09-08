-- SENATRAN mock — enforced reference relationships.
--
-- Cross-entity coherence (vehicle satellites, driver extracts and AIT children)
-- remains the deterministic seed generator's responsibility, as defined by
-- docs/framework/arch/data-model.md. Only normalized reference relationships
-- with materialized scalar keys are enforced here.

begin;

alter table senatran.ref_municipio
  add constraint fk_ref_municipio_uf
  foreign key (uf)
  references senatran.ref_uf (uf)
  on update no action
  on delete restrict
  not valid;

alter table senatran.ref_orgao_autuador
  add constraint fk_ref_orgao_autuador_uf
  foreign key (uf)
  references senatran.ref_uf (uf)
  on update no action
  on delete restrict
  not valid;

alter table senatran.veiculo
  add constraint fk_veiculo_tipo_proprietario
  foreign key (tipo_proprietario)
  references senatran.ref_tipo_proprietario (codigo)
  on update no action
  on delete restrict
  not valid;

alter table senatran.infracao
  add constraint fk_infracao_orgao_autuador
  foreign key (codigo_orgao_autuador)
  references senatran.ref_orgao_autuador (codigo)
  on update no action
  on delete restrict
  not valid;

alter table senatran.ref_municipio
  validate constraint fk_ref_municipio_uf;

alter table senatran.ref_orgao_autuador
  validate constraint fk_ref_orgao_autuador_uf;

alter table senatran.veiculo
  validate constraint fk_veiculo_tipo_proprietario;

alter table senatran.infracao
  validate constraint fk_infracao_orgao_autuador;

commit;
