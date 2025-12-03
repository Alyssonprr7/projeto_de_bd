# Sistema de Catalogação de Streamers

## Pré-requisitos

- PostgreSQL 12 ou superior

## Estrutura de Arquivos

| Arquivo | Descrição |
|---------|-----------|
| `0_initial_ddls.sql` | Criação das tabelas e estrutura do banco |
| `1_populate_data.sql` | Procedures para popular o banco com dados de teste |
| `2_pure_sql_queries.sql` | Consultas SQL puras (sem views/functions) |
| `3_creating_views.sql` | Criação das views virtuais e materializadas |
| `4_pure_sql_queries_views.sql` | Consultas SQL utilizando as views |
| `5_creating_indexes.sql` | Criação dos índices para otimização |
| `6_functions.sql` | Criação das functions |
| `7_triggers.sql` | Criação dos triggers |
| `8_queries_after_functions.sql` | Consultas SQL utilizando as functions |

## Executando o Projeto

### Passo 1: Criar o Banco de Dados

Antes de restaurar qualquer dump, crie o banco:
```sql
CREATE DATABASE streamers_db;
```

Ou via linha de comando:
```bash
psql -U postgres -c "CREATE DATABASE streamers_db;"
```

### Passo 2: Escolha uma das opções abaixo

#### Opção A: Banco completo (recomendado)

Restaura o banco já com todos os dados, views, índices, functions e triggers:
```bash
psql -U postgres -d streamers_db < ./dump/dump_all_database.sql
```

#### Opção B: Apenas dados iniciais

Restaura apenas a estrutura e os dados, permitindo executar os demais scripts manualmente:
```bash
psql -U postgres -d streamers_db < ./dump/dump_data.sql
```

Depois, execute os scripts na ordem:
```bash
psql -U postgres -d streamers_db < 3_creating_views.sql
psql -U postgres -d streamers_db < 5_creating_indexes.sql
psql -U postgres -d streamers_db < 6_functions.sql
psql -U postgres -d streamers_db < 7_triggers.sql
```

## Usando com Docker

Se estiver utilizando PostgreSQL em container Docker, adicione `docker exec -i <nome_container>` antes dos comandos. 

Exemplo considerando um container chamado `pg`:
```bash
# Criar banco
docker exec -i pg psql -U postgres -c "CREATE DATABASE streamers_db;"

# Restaurar dump completo
docker exec -i pg psql -U postgres -d streamers_db < ./dump/dump_all_database.sql
```

```bash
# Restaurar dump completo
docker exec -i pg pg_restore -U postgres -d streamers_db <  ./dump/backup_data.dump
```



