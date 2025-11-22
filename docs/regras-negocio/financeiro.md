# Regras de Negócio Financeiras

## Estrutura de Lançamentos

### 1. Contratos (`fin_contratos`)
Representa um acordo financeiro macro (ex: Honorários de um Processo).
- **Valor Total**: Valor global do contrato.
- **Parcelamento**: Define como serão gerados os itens financeiros.

### 2. Lançamentos Avulsos (`fin_lancamentos_avulsos`)
Receitas ou despesas pontuais não atreladas a um contrato formal de longo prazo (ex: Pagamento de custas, Compra de material).

### 3. Itens Financeiros (`fin_itens`)
A unidade atômica de cobrança/pagamento. É a "parcela" ou a "conta".
- **Vencimento**: Data limite para pagamento sem encargos.
- **Competência**: Mês de referência contábil.
- **Cálculo de Total**: `Valor Principal + Juros + Multa - Desconto`.

## Status do Lançamento
- **PENDENTE**: Aguardando pagamento.
- **PAGO**: Totalmente quitado.
- **PARCIAL**: Pago parcialmente (gera saldo remanescente).
- **CANCELADO**: Inativado.
- **ATRASADO**: Vencimento passou e não foi pago (status calculado).

## Fluxo de Caixa
- **Receita**: Entradas confirmadas (`data_pagamento` preenchida).
- **Despesa**: Saídas confirmadas.
- **Provisão**: Lançamentos futuros (Pendentes).
