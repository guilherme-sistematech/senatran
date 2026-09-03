# Senatran Data Seeder

Gerador determinístico de CSVs sintéticos para as tabelas
`senatran.condutor` e `senatran.veiculo`. É uma ferramenta exclusiva de
desenvolvimento e testes e recusa execução com `NODE_ENV=production`.

## Execução

```bash
pnpm data:generate --schema tools/data-seeder/schemas/condutor.schema.json --rows 100 --output tmp/condutores.csv --seed 20250101
pnpm data:generate --schema tools/data-seeder/schemas/veiculo.schema.json --rows 100 --output tmp/veiculos.csv --seed 20250101
```

`--schema`, `--rows` e `--output` são obrigatórios. `--seed` é opcional e usa
`20250101` por padrão. O diretório de saída é criado automaticamente.

## Schemas

- `tools/data-seeder/schemas/condutor.schema.json`
- `tools/data-seeder/schemas/veiculo.schema.json`

Os schemas definem ordem das colunas, obrigatoriedade, formatos, unicidade,
defaults e ranges usados na geração e validação. A coluna `id` não entra no CSV:
o PostgreSQL a gera por `bigserial`. O `payload` é serializado como JSON válido
em uma célula CSV escapada.
