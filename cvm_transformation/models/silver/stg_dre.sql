with raw_source as (

    select * 
    from read_csv_auto(
        '../data/bronze/*/dfp_cia_aberta_DRE_con_*.csv',
        delim = ';',
        encoding = 'latin-1'
    )
),

renamed_and_filtered as (

    select
        cast(cd_cvm as integer) as cod_cvm,
        cnpj_cia,
        trim(denom_cia) as nome_empresa,

        cast(dt_refer as date) as dt_referencia,
        cast(dt_ini_exerc as date) as dt_inicio_exercicio,
        cast(dt_fim_exerc as date) as dt_fim_exercicio,
        ordem_exerc,
        cast(versao as integer) as versao,
        escala_moeda,

        trim(cd_conta) as cod_conta,
        trim(ds_conta) as desc_conta,
        cast(vl_conta as double) as valor_conta

    from raw_source
    where ordem_exerc = 'ÚLTIMO'
)

select * from renamed_and_filtered