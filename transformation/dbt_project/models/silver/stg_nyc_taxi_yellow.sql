{{
  config(
    materialized='incremental',
    unique_key='trip_id',
    on_schema_change='merge',
    file_format='delta',
    incremental_strategy='merge'
  )
}}

with source as (

    select * from {{ source('bronze', 'nyc_taxi_yellow') }}

    {% if is_incremental() %}
    where tpep_pickup_datetime > (
        select max(pickup_datetime) from {{ this }}
    )
    {% endif %}

),

cleaned as (

    select
        md5(
            cast(VendorID as string) ||
            cast(tpep_pickup_datetime as string) ||
            cast(tpep_dropoff_datetime as string)
        )                                               as trip_id,

        cast(VendorID as int)                           as vendor_id,
        cast(tpep_pickup_datetime as timestamp)         as pickup_datetime,
        cast(tpep_dropoff_datetime as timestamp)        as dropoff_datetime,
        cast(passenger_count as int)                    as passenger_count,
        cast(trip_distance as double)                   as trip_distance_miles,
        cast(fare_amount as double)                     as fare_amount_usd,
        cast(tip_amount as double)                      as tip_amount_usd,
        cast(total_amount as double)                    as total_amount_usd,
        cast(PULocationID as int)                       as pickup_location_id,
        cast(DOLocationID as int)                       as dropoff_location_id,
        cast(payment_type as int)                       as payment_type,

        cast(
            unix_timestamp(tpep_dropoff_datetime) -
            unix_timestamp(tpep_pickup_datetime)
            as int
        )                                               as trip_duration_seconds,

        current_timestamp()                             as _loaded_at

    from source

),

validated as (

    select * from cleaned
    where
        passenger_count > 0
        and passenger_count <= 8
        and trip_distance_miles > 0
        and trip_distance_miles < 500
        and fare_amount_usd > 0
        and fare_amount_usd < 1000
        and pickup_datetime < dropoff_datetime
        and trip_duration_seconds > 0
        and trip_duration_seconds < 86400

)

select * from validated