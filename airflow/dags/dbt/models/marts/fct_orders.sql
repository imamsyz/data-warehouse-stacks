with stg_orders as (
    select * from {{ ref('stg_orders') }}
),

paid_orders as (
    select 
        order_id,
        customer_id,
        order_ts,
        amount,
        status,
        amount_quality_flag,
        data_freshness_flag
    from stg_orders
    where status = 'paid'
),

enriched_orders as (
    select 
        order_id,
        customer_id,
        order_ts,
        amount,
        status,
        amount_quality_flag,
        data_freshness_flag,
        -- Add business metrics
        case 
            when amount >= 100 then 'high_value'
            when amount >= 50 then 'medium_value'
            else 'low_value'
        end as order_value_tier,
        extract(year from order_ts) as order_year,
        extract(month from order_ts) as order_month,
        extract(dayofweek from order_ts) as order_day_of_week
    from paid_orders
)

select * from enriched_orders