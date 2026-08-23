-- Highest-Risk Regions
-- Business Question: Which regions have the worst delivery performance?

select
    `Order Region` as order_region,
    count(distinct `Order Id`) as total_orders,
    round(avg(`Late_delivery_risk`) * 100, 2) as late_delivery_pct,
    round(avg(`Days for shipping (real)`), 2) as avg_shipping_days,
    round(avg(`Days for shipment (scheduled)`), 2) as avg_scheduled_days
from supply_chain_orders
group by `Order Region`
having count(distinct `Order Id`) >= 100
order by late_delivery_pct desc;

-- Insight: Regions with high late-delivery rates and longer shipping times should be investigated for carrier, route, and capacity problems.

-- Customer Segment Profitability
-- Business Question: Which customer segment creates the greatest financial value?

select
    `Customer Segment` as customer_segment,
    count(distinct `Order Customer Id`) as customers,
    count(distinct `Order Id`) as orders,
    round(sum(`Sales`), 2) as revenue,
    round(sum(`Order Profit Per Order`), 2) as profit,
    round(
        sum(`Order Profit Per Order`) /
        nullif(sum(`Sales`), 0) * 100,
        2
    ) as profit_margin
from supply_chain_orders
group by `Customer Segment`
order by profit desc;

-- Insight: This helps management understand which customer segments provide the strongest combination of revenue and profitability.

-- Market × Shipping Mode Risk
-- Business Question: Identify specific market and shipping-mode combinations creating the greatest delivery risk.

select
    `Market` as market,
    `Shipping Mode` as shipping_mode,
    count(distinct `Order Id`) as total_orders,
    round(avg(`Late_delivery_risk`) * 100, 2) as late_delivery_pct,
    round(avg(`Days for shipping (real)`), 2) as avg_shipping_days
from supply_chain_orders
group by `Market`, `Shipping Mode`
having count(distinct `Order Id`) >= 100
order by late_delivery_pct desc;

-- Insight: This is more actionable than analyzing markets or shipping modes separately because it identifies the exact operational combinations requiring intervention.

-- Pareto Analysis — Products Driving Profit
-- Business Question: Does a small number of products generate most of the company's profit?

with product_profit as (
    select
        `Product Name` as product_name,
        sum(`Order Profit Per Order`) as profit
    from supply_chain_orders
    group by `Product Name`
),
ranked_products as (
    select
        product_name,
        profit,
        sum(profit) over(
            order by profit desc
            rows unbounded preceding
        ) as cumulative_profit,
        sum(profit) over() as total_profit
    from product_profit
)
select
    product_name,
    round(profit, 2) as profit,
    round(
        cumulative_profit /
        nullif(total_profit, 0) * 100,
        2
    ) as cumulative_profit_pct
from ranked_products
order by profit desc;

-- Insight: If a relatively small group of products contributes a large percentage of profit, those products should receive stronger inventory and supply-chain protection.



