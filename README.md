# OnboardOps

Portal interno de **Customer Success & Onboarding B2B** da Trinus — uma SPA (single-page app) feita em HTML/CSS/JS puro, em um único arquivo (`index.html`), sem build, sem framework e sem backend.

## O que o sistema faz

Gerencia todo o ciclo de onboarding de clientes (incorporadoras/construtoras que usam produtos Trinus), do contrato assinado até a operação estável:

- **Dashboard Executivo** — KPIs da carteira (contratos assinados, clientes em onboarding, operação ativa, health score médio) e alertas do que exige atenção agora.
- **Pipeline da Carteira** — funil kanban de propostas e evolução por etapa (Contrato → Onboarding → Operação → Standby/Churn).
- **Jornada do Cliente** — painel 360° por cliente: atividades, interações, histórico.
- **Cadastro Mestre** — cadastro de clientes e seus ativos/SPEs (empreendimentos, VGV, unidades, tipologia, região).
- **Pesquisa Pós-Kickoff** — captura de satisfação logo após o kickoff.
- **Ativação Operacional** — marcos técnicos/operacionais da implantação.
- **Time to First Value (TTFV)** — tempo até o cliente perceber o primeiro valor gerado.
- **Health Score** — nota composta de saúde do cliente (verde/amarelo/vermelho).
- **Relatórios** — relatório executivo exportável (gera um HTML/print separado).
- **Mapa de Distribuição** — distribuição geográfica de clientes/ativos por estado e região.
- **Pendências e Atividades** — central de tarefas em aberto com farol de atraso.
- **Interações do Cliente** — histórico tipo CRM (ex.: WhatsApp) com o cliente.
- **Histórico de Alterações / Auditoria** — rastreabilidade de mudanças e acessos por usuário.
- **Backup & Segurança** — exportar/restaurar um snapshot completo dos dados.
- **Gestão de Usuários / Configurações** — perfis de acesso (Gestão Executiva, Key Account, Onboarding) e matriz RACI.

**Como funciona por baixo dos panos:** tudo — usuários, clientes, atividades, configurações — é gerado como dados mock dentro do próprio JS (função `DB()`) e persistido no `localStorage` do navegador. Não há chamadas de rede (`fetch`/API): é 100% front-end. Login é por e-mail + senha, com hash salvo localmente (mencionado no próprio app como preparado para futura integração com Microsoft Entra ID / SSO corporativo).

## Como rodar

Não precisa de Node, Python nem instalar nada — é servido via um script PowerShell simples (`serve.ps1`) usando `HttpListener` do .NET, que já vem com o Windows.

**Opção 1 — dentro do Claude Code:** já está configurado em `.claude/launch.json`; o preview abre sozinho em `http://localhost:8080`.

**Opção 2 — manualmente, fora do Claude Code:**
```powershell
powershell -ExecutionPolicy Bypass -File onboardops/serve.ps1 -Port 8080
```
Depois abra `http://localhost:8080` no navegador.

**Opção 3 — mais simples ainda:** dê duplo-clique no `index.html` para abrir direto no navegador (funciona também assim, já que o app não depende de servidor — só perde a URL "bonita" `localhost`).

## Login de teste

O cadastro de usuários já vem com e-mails fictícios da equipe Trinus (ex.: `victor.espindola@trinusco.com.br`). Use **"Criar senha / Primeiro acesso"** na tela de login, informe um desses e-mails e defina uma senha para entrar.

## Estado atual / próximos passos possíveis

- Dados são fictícios e ficam só no navegador (sem backend real, sem sincronização entre usuários).
- Se quiser evoluir para uso real da equipe, os próximos passos naturais seriam: (1) um backend/API + banco de dados de verdade, (2) autenticação corporativa (Entra ID, como já sinalizado na tela de login), e (3) hospedagem compartilhada (ex.: publicado num servidor interno ou serviço de hosting).

Mudança para testar Cummit
