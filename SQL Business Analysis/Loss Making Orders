/* Finance wants to understand why certain orders generate negative profit. Identify loss-making orders and investigate whether they are associated with high discounts, 
expensive products, large quantities, specific markets, shipping modes, or categories. Quantify the financial impact and identify the major sources of losses. */

with loss_analysis as (
    select
        `Order Id` as order_id,
        `Market` as market,
        `Shipping Mode` as shipping_mode,
        `Category Name` as category,

        Sales as revenue,
        `Order Profit Per Order` as profit,
        `Order Item Discount` as discount,
        `Order Item Quantity` as quantity,
        `Product Price` as product_price,

        case
            when `Order Profit Per Order` < 0
                then 1
            else 0
        end as loss_order
    from supply_chain_orders
),
loss_summary as (
    select
        market,
        shipping_mode,
        category,
        count(*) as total_orders,
        sum(loss_order) as loss_orders,
        round(
            sum(loss_order) * 100.0 / count(*),
            2
        ) as loss_rate,
        round(sum(revenue), 2) as total_revenue,
        round(
            sum(
                case
                    when loss_order = 1 then profit
                    else 0
                end
            ),
            2
        ) as total_loss,
        round(avg(
            case
                when loss_order = 1 then discount
            end
        ) * 100, 2) as avg_discount,

        round(avg(
            case
                when loss_order = 1 then product_price
            end
        ), 2) as avg_product_price,

        round(avg(
            case
                when loss_order = 1 then quantity
            end
        ), 2) as avg_quantity

    from loss_analysis

    group by
        market,
        shipping_mode,
        category
)
select
    market,
    shipping_mode,
    category,

    total_orders,
    loss_orders,
    loss_rate,

    total_revenue,
    total_loss,

    avg_discount,
    avg_product_price,
    avg_quantity,

    case
        when total_loss < -10000
             and avg_discount >= 0.20
            then 'Critical - High Discount Loss'
        when total_loss < -10000
             and avg_quantity >= 3
            then 'High Risk - Volume Driven Loss'
        when total_loss < -10000
            then 'Critical - Major Loss Source'
        when loss_rate >= 20
            then 'High Loss Rate'
        else 'Monitor'
    end as loss_category
from loss_summary
where loss_orders > 0
order by
    total_loss asc,
    loss_orders desc;
    
-- Quantify the overall financial impact
select
    count(*) as total_orders,
    sum(case
        when `Order Profit Per Order` < 0 then 1
        else 0
    end) as loss_orders,
    round(
        sum(case
            when `Order Profit Per Order` < 0
            then `Order Profit Per Order`
            else 0
        end),
        2
    ) as total_loss,
    round(
        sum(case
            when `Order Profit Per Order` < 0
            then Sales
            else 0
        end),
        2
    ) as revenue_from_loss_orders
from supply_chain_orders;

/* Loss-making orders should be investigated by examining discount levels, order quantity, product economics, market, shipping mode, and category together. 
The highest priority should be combinations generating a large absolute loss, rather than simply combinations with the highest loss percentage. 
High-discount loss orders indicate potential pricing pressure, while high-volume loss orders can magnify financial impact. Markets, shipping modes, 
and categories with concentrated losses should be reviewed for regional pricing, fulfillment, and product-level cost issues. */

