# Visão Geral do Sistema Juris360

## Descrição
O **Juris360** é um sistema de gestão jurídica completo (ERP Jurídico) projetado para escritórios de advocacia e departamentos jurídicos. O sistema visa centralizar todas as operações do escritório, desde o acompanhamento de processos e publicações até a gestão financeira e relacionamento com clientes.

## Público-Alvo
- Escritórios de Advocacia (pequeno, médio e grande porte)
- Advogados Autônomos
- Departamentos Jurídicos de Empresas

## Principais Módulos

### 1. Gestão de Processos
Centraliza todas as informações dos processos judiciais e administrativos.
- Cadastro automático e manual de processos.
- Acompanhamento de movimentações e publicações.
- Vinculação de partes (clientes, advogados, terceiros).
- Controle de prazos e audiências.

### 2. Gestão Financeira
Controle completo das finanças do escritório.
- Contas a Pagar e Receber.
- Fluxo de Caixa.
- Gestão de Honorários e Contratos.
- Emissão de Boletos e Notas Fiscais (integrações).

### 3. Agenda e Prazos
Calendário inteligente integrado aos processos.
- Agendamento de audiências, reuniões e prazos.
- Lembretes automáticos por e-mail e notificações.
- Integração com Google Calendar (previsto).

### 4. Gestão de Clientes (CRM)
Base de dados completa de pessoas físicas e jurídicas.
- Cadastro detalhado de clientes.
- Histórico de processos e financeiro por cliente.
- Gestão de documentos pessoais.

### 5. Gestão Eletrônica de Documentos (GED)
Armazenamento seguro e organizado de arquivos.
- Upload de petições, contratos e provas.
- Vinculação de documentos a processos e clientes.
- Versionamento de arquivos.

## Arquitetura de Dados
O sistema é multi-tenant (multi-empresa), onde cada escritório possui seus dados isolados, identificados pelo `id_empresa`. A segurança e integridade dos dados são garantidas através de relacionamentos fortes no banco de dados e verificações de permissão em nível de aplicação.
