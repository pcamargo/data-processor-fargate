# Nem todo pipeline precisa de Spark: explorando AWS Fargate + DuckDB para ETL

Durante muito tempo, a resposta para muitos desafios de engenharia de dados parecia quase automática:

**"Precisamos processar dados? Vamos colocar Spark nisso."**

E, em muitos cenários, essa é exatamente a decisão correta.

Quando estamos falando de grandes volumes, processamento distribuído, terabytes ou petabytes de dados, transformações complexas e workloads que realmente precisam escalar horizontalmente, tecnologias como **Apache Spark**, **AWS Glue** e **Amazon EMR** continuam sendo excelentes escolhas.

Mas existe uma pergunta que nem sempre fazemos:

> **O problema que estamos tentando resolver realmente precisa de um engine distribuído?**

Foi essa pergunta que me levou a experimentar uma arquitetura diferente:

**AWS Fargate + DuckDB + Amazon S3 + AWS Step Functions.**

---

## Uma observação durante minha preparação para o DEA-C01

Durante minha preparação para o **AWS Certified Data Engineer – Associate (DEA-C01)**, e também durante o próprio exame, tive contato com diversos cenários envolvendo processamento de dados, AWS Glue, Amazon EMR, Spark, Athena, S3 e outros serviços.

Uma coisa, porém, me chamou a atenção.

**Não encontrei nos materiais que estudei nem nas questões que resolvi uma abordagem explorando diretamente AWS Fargate como runtime para workloads de ETL utilizando um engine analítico como o DuckDB.**

Isso despertou uma curiosidade:

> **Será que Fargate poderia ser uma alternativa interessante para determinados workloads de processamento de dados?**

Não para substituir Glue ou EMR.

Mas para adicionar mais uma opção à caixa de ferramentas do engenheiro de dados.

Foi então que decidi parar de apenas estudar a possibilidade e construir um pequeno experimento na AWS.

---

# A alternativa: AWS Fargate + DuckDB

A ideia é relativamente simples.

Em vez de manter um ambiente distribuído para uma carga que pode ser processada eficientemente em uma única máquina, podemos executar uma aplicação containerizada sob demanda no **AWS Fargate**, utilizando o **DuckDB** como engine analítico.

A arquitetura que implementei utiliza:

* **Amazon S3** para armazenamento dos dados;
* **DuckDB** para processamento analítico;
* **AWS Fargate** para executar o container;
* **Amazon ECR** para armazenar a imagem Docker;
* **AWS Step Functions** para orquestrar a execução;
* **IAM** para controle de acesso;
* **VPC/NAT Gateway** para conectividade de rede.

O fluxo é basicamente:

```text
                    AWS Step Functions
                            │
                            ▼
                    AWS Fargate Task
                            │
                            ▼
                          DuckDB
                          /    \
                         /      \
                        ▼        ▼
                       S3        S3
                     leitura   escrita
                     Parquet   Parquet
```

A aplicação é empacotada como um container Docker e executada somente quando existe trabalho para processar.

Quando termina, a Task Fargate também termina.

---

# Por que DuckDB?

Uma das características mais interessantes do DuckDB é que ele foi projetado para **processamento analítico dentro de um único processo**, utilizando execução vetorizada e processamento eficiente em memória.

Isso muda bastante a perspectiva.

Nem todo workload precisa de:

```text
Driver
   +
Executors
   +
Cluster
   +
Shuffle
   +
Coordenação distribuída
```

Para determinadas cargas, podemos ter:

```text
Container
   +
CPU
   +
Memória
   +
DuckDB
```

E isso pode ser suficiente.

Além disso, o DuckDB consegue trabalhar diretamente com arquivos Parquet armazenados no S3, permitindo que a aplicação consulte os dados remotamente sem precisar necessariamente baixar todo o dataset para o container.

Por exemplo:

```sql
SELECT
    PassengerId,
    Name,
    Sex,
    Age
FROM 's3://bucket/titanic/raw/*.parquet'
WHERE Survived = 1;
```

O resultado pode ser gravado novamente no S3:

```text
s3://bucket/curated/data.parquet
```

Tudo dentro da própria Task Fargate.

---

# E onde entra o Fargate?

O Fargate resolve outra parte do problema:

**onde executar esse processamento?**

Em vez de manter uma máquina ou cluster permanentemente disponível, podemos definir uma Task com os recursos necessários:

```text
CPU:    2 vCPUs
Memory: 8 GB
```

ou, dependendo da carga:

```text
CPU:    4 vCPUs
Memory: 16 GB
```

A aplicação é iniciada, executa o processamento e termina.

Não existe servidor esperando o próximo job.

Não existe cluster Spark permanentemente provisionado.

É simplesmente:

```text
Step Functions
      │
      ▼
RunTask
      │
      ▼
Fargate
      │
      ▼
DuckDB
      │
      ▼
Processamento concluído
      │
      ▼
Task STOPPED
```

---

# O resultado prático

No meu experimento, o container foi capaz de:

1. iniciar no Fargate;
2. autenticar utilizando a identidade da Task;
3. acessar os dados no S3;
4. processar os arquivos Parquet com DuckDB;
5. gerar um novo arquivo Parquet;
6. gravar o resultado novamente no S3;
7. encerrar a execução.

E tudo isso sem a necessidade de um cluster Spark.

Esse ponto é importante:

> **Não estou dizendo que Fargate + DuckDB é mais rápido ou mais barato em qualquer cenário.**

A proposta é identificar os cenários em que ele **pode ser uma alternativa mais simples e econômica**.

---

# E o custo?

Aqui entra uma questão interessante de FinOps.

Em um workload adequado, podemos substituir uma infraestrutura de processamento distribuído por uma Task temporária dimensionada de acordo com a necessidade.

O modelo passa a ser aproximadamente:

```text
recursos necessários
        ×
tempo efetivamente executado
```

Em vez de pensar apenas:

> "Qual serviço de ETL devo utilizar?"

podemos pensar:

> **"Qual é o menor ambiente capaz de executar este workload com segurança, performance e confiabilidade?"**

Para determinadas cargas, essa mudança de perspectiva pode resultar em uma redução significativa de custo.

Mas eu evitaria transformar isso em uma promessa genérica de "60% de economia".

**A economia precisa ser medida.**

Ela depende de:

* volume de dados;
* duração do processamento;
* quantidade de CPU;
* memória;
* frequência dos jobs;
* configuração do Glue/EMR;
* paralelismo;
* tempo de inicialização;
* arquitetura utilizada.

Ou seja:

**benchmark antes de decisão.**

---

# Quando essa arquitetura faz sentido?

Eu consideraria essa abordagem principalmente para workloads que:

* cabem confortavelmente na memória disponível;
* podem ser processados em uma única máquina;
* utilizam Parquet ou outros formatos adequados para processamento analítico;
* possuem execução relativamente curta;
* não exigem processamento distribuído;
* precisam de uma execução sob demanda;
* podem ser empacotados facilmente em um container.

Por exemplo:

```text
S3
 │
 ├── 20 GB Parquet
 ├── 30 GB Parquet
 └── 10 GB Parquet
        │
        ▼
   DuckDB / Fargate
        │
        ▼
   5 GB Parquet
        │
        ▼
       S3
```

A quantidade de dados, entretanto, não é o único fator.

**O perfil do workload importa tanto quanto o volume.**

---

# Quando eu continuaria usando Glue ou EMR?

Aqui está talvez o ponto mais importante deste artigo.

**Essa arquitetura não pretende substituir AWS Glue ou Amazon EMR.**

Se o problema exige processamento distribuído, grandes volumes que não cabem adequadamente em uma única máquina, operações com grandes shuffles, necessidade de escalar horizontalmente ou workloads que naturalmente se beneficiam do ecossistema Spark, **Spark continua sendo uma excelente escolha**.

Por exemplo:

```text
             WORKLOAD
                 │
       ┌─────────┴─────────┐
       │                   │
       ▼                   ▼
 Cabe em uma máquina?    Precisa distribuir?
       │                   │
      SIM                  SIM
       │                   │
       ▼                   ▼
Fargate + DuckDB       Glue / EMR + Spark
```

Portanto, a pergunta não deveria ser:

> **"Fargate ou Glue?"**

Mas:

> **"Qual engine e qual runtime são mais adequados para este workload?"**

---

# E existe ainda outra possibilidade

A arquitetura também abre espaço para paralelismo.

Como a Task Fargate é efêmera, várias execuções podem acontecer simultaneamente:

```text
                 Step Functions
                       │
          ┌────────────┼────────────┐
          ▼            ▼            ▼
       Fargate       Fargate      Fargate
        Task 1        Task 2       Task 3
          │            │            │
          ▼            ▼            ▼
       DuckDB        DuckDB       DuckDB
          │            │            │
          └────────────┼────────────┘
                       ▼
                      S3
```

Isso permite criar arquiteturas de processamento paralelas sem precisar manter um cluster permanente.

Naturalmente, isso também traz novos desafios: concorrência, particionamento dos dados, escrita simultânea no S3, limites de execução e controle de custos.

Ou seja, **escalar também exige arquitetura.**

---

# O principal aprendizado

O maior aprendizado desse experimento não foi simplesmente:

> "DuckDB funciona no Fargate."

Isso eu consegui validar na prática.

O aprendizado mais interessante foi outro:

> **Nem todo problema de dados precisa da mesma arquitetura.**

Spark é extremamente poderoso.

Glue é extremamente útil.

EMR continua sendo uma excelente opção para workloads distribuídos.

Mas isso não significa que todo pipeline precise de um cluster.

Às vezes, a solução mais adequada pode ser:

```text
S3
 +
DuckDB
 +
Container
 +
Fargate
 +
Step Functions
```

Uma arquitetura menor, temporária e dimensionada para o problema.

---

# Arquitetura de dados também é saber quando não usar uma tecnologia

Talvez essa seja a principal reflexão que levo desse experimento e também da minha preparação para o **AWS Certified Data Engineer – Associate**.

Certificações ajudam a conhecer os serviços.

Projetos ajudam a entender como utilizá-los.

Mas arquitetura exige uma pergunta adicional:

> **"Eu realmente preciso de tudo isso para resolver este problema?"**

Não se trata de abandonar Spark.

Não se trata de substituir Glue.

Não se trata de dizer que Fargate é melhor.

Trata-se de **escolher conscientemente o nível de complexidade necessário para cada workload.**

E, quando uma única máquina é suficiente, talvez um cluster inteiro seja simplesmente mais infraestrutura do que o problema precisa.

---

**Projeto experimental:** AWS Fargate + DuckDB + S3 + Step Functions

**AWS Certified Data Engineer – Associate (DEA-C01) — Certified ✅**

**Paulo Cesar Camargo**
