# Acordo de trabalho dos agentes

## Objetivo

Implementar e revisar o Senatran Data Seeder: uma ferramenta de desenvolvimento para gerar e inserir dados sintéticos, determinísticos e semanticamente coerentes no mock da SENATRAN. Uso em produção é proibido. Trabalhe em uma task por vez e não amplie o escopo aprovado.

## Fontes de verdade e leitura

Leia, nesta ordem:

1. `docs/mock-data/README.md` — escopo e mapa da documentação;
2. `docs/mock-data/decisions.md` — decisões de domínio aprovadas;
3. `docs/mock-data/generation-spec.md` — requisitos funcionais;
4. `docs/mock-data/tasks.md` — dependências, estado e critérios de aceite;
5. `docs/mock-data/open-questions.md` — impedimentos e decisões pendentes.

Consulte `docs/mock-data/investigation.md` somente para fatos e contexto. `docs/mock-data/proposed-decisions.md` e `docs/raw-investigation/` são históricos e não normativos. Não replique regras de domínio neste arquivo. Diante de conflito entre fontes normativas, interrompa apenas a task afetada e peça decisão ao Owner.

## Papéis

### Implementer

- Escolhe uma task `TODO` cujas dependências estejam `APPROVED`, muda-a para `IN_PROGRESS`, implementa somente seu escopo e executa os testes relevantes.
- Registra em `Implementação` um resumo, arquivos alterados e testes; então muda o status para `IMPLEMENTED`.
- Para findings, registra o atendimento em `Correções` e retorna a task de `CHANGES_REQUESTED` para `IMPLEMENTED`.
- Não inventa regra de domínio, não altera decisão aprovada silenciosamente e nunca marca `REVIEWED` ou `APPROVED`.

### Reviewer

- Revisa somente tasks `IMPLEMENTED`, comparando código, diff e testes com as decisões, a spec e cada critério de aceite.
- Registra em `Revisão` o resultado e findings claros, verificáveis e com evidência suficiente.
- Muda a task para `CHANGES_REQUESTED` quando houver findings ou para `REVIEWED` quando estiver conforme.
- Não corrige silenciosamente o código revisado e nunca marca `APPROVED`.

### Owner

Resolve decisões de domínio, ambiguidades e mudanças de especificação. Faz o aceite final, incluindo a transição de `REVIEWED` para `APPROVED`.

## Regras de execução e revisão

- Respeite dependências e critérios de aceite de `tasks.md`; não resolva incidentalmente outra task.
- Preserve determinismo, compatibilidade contratual, transações, proteção contra produção e ausência de segredos em logs conforme a spec.
- Mudanças de DDL, contratos ou fixtures só são permitidas quando uma task e uma decisão aprovada as autorizarem explicitamente.
- Não marque critérios como atendidos sem evidência. Resumos ficam em `docs/mock-data/tasks.md`; evidência extensa pode ficar em relatório separado vinculado pela task.
- O fluxo é `TODO → IN_PROGRESS → IMPLEMENTED → REVIEWED → APPROVED`, com o ciclo `IMPLEMENTED → CHANGES_REQUESTED → IMPLEMENTED` quando necessário.

## Ambiguidades e bloqueios

Não presuma informação ausente ou contraditória. Registre a questão em `docs/mock-data/open-questions.md` e uma nota curta na seção da task, sem mudar regra normativa. Interrompa somente a task afetada; outras tasks independentes podem avançar. Apenas o Owner fecha questão de domínio ou altera `docs/mock-data/decisions.md` ou `docs/mock-data/generation-spec.md`.
