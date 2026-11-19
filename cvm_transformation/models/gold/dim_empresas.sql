with empresas_union as (

    select 
        cod_cvm,
        cnpj_cia,
        nome_empresa,
        dt_referencia
    from {{ ref('stg_dre') }}

    union all 

    select 
        cod_cvm,
        cnpj_cia,
        nome_empresa,
        dt_referencia
    from {{ ref('stg_bpa') }}

),

ranked as (

    select
        cod_cvm,
        cnpj_cia,
        nome_empresa,
        row_number() over (
            partition by cod_cvm
            order by dt_referencia desc, length(nome_empresa) desc
        ) as rn
    from empresas_union
    where cod_cvm is not null

)

select
    cod_cvm,
    cnpj_cia as cnpj, 
    nome_empresa
from ranked
where rn = 1