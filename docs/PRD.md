# PRD — Consulta de Patrocinadores Rouanet (produto interno Tatu Cult)

> Documento de arquitetura e requisitos. Autoridade: Tech Lead IA (COMO se constrói e opera).
> Natureza do dado: **público** (SalicNet/MinC), pessoas jurídicas. Única PII: e-mail da equipe que acessa.
> Status: proposta para decisão. **Antes de construir, decidir entre o Cenário A (recomendado) e o Cenário B.**

---

## 1. PROBLEMA TÉCNICO
Hoje a base de patrocinadores PJ existe como planilha Google e como CSVs. A equipe precisa **consultar rápido** ("quem patrocina em SP?", "quanto RJ mandou para projetos de MG?", "maiores origens em 2025") sem abrir a planilha inteira, e esse acesso precisa ficar **restrito à equipe Tatu Cult (e-mails do domínio) com autenticação forte (2FA)**. O que não é verdade hoje: (a) uma fonte única versionada e protegida contra edição acidental; (b) uma porta de entrada com identidade e 2FA controlados.

## 2. USUÁRIOS E USO
- Equipe Tatu Cult (captação, projetos, comercial). Perfil majoritariamente **não técnico**.
- Uso: consulta de leitura — rankings de origem/destino, fluxos entre estados, série 2022–2026, busca por UF. **Nunca** edição da base pela interface.
- Volume: pequeno (dezenas de consultas/semana, <15 usuários). Base estática entre atualizações trimestrais.

## 3. RESPOSTA DIRETA À PERGUNTA (2FA + domínio Tatu Cult)
**Sim, é possível — e de duas formas, da mais simples para a mais robusta.** A restrição "só e-mail do domínio + 2FA" **não exige construir autenticação do zero**: ela é herdada da identidade que a equipe já usa.
- **Caminho recomendado:** login via **SSO do Google Workspace (OIDC)**. Só e-mails `@tatucultural.com.br` entram, e o **2FA é o que o Workspace já exige** — não se cria uma segunda senha nem um segundo app de 2FA. Menos a manter, menos a vazar.
- **Caminho alternativo:** autenticação própria (Supabase Auth) com e-mail + **TOTP (2FA)** e um *hook* de cadastro que **rejeita qualquer e-mail fora do domínio**. Funciona, mas cria uma credencial a mais para a equipe gerenciar.

## 4. DEGRAU RECOMENDADO (arquitetura mínima suficiente)
Isto **não é um problema de IA/agente** — é de acesso a dado estruturado. Duas opções, e a regra da casa manda considerar e descartar por escrito a mais simples.

### Cenário A — RECOMENDADO para começar: planilha Google + controles do Workspace
A planilha já construída, compartilhada com um **Grupo do Google** da equipe, com acesso **restrito ao domínio** e **somente leitura** para quem consulta. O **2FA e a restrição de domínio já existem no Workspace** — custo zero, zero código, zero infra a manter, e satisfaz literalmente "login 2FA só do domínio Tatu Cult". É o degrau que **resolve o requisito de segurança hoje**.
- GitHub entra aqui só como **fonte da verdade versionada** (os CSVs), separando "a base canônica" de "a cópia que a equipe lê".

### Cenário B — Produto dedicado (se A não bastar): GitHub → Supabase → app Lovable
Construir só se surgir necessidade real que a planilha não cobre: UI de consulta guiada para não-técnicos, filtros/visual de dashboard, ou impedir por completo o acesso à planilha-fonte. Reusa o stack que a Tatu já opera.

```
[GitHub repo privado]  ──(GitHub Action: carga)──>  [Supabase Postgres + RLS]
   data/*.csv (fonte da verdade)                         ▲ leitura (service role, server-side)
                                                          │
                              [App Lovable]  ──login SSO Google (OIDC)──>  [Supabase Auth]
                               UI de consulta              só @tatucultural.com.br + 2FA do Workspace
                               (read-only)
```
Fluxo de dados: a base **só muda por PR no GitHub** (com validação automática) → um job carrega no Supabase → o app lê de *views* read-only (`v_origem_uf`, `v_destino_uf`, `v_fluxos`, ver `schema/schema.sql`). O usuário nunca escreve, nunca vê as tabelas cruas, nunca vê segredo.

## 5. ALTERNATIVA MAIS SIMPLES DESCARTADA (obrigatório)
- **"App custom com banco e autenticação própria desde já"** — descartado como ponto de partida: cria infra permanente para manter (banco, auth, deploy) numa equipe sem engenheiro dedicado, para um dado público e pequeno. Só se justifica (Cenário B) **depois** que a planilha compartilhada (Cenário A) comprovar não bastar.
- **"Autenticação própria com senha + TOTP"** — descartada em favor do SSO Google: o Workspace já impõe domínio + 2FA; uma segunda credencial é superfície de ataque e suporte a mais, sem ganho.
- **"Consultar os CSVs direto no GitHub"** — descartado para o usuário final: GitHub não é motor de consulta para quem é não-técnico; serve como fonte versionada, não como interface.

## 6. CAMADAS DE SEGURANÇA (contenção por ambiente, depois orientação)
Hierarquia aplicada: o que o usuário **não pode fazer por construção** > só leitura > aprovação > pedido no texto.

1. **Identidade (quem entra):** SSO Google Workspace → só `@tatucultural.com.br`, 2FA herdado. (Fallback: Supabase Auth + TOTP + allowlist de domínio.)
2. **Autorização (o que pode):** Supabase **RLS liga em todas as tabelas**; o papel `authenticated` só tem `SELECT`; **nenhuma** policy de escrita para o app ⇒ read-only por construção. Carga de dados só pela `service_role`, server-side.
3. **Integridade da base:** GitHub repo **privado**, **2FA obrigatório na org**, **branch protection** em `main`, PR com revisão + **CI `validate.py`** (reconciliação de totais). A base não muda sem revisão e validação verde.
4. **Segredos:** `service_role key`, credenciais do banco e client secret do OIDC moram em **variáveis de ambiente / cofre** (Supabase, Lovable, Make) — **nunca** no repo, nunca em `data/`, nunca em prompt, nunca em planilha. Rotação registrada; **offboarding revoga** (item de checklist, não lembrança).
5. **Transporte/rede:** HTTPS ponta a ponta; projeto Supabase com chaves anon/role separadas; a `anon key` sozinha não lê nada (RLS exige `authenticated`).
6. **Dado pessoal:** a base é pública (PJ) → risco baixo. A única PII é o **e-mail da equipe**; minimizar (só o necessário para login), reter só enquanto a pessoa estiver na equipe. Sem decisão automatizada sobre pessoas. (Acionar skill de LGPD só se entrar dado pessoal novo.)
7. **Observabilidade e custo-teto:** logs de acesso do Supabase (monitorar *padrão* de acesso, não conteúdo); sem agente/LLM em produção ⇒ sem fatura aberta de tokens; tiers gratuitos cobrem o volume.

## 7. COMO VAMOS AVALIAR (eval — obrigatório antes de produção)
Para um produto de dados, o "eval" é **integridade de dados**, não qualidade de modelo:
- **Baseline registrada** (já validada nesta entrega): r3 soma R$ 12.226.772.422 / 59.045 aportes; r2 reconcilia 100% com r3 (0 divergências em 135 UF×ano); totais anuais batem com o portal.
- **Regressão automática:** `schema/validate.py` roda no CI a cada PR que toca `data/`. PR não entra com check vermelho. A cada atualização trimestral, os totais esperados são atualizados **no mesmo PR**.
- **Teste de acesso (Cenário B):** antes de liberar, verificar que (a) e-mail fora do domínio é barrado; (b) usuário autenticado só lê; (c) tentativa de escrita falha; (d) `anon key` não retorna dado.

## 8. CUSTO (com premissas)
- **Cenário A:** R$ 0 incremental (usa Workspace + GitHub já existentes; repositórios privados são gratuitos no GitHub).
- **Cenário B:** GitHub privado grátis; **Supabase** free tier provavelmente suficiente (base pequena, leitura leve) — Pro ~US$ 25/mês só se precisar; **Lovable** no plano que a Tatu já tem; Workspace já contratado. Construção: baixa (reuso de stack). **Premissa:** <15 usuários, base estática entre trimestres.

## 9. DONO E MANUTENÇÃO
- **Dono nomeado (obrigatório):** _[definir]_ — responsável pela atualização trimestral (reextração + PR) e pela revisão de acesso.
- **Cadência:** base trimestral; revisão de membros/escopos trimestral; rotação de segredos semestral + no offboarding.
- Critério da casa: **a equipe entende, opera, avalia e desliga** sem depender de uma só pessoa. Documentado aqui e no README.

## 10. RISCOS
- **Técnico:** carga Supabase desatualizada vs. GitHub → mitigar com job idempotente disparado pelo merge (fonte da verdade sempre o GitHub).
- **Dependência:** Supabase/Lovable mudam preço/API → Cenário A permanece como plano de queda (a planilha sempre funciona); desmonte é barato.
- **Segurança:** vazamento de `service_role key` → manter só server-side, rotacionar, nunca no front; injeção não se aplica (sem LLM/agente no fluxo).
- **Operacional:** atualização trimestral esquecida → dono nomeado + lembrete recorrente; a base exibe sempre a data de extração.

## 11. PLANO DE DESMONTE
Desligar o app Lovable e o projeto Supabase **não quebra nada**: a fonte da verdade (GitHub) e a planilha Google seguem de pé. Volta-se ao Cenário A sem perda de dado. Escrito antes de ligar, não depois de quebrar.

## 12. PRÓXIMOS PASSOS
| # | Passo | Responsável | Prazo |
|---|---|---|---|
| 1 | Decidir Cenário A (começar) vs. B (produto) | Orquestrador + Dono | — |
| 2 | Criar repo privado na org GitHub, 2FA obrigatório + branch protection; subir este pacote | Tech Lead/Dono | — |
| 3 | Cenário A: Grupo Google da equipe + compartilhar planilha restrita ao domínio (somente leitura) | Dono | — |
| 4 | (Se B) Provisionar Supabase, aplicar `schema.sql`, job de carga, SSO Google, app Lovable read-only | Tech Lead | — |
| 5 | Rodar eval de acesso + registrar baseline; nomear dono; agendar revisão trimestral | Tech Lead + Dono | — |

---
*Hospedagem canônica deste documento: Drive `HUB Central de IA Tatu → 18_ARQUITETURA`. Catálogo de conectores (Supabase, GitHub) → `15_MCP`. Política de segredos/acesso → `11_SEGURANCA_COMPLIANCE`.*
