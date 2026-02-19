with source as (
    select * from {{ source('raw_data', 'fhv_tripdata_2019_non_partitione') }}
),

renamed as (
    select
        -- identifiers
        cast(dispatching_base_num as integer) as dispatching_base_num,
        --cast(ratecodeid as integer) as rate_code_id,
        cast(PUlocationID as integer) as pickup_location_id,
        cast(DOlocationID as integer) as dropoff_location_id,

        -- timestamps
        cast(pickup_datetime as timestamp) as pickup_datetime,  
        cast(dropoff_datetime as timestamp) as dropoff_datetime,

        cast(SR_Flag as integer) as sr_flag,
        cast(Affiliated_base_number as string) as affiliated_base_number,



    from source
    -- Filter out records with null dispatching_base_num (data quality requirement)
    where dispatching_base_num is not null
)

select * from renamed

-- Sample records for dev environment using deterministic date filter
{% if target.name == 'dev' %}
where pickup_datetime >= '2019-01-01' and pickup_datetime < '2019-02-01'
{% endif %}