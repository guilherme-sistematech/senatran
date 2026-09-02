# Base para a próxima etapa

Esta não é uma especificação definitiva. Ela organiza a sequência de trabalho sem
preencher formatos, ranges ou schemas que ainda precisam ser definidos. Antes de
implementar, compare cada etapa com o código parcial existente em
`tools/data-seeder/`.

## A — DDL

- Comparar o DDL atual com o data model e com as decisões registradas.
- Confirmar chassi como PK, placa e RENAVAM únicos e `id` como cursor técnico.
- Registrar apenas divergências que afetem a geração ou a leitura dos dados.
- Não ampliar a revisão para uma remodelagem geral do banco.

## B — Formatos

- Consolidar os formatos exigidos pelo OpenAPI, DDL, testes e geradores existentes.
- Resolver inconsistências com evidência das fontes; não inventar regra de domínio.
- Definir a correspondência entre colunas de busca e propriedades do payload.

## C — Ranges

- Definir limites e conjuntos de valores apenas onde houver fonte ou necessidade
  técnica verificável.
- Preservar determinismo, unicidade necessária e ausência de colisão com chaves de
  cenário.
- Preferir casos mínimos representativos quando não houver distribuição conhecida.

## D — JSON Schema

- Criar um schema para Condutores e outro para Veículos depois de fechar formatos
  e ranges.
- Derivar a estrutura do contrato OpenAPI e explicitar as âncoras relacionais.
- Validar os objetos antes de qualquer persistência.

## E — Gerador CSV

- Reaproveitar os componentes existentes que forem compatíveis com A–D.
- Gerar dados sintéticos e determinísticos na ordem: referências, Condutores,
  Veículos e auxiliares diretas.
- Validar o CSV e os payloads antes de gravar no banco.
- Recusar produção e evitar dados reais, segredos e valores dependentes do relógio.

## Validação final

- Executar a geração duas vezes com a mesma configuração e comparar os resultados.
- Validar formatos, ranges, schemas, unicidade, referências e chaves de cenário.
- Exercitar o volume acordado em banco descartável.
- Executar `pnpm check` e os testes de integração/e2e relacionados.
