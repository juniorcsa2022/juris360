# Permissões e Controle de Acesso

## Modelo RBAC (Role-Based Access Control)
O acesso é controlado através de **Papéis (Roles)** atribuídos aos usuários dentro de uma empresa.

### Papéis Padrão
1. **Admin (Administrador)**
   - Acesso total a todos os módulos.
   - Pode criar/editar usuários e configurações da empresa.
   - Pode ver financeiro completo.

2. **Advogado**
   - Acesso completo a Processos, Clientes, Agenda e Documentos.
   - Acesso restrito ao Financeiro (pode lançar honorários, mas não vê fluxo de caixa global, dependendo da configuração).

3. **Secretária / Assistente**
   - Acesso a Agenda, Clientes e cadastro básico de Processos.
   - Sem acesso a exclusão de dados críticos.

4. **Cliente (Portal do Cliente - Futuro)**
   - Acesso apenas leitura aos seus próprios processos e andamentos.

## Escopo de Dados
- **Privacidade**: Usuários só veem dados da empresa em que estão logados.
- **Restrição por Responsável**: Pode-se configurar para que advogados vejam apenas processos onde são responsáveis (opcional).
