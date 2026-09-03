# Decisões técnicas

Somente decisões que afetam diretamente o resultado do Data Seeder.

## Estrutura de Veículo

- O data model é a referência desejada para a divergência identificada em
  Veículo: `chassi` é a chave primária; `placa` e `codigo_renavam` são únicos e
  obrigatórios.
- `id bigserial` permanece único e gerado pelo banco, exclusivamente como cursor
  técnico de `idUltimoRegistro`. O seeder não fornece esse valor nos inserts.
- As demais escolhas físicas atuais permanecem: colunas de busca mais
  `payload jsonb`, códigos textuais e ausência das FKs não existentes no DDL.
  Em conflito sobre o formato da resposta, prevalece o OpenAPI.

## Conteúdo gerado

- O payload deve conter as propriedades aplicáveis dos componentes OpenAPI de
  Condutor e Veículo e manter suas âncoras iguais às colunas relacionais.
- CPF, registro CNH e RENACH são únicos na massa padrão. Identificadores opcionais
  também não se repetem quando presentes, sem transformar isso em nova constraint
  de domínio.
- CPF, CNPJ, placa, chassi e RENAVAM usam os geradores regulados existentes.
- Dados humanos podem usar `@faker-js/faker` com locale `pt_BR`, versão fixada e
  streams independentes por entidade; identificadores regulados não usam Faker.
- Dados auxiliares são derivados de um único Condutor ou Veículo, preservando
  chaves e valores equivalentes.
- As distribuições já decididas são 70/30 para placas Mercosul/legadas e
  80/10/5/5 para situações de CNH. Para os demais campos sem fonte, use casos
  mínimos determinísticos em vez de percentuais inventados.
- A geração usa `2025-01-01T00:00:00Z` como data-base fixa; não depende do relógio
  do sistema.

## Escopo e segurança

- O trabalho se divide entre entidades principais e as sete auxiliares diretamente
  usadas pelos endpoints de Condutores e Veículos.
- O volume de referência para validação é 10.000 Condutores e 10.000 Veículos; os
  pequenos seeds SQL versionados continuam independentes.
- Catálogos existentes são preenchidos de forma idempotente: inserir ausente,
  preservar idêntico e falhar diante de descrição divergente.
- O seeder não deve mascarar filtros incorretos da aplicação com dados artificiais.
- Execução contra ambiente de produção é proibida e deve falhar antes de qualquer
  escrita.
