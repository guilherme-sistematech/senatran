# Senatran Data Seeder

Este projeto especifica uma ferramenta para gerar e inserir dados sintéticos, determinísticos e semanticamente coerentes no mock da SENATRAN.

## Escopo atual

- **Fase 1a — core:** catálogos necessários, 10.000 Condutores e 10.000 Veículos.
- **Fase 1b — cobertura dos controllers:** sete tabelas auxiliares diretamente usadas pelos endpoints de Veículos e Condutores.
- Fora do escopo: população geral dos demais domínios SENATRAN e execução em produção.

## Estágio

A investigação e as decisões foram consolidadas. A especificação está pronta para implementação, que deve começar pelos pré-requisitos estruturais descritos em `generation-spec.md` e `tasks.md`. Este repositório ainda não contém o código-fonte no qual as tasks serão executadas; consulte `open-questions.md`.

## Documentos oficiais

- [`investigation.md`](investigation.md): fatos encontrados no levantamento e no repositório analisado.
- [`decisions.md`](decisions.md): decisões aprovadas pelo owner.
- [`generation-spec.md`](generation-spec.md): fonte de verdade funcional para a implementação.
- [`tasks.md`](tasks.md): plano executável, dependências e critérios de aceite.
- [`open-questions.md`](open-questions.md): questões que ainda exigem decisão.

As fontes brutas permanecem em [`../raw-investigation/`](../raw-investigation/) como material histórico. `proposed-decisions.md` também é histórico e foi substituído, para fins normativos, por `decisions.md`.

## Ordem de leitura

1. `decisions.md`;
2. `generation-spec.md`;
3. `tasks.md`;
4. `investigation.md`, para evidências e contexto;
5. `open-questions.md`.
