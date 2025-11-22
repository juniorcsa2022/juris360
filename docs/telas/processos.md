# Módulo de Processos

## Listagem de Processos (`/processos`)

### Filtros e Busca
- **Barra de Busca**: Pesquisa por número do processo, título ou nome das partes.
- **Filtros Avançados**:
  - Status (Ativo, Arquivado, Suspenso).
  - Responsável.
  - Marcadores (Tags).
  - Data de distribuição.

### Tabela de Resultados
Colunas exibidas:
- **Número do Processo**: Link para detalhes.
- **Título/Cliente**: Identificação amigável.
- **Vara/Foro**: Localização do processo.
- **Última Movimentação**: Data e descrição resumida.
- **Status**: Situação atual.
- **Ações**: Botões rápidos (Editar, Arquivar).

### Paginação
- Controle de páginas (Anterior, Próximo, Números).
- Itens por página (10, 20, 50).

## Detalhes do Processo (`/processos/[id]`)

### Cabeçalho
- Informações chave em destaque: Número, Classe, Vara, Valor da Causa.
- Barra de progresso ou status visual.

### Abas de Conteúdo
1. **Resumo**: Dados gerais, partes envolvidas, etiquetas.
2. **Movimentações**: Linha do tempo com o histórico do processo (andamentos).
3. **Publicações**: Recortes de diários oficiais vinculados.
4. **Prazos/Agenda**: Compromissos futuros e passados deste processo.
5. **Documentos**: Ged específico do processo (petições, anexos).
6. **Financeiro**: Honorários e custas vinculadas.

### Ações Principais
- Nova Movimentação.
- Agendar Prazo.
- Anexar Documento.
- Gerar Relatório.
