# Módulo Financeiro

## Visão Geral (`/financeiro`)

### Cards de Resumo (KPIs)
- **Receita Mensal**: Valor total recebido no mês.
- **Despesa Mensal**: Valor total pago no mês.
- **Saldo Previsto**: Projeção para o fim do mês.
- **Inadimplência**: Valor vencido e não recebido.

### Listagem de Lançamentos (Extrato)
Tabela unificada de contas a pagar e receber.

#### Colunas
- **Data**: Vencimento ou Pagamento.
- **Descrição**: O que é o lançamento.
- **Categoria**: Classificação (ex: Honorários, Aluguel, Custas).
- **Pessoa**: Cliente ou Fornecedor vinculado.
- **Valor**: Valor original.
- **Status**: Pendente, Pago, Atrasado.
- **Ações**: Baixar (Pagar/Receber), Editar, Excluir.

#### Filtros
- Período (Mês atual, Ano, Personalizado).
- Tipo (Receita, Despesa).
- Status (Aberto, Liquidado).
- Conta Bancária.

## Detalhes do Lançamento
- Edição de valores, datas e categorias.
- Anexo de comprovantes.
- Histórico de alterações.

## Contratos de Honorários
Gestão de contratos recorrentes ou parcelados.
- Cadastro de contrato com valor total e número de parcelas.
- Geração automática das parcelas (lançamentos) no financeiro.
