-- High-Value Markets With High Delivery Risk
-- Business Question: Which markets have both high revenue and high delivery risk?

with market_metrics as (
    select
        `Market` as market,
        count(distinct `Order Id`) as orders,
        sum(`Sales`) as revenue,
        sum(`Order Profit Per Order`) as profit,
        avg(`Late_delivery_risk`) * 100 as late_pct
    from supply_chain_orders
    group by `Market`
)
select
    market,
    orders,
    round(revenue, 2) as revenue,
    round(profit, 2) as profit,
    round(late_pct, 2) as late_delivery_pct
from market_metrics
where revenue >= (select avg(revenue) from market_metrics)
  and late_pct >= (select avg(late_pct) from market_metrics)
order by revenue desc;

-- Insight: These markets should receive immediate attention because they combine substantial financial importance with operational risk.

-- Product Portfolio Classification
-- Business Question: Classify products into strategic groups based on revenue and profit.

with product_metrics as (
    select
        `Product Name` as product_name,
        sum(`Sales`) as revenue,
        sum(`Order Profit Per Order`) as profit
    from supply_chain_orders
    group by `Product Name`
),
benchmarks as (
    select
        avg(revenue) as avg_revenue,
        avg(profit) as avg_profit
    from product_metrics
)
select
    p.product_name,
    round(p.revenue, 2) as revenue,
    round(p.profit, 2) as profit,
    case
        when p.revenue >= b.avg_revenue
         and p.profit >= b.avg_profit
            then 'high revenue - high profit'
        when p.revenue >= b.avg_revenue
         and p.profit < b.avg_profit
            then 'high revenue - low profit'
        when p.revenue < b.avg_revenue
         and p.profit >= b.avg_profit
            then 'low revenue - high profit'
        else 'low revenue - low profit'
    end as product_segment
from product_metrics p
cross join benchmarks b
order by revenue desc;

/*Insight:
High revenue + high profit → Protect & Grow
High revenue + low profit → Optimize
Low revenue + high profit → Promote
Low revenue + low profit → Review
*/

-- Supply Chain Risk Score
-- Business Question: Create a single operational risk score for each market.

with market_metrics as (
    select
        `Market` as market,
        avg(`Late_delivery_risk`) * 100 as late_pct,
        avg(
            `Days for shipping (real)` -
            `Days for shipment (scheduled)`
        ) as avg_delay,
        avg(`Days for shipping (real)`) as avg_shipping_days
    from supply_chain_orders
    group by `Market`
)
select
    market,
    round(late_pct, 2) as late_pct,
    round(avg_delay, 2) as avg_delay,
    round(avg_shipping_days, 2) as avg_shipping_days,
    round(
        late_pct * 0.5 +
        greatest(avg_delay, 0) * 10 * 0.3 +
        avg_shipping_days * 0.2,
        2
    ) as supply_chain_risk_score
from market_metrics
order by supply_chain_risk_score desc;

-- Insight: Higher scores indicate markets where delivery reliability and shipping delays create greater operational risk.

-- Executive Supply Chain Health Score
-- Business Question: The CEO wants one consolidated market-level scorecard using revenue, profitability, delivery reliability, and order volume. Rank markets and identify those requiring management attention.

with market_metrics as (
    select
        `Market` as market,
        count(distinct `Order Id`) as orders,
        sum(`Sales`) as revenue,
        sum(`Order Profit Per Order`) as profit,
        sum(`Order Profit Per Order`) /
            nullif(sum(`Sales`), 0) * 100 as profit_margin,
        avg(`Late_delivery_risk`) * 100 as late_pct,
        avg(`Days for shipping (real)`) as avg_shipping_days
    from supply_chain_orders
    group by `Market`
),
scored_markets as (
    select
        *,
        ntile(5) over(order by revenue) as revenue_score,
        ntile(5) over(order by profit_margin) as profit_score,
        ntile(5) over(order by late_pct desc) as delivery_score,
        ntile(5) over(order by orders) as volume_score
    from market_metrics
),
final_scores as (
    select
        *,
        revenue_score +
        profit_score +
        delivery_score +
        volume_score as health_score
    from scored_markets
)
select
    market,
    orders,
    round(revenue, 2) as revenue,
    round(profit, 2) as profit,
    round(profit_margin, 2) as profit_margin,
    round(late_pct, 2) as late_delivery_pct,
    round(avg_shipping_days, 2) as avg_shipping_days,
    health_score,
    rank() over(
        order by health_score desc
    ) as market_rank,
    case
        when health_score <= 6 then 'critical'
        when health_score <= 10 then 'needs attention'
        when health_score <= 14 then 'stable'
        else 'strong'
    end as management_status
from final_scores
order by market_rank;

-- Insight: This creates an executive-level view combining financial and operational KPIs. Markets with weak scores can be prioritized for pricing, logistics, or operational improvement.