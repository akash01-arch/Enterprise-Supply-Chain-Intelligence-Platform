-- Year-over-Year Revenue Growth
-- Business Question: How has revenue changed year over year?

with yearly_revenue as (
    select
        year(str_to_date(`order date (DateOrders)`, '%m/%d/%Y %H:%i')) as order_year,
        sum(`Sales`) as revenue
    from supply_chain_orders
    group by year(str_to_date(`order date (DateOrders)`, '%m/%d/%Y %H:%i'))
)
select
    order_year,
    round(revenue, 2) as revenue,
    round(
        (revenue - lag(revenue) over(order by order_year)) /
        nullif(lag(revenue) over(order by order_year), 0) * 100,
        2
    ) as yoy_growth_pct
from yearly_revenue
order by order_year;

-- Insight: This identifies periods of growth or decline and allows management to investigate the underlying business drivers.

-- Monthly Revenue Trend
-- Business Question: Identify monthly revenue patterns and short-term trends.
with monthly_revenue as (
    select
        year(str_to_date(`order date (DateOrders)`, '%m/%d/%Y %H:%i')) as order_year,
        month(str_to_date(`order date (DateOrders)`, '%m/%d/%Y %H:%i')) as order_month,
        sum(`Sales`) as revenue
    from supply_chain_orders
    group by
        year(str_to_date(`order date (DateOrders)`, '%m/%d/%Y %H:%i')),
        month(str_to_date(`order date (DateOrders)`, '%m/%d/%Y %H:%i'))
)
select
    order_year,
    order_month,
    round(revenue, 2) as revenue,
    round(
        avg(revenue) over(
            order by order_year, order_month
            rows between 2 preceding and current row
        ),
        2
    ) as three_month_avg
from monthly_revenue
order by order_year, order_month;

-- Insight: The three-month moving average reduces short-term noise and highlights sustained revenue trends.

-- Discount vs Profitability
-- Business Question: Does higher discounting negatively affect profitability?
select
    case
        when `Order Item Discount Rate` = 0
            then 'no discount'
        when `Order Item Discount Rate` <= 0.10
            then 'low discount'
        when `Order Item Discount Rate` <= 0.20
            then 'medium discount'
        else 'high discount'
    end as discount_band,
    count(distinct `Order Id`) as total_orders,
    round(sum(`Sales`), 2) as revenue,
    round(sum(`Order Profit Per Order`), 2) as profit,
    round(
        sum(`Order Profit Per Order`) /
        nullif(sum(`Sales`), 0) * 100,
        2
    ) as profit_margin
from supply_chain_orders
group by discount_band
order by profit_margin desc;

-- insight: If profit margin falls as discounts increase, the company should review promotional thresholds and avoid unnecessary discounting.

-- High-Value Orders With Delivery Risk
-- Business Question: Identify high-value orders that are at risk of late delivery.

select
    `Order Id` as order_id,
    round(`Order Item Total`, 2) as order_value,
    `Market` as market,
    `Shipping Mode` as shipping_mode,
    `Category Name` as category_name,
    `Late_delivery_risk` as late_delivery_risk,
    `Days for shipping (real)` as actual_shipping_days,
    `Days for shipment (scheduled)` as scheduled_shipping_days
from supply_chain_orders
where `Late_delivery_risk` = 1
order by `Order Item Total` desc
limit 100;

-- Insight: High-value orders with delivery risk should receive priority monitoring because delays can create significant financial and customer impact.