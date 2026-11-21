# CVM Financial Data Lakehouse (dbt + DuckDB)

Pipeline end-to-end de Engenharia de Dados para ingestão, tratamento contábil e modelagem dimensional (Star Schema) das Demonstrações Financeiras Padronizadas (DFP) de companhias abertas listadas na B3, utilizando dados públicos da Comissão de Valores Mobiliários (CVM).

## Arquitetura do Projeto

O pipeline segue a arquitetura **Medalhão (Bronze, Silver e Gold)** executada localmente com **Python**, **DuckDB** e **dbt Core**:

```text
CVM Open Data (ZIP/CSV)
       │
       ▼  [src/extract.py - Python / Requests]
┌──────────────────┐
│  Camada Bronze   │  Arquivos CSV brutos particionados por ano (DFP Consolidado: DRE, BPA, BPP)
└──────────────────┘
       │
       ▼  [dbt Views - models/silver/]
┌──────────────────┐
│  Camada Silver   │  Tipagem, deduplicação temporal (ORDEM_EXERC = 'ÚLTIMO') e normalização de escala
└──────────────────┘
       │
       ▼  [dbt Tables - models/gold/]
┌──────────────────┐
│   Camada Gold    │  Star Schema (dim_empresas + fct_indicadores_financeiros) com testes de qualidade
└──────────────────┘
```

## Desafios Contábeis e Regras de Negócio Resolvidos

Trabalhar com dados regulatórios reais da CVM exige tratamento específico para evitar distorções nos indicadores financeiros:

1. **Duplicidade Temporal de Exercícios (`ORDEM_EXERC`):** Cada arquivo anual da DFP contém tanto o exercício atual (`'ÚLTIMO'`) quanto o exercício comparativo anterior (`'PENÚLTIMO'`). A camada Silver filtra estritamente `'ÚLTIMO'` para evitar sobreposição histórica ao consolidar múltiplos anos.
2. **Escalas Monetárias Mistas (`MIL` vs. `UNIDADE`):** Embora a maioria das companhias reporte valores em milhares de reais (`MIL`), algumas empresas reportam em reais inteiros (`UNIDADE`). Os modelos da Silver normalizam todas as contas dividindo registros em `UNIDADE` por `1000.0` e padronizando `escala_moeda = 'MIL'`.
3. **Planos de Contas Multi-Setoriais (IFRS / Cosif):**
   - **Patrimônio Líquido:** Capturado na conta `2.03` (empresas comerciais/industriais) e nas contas `2.07` e `2.08` (instituições financeiras e seguradoras), filtrado pela descrição para evitar provisões.
   - **Lucro Líquido:** Consolidado via `COALESCE` entre a conta `3.11` (padrão geral) e `3.09` (bancos sob padrão IFRS).
   - **Endividamento Geral:** Calculado pela identidade patrimonial `(Ativo Total - Patrimônio Líquido) / Ativo Total`, garantindo consistência inclusive para bancos que não segregam passivo circulante e não circulante.
4. **Saneamento de Indicadores:** O cálculo de **ROE** anula automaticamente registros com Patrimônio Líquido negativo ou zero, evitando distorções matemáticas em empresas com passivo a descoberto.

## Estrutura do Repositório

```text
cvm-lakehouse-dbt/
├── src/
│   └── extract.py                    # Script de ingestão automatizada do portal de Dados Abertos da CVM
├── requirements.txt                  # Dependências do ambiente Python (dbt-duckdb, requests, etc.)
└── cvm_transformation/               # Projeto dbt
    ├── dbt_project.yml               # Configurações de materialização (Silver: view | Gold: table)
    └── models/
        ├── silver/
        │   ├── stg_dre.sql           # Demonstração do Resultado do Exercício tratada
        │   ├── stg_bpa.sql           # Balanço Patrimonial Ativo tratado
        │   ├── stg_bpp.sql           # Balanço Patrimonial Passivo tratado
        │   └── schema.yml            # Testes de integridade e documentação da Silver
        └── gold/
            ├── dim_empresas.sql      # Dimensão cadastral única (ROW_NUMBER por dt_referencia)
            ├── fct_indicadores_financeiros.sql  # Tabela fato com indicadores fundamentalistas
            └── schema.yml            # Testes de chave primária, integridade referencial e documentação
```

## Como Executar Localmente

1. **Clonar o repositório e ativar o ambiente virtual:**
   ```bash
   git clone (https://github.com/dnlcs/cvm-lakehouse-dbt.git)
   cd cvm-lakehouse-dbt
   python -m venv .venv
   # Windows:
   .venv\Scripts\activate
   # Linux/Mac:
   source .venv/bin/activate
   pip install -r requirements.txt
   ```

2. **Executar a ingestão da camada Bronze:**
   ```bash
   python src/extract.py
   ```

3. **Construir os modelos e rodar os testes no dbt:**
   ```bash
   cd cvm_transformation
   dbt build
   ```

4. **Gerar e visualizar a documentação e linhagem de dados (opcional):**
   ```bash
   dbt docs generate
   dbt docs serve
   ```