# Fluxo de Navegação (Sitemap)

1. **Público**
   - `/login`: Autenticação.
   - `/recuperar-senha`: Solicitação de reset.
   - `/resetar-senha`: Definição de nova senha.

2. **Área Logada (Dashboard)**
   - `/`: Redireciona para Dashboard.
   - `/dashboard`: Visão geral.

   - **Publicações (Inbox)**
     - `/publicacoes`: Listagem de intimações.
     - `/publicacoes/[id]`: Leitura e tratamento.
   
   - **Processos**
     - `/processos`: Listagem.
     - `/processos/novo`: Cadastro.
     - `/processos/[id]`: Detalhes.
       - `/processos/[id]/editar`: Edição.
       - `/processos/[id]/movimentacoes`: Aba específica.
   
   - **Financeiro**
     - `/financeiro`: Visão geral e extrato.
     - `/financeiro/lancamentos/novo`: Novo lançamento.
     - `/financeiro/contratos`: Gestão de contratos.
   
   - **Agenda**
     - `/agenda`: Calendário.
   
   - **Clientes**
     - `/clientes`: Listagem.
     - `/clientes/novo`: Cadastro.
     - `/clientes/[id]`: Detalhes.
   
   - **Documentos**
     - `/documentos`: Biblioteca geral.
   
   - **Configurações**
     - `/configuracoes/perfil`: Dados do usuário.
     - `/configuracoes/empresa`: Dados do escritório.
     - `/configuracoes/usuarios`: Gestão de equipe (Admin).
