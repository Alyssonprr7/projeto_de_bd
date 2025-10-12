# Sistema de Catalogação de Streamers - Instruções de Execução

## Pré-requisitos

- PostgreSQL versão 12 ou superior instalado

## Executando o Projeto

### Passo 1: Criar o Banco de Dados

Execute o arquivo `initial_ddls.sql` para criar o banco de dados e todas as tabelas:

```bash
psql -U postgres -f initial_ddls.sql
```

Ou, se estiver usando Docker:

```bash
docker exec -i <container_name> psql -U postgres < initial_ddls.sql
```

## Verificação

Para verificar se o banco foi criado corretamente:

```bash
psql -U postgres -d streamers_db -c "\dt"
```
