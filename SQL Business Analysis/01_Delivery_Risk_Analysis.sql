-- High Revenue, Low Profit Markets
-- Identify markets generating above-average revenue but below-average profit margin.
with market_performance as (
    select
        `Market` as market,
        count(distinct `Order Id`) as total_orders,
        sum(`Sales`) as revenue,
        sum(`Order Profit Per Order`) as profit,
        sum(`Order Profit Per Order`) /
            nullif(sum(`Sales`), 0) * 100 as profit_margin
    from supply_chain_orders
    group by `Market`
)
select
    market,
    total_orders,
    round(revenue, 2) as revenue,
    round(profit, 2) as profit,
    round(profit_margin, 2) as profit_margin
from market_performance
where revenue > (select avg(revenue) from market_performance)
  and profit_margin < (select avg(profit_margin) from market_performance)
order by revenue desc;

/* Insight: These markets are strategically important because they generate strong revenue but weak profitability. Management should investigate discounts, product mix, pricing, and operational costs.
*/

-- Top 10 Profitable Products Within Each Category
-- Identify the top 10 most profitable products in every category.
with product_profit as (
    select
        `Category Name` as category_name,
        `Product Name` as product_name,
        sum(`Order Profit Per Order`) as profit
    from supply_chain_orders
    group by `Category Name`, `Product Name`
),
ranked_products as (
    select
        *,
        row_number() over(
            partition by category_name
            order by profit desc
        ) as product_rank
    from product_profit
)
select
    category_name,
    product_name,
    round(profit, 2) as profit,
    product_rank
from ranked_products
where product_rank <= 10
order by category_name, product_rank;

/* Insight: These products are major profit contributors within their categories and should receive priority in inventory planning, availability, and promotional strategy.
*/

-- Market Revenue Contribution
-- What percentage of total company revenue comes from each market?
select
    `Market` as market,
    round(sum(`Sales`), 2) as revenue,
    round(
        sum(`Sales`) * 100.0 /
        sum(sum(`Sales`)) over(),
        2
    ) as revenue_contribution_pct
from supply_chain_orders
group by `Market`
order by revenue_contribution_pct desc;

/* Insight: This identifies revenue concentration. If a small number of markets contribute a large share of revenue, the company should avoid excessive dependency on those markets.
*/

-- Shipping Mode Delivery Risk
--  Which shipping modes have the highest late-delivery risk?
select
    `Shipping Mode` as shipping_mode,
    count(distinct `Order Id`) as total_orders,
    sum(`Late_delivery_risk`) as late_orders,
    round(
        sum(`Late_delivery_risk`) * 100.0 /
        count(*),
        2
    ) as late_delivery_pct,
    round(avg(`Days for shipping (real)`), 2) as avg_shipping_days,
    round(avg(`Days for shipment (scheduled)`), 2) as avg_scheduled_days
from supply_chain_orders
group by `Shipping Mode`
order by late_delivery_pct desc;

/* Insight: Shipping modes with high late-delivery risk require investigation of carriers, routes, capacity, and scheduling.
*/
