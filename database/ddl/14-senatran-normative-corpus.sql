-- SENATRAN mock — snapshot versionado do corpus normativo do TEAT.
-- Fonte: BackOffice TEAT staging, compilado em 2026-09-08 (106 fichas).
-- O código só é unívoco dentro do pacote/snapshot que lhe dá significado.
begin;

create table senatran.ref_pacote_normativo (
  id uuid primary key,
  codigo text not null unique,
  nome text not null,
  versao text not null,
  vigente_desde date not null,
  vigente_ate date,
  fonte text not null,
  quantidade_fichas integer not null check (quantidade_fichas > 0),
  capturado_em timestamptz not null,
  metadata jsonb not null default '{}'::jsonb
);

create table senatran.ref_codigo_infracao (
  pacote_normativo_id uuid not null,
  codigo text not null,
  descricao text not null,
  dispositivo text not null,
  codigo_fonte uuid not null,
  situacao text not null default 'ATIVA',
  primary key (pacote_normativo_id, codigo),
  unique (pacote_normativo_id, codigo_fonte),
  constraint fk_ref_codigo_infracao_pacote
    foreign key (pacote_normativo_id)
    references senatran.ref_pacote_normativo (id)
    on update no action
    on delete restrict
);

insert into senatran.ref_pacote_normativo (
  id, codigo, nome, versao, vigente_desde, fonte,
  quantidade_fichas, capturado_em, metadata
) values (
  '10610610-0000-4000-8000-000000000001',
  'teat-staging-corpus-2026-09-08',
  'Corpus normativo TEAT — massa e corpus',
  '2026-09-08',
  date '2026-09-08',
  'TEAT BackOffice staging / normative.normative_framing',
  106,
  timestamptz '2026-09-08 16:55:00-03',
  '{"ambiente":"staging","finalidade":"mock","observacao":"As fichas variam por pacote normativo"}'::jsonb
);

-- BEGIN TEAT NORMATIVE CORPUS
insert into senatran.ref_codigo_infracao (
  pacote_normativo_id, codigo, descricao, dispositivo, codigo_fonte
)
select
  '10610610-0000-4000-8000-000000000001'::uuid,
  codigo,
  descricao,
  dispositivo,
  codigo_fonte
from (values
  ('CTB-255', 'Uso irregular de veículo de tração animal', 'CTB 255', '59ac58f3-0294-4436-bcd7-1ceb4bb7270e'::uuid),
  ('CTB-254', 'Proibições ao pedestre (andar fora da faixa, atravessar fora do local, etc., I a VII)', 'CTB 254', '3b062dc3-9c6e-4706-9294-29ef4a29a6f7'::uuid),
  ('CTB-253-A', 'Usar veículo para interromper/restringir/perturbar a circulação sem autorização', 'CTB 253-A', '8911e800-57ec-4ca1-8400-8227c5534d90'::uuid),
  ('CTB-253', 'Conduzir motocicleta/ciclomotor sem capacete/vestuário de proteção', 'CTB 253', 'e0283e9d-ed61-4abf-8cb6-0d235d6cbe96'::uuid),
  ('CTB-252', 'Dirigir sem condições exigidas (celular, calçado inadequado, braço fora, I a VI)', 'CTB 252', '89b78322-5c0a-4cd8-9ce5-97cf2b439ccd'::uuid),
  ('CTB-251', 'Usar luz vermelha intermitente ou alarme não autorizado', 'CTB 251', '9b0d1a7c-d1a8-4a0c-8ae0-4c5183488d62'::uuid),
  ('CTB-250', 'Usar equipamento/luzes/películas em desacordo com regulamentação', 'CTB 250', '8276f345-cb10-4d4c-825e-e4813da0e6ff'::uuid),
  ('CTB-249', 'Usar buzina em situação/horário/local proibido', 'CTB 249', 'a783d7b0-1720-4c50-b745-58cbacdf294a'::uuid),
  ('CTB-248', 'Conduzir com vidros/películas que impeçam visualização', 'CTB 248', '0f85f30e-f2b2-4aab-8eb5-65904f2727f9'::uuid),
  ('CTB-247', 'Deixar o veículo com sistema de descarga livre (escapamento irregular)', 'CTB 247', '68d010c5-badc-4feb-ba57-b47fc8b4dbef'::uuid),
  ('CTB-246', 'Utilizar veículo sem limpador de para-brisa funcionando', 'CTB 246', '758b9c23-031e-455b-8d97-a8e5511bec64'::uuid),
  ('CTB-245', 'Utilizar/deixar de utilizar retrovisores obrigatórios', 'CTB 245', '8f0281ed-f4fb-455f-be87-3589d3319ca2'::uuid),
  ('CTB-244', 'Conduzir motocicleta/moto-táxi/ciclomotor em desacordo com normas (I a VI)', 'CTB 244', 'ff730fae-bbb0-4f5c-8b3f-69997ac085c1'::uuid),
  ('CTB-243', 'Usar equipamento/acessório proibido (ex. detector de radar)', 'CTB 243', 'fec17cea-d60d-439e-ae2f-07141c956565'::uuid),
  ('CTB-242', 'Fazer uso de sirene sem autorização', 'CTB 242', '06100c89-525a-41ee-bfb3-37477989f166'::uuid),
  ('CTB-241', 'Usar indevidamente dispositivo de alarme sonoro (sirene)', 'CTB 241', '29991365-20f2-4f97-963c-17035e58a5ed'::uuid),
  ('CTB-240', 'Deixar de dar preferência a veículo de emergência/batedores', 'CTB 240', 'aabdad98-2811-4e75-8733-61a04914052a'::uuid),
  ('CTB-239', 'Retirar do local veículo retido pela fiscalização sem autorização', 'CTB 239', 'efa6911f-ba8d-4751-869b-f3190778dda9'::uuid),
  ('CTB-238', 'Deixar de fornecer/fornecer falsamente dados a agente de trânsito', 'CTB 238', '3298385f-fb44-4679-bce7-4b3f95dff72b'::uuid),
  ('CTB-237', 'Colocar inscrição/dispositivo sem autorização ou não comunicar modificação', 'CTB 237', 'b65eb61c-be80-4ca1-8125-e4a299d92670'::uuid),
  ('CTB-236', 'Rebocar outro veículo em desacordo com as normas', 'CTB 236', '3645b4d3-1063-49ad-99bb-4785282e925e'::uuid),
  ('CTB-235', 'Deixar de dar baixa em registro de veículo irrecuperável', 'CTB 235', 'c141bad5-1f88-40e8-8671-8233d033d6ef'::uuid),
  ('CTB-234', 'Portar documento de habilitação ou do veículo falsificado/adulterado', 'CTB 234', '55abab13-97ee-40f8-8570-86a5b6fd56f3'::uuid),
  ('CTB-233', 'Deixar de efetuar registro do veículo / transporte irregular de passageiros', 'CTB 233', 'd50db647-34f7-4a4e-a9ec-9d580049f966'::uuid),
  ('CTB-232', 'Conduzir sem os documentos de porte obrigatório (CNH/CRLV)', 'CTB 232', '8523b0b9-bee1-470e-b479-165363280b45'::uuid),
  ('CTB-231', 'Excesso de peso/carga mal acondicionada/fumaça excessiva (I a IX)', 'CTB 231', '98f9fa41-3292-40de-a039-c985ef975c85'::uuid),
  ('CTB-230', 'Conduzir sem equipamento obrigatório, CRLV ou seguro em dia (I a XVI)', 'CTB 230', '4c9afe34-9f15-4306-81be-3721bd55c833'::uuid),
  ('CTB-229', 'Usar placa de identificação em desacordo (falsificada, ilegível)', 'CTB 229', '2e46b3bb-eb9b-40e4-be1c-765baba07639'::uuid),
  ('CTB-228', 'Usar veículo com sistema de freios ineficiente/defeituoso', 'CTB 228', '46f0f061-043b-4c00-a2a4-69aa00e86b7a'::uuid),
  ('CTB-227', 'Usar veículo em mau estado de conservação, com risco à segurança', 'CTB 227', '31558bd8-93b1-44bf-bb52-adf1c8e3ac21'::uuid),
  ('CTB-226', 'Deixar de sinalizar parada/estacionamento irregular', 'CTB 226', '7eeac20b-9b87-494e-a036-bc376223efd7'::uuid),
  ('CTB-225', 'Mudar de faixa sem sinalizar previamente', 'CTB 225', '97358761-7702-46a0-bfb3-f9465f3a33bf'::uuid),
  ('CTB-224', 'Conversão à esquerda/retorno proibidos pela sinalização', 'CTB 224', '5076a8fe-6bb1-4d84-9f80-86e61e0508a0'::uuid),
  ('CTB-223', 'Deixar de acionar pisca-alerta quando exigido', 'CTB 223', '6c86e650-854d-4b6d-b20d-085b95b77897'::uuid),
  ('CTB-222', 'Não respeitar preferência em rotatória', 'CTB 222', '061a8b31-189d-4617-8c45-e8e0e2486f22'::uuid),
  ('CTB-221', 'Usar o acostamento como faixa de rolamento', 'CTB 221', 'fd291c9e-6b2b-4056-89f6-5376cd284d2e'::uuid),
  ('CTB-220', 'Deixar de sinalizar com antecedência conversão/curva', 'CTB 220', 'b224f788-8278-4733-9960-7d65a6519298'::uuid),
  ('CTB-219', 'Estacionar/parar em rodovia sobre a pista de rolamento', 'CTB 219', '94e5d999-e6c0-4c86-ab3f-9bf7c224220a'::uuid),
  ('CTB-218', 'Excesso de velocidade (I até 20%, II 20-50%, III acima de 50%)', 'CTB 218', 'ed05d0e7-d570-497d-b23b-21b1474873e9'::uuid),
  ('CTB-217', 'Parar na pista para conversar/embarque quando havia local adequado', 'CTB 217', '2c534c86-6e8c-4f86-ba4d-4ed03b764f80'::uuid),
  ('CTB-216', 'Entrar/sair de fila sem sinalizar/sem dar preferência', 'CTB 216', '564926e9-4530-4718-9683-d49538302582'::uuid),
  ('CTB-215', 'Ultrapassar pela contramão veículos em filas em movimento', 'CTB 215', 'fe009f42-db08-4ecd-a54e-74471369c84e'::uuid),
  ('CTB-214', 'Deixar de parar/dar preferência ao pedestre na faixa', 'CTB 214', '471842fc-dd27-4aee-a6d4-4cb7ad1ae7db'::uuid),
  ('CTB-213', 'Deixar de dar preferência a pedestre/ciclista que iniciou travessia', 'CTB 213', 'e5d76efb-94ad-4479-a81e-4af850996fdc'::uuid),
  ('CTB-212', 'Deixar de parar antes de cruzamento com linha férrea', 'CTB 212', '8f188434-dd6d-4285-88e9-66dd1b15a756'::uuid),
  ('CTB-211', 'Ultrapassar em faixa contínua/sem visibilidade suficiente', 'CTB 211', '46002929-dbb2-4a77-9721-c6269aec0187'::uuid),
  ('CTB-210', 'Ultrapassar pela contramão veículos parados em fila; transpor bloqueio', 'CTB 210', 'c97c37d6-8e25-48f6-a042-3ba3029ee0b1'::uuid),
  ('CTB-209', 'Transpor sem autorização bloqueio viário/balança/pedágio', 'CTB 209', '429a3dea-dd65-47ff-832b-d85b17dbe59b'::uuid),
  ('CTB-208', 'Avançar sinal vermelho do semáforo ou parada obrigatória', 'CTB 208', '3d75ad6b-b2bf-4392-bdcf-e43f8bc750de'::uuid),
  ('CTB-207', 'Deixar de dar preferência de passagem / conversão proibida', 'CTB 207', '08a50722-d951-46e4-9c22-944fb8c21072'::uuid),
  ('CTB-206', 'Deixar de guardar distância de segurança / não dar preferência', 'CTB 206', '3373e6cc-b6b5-496d-a422-4fafad306efe'::uuid),
  ('CTB-205', 'Ultrapassar em pontes, viadutos ou túneis', 'CTB 205', '0f988be9-84ff-48f1-8037-5cbf27627e71'::uuid),
  ('CTB-204', 'Ultrapassar pelo acostamento', 'CTB 204', '69c65af6-7b4c-42e8-b04a-4d25736eef4f'::uuid),
  ('CTB-203', 'Ultrapassar em faixa contínua/local com risco de acidente', 'CTB 203', '3c0aff16-5c13-4ddd-9455-19a10e0f13ff'::uuid),
  ('CTB-202', 'Ultrapassar pela direita, salvo exceções', 'CTB 202', '0f87ec3f-0d1e-4602-8413-2b8f48686f46'::uuid),
  ('CTB-201', 'Deixar de dar passagem pela esquerda a quem ultrapassa', 'CTB 201', 'a6ec46cc-a800-43a1-a017-c8ad761bce4a'::uuid),
  ('CTB-200', 'Ultrapassar veículo em interseções e cruzamentos', 'CTB 200', '08908a1c-ec09-4da4-b186-f14d7a595506'::uuid),
  ('CTB-199', 'Ultrapassar pela contramão em local proibido/curva/aclive', 'CTB 199', '9a71bc6c-0d96-4887-a99e-6dc212285cbd'::uuid),
  ('CTB-198', 'Deixar de dar preferência em interseção não sinalizada', 'CTB 198', 'c521bfb1-ce9d-451f-81dc-ec87c60fe628'::uuid),
  ('CTB-197', 'Deixar de dar preferência a pedestre/ciclista', 'CTB 197', '127181ae-7086-47ac-97b2-0f6ddae4be2c'::uuid),
  ('CTB-196', 'Deixar de sinalizar com antecedência manobra', 'CTB 196', '7d65c083-cfc0-492f-9f14-05c940008d1f'::uuid),
  ('CTB-195', 'Desobedecer ordens de autoridade/agente de trânsito', 'CTB 195', '0f31884d-2f5a-4595-ad3b-f6181082dffd'::uuid),
  ('CTB-194', 'Transitar em calçadas, ilhas, canteiros, ciclovias', 'CTB 194', 'bdb9b261-1091-4344-be1b-afb657662933'::uuid),
  ('CTB-193', 'Transitar pelo acostamento', 'CTB 193', 'dd107db3-d06b-4dff-9152-bc2e794ed7e1'::uuid),
  ('CTB-192', 'Deixar de guardar distância lateral de segurança', 'CTB 192', 'be7561df-360a-49d4-abea-532fec9547fe'::uuid),
  ('CTB-191', 'Forçar passagem entre veículos em sentidos opostos', 'CTB 191', '8d989e0e-c767-4a00-97ca-2fec2fc99cb3'::uuid),
  ('CTB-190', 'Seguir veículo de emergência em deslocamento de urgência', 'CTB 190', '5cd41297-ab83-41ad-a84c-16599ac0d251'::uuid),
  ('CTB-189', 'Deixar de dar preferência/parar em sinalização de parada obrigatória', 'CTB 189', 'f576a0ce-24d4-4571-8015-f98f47af1c62'::uuid),
  ('CTB-188', 'Transitar ao lado de outro veículo ocupando mais de uma faixa', 'CTB 188', 'e2175b9e-969a-4794-a776-a526b4cca26e'::uuid),
  ('CTB-187', 'Transitar em local/horário não permitido (rodízio, restrição)', 'CTB 187', 'e22b9a2c-c8d2-459b-84a5-02659cd7f4fd'::uuid),
  ('CTB-186', 'Transitar pela contramão de direção', 'CTB 186', '23083338-60c0-4289-a3e2-b260b6783fe8'::uuid),
  ('CTB-185', 'Transitar em marcha à ré / uso indevido de buzina', 'CTB 185', 'bc6d9d2b-3d7d-48fd-ae4c-38386d3ae15f'::uuid),
  ('CTB-184', 'Transitar em faixa/via/calçada exclusiva ou proibida', 'CTB 184', '8bcca4bf-a2f3-412c-80b7-c640bb1d5e89'::uuid),
  ('CTB-183', 'Parar sobre faixa de pedestres na mudança de sinal', 'CTB 183', 'e9b78111-6241-4929-a638-a1ced334734f'::uuid),
  ('CTB-182', 'Parar em local/forma proibidos', 'CTB 182', '62add3c4-8633-42c4-91ca-a09665a0ef4c'::uuid),
  ('CTB-181', 'Estacionar em local/forma proibidos (I a XIX)', 'CTB 181', 'e19418aa-1aa0-40b9-86a7-0e3cb58c9b1a'::uuid),
  ('CTB-180', 'Deixar de dar passagem/reboque irregular; faixa exclusiva de ônibus', 'CTB 180', '3641295d-d88e-4a9f-83f8-f37efa0e09f7'::uuid),
  ('CTB-179', 'Deixar de retirar veículo/carga da via sem sinalização em caso de acidente/pane', 'CTB 179', '30ed5f4a-4b49-4d22-9045-abc1743e9d44'::uuid),
  ('CTB-178', 'Deixar de sinalizar/adotar providências de segurança no local do acidente', 'CTB 178', '5076d216-4a75-4826-8db2-1dea00fed547'::uuid),
  ('CTB-177', 'Deixar o condutor envolvido em acidente de prestar socorro', 'CTB 177', '0c775a10-7cc8-4ab2-a677-6d360423d7c5'::uuid),
  ('CTB-176', 'Deixar de prestar socorro à vítima quando possível', 'CTB 176', 'eb0e39f6-54d2-48ac-aa3e-bc3d5664d642'::uuid),
  ('CTB-175', 'Utilizar veículo para exibição/manobra perigosa (arrancada, derrapagem)', 'CTB 175', '6cd000ea-8b5a-4149-8516-c7c032c6d63a'::uuid),
  ('CTB-174', 'Participar de racha promovendo/exibindo manobra perigosa', 'CTB 174', '6c47c90e-1de3-4294-b023-56dac959e34a'::uuid),
  ('CTB-173', 'Disputar corrida (competição não autorizada)', 'CTB 173', 'cbc5ec73-86e3-401f-b3ce-27bec708efc5'::uuid),
  ('CTB-172', 'Atirar objetos ou substâncias do veículo em via pública', 'CTB 172', '3a71bebb-0787-420a-bf80-8ca84c40b80b'::uuid),
  ('CTB-171', 'Usar veículo para arremessar sobre pedestre água ou detrito', 'CTB 171', 'd3bc17f4-538c-47ab-9cf1-c70964836c6c'::uuid),
  ('CTB-170', 'Dirigir ameaçando pedestres/manobra perigosa', 'CTB 170', 'bd18999b-e7d6-4485-ad4c-272a850bf256'::uuid),
  ('CTB-169', 'Dirigir sem atenção ou sem os cuidados indispensáveis', 'CTB 169', '567c9fdf-8f53-425a-b4b5-4d98053cb435'::uuid),
  ('CTB-168', 'Transportar criança sem cadeirinha/dispositivo de retenção', 'CTB 168', 'f330a8f6-6888-4cdd-8be9-798faace5d11'::uuid),
  ('CTB-167', 'Deixar de usar cinto de segurança / veículo sem equipamento de acessibilidade', 'CTB 167', '2f6e0d04-10b5-4b0e-b7b8-8b264bf4f002'::uuid),
  ('CTB-166', 'Confiar/entregar direção a pessoa embriagada ou sob efeito de substância psicoativa', 'CTB 166', 'bc17e98e-df70-47ce-a9c3-76cc3d92426e'::uuid),
  ('CTB-165-D', 'Deixar de realizar o exame toxicológico após 30 dias do vencimento do prazo', 'CTB 165-D', '7fb45c8b-1765-45a6-9bf0-5622699d5abf'::uuid),
  ('CTB-165-C', 'Dirigir com resultado positivo no exame toxicológico do art. 148-A', 'CTB 165-C', '965a347b-c88a-445b-b3c1-92f398c99dd2'::uuid),
  ('CTB-165-B', 'Dirigir sem ter realizado o exame toxicológico do art. 148-A', 'CTB 165-B', '43325be0-dbf9-4ea2-bea6-cdf2d73f79d2'::uuid),
  ('CTB-165-A', 'Recusar-se a realizar teste de alcoolemia, perícia ou exame clínico', 'CTB 165-A', '561ec9be-3875-4375-bae9-031bd71d8205'::uuid),
  ('CTB-165', 'Dirigir sob influência de álcool ou outra substância psicoativa que determine dependência', 'CTB 165', '6742b3c3-2bd3-4555-8231-e6975ffc9d85'::uuid),
  ('CTB-164', 'Confiar/entregar veículo a menor de idade', 'CTB 164', '8677a0de-5b49-4b17-806e-e8789de204f6'::uuid),
  ('CTB-163', 'Entregar veículo a pessoa não habilitada, com CNH cassada/suspensa ou sem condições de dirigir', 'CTB 163', 'afa10d9d-6ee8-4966-a9e5-f7302be8a44e'::uuid),
  ('CTB-162-VI', 'Confiar/entregar direção de veículo a pessoa nas condições dos incisos I a VI do art. 162', 'CTB 162, VI', 'a87b56cc-b1bb-4d0e-bd1c-840461280b3e'::uuid),
  ('CTB-162-V', 'Dirigir com CNH vencida há mais de 30 dias', 'CTB 162, V', '4fa08f4f-bb70-4ad1-89c3-530d2e2e4f39'::uuid),
  ('CTB-162-IV', 'Dirigir veículo remunerado sem autorização', 'CTB 162, IV', '438e9660-976f-4949-93dc-c054a1dde764'::uuid),
  ('CTB-162-III', 'Dirigir com CNH ou PPD suspensa/cassada', 'CTB 162, III', 'c0d64921-440b-4a00-b4b1-3cfdce6c1c1f'::uuid),
  ('CTB-162-II', 'Dirigir com categoria de CNH diferente da do veículo', 'CTB 162, II', '9c31306e-1872-4517-9002-56d569759dc4'::uuid),
  ('CTB-162-I', 'Dirigir sem CNH/PPD/ACC', 'CTB 162, I', 'eb4705ae-59e1-47ed-8c54-1c0fdc3b5e7f'::uuid),
  ('CTB-161', 'Norma geral: constitui infração a inobservância de qualquer preceito do CTB', 'CTB 161', 'b3a7dec1-11f9-4aef-9caf-6dad1fd3c1d1'::uuid),
  ('74550', 'Transitar em velocidade superior a maxima permitida em ate vinte por cento.', 'CTB 218, I', 'cccccccc-cccc-4ccc-8ccc-ccccccccccc2'::uuid)
) as ficha(codigo, descricao, dispositivo, codigo_fonte);
-- END TEAT NORMATIVE CORPUS

alter table senatran.infracao
  add column pacote_normativo_id uuid not null
  default '10610610-0000-4000-8000-000000000001'::uuid;

-- Preserva a chave externa das tabelas-filhas enquanto substitui os códigos
-- aleatórios preexistentes por uma distribuição determinística das 106 fichas.
create temporary table tmp_infracao_codigo_migracao on commit drop as
with infracao_numerada as (
  select
    i.id,
    i.auto_infracao,
    i.codigo_orgao_autuador,
    i.codigo_infracao as codigo_antigo,
    row_number() over (order by i.id) as rn
  from senatran.infracao i
), ficha_numerada as (
  select
    f.codigo,
    f.descricao,
    row_number() over (order by f.codigo) as rn
  from senatran.ref_codigo_infracao f
  where f.pacote_normativo_id = '10610610-0000-4000-8000-000000000001'::uuid
)
select
  i.id,
  i.auto_infracao,
  i.codigo_orgao_autuador,
  i.codigo_antigo,
  f.codigo as codigo_novo,
  f.descricao as descricao_nova
from infracao_numerada i
join ficha_numerada f
  on f.rn = ((i.rn - 1) % 106) + 1;

update senatran.infracao_ocorrencia o
set codigo_infracao = m.codigo_novo
from tmp_infracao_codigo_migracao m
where o.auto_infracao = m.auto_infracao
  and o.codigo_orgao_autuador = m.codigo_orgao_autuador
  and o.codigo_infracao = m.codigo_antigo;

update senatran.infracao_pagamento p
set codigo_infracao = m.codigo_novo
from tmp_infracao_codigo_migracao m
where p.auto_infracao = m.auto_infracao
  and p.codigo_orgao_autuador = m.codigo_orgao_autuador
  and p.codigo_infracao = m.codigo_antigo;

update senatran.infracao i
set
  codigo_infracao = m.codigo_novo,
  payload = case
    when m.codigo_novo ~ '^[0-9]{5}$' then
      jsonb_set(
        jsonb_set(
          jsonb_set(i.payload, '{codigoInfracao}', to_jsonb(m.codigo_novo), true),
          '{descricaoInfracao}', to_jsonb(m.descricao_nova), true
        ),
        '{codigoDesdobramentoInfracao}', to_jsonb(right(m.codigo_novo, 1)), true
      )
    else
      jsonb_set(
        jsonb_set(i.payload - 'codigoDesdobramentoInfracao', '{codigoInfracao}', to_jsonb(m.codigo_novo), true),
        '{descricaoInfracao}', to_jsonb(m.descricao_nova), true
      )
  end
from tmp_infracao_codigo_migracao m
where i.id = m.id;

alter table senatran.infracao
  alter column codigo_infracao set not null;

alter table senatran.infracao
  add constraint fk_infracao_codigo_normativo
  foreign key (pacote_normativo_id, codigo_infracao)
  references senatran.ref_codigo_infracao (pacote_normativo_id, codigo)
  on update no action
  on delete restrict
  not valid;

alter table senatran.infracao
  validate constraint fk_infracao_codigo_normativo;

create index idx_infracao_pacote_codigo
  on senatran.infracao (pacote_normativo_id, codigo_infracao);

commit;
