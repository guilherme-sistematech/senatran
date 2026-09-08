import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { PgDatabase } from '../../domain/shared/api/src/database/database.js';
import { loadConfig } from '../../domain/shared/api/src/config/configuration.js';

let db: PgDatabase;

beforeAll(() => {
  db = new PgDatabase(loadConfig().database);
});

afterAll(() => db.close());

describe('senatran normative infraction corpus', () => {
  it('installs the complete 106-record TEAT staging package', async () => {
    const result = await db.query<{
      quantidade_declarada: number;
      quantidade_instalada: string;
    }>(
      `select p.quantidade_fichas as quantidade_declarada,
              count(c.codigo)::text as quantidade_instalada
         from senatran.ref_pacote_normativo p
         join senatran.ref_codigo_infracao c
           on c.pacote_normativo_id = p.id
        where p.codigo = 'teat-staging-corpus-2026-09-08'
        group by p.id`,
    );

    expect(result.rows).toEqual([
      { quantidade_declarada: 106, quantidade_instalada: '106' },
    ]);
  });

  it('keeps every infraction inside its versioned package and payload', async () => {
    const result = await db.query<{
      orfaos: string;
      payloads_divergentes: string;
    }>(
      `select count(*) filter (where c.codigo is null)::text as orfaos,
              count(*) filter (
                where i.payload->>'codigoInfracao' is distinct from i.codigo_infracao
                   or i.payload->>'descricaoInfracao' is distinct from c.descricao
              )::text as payloads_divergentes
         from senatran.infracao i
         left join senatran.ref_codigo_infracao c
           on c.pacote_normativo_id = i.pacote_normativo_id
          and c.codigo = i.codigo_infracao`,
    );

    expect(result.rows).toEqual([{ orfaos: '0', payloads_divergentes: '0' }]);
  });

  it('rejects a code that does not belong to the selected package', async () => {
    await db.query('begin');
    try {
      await expect(
        db.query(
          `update senatran.infracao
              set codigo_infracao = 'CODIGO-INEXISTENTE'
            where id = (select min(id) from senatran.infracao)`,
        ),
      ).rejects.toMatchObject({ code: '23503' });
    } finally {
      await db.query('rollback');
    }
  });
});
