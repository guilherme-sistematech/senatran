# Senatran Data Seeder

Documentação de apoio para gerar dados sintéticos, determinísticos e coerentes
para o mock local da SENATRAN. A ferramenta é exclusiva para desenvolvimento e
testes; uso com dados ou ambientes de produção é proibido.

## Escopo

- Condutores e Veículos, incluindo os catálogos de que dependem.
- Auxiliares usadas diretamente pelos endpoints desses dois domínios.
- Validação dos dados gerados antes da gravação.
- Fora do escopo: popular todos os demais domínios do mock ou alterar o contrato
  da API para acomodar o seeder.

## Estado atual

A investigação foi consolidada e existe uma implementação parcial em
`tools/data-seeder/`, acompanhada por alterações de DDL, fixtures e testes. Esse
trabalho deve ser avaliado e aproveitado; os passos abaixo não presumem que ele
esteja concluído.

## Próximos passos

1. Alinhar o DDL com os documentos.
2. Definir formatos específicos.
3. Definir ranges.
4. Criar os JSON Schemas de Condutores e Veículos.
5. Concluir o gerador CSV e validar a geração.

## Onde encontrar as informações

- [`investigation.md`](investigation.md): fatos encontrados no repositório.
- [`decisions.md`](decisions.md): decisões técnicas que afetam os dados gerados.
- [`generation-spec.md`](generation-spec.md): sequência de trabalho para a próxima etapa.
- [`tasks.md`](tasks.md): checklist resumido.
- [`../raw-investigation/`](../raw-investigation/): fontes brutas preservadas como histórico.
