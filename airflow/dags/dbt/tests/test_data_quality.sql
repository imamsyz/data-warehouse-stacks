-- Test for data quality issues in raw_orders
with raw_data as (
    select * from {{ ref('raw_orders') }}
),

quality_issues as (
    select 
        'duplicate_order_ids' as issue_type,
        count(*) as issue_count
    from raw_data
    group by order_id
    having count(*) > 1
    
    union all
    
    select 
        'negative_amounts' as issue_type,
        count(*) as issue_count
    from raw_data
    where amount < 0
    
    union all
    
    select 
        'future_dates' as issue_type,
        count(*) as issue_count
    from raw_data
    where order_ts > now()
    
    union all
    
    select 
        'invalid_status' as issue_type,
        count(*) as issue_count
    from raw_data
    where status not in ('paid', 'pending', 'cancelled')
)

select 
    issue_type,
    issue_count
from quality_issues
where issue_count > 0
