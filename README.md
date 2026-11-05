# Base de Patrocinadores Rouanet (PJ) — Tatu Cult

Fonte da verdade, versionada, da base de incentivadores **pessoa jurídica** da Lei Rouanet, extraída do SalicNet/Comparar (MinC), 2022–2026. Dados **públicos**.

Este repositório é o **source of truth**: a planilha Google e o app de consulta são *leitores* desta base, não o contrário. A base só muda por Pull Request aprovado com o check de validação verde.

## Estrutura
```
data/        CSVs (a base) — r1, r2, r3 (ver schema/data_dictionary.md)
schema/      dicionário de dados, schema.sql (Supabase/Postgres + RLS), validate.py
docs/        PRD, ARQUITETURA (ADR), SEGURANCA
.github/     workflow de validação (CI)
```

## A base em 1 parágrafo
R$ 12,23 bi de captação PJ em 2022–2026, 59.045 aportes. São Paulo (38,9%) e Rio de Janeiro (29,3%) concentram 68% da **origem** do patrocínio; SP (38,6%), RJ (20,4%) e MG (11,2%) concentram o **destino**. Detalhe e validação no dicionário de dados.

## Como atualizar (trimestral)
1. Reextrair do SalicNet (ver `docs/ARQUITETURA.md` → Pipeline), gerar os 3 CSVs no mesmo formato.
2. Abrir PR com os CSVs novos. O CI roda `schema/validate.py`.
3. Ajustar os totais esperados em `validate.py` para o novo período (parte do PR).
4. Merge só com check verde + revisão do dono.

## Segurança (resumo — ver docs/SEGURANCA.md)
- Repositório **privado**, dentro da org Tatu Cult no GitHub, com **2FA obrigatório** para toda a org e **branch protection** em `main`.
- Dados são públicos → baixo risco de dados. A proteção real é de **integridade** (ninguém altera a base sem PR+validação) e de **acesso ao produto** (só e-mails do domínio).
- Nenhum segredo neste repo. Chaves do app ficam em variáveis de ambiente / cofre, nunca em `data/` nem em commit.

**Dono:** _[nomear responsável]_ · **Cadência de revisão:** trimestral.
