# Módulo de Publicações e Comunicados

## Visão Geral (`/publicacoes`)
Este módulo é o "coração" da inteligência jurídica do sistema. Ele centraliza todas as intimações e publicações capturadas dos Diários de Justiça, processadas e entregues aos advogados.

### Diferenciais de IA (Inteligência Artificial)
O sistema original possui recursos avançados de análise automática das publicações (tabela `tb_comunicado_fala`):
- **Resumo Automático**: A IA gera um resumo da decisão (`ia_resumo_decisao`).
- **Sugestão de Prazos**: Identifica prazos processuais (`ia_prazo_dias`, `ia_prazo_estimado`) e o ato cabível (`ia_ato_cabivel`).
- **Leitura em Áudio**: Converte o texto da publicação em MP3 para que o advogado possa ouvir no trânsito (`url_mp3`).

## Listagem de Publicações (Inbox)

### Filtros
- **Status de Leitura**: Lidas / Não Lidas.
- **Status de Tratamento**: Pendente / Tratada / Arquivada.
- **Data**: Período de disponibilização.
- **Advogado**: Filtrar por responsável.
- **Tribunal/Órgão**: Origem da publicação.

### Cards de Publicação
Cada item na lista exibe:
- **Cabeçalho**: Tribunal, Vara e Número do Processo.
- **Resumo IA**: O "título" gerado pela inteligência artificial (ex: "Sentença de Procedência", "Despacho de Mero Expediente").
- **Texto**: Trecho relevante da publicação.
- **Prazos**: Destaque visual se houver prazo fatal identificado.
- **Ações Rápidas**:
  - "Marcar como Lida".
  - "Ouvir" (Player de áudio).
  - "Ver Processo".

## Detalhes da Publicação (`/publicacoes/[id]`)

### Conteúdo Principal
- **Texto Completo**: O teor integral da publicação.
- **Análise da IA**:
  - Resumo.
  - Fundamentação do Prazo.
  - Sugestão de providência.

### Fluxo de Trabalho (Tratamento)
O advogado deve "tratar" a publicação, transformando-a em ação:
1. **Vincular a Processo**: Se não estiver vinculado automaticamente.
2. **Agendar Prazo/Audiência**: Criar evento na agenda a partir da publicação.
   - O sistema já deve sugerir a data baseada na IA.
3. **Notificar Cliente**: Enviar e-mail ou WhatsApp (tabela `tb_advogado_comunicado` indica integração com WhatsApp).
4. **Encerrar**: Marcar como "Tratada".

## Integrações
- **WhatsApp**: Envio automático ou manual do resumo para o advogado ou cliente.
- **Agenda**: Criação automática de prazos sugeridos (com revisão humana).
