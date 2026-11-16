with dre as (

    select 
        cod_cvm,
        max(nome_empresa) as nome_empresa,
        dt_referencia,
        max(escala_moeda) as escala_moeda,
        max(case when cod_conta = '3.01' then valor_conta end) as receita_liquida,
        max(case when cod_conta = '3.05' then valor_conta end) as ebit,
        coalesce(    
            max(case when cod_conta = '3.11' then valor_conta end),
            max(case when cod_conta = '3.09' then valor_conta end) 
        ) as lucro_liquido
    from {{ ref('stg_dre') }}
    where cod_conta in ('3.01', '3.05', '3.09', '3.11')
    group by cod_cvm, dt_referencia

),

bpa as (

    select
        cod_cvm,
        dt_referencia,
        max(case when cod_conta = '1' then valor_conta end) as ativo_total,
        max(case when cod_conta = '1.01' then valor_conta end) as ativo_circulante,
    from {{ ref('stg_bpa') }}
    where cod_conta in ('1','1.01')
    group by cod_cvm, dt_referencia

),

bpp as (

    select
        cod_cvm,
        dt_referencia,
        max(case when cod_conta = '2.01' then valor_conta end) as passivo_circulante,
        max(case when cod_conta = '2.02' then valor_conta end) as passivo_nao_circulante,
        max(case 
            when cod_conta in ('2.03', '2.07', '2.08')
            and lower(desc_conta) like 'patrimônio líquido%'
            then valor_conta
        end) as patrimonio_liquido
    from {{ ref('stg_bpp') }}
    where cod_conta in ('2.01','2.02','2.03', '2.07', '2.08')
    group by cod_cvm, dt_referencia

),

consolidado as (

    select  
        dre.cod_cvm,
        dre.nome_empresa,
        dre.dt_referencia,
        extract(year from dre.dt_referencia) as ano,
        dre.escala_moeda,

        dre.receita_liquida,
        dre.ebit,
        dre.lucro_liquido,
        bpa.ativo_total,
        bpa.ativo_circulante,
        bpp.passivo_circulante,
        bpp.passivo_nao_circulante,
        bpp.patrimonio_liquido,

        case
            when bpp.patrimonio_liquido > 0
            then round(dre.lucro_liquido / bpp.patrimonio_liquido, 4)
            else null
        end as roe,

        round(dre.lucro_liquido / nullif(bpa.ativo_total, 0), 4) as roa,
        round(dre.lucro_liquido / nullif(dre.receita_liquida, 0), 4) as margem_liquida,
        round(dre.ebit / nullif(dre.receita_liquida, 0), 4) as margem_ebit,

        round(bpa.ativo_circulante / nullif(bpp.passivo_circulante, 0), 4) as liquidez_corrente,
        round((bpa.ativo_total - bpp.patrimonio_liquido) / nullif(bpa.ativo_total, 0), 4) as endividamento_geral

    from dre
    inner join bpa
        on dre.cod_cvm = bpa.cod_cvm
        and dre.dt_referencia = bpa.dt_referencia
    inner join bpp
        on dre.cod_cvm = bpp.cod_cvm
        and dre.dt_referencia = bpp.dt_referencia
    
)

select * from consolidado