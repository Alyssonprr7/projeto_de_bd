# Sistema de Catalogação de Streamers - Instruções de Execução

## Pré-requisitos

- PostgreSQL versão 12 ou superior instalado

## Executando o Projeto

### Passo 1: Criar o Banco de Dados

Execute o arquivo `0_initial_ddls.sql` para criar o banco de dados e todas as tabelas:

```bash
psql -U postgres -f 0_initial_ddls.sql
```

Ou, se estiver usando Docker:

```bash
docker exec -i <container_name> psql -U postgres < 0_initial_ddls.sql
```

## Verificação

Para verificar se o banco foi criado corretamente:

```bash
psql -U postgres -d streamers_db -c "\dt"
```


### Passo 2: Popular o Banco com Dados de Teste

Após a criação das tabelas, é necessário popular o banco com dados artificiais.  
Execute o arquivo `1_populate_data.sql` para criar as procedures de população.


```bash
psql -U postgres -d streamers_db -f 1_populate_data.sql
```

Caso esteja utilizando um conteiner Docker, execute 

```bash
docker exec -i <nome_container> psql -U postgres -d streamers_db < 1_populate_data.sql
```

Depois, basta chamar as Procedures que foram criadas 

```sql
CALL limpar_dados(); 
CALL popular_banco(500);
```

Caso queira limpar o banco e recriar os dados, basta chamar essa procedure novamente.


### Passo 3: Criar as Views do Sistema

Após popular o banco com dados, execute o arquivo `4 - creating_views.sql` para criar as views virtuais e a view materializada:
```bash
psql -U postgres -d streamers_db -f "3_creating_views.sql"
```

Caso esteja utilizando um container Docker, execute:
```bash
docker exec -i  psql -U postgres -d streamers_db < "3_creating_views.sql"
```

Este script criará:
- 4 views virtuais para simplificar consultas complexas
- 1 view materializada para otimização de consultas analíticas
- Índices na view materializada para melhor performance

Para verificar se as views foram criadas corretamente:
```bash
psql -U postgres -d streamers_db -c "\dv"
psql -U postgres -d streamers_db -c "\dm"
```

**Nota:** A view materializada é criada já populada com dados (`WITH DATA`). Para atualizá-la manualmente, execute:
```sql
REFRESH MATERIALIZED VIEW mv_faturamento_consolidado;
```
