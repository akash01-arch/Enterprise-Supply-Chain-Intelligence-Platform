-- High-Sales Loss-Making Products
-- Find products with significant sales but negative profit.
select
    `Product Name` as product_name,
    round(sum(`Sales`), 2) as revenue,
    round(sum(`Order Profit Per Order`), 2) as profit,
    round(
        sum(`Order Profit Per Order`) /
        nullif(sum(`Sales`), 0) * 100,
        2
    ) as profit_margin,
    round(avg(`Order Item Discount Rate`) * 100, 2) as avg_discount
from supply_chain_orders
group by `Product Name`
having sum(`Sales`) > 1000
   and sum(`Order Profit Per Order`) < 0
order by revenue desc;

-- Insight: High-sales loss-making products are immediate candidates for pricing, discount, procurement, and shipping-cost reviews.

-- Market Profitability Ranking
-- Rank markets from most to least profitable.
select
    `Market` as market,
    round(sum(`Sales`), 2) as revenue,
    round(sum(`Order Profit Per Order`), 2) as profit,
    round(
        sum(`Order Profit Per Order`) /
        nullif(sum(`Sales`), 0) * 100,
        2
    ) as profit_margin,
    dense_rank() over(
        order by
        sum(`Order Profit Per Order`) /
        nullif(sum(`Sales`), 0) desc
    ) as profitability_rank
from supply_chain_orders
group by `Market`
order by profitability_rank;

-- Insight: This gives management a clear profitability benchmark across markets and highlights markets requiring financial improvement.

-- Top 20 Customers by Profit
--  Which customers generate the greatest financial value?
select
    `Order Customer Id` as customer_id,
    count(distinct `Order Id`) as total_orders,
    round(sum(`Sales`), 2) as revenue,
    round(sum(`Order Profit Per Order`), 2) as profit,
    round(
        sum(`Sales`) /
        nullif(count(distinct `Order Id`), 0),
        2
    ) as avg_order_value,
    rank() over(
        order by sum(`Order Profit Per Order`) desc
    ) as customer_rank
from supply_chain_orders
group by `Order Customer Id`
order by customer_rank
limit 20;

-- Insight: High-profit customers are strong candidates for retention programs, personalized offers, and premium customer service.

-- Category Performance & Delivery Risk
--  Which product categories combine strong financial performance with poor delivery reliability?
select
    `Category Name` as category_name,
    count(distinct `Order Id`) as total_orders,
    round(sum(`Sales`), 2) as revenue,
    round(sum(`Order Profit Per Order`), 2) as profit,
    round(
        sum(`Order Profit Per Order`) /
        nullif(sum(`Sales`), 0) * 100,
        2
    ) as profit_margin,
    round(avg(`Late_delivery_risk`) * 100, 2) as late_delivery_pct
from supply_chain_orders
group by `Category Name`
order by revenue desc;



