with source_data as (
    select 
        toUInt32(order_id) as order_id,
        toDateTime(order_ts) as order_ts,
        toUInt32(customer_id) as customer_id,
        toDecimal64(amount, 2) as amount,
        status
    from raw_orders
),

cleaned_data as (
    select 
        order_id,
        order_ts,
        customer_id,
        amount,
        status,
        -- Add data quality flags
        case 
            when amount < {{ var('min_order_amount') }} then 'low_amount'
            when amount > {{ var('max_order_amount') }} then 'high_amount'
            else 'normal'
        end as amount_quality_flag,
        case 
            when order_ts < now() - interval {{ var('data_freshness_hours') }} hour then 'stale'
            else 'fresh'
        end as data_freshness_flag
    from source_data
)

select * from cleaned_data