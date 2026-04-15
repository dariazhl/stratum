{{
  config(
    materialized='table',
    file_format='delta'
  )
}}

select
    pickup_location_id,
    date_trunc('hour', pickup_datetime)         as pickup_hour,
    dayofweek(pickup_datetime)                  as day_of_week,
    count(*)                                    as total_trips,
    avg(trip_distance_miles)                    as avg_distance_miles,
    avg(trip_duration_seconds) / 60             as avg_duration_minutes,
    avg(fare_amount_usd)                        as avg_fare_usd,
    sum(total_amount_usd)                       as total_revenue_usd,
    avg(tip_amount_usd /
        nullif(fare_amount_usd, 0))             as avg_tip_rate,
    current_timestamp()                         as _calculated_at

from {{ ref('stg_nyc_taxi_yellow') }}

group by
    pickup_location_id,
    date_trunc('hour', pickup_datetime),
    dayofweek(pickup_datetime)