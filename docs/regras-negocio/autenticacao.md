# Regras de Autenticação e Segurança

## Senhas
Para manter compatibilidade com sistemas legados (Delphi), utilizamos um algoritmo de hash customizado.

### Algoritmo "MD5 Salt Custom"
1. **Salt Fixo**: Uma string constante definida no sistema.
2. **Intercalação**: A senha do usuário é intercalada caractere a caractere com o Salt.
3. **Hashing**: O resultado sofre hash MD5 duas vezes consecutivas.
4. **Armazenamento**: O hash final (hexadecimal lowercase) é armazenado no banco.

**Nota**: Novas implementações devem considerar migrar para algoritmos mais seguros (ex: Argon2 ou Bcrypt) assim que a compatibilidade legada não for mais necessária.

## Sessão (JWT)
- A autenticação gera um **JSON Web Token (JWT)**.
- **Payload**: Contém `id_usuario`, `id_empresa` e `role`.
- **Armazenamento**: Cookie `HttpOnly`, `Secure` e `SameSite=Lax`.
- **Validade**: 7 dias (renovável).

## Multi-tenancy
- Todo acesso a dados deve ser filtrado pelo `id_empresa` presente no token JWT.
- Um usuário pode pertencer a múltiplas empresas (tabela `usuario_empresas`), mas deve selecionar uma empresa ativa para a sessão ("troca de contexto").
