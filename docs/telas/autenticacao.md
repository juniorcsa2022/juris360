# Tela de Autenticação

## Login
A porta de entrada do sistema.

### Elementos da Tela
- **Logo**: Logotipo do Juris360.
- **Campo E-mail**: Input de texto para o e-mail ou usuário.
- **Campo Senha**: Input de senha (oculto).
- **Botão "Entrar"**: Submete o formulário.
- **Link "Esqueceu a senha?"**: Redireciona para fluxo de recuperação.

### Comportamento
1. Usuário insere credenciais.
2. Sistema valida formato do e-mail (flexível para aceitar usuários legados).
3. Sistema verifica credenciais no backend (comparação de hash MD5 Salt).
4. Se sucesso:
   - Cria sessão JWT.
   - Redireciona para Dashboard ou última página tentada.
5. Se falha:
   - Exibe mensagem de erro "Credenciais inválidas".

## Recuperação de Senha
(Ainda não implementado no frontend atual, mas previsto)
- Solicitação via e-mail.
- Envio de link com token temporário.
- Tela de definição de nova senha.
