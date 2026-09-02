# Especificação de geração

## DDL e colunas CSV

`senatran.veiculo` usa `chassi` como chave primária, `placa` e
`codigo_renavam` como valores obrigatórios e únicos, e mantém `id bigserial`
único como cursor técnico. `senatran.condutor` mantém `id bigserial` como chave
primária. `id` é gerado pelo banco e não aparece nos CSVs.

As propriedades camelCase do payload que correspondem às colunas relacionais
devem ter o mesmo valor. O schema de cada tabela declara essa correspondência em
`x-source` e a ordem do cabeçalho em `x-columnOrder`.

## Formatos específicos

| Campo                | Tipo/formato                                           | Único na massa      | Geração                                       |
| -------------------- | ------------------------------------------------------ | ------------------- | --------------------------------------------- |
| CPF                  | texto, 11 dígitos, verificadores mod-11                | sim                 | base aleatória determinística + verificadores |
| CNPJ de proprietário | texto, 14 dígitos, matriz `0001`, verificadores mod-11 | não                 | base determinística + `0001` + verificadores  |
| registro CNH         | texto, 11 dígitos                                      | sim                 | dígitos determinísticos                       |
| RENACH               | texto, `RN` + 10 dígitos                               | sim                 | prefixo + dígitos determinísticos             |
| impedimento/PGU/PID  | texto, `IMP`/`PGU`/`PID` + 7 dígitos                   | sim quando presente | prefixo + índice preenchido com zeros         |
| placa                | texto, `LLLNLNN` ou `LLLNNNN`, sem I/O/Q               | sim                 | gerador regulado; 70% Mercosul e 30% legada   |
| chassi               | texto, 17 caracteres VIN, sem I/O/Q                    | sim                 | gerador regulado                              |
| RENAVAM              | texto, 11 dígitos, verificador mod-11                  | sim                 | base determinística + verificador             |
| motor/câmbio         | texto, `MOT`/`CAM` + 7 dígitos                         | sim quando presente | prefixo + índice preenchido com zeros         |

Nomes e endereços usam `@faker-js/faker` 10.1.0 com locale `pt_BR` e seed
derivada por entidade. Identificadores regulados não usam Faker.

## Ranges e conjuntos

- nascimento: 1945-01-01 a 2006-12-28 (18 a 80 anos na data-base);
- primeira habilitação: entre 18 e 35 anos após o nascimento;
- emissão de CNH: de 2015 a 2024 e nunca antes da primeira habilitação;
- validade: 2024 para vencida ou 2026 a 2033 para as demais;
- situação CNH: `A`, `V`, `B`, `S`, `C`, com massa de referência 80/10/5/5;
- sexo: `1` ou `2`; booleanos de indicadores: `true` ou `false`;
- fabricação: 1990 a 2024; ano-modelo igual ao de fabricação ou um ano maior;
- potência: 25 a 300; cilindradas: 250 a 6000; eixos: 2 a 3;
- lotação: 3 a 42; PBT: 2000 a 16000; CMT: 3500 a 25000;
  CMC: 4000 a 30000;
- códigos de município, marca/modelo, cor, espécie, tipo, carroceria,
  categoria, combustível, proprietário e situação CNH vêm dos catálogos
  curados do projeto.

Os schemas JSON em `tools/data-seeder/schemas/` são a definição estruturada
consumida pelo gerador CSV. Extensões `x-*` registram origem, ordem, unicidade e
limites de data que não são palavras-chave nativas do JSON Schema.
