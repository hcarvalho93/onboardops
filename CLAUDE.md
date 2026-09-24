# APP1_Sistema_CXCS

Nome do produto: **OnboardOps** — Portal interno de Customer Success & Onboarding B2B da Trinus.

## Identidade
- Prefixo de governança: `APP1` (aplicação de desenvolvimento, não automação)
- Pasta: `C:\Claude\APP1_Sistema_CXCS`
- Grupo na sidebar: `APP1_Sistema_CXCS`
- Não confundir com outras iniciativas — cada uma tem sua própria pasta/grupo com prefixo próprio (`APPx` para apps, `AUTx` para automações).

## Stack
- SPA em HTML/CSS/JS puro, arquivo único (`index.html`), sem build, sem framework.
- Backend/dados: Supabase — organização "Trinus", projeto `onboardops` (ref `bnxasipcyfmwrargrjoj`), região São Paulo.
- Servido localmente via `serve.ps1` (HttpListener do .NET, sem Node/Python).

## Sistemas externos conectados
- Supabase (banco + auth) — ver acima.
- GitHub — repositório `hcarvalho93/onboardops` (privado). Git local instalado e configurado desde 2026-09-25 (`C:\Users\henrique.beserra\AppData\Local\Programs\Git`, ainda não no PATH desta sessão — usar caminho completo do `git.exe` até o app reiniciar). Fluxo de PR agora é `git add`/`commit`/`push` + criação/merge do PR pelo navegador (upload de arquivo pelo site não é mais necessário). GitHub Pages ativo, publica a `main` em `https://hcarvalho93.github.io/onboardops/`.
- (adicionar aqui outros sistemas conforme forem conectados, ex.: ASO)

## Convenções deste projeto
- Sem comentários de código desnecessários; só onde o "porquê" não é óbvio.
- Mudanças de schema no Supabase devem ser confirmadas explicitamente antes de aplicar.
