-- ============================================================
-- OnboardOps — carga dos dados de exemplo (fictícios) usados
-- para teste, espelhando a função seed() do index.html.
-- Datas relativas calculadas com current_date, igual à lógica
-- ago()/ahead() do app.
-- ============================================================

insert into public.clientes (id, nome, cnpj, produtos, tipologia, data_assinatura, data_kickoff, go_live_previsto, go_live_real, resp_onboarding, key_account, resp_comercial, resp_kickoff, status, etapa, obs, estado, cidade, criado_em, criado_por) values
('rdville','RD VILLE CONSTRUTORA E INCORPORADORA LTDA','12.345.678/0001-90', array['Backoffice'],'Incorporação', current_date-120, current_date-114, current_date-46, null, 'Victor Abreu Espíndola','Ester Silva de Souza','Felipe Henrique','Victor Abreu Espíndola','Em andamento','onboarding','','GO','Goiânia', current_date-120,'Waleria Santos'),
('barion','BARION EMPREENDIMENTOS IMOBILIARIOS LTDA.','23.456.789/0001-11', array[]::text[], 'Incorporação', current_date-122, null, null, null, 'Victor Abreu Espíndola','Ester Silva de Souza','Paulo Roberto', null, 'Aguardando Cliente','contrato','','SP','São Paulo', current_date-122,'Waleria Santos'),
('calftech','CALFTECH CONSTRUTORA E INCORPORADORA LTDA.','34.567.890/0001-22', array[]::text[], 'Incorporação', current_date-118, null, null, null, 'Natalia Yoshimura Lopes','Ester Silva de Souza', null, null, 'Aguardando Cliente','contrato','','PR','Curitiba', current_date-118,'Waleria Santos'),
('novaalianca','NOVA ALIANÇA INCORPORADORA LTDA','45.678.901/0001-33', array['Backoffice','Gerente de Projetos'],'Incorporação', current_date-210, current_date-204, current_date-180, current_date-178, 'Natalia Yoshimura Lopes','Ester Silva de Souza','Felipe Henrique','Natalia Yoshimura Lopes','Concluído','operacao','Cliente operando com saúde excelente — referência de onboarding bem-sucedido.','SP','Campinas', current_date-210,'Waleria Santos'),
('solaris','SOLARIS EMPREENDIMENTOS LTDA','56.789.012/0001-44', array['Backoffice'],'Incorporação', current_date-160, current_date-150, current_date-90, null, 'Victor Abreu Espíndola','Ester Silva de Souza','Paulo Roberto','Victor Abreu Espíndola','Em andamento','onboarding','Cliente com dificuldade recorrente em liberar acessos bancários — onboarding travado.','RJ','Rio de Janeiro', current_date-160,'Waleria Santos');

insert into public.ativos (id, cliente_id, nome, estado, cidade, regiao, tipologia, quantidade, unidades, vgv, status_ativo, criado_em, criado_por, obs) values
('at_rd1','rdville','SPE Jardim Aurora','GO','Goiânia','Centro-Oeste','Incorporação',1,240,180000000,'Comercialização', current_date-114,'Victor Abreu Espíndola',''),
('at_rd2','rdville','SPE Mar Azul','BA','Salvador','Nordeste','Multipropriedade',3,520,420000000,'Lançamento', current_date-114,'Victor Abreu Espíndola','Resort em fase de lançamento'),
('at_ba1','barion','Loteamento Bosque Verde','SP','Campinas','Sudeste','Loteamento',2,380,150000000,'Obras', current_date-121,'Victor Abreu Espíndola',''),
('at_na1','novaalianca','SPE Alto da Serra','SP','Campinas','Sudeste','Incorporação',1,300,220000000,'Comercialização', current_date-204,'Natalia Yoshimura Lopes',''),
('at_so1','solaris','Residencial Vista Mar','RJ','Rio de Janeiro','Sudeste','Incorporação',1,150,95000000,'Obras', current_date-150,'Victor Abreu Espíndola','');

insert into public.surveys (cliente_id, data_resposta, q1,q2,q3,q4,q5, comentarios) values
('rdville', current_date-112, 5,5,4,5,5, 'Espero construir uma parceria de longo prazo, com troca de conhecimento, visão estratégica e apoio na tomada de decisões importantes para o crescimento da empresa.'),
('novaalianca', current_date-200, 5,5,5,4,5, 'Onboarding muito bem conduzido, equipe extremamente atenciosa e prazos cumpridos à risca.'),
('solaris', current_date-145, 2,3,2,3,2, 'Estamos com dificuldades internas para disponibilizar os acessos solicitados — o processo está mais lento do que esperávamos.');

insert into public.activation (cliente_id, items, dates) values
('rdville',
 '{"plano.elaborado":"SIM","plano.validInterno":"SIM","plano.compartilhado":"SIM","plano.aprovCliente":"SIM","erp.solicitado":"SIM","erp.recebido":"SIM","erp.validado":"PENDENTE","bancario.solicitado":"SIM","bancario.recebido":"PENDENTE","bancario.validado":"","master.identificado":"SIM","master.agenda":"SIM","master.treino":"PENDENTE","doc.solicitada":"SIM","doc.recebida":"PENDENTE","treino.agendado":"PENDENTE","treino.realizado":"","entrega.concluida":""}'::jsonb,
 jsonb_build_object('plano.inicio',(current_date-114)::text,'plano.fim',(current_date-108)::text,'erp.inicio',(current_date-108)::text,'bancario.inicio',(current_date-100)::text)
),
('novaalianca',
 '{"plano.elaborado":"SIM","plano.validInterno":"SIM","plano.compartilhado":"SIM","plano.aprovCliente":"SIM","erp.solicitado":"SIM","erp.recebido":"SIM","erp.validado":"SIM","bancario.solicitado":"SIM","bancario.recebido":"SIM","bancario.validado":"SIM","master.identificado":"SIM","master.agenda":"SIM","master.treino":"SIM","doc.solicitada":"SIM","doc.recebida":"SIM","treino.agendado":"SIM","treino.realizado":"SIM","entrega.concluida":"SIM"}'::jsonb,
 jsonb_build_object('plano.inicio',(current_date-204)::text,'plano.fim',(current_date-200)::text,'erp.inicio',(current_date-200)::text,'erp.fim',(current_date-196)::text,'bancario.inicio',(current_date-200)::text,'bancario.fim',(current_date-195)::text,'master.inicio',(current_date-195)::text,'master.fim',(current_date-190)::text,'doc.inicio',(current_date-196)::text,'doc.fim',(current_date-192)::text,'treino.inicio',(current_date-190)::text,'treino.fim',(current_date-182)::text,'entrega.inicio',(current_date-180)::text,'entrega.fim',(current_date-178)::text)
),
('solaris',
 '{"plano.elaborado":"SIM","plano.validInterno":"PENDENTE","plano.compartilhado":"","plano.aprovCliente":"","erp.solicitado":"PENDENTE","erp.recebido":"","erp.validado":"","bancario.solicitado":"SIM","bancario.recebido":"PENDENTE","bancario.validado":"","master.identificado":"PENDENTE","master.agenda":"","master.treino":"","doc.solicitada":"PENDENTE","doc.recebida":"","treino.agendado":"","treino.realizado":"","entrega.concluida":""}'::jsonb,
 jsonb_build_object('plano.inicio',(current_date-150)::text,'bancario.inicio',(current_date-130)::text)
);

insert into public.ttfv (cliente_id, tipo, data_valor) values
('rdville','Primeira demanda atendida', current_date-113),
('novaalianca','Primeira demanda atendida', current_date-202);

insert into public.activities (id, cliente_id, titulo, descricao, responsavel, prioridade, status, criacao, prazo, data_conclusao) values
('a1','rdville','Validar Plano de Sucesso com o cliente','Revisar e obter aprovação formal do plano.','Victor Abreu Espíndola','Alta','Concluído', current_date-113, current_date-103, current_date-105),
('a2','rdville','Validar acessos bancários com o cliente','Confirmar recebimento e validar credenciais para integração financeira.','Victor Abreu Espíndola','Crítica','Aguardando Cliente', current_date-100, current_date-5, null),
('a1b','rdville','Agendar treinamento do usuário master','Marcar sessão de treinamento com o responsável técnico do cliente.','Victor Abreu Espíndola','Média','A Fazer', current_date-10, current_date+7, null),
('a3','barion','Agendar reunião de kickoff','Definir data de kickoff com o cliente.','Victor Abreu Espíndola','Média','A Fazer', current_date-20, current_date+10, null),
('a4','calftech','Confirmar responsável técnico do cliente','Identificar e registrar o usuário master indicado pela Calftech.','Natalia Yoshimura Lopes','Média','A Fazer', current_date-6, current_date+4, null),
('a5','novaalianca','Validar Plano de Sucesso com o cliente','Revisar e obter aprovação formal do plano.','Natalia Yoshimura Lopes','Alta','Concluído', current_date-203, current_date-195, current_date-198),
('a6','novaalianca','Registrar Time to First Value','Confirmar e registrar a primeira entrega de valor percebida pelo cliente.','Natalia Yoshimura Lopes','Alta','Concluído', current_date-202, current_date-200, current_date-202),
('a7','solaris','Cobrar validação dos acessos bancários','Cliente ainda não validou as credenciais enviadas.','Victor Abreu Espíndola','Alta','Em Andamento', current_date-40, current_date-20, null),
('a8','solaris','Reagendar treinamento com o cliente','Cliente cancelou a sessão de treinamento pela segunda vez.','Victor Abreu Espíndola','Crítica','Aguardando Cliente', current_date-15, current_date-8, null);

insert into public.interactions (id, cliente_id, data, hora, canal, responsavel, tipo, status, resumo, texto, proxima_acao, prazo_acao, tags, anexos) values
('i1','rdville', current_date-112,'14:32','WhatsApp','Victor Abreu Espíndola','Pendência documental','Aguardando cliente','Cliente confirmou envio das credenciais bancárias em breve.', '[14:30] Onboarding: Olá! Precisamos das credenciais para a integração.
[14:32] Cliente: Perfeito, envio em breve.','Cobrar envio das credenciais', current_date-109, array['Pendência','Follow-up'], '[]'::jsonb),
('i2','barion', current_date-15,'10:05','Telefone','Paulo Roberto','Confirmação de agenda','Aguardando cliente','Contato para agendar reunião de kickoff; cliente pediu mais alguns dias para confirmar disponibilidade da equipe.', '[10:00] Comercial: Bom dia! Podemos agendar o kickoff para a próxima semana?
[10:05] Cliente: Precisamos alinhar internamente, retornamos em breve.','Reforçar contato para confirmar data', current_date+5, array['Follow-up','Comercial'], '[]'::jsonb),
('i3','calftech', current_date-10,'09:40','E-mail','Natalia Yoshimura Lopes','Alinhamento operacional','Registrado','Primeiro contato pós-assinatura, apresentação da equipe de onboarding e próximos passos.', 'E-mail de boas-vindas enviado com apresentação da equipe e cronograma inicial de implantação.','Aguardar indicação do usuário master', current_date+6, array['Operacional'], '[]'::jsonb),
('i4','novaalianca', current_date-179,'16:20','Reunião','Natalia Yoshimura Lopes','Decisão acordada','Resolvido','Reunião de encerramento do onboarding; cliente aprovou a operação assistida e elogiou o processo.', '[16:20] Cliente: Equipe muito atenciosa, superou nossas expectativas em todo o processo.','Nenhuma — cliente em operação plena', null, array['Decisão acordada'], '[]'::jsonb),
('i5','solaris', current_date-9,'11:15','WhatsApp','Victor Abreu Espíndola','Registro de insatisfação','Aguardando cliente','Cliente relatou dificuldade interna para liberar os acessos bancários e pediu mais prazo, gerando atraso na ativação.', '[11:10] Onboarding: Precisamos dos acessos bancários para avançar com a ativação.
[11:15] Cliente: Estamos com dificuldades internas, vamos precisar de mais alguns dias.','Escalar internamente se não houver retorno em 5 dias', current_date+5, array['Risco','Cliente insatisfeito','Pendência documental'], '[]'::jsonb);

insert into public.propostas (id, cliente_nome, status, valor, booked_value, produto, produtos, responsavel, data_elaboracao, data_prevista, data_aprovacao, data_assinatura, data_perdida, obs) values
('pp1','RD VILLE CONSTRUTORA E INCORPORADORA LTDA','Contrato Assinado',180000,180000,'Backoffice',array['Backoffice'],'Felipe Henrique','2026-04-10','2026-05-15','2026-04-28','2026-05-19', null, 'Contrato fechado — Backoffice.'),
('pp2','BARION EMPREENDIMENTOS IMOBILIARIOS LTDA.','Contrato Assinado',120000,120000,'Backoffice',array['Backoffice'],'Paulo Roberto','2026-04-15','2026-05-10','2026-05-02','2026-05-15', null, ''),
('pp3','CALFTECH CONSTRUTORA E INCORPORADORA LTDA.','Contrato Assinado',96000,96000,'Monitoramento de Projetos',array['Monitoramento de Projetos'], null, '2026-04-20','2026-05-20','2026-05-08','2026-05-22', null, ''),
('pp4','HORIZONTE URBANISMO SPE LTDA','Proposta Aprovada',150000,150000,'Gerente de Projetos',array['Gerente de Projetos'],'Felipe Henrique','2026-05-02','2026-06-15','2026-05-25', null, null, 'Aguardando assinatura do contrato.'),
('pp5','VERTENTE INCORPORAÇÕES S.A.','Em Negociação',210000,210000,'Análise Orçamentária',array['Análise Orçamentária'],'Paulo Roberto','2026-05-06','2026-06-20', null, null, null, ''),
('pp6','MERIDIANO LOTEAMENTOS LTDA','Proposta Enviada',88000,88000,'Backoffice',array['Backoffice'],'Felipe Henrique','2026-05-18','2026-06-30', null, null, null, 'Em análise pelo cliente.'),
('pp7','COSTA AZUL MULTIPROPRIEDADE LTDA','Proposta Elaborada',175000,175000,'Gerente de Projetos',array['Gerente de Projetos'], null, '2026-05-24','2026-07-10', null, null, null, ''),
('pp8','PRIME DESENVOLVIMENTO IMOBILIÁRIO','Proposta Perdida',130000,130000,'Backoffice',array['Backoffice'],'Paulo Roberto','2026-04-30','2026-05-30', null, null, '2026-05-28', 'Optou por concorrente.'),
('pp9','NOVA ALIANÇA INCORPORADORA LTDA','Contrato Assinado',200000,200000,'Gerente de Projetos',array['Gerente de Projetos'],'Felipe Henrique', current_date-215, current_date-212, current_date-213, current_date-210, null, 'Contrato fechado — Gerente de Projetos.'),
('pp10','SOLARIS EMPREENDIMENTOS LTDA','Contrato Assinado',140000,140000,'Backoffice',array['Backoffice'],'Paulo Roberto', current_date-165, current_date-162, current_date-163, current_date-160, null, 'Contrato fechado — Backoffice.');

update public.config set
  empresa = 'Trinus',
  tagline = 'Portal de Customer Success & Jornada do Cliente',
  thr = '{"saudavel":70,"atencao":40}'::jsonb,
  escala_imediata = 30,
  escala_semanal = 50,
  produtos = array['Backoffice','Gerente de Projetos','Monitoramento de Projetos','Análise Orçamentária','Elaboração de Orçamento','Monitoramento de Obras','Gestão de Carteira','Viabilidade','Secretaria de Vendas','Suprimentos','Assessoria Jurídica'],
  tipologias = array['Incorporação','Loteamento','Multipropriedade','Outros']
where id = 1;
