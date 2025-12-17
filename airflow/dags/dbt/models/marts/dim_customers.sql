with stg_orders as (
    select * from {{ ref('stg_orders') }}
),

customer_metrics as (
    select 
        customer_id,
        min(order_ts) as first_order_date,
        max(order_ts) as last_order_date,
        count(*) as total_orders,
        sum(amount) as total_amount,
        avg(amount) as avg_order_amount,
        count(case when status = 'paid' then 1 end) as paid_orders,
        count(case when status = 'cancelled' then 1 end) as cancelled_orders,
        sum(case when status = 'paid' then amount else 0 end) as total_paid_amount
    from stg_orders
    group by customer_id
),

customer_segments as (
    select 
        customer_id,
        first_order_date,
        last_order_date,
        total_orders,
        total_amount,
        avg_order_amount,
        paid_orders,
        cancelled_orders,
        total_paid_amount,
        -- Customer segmentation
        case 
            when total_paid_amount >= 1000 then 'VIP'
            when total_paid_amount >= 500 then 'Premium'
            when total_paid_amount >= 100 then 'Regular'
            else 'New'
        end as customer_segment,
        -- Customer lifecycle stage
        case 
            when dateDiff('day', first_order_date, last_order_date) <= 30 then 'New'
            when dateDiff('day', last_order_date, now()) <= 30 then 'Active'
            when dateDiff('day', last_order_date, now()) <= 90 then 'At Risk'
            else 'Inactive'
        end as lifecycle_stage,
        -- Order frequency
        case 
            when total_orders = 1 then 'One-time'
            when total_orders <= 5 then 'Occasional'
            when total_orders <= 20 then 'Regular'
            else 'Frequent'
        end as order_frequency
    from customer_metrics
)

select * from customer_segments