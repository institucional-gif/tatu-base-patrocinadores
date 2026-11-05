# Dicionário de Dados — Base de Patrocinadores Rouanet (PJ)

Fonte: SalicNet / Comparar — Ministério da Cultura (Incentivo Fiscal Federal / Lei Rouanet).
URL: https://aplicacoes.cultura.gov.br/comparar/salicnet/
Período: 2022–2026 (2026 é ano corrente, incompleto). Data da extração: 04/11/2026.
Natureza dos dados: **públicos**, de portal de transparência. Pessoas **jurídicas** (empresas incentivadoras). Não há dado pessoal sensível de titulares; a única PII do sistema é o e-mail da equipe que acessa a ferramenta.

Convenções:
- Valores monetários em Reais (R$), ponto como separador decimal nos CSVs (ex.: `698111.10`).
- `uf` = sigla de 2 letras (UF). `NI` = não informado; `35` = código residual preservado como na fonte (apenas no arquivo 1).
- "UF Incentivador" = estado de **origem** do recurso (empresa patrocinadora). "UF Projeto" = estado de **destino** (onde o projeto é executado).

---

## Arquivo 1 — `data/r1_cem_maiores_uf.csv`
Relatório "Cem maiores incentivadores por ano e UF" (todos os tipos de pessoa — PF + PJ). Valor **incentivado** por UF e ano.

| coluna | tipo | descrição |
|---|---|---|
| uf | texto(2) | UF do incentivador (inclui `NI` e `35`) |
| 2022..2026 | numérico | Vl. Incentivado no ano (R$) |
| total_2022_2026 | numérico | soma dos 5 anos (R$) |

## Arquivo 2 — `data/r2_pj_regiao_uf.csv`
Relatório "Incentivador por ano, região, UF e tipo de pessoa" — **apenas Pessoa Jurídica**. Valor incentivado e nº de projetos por UF/região e ano (formato longo).

| coluna | tipo | descrição |
|---|---|---|
| ano | inteiro | 2022–2026 |
| regiao_uf | texto | nome da região (subtotal) OU nome do estado OU `TOTAL_GERAL` |
| qtd_projetos | inteiro | nº de projetos distintos incentivados por PJ daquela UF/região no ano |
| vl_incentivado | numérico | Vl. Incentivado (R$) |

Observação: linhas de região (Norte, Nordeste, Centro Oeste, Sudeste, Sul) são **subtotais**; `TOTAL_GERAL` é o total Brasil. Para somar só UFs, filtrar fora região e total.

## Arquivo 3 — `data/r3_matriz_cruzada.csv`  ← **tabela-base para consultas**
Relatório "Incentivador por ano de aporte, região e UF do projeto" — **apenas Pessoa Jurídica**. Matriz cruzada completa: para cada ano, quanto cada UF de origem (incentivador) aportou em projetos de cada UF de destino (projeto).

| coluna | tipo | descrição |
|---|---|---|
| ano | inteiro | 2022–2026 |
| inc_uf | texto(2) | UF do incentivador (origem do recurso) |
| proj_uf | texto(2) | UF do projeto (destino) |
| valor | numérico | Vl. Captado agregado nesse par UF×UF×ano (R$) |
| qtd | inteiro | nº de aportes (transações incentivador→projeto) |

Granularidade: 1 linha por (ano, inc_uf, proj_uf). 1.514 linhas.

---

## Integridade (validada na extração)
- Soma de `valor` em r3 = **R$ 12.226.772.422** ; soma de `qtd` = **59.045** aportes.
- Por ano (valor PJ / nº aportes): 2022 = 2.073.786.721 / 9.876 · 2023 = 2.265.597.383 / 11.062 · 2024 = 2.925.597.595 / 14.349 · 2025 = 3.311.392.900 / 15.629 · 2026 = 1.650.397.822 / 8.129.
- **Reconciliação cruzada:** a soma de r3 por (ano, inc_uf) bate 100% com `vl_incentivado` de r2 (0 divergências em 135 pares UF×ano). Os totais anuais coincidem com os números exibidos no portal.
