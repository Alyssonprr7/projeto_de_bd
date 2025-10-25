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


### Passo 2: Popular o Banco com Dados de Teste

Após a criação das tabelas, é necessário popular o banco com dados artificiais.  
Execute o arquivo `populate_data.sql` para criar as procedures de população.


```bash
psql -U postgres -d streamers_db -f populate_data.sql
```

Caso esteja utilizando um conteiner Docker, execute 

```bash
docker exec -i <nome_container> psql -U postgres -d streamers_db < populate_data.sql
```

Depois, basta chamar as Procedures que foram criadas 

```sql
CALL limpar_dados(); 
CALL popular_banco(500);
```

Caso queira limpar o banco e recriar os dados, basta chamar essa procedure novamente. 
