# Questões abertas

Registre aqui apenas ambiguidades e impedimentos que não possam ser resolvidos pelas fontes normativas. O Owner decide questões de domínio e mudanças de especificação; resolver uma questão deve atualizar a fonte de verdade correspondente.

## OQ-001 — Disponibilização do repositório de implementação

**Status:** RESOLVED

**Afeta:** todas as tasks de implementação (`TASK-001` a `TASK-014`).

**Contexto:** este diretório contém a documentação consolidada, mas não contém o código-fonte do snapshot SENATRAN investigado, metadados Git, `package.json`, DDL, contrato OpenAPI ou testes citados pela especificação.

**Decisão necessária:** definir se o código-fonte será incorporado a este repositório ou se estes documentos e o `AGENTS.md` serão aplicados ao repositório SENATRAN correspondente ao snapshot investigado.

**Condição para desbloqueio:** o Implementer deve ter acesso ao código-fonte compatível e conseguir localizar os caminhos e comandos citados na investigação antes de iniciar uma task.

**Resolução:** o Owner confirmou em 2026-09-02 que o repositório disponível é o alvo da implementação e aprovou a continuidade de todas as tasks.

## OQ-002 — Aprovação das dependências das próximas tasks

**Status:** RESOLVED

**Afeta:** `TASK-003` e `TASK-005` e, transitivamente, `TASK-006` a `TASK-014`.

**Contexto:** o código-fonte está disponível e as tasks sem dependências já executadas estão em `REVIEWED`. Entretanto, o acordo de trabalho permite ao Implementer iniciar uma task `TODO` somente quando suas dependências estão `APPROVED`. `TASK-003` depende de `TASK-002`; `TASK-005` depende de `TASK-001` e `TASK-004`; as três dependências permanecem em `REVIEWED`. O Implementer não tem autoridade para promovê-las.

**Decisão necessária:** o Owner deve concluir o aceite das tasks revisadas ou alterar explicitamente o fluxo normativo.

**Condição para desbloqueio:** `TASK-001`, `TASK-002` e `TASK-004` em `APPROVED`, além do encerramento pelo Owner de `OQ-001`, cuja condição factual agora pode ser verificada no repositório.

**Resolução:** o Owner aprovou explicitamente as dependências em 2026-09-02; os respectivos estados foram registrados em `tasks.md`.
