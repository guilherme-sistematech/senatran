# Checklist

## Condutor e Veículo — concluído

- [x] Alinhar DDL com documentos.
- [x] Definir formatos específicos.
- [x] Definir ranges.
- [x] Criar JSON Schema de Condutores.
- [x] Criar JSON Schema de Veículos.
- [x] Implementar gerador CSV.
- [x] Validar geração.

## Fase A — Agente

- [x] Adicionar a estrutura mínima proposta de `renainf.agente` ao DDL.
- [x] Criar `tools/data-seeder/schemas/agente.schema.json`.
- [x] Implementar candidate e gerador determinístico.
- [x] Implementar validação de CPF, matrícula, órgão e chave composta.
- [x] Adicionar agente ao dispatcher CSV.
- [x] Adicionar teste determinístico.
- [x] Gerar `tmp/agentes.csv`.
- [x] Executar COPY.
- [x] Validar quantidade, estados, amostra, unicidade e órgãos com SELECT.

## Fase B — Dispositivo

- [x] Criar `tools/data-seeder/schemas/dispositivo.schema.json`.
- [x] Implementar candidate e gerador determinístico.
- [x] Implementar validação de ID, órgão, booleanos e payload.
- [x] Adicionar dispositivo ao dispatcher CSV.
- [x] Evitar colisão com os seeds `DEV-0001` a `DEV-0015`.
- [x] Adicionar teste determinístico.
- [x] Gerar `tmp/dispositivos.csv`.
- [x] Executar COPY.
- [x] Validar quantidade, estados, IDs CSV e coerência do payload com SELECT.

## Fase C — Plantão — bloqueada

- [ ] Obter do responsável a definição mínima de plantão: o que representa para
      a aplicação consumidora e quais campos ela espera receber ou consultar.

Os itens seguintes não são executáveis enquanto a decisão acima estiver
pendente:

- [ ] Definir DDL mínimo.
- [ ] Definir schema.
- [ ] Implementar gerador.
- [ ] Implementar validação.
- [ ] Gerar CSV.
- [ ] Executar COPY.
- [ ] Validar registros.

## Fase D — Validação final

- [x] Regenerar os CSVs implementados com a mesma seed.
- [x] Confirmar arquivos idênticos.
- [x] Confirmar COPY sem erro.
- [x] Confirmar quantidade esperada.
- [x] Confirmar constraints e referências necessárias.
