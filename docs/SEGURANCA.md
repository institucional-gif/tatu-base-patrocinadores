# Segurança — Base e Produto de Consulta (Patrocinadores Rouanet)

Dado é **público** (SalicNet/MinC, PJ). O risco real não é vazamento de dado — é **integridade** da base e **controle de acesso** à ferramenta. Princípio: conter no ambiente primeiro, orientar o comportamento depois.

## Checklist de acesso (quem entra)
- [ ] GitHub: repositório **público** (o dado já é público) na org Tatu Cult; **2FA na conta**; `main` com **branch protection aplicada** via ruleset — PR obrigatório + status check `validar` verde + bloqueio de force-push e de deleção da branch. (Revisão exigida: 0 enquanto solo; subir para 1 quando houver 2º membro.)
- [ ] Produto (se Cenário B): login por **SSO Google Workspace (OIDC)** → só `@tatucultural.com.br`; 2FA herdado do Workspace. Sem SSO: Supabase Auth + **TOTP** + hook que rejeita e-mail fora do domínio.
- [ ] Revisão **trimestral** de quem tem acesso (repo e produto). Saída da equipe → revogação imediata (checklist de offboarding).

## Checklist de autorização (o que pode)
- [ ] Supabase **RLS ligado** em todas as tabelas; papel `authenticated` só `SELECT`; nenhuma policy de escrita para o app.
- [ ] App lê de **views** (`v_*`), não das tabelas cruas; carga de dados só via `service_role`, server-side, disparada pelo merge no GitHub.
- [ ] `anon key` sozinha não retorna dado (RLS exige autenticação).

## Checklist de segredos
- [ ] `service_role key`, credenciais do banco, client secret OIDC em **env/cofre** (Supabase, Lovable, Make). **Nunca** no repo, em `data/`, em prompt, em planilha ou em chat.
- [ ] Rotação semestral e **no offboarding**. Registro de quem autorizou cada segredo.
- [ ] `.gitignore` cobre `.env`, chaves e qualquer credencial.

## Catálogo de conectores (manter em `15_MCP`)
Uma linha por conector: nome · o que acessa · escopo · quem autorizou · data · versão · dado pessoal? · última revisão · dono.
Conectores previstos: **GitHub** (repo público, escopo mínimo), **Supabase** (projeto, chaves separadas anon/service), **Make** (se usado para a carga). Conector sem linha no catálogo = não autorizado.

## LGPD (controles técnicos)
- Base sem dado pessoal de titulares (PJ, público). Única PII: e-mail da equipe para login → minimizar e reter só enquanto a pessoa estiver na equipe.
- Sem decisão automatizada sobre pessoas. Acionar skill de LGPD só se entrar dado pessoal novo ou nova finalidade.

## Falhar ruidosamente
- `validate.py` no CI **barra** PR com base inconsistente (falha visível, não silenciosa).
- A planilha e o app exibem sempre a **data de extração** — dado velho é visível, não presumido atual.
