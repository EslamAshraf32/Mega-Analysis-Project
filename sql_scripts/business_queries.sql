-- Identify customers with the highest number of orders.

SELECT 
	RANK() OVER (ORDER BY COUNT(o.id) DESC) AS rank_by_orders,
    c.id AS customer_id,
    c.first_name + ' ' + c.last_name AS customer_name,
    c.email,
    COUNT(o.id) AS num_orders,
    SUM(o.total_amount) AS total_spend,
    AVG(o.total_amount) AS avg_order_value,
    CAST(MIN(o.order_date) AS DATE) AS first_order_date,
    CAST(MAX(o.order_date) AS DATE) AS last_order_date
FROM customers c
JOIN orders o ON c.id = o.customer_id
GROUP BY c.id, c.first_name, c.last_name, c.email
ORDER BY num_orders DESC;



-- Recommend products frequently bought together with items in customer wishlists.

CREATE PROCEDURE sp_GetFrequentlyBoughtWithWishlistProducts
AS
BEGIN
    -- CTE for wishlisted products per customer
    WITH WishlistProducts AS (
        SELECT customer_id, product_id
        FROM wishlists
    ),

    -- Orders made by those customers
    CustomerOrders AS (
        SELECT o.customer_id, od.product_id
        FROM orders o
        INNER JOIN order_details od ON o.id = od.order_id
    ),

    -- Join to find frequently bought-together items
    ProductsBoughtWithWishlist AS (
        SELECT 
            wp.product_id AS wishlist_product_id,
            co.product_id AS bought_product_id,
            COUNT(*) AS times_bought_together
        FROM WishlistProducts wp
        INNER JOIN CustomerOrders co 
            ON wp.customer_id = co.customer_id
            AND wp.product_id <> co.product_id
        GROUP BY wp.product_id, co.product_id
    )

    -- Return with product names
    SELECT 
        pbw.wishlist_product_id,
        wp.name AS wishlist_product_name,
        pbw.bought_product_id,
        bp.name AS bought_product_name,
        pbw.times_bought_together
    FROM ProductsBoughtWithWishlist pbw
   INNER JOIN products wp ON wp.id = pbw.wishlist_product_id
   INNER JOIN products bp ON bp.id = pbw.bought_product_id
    ORDER BY 
        pbw.times_bought_together DESC;
END;
 

EXEC sp_GetFrequentlyBoughtWithWishlistProducts;



-- Calculate the time taken to deliver orders in days.
SELECT
	o.id AS order_id,
	c.first_name + ' ' + c.last_name AS customer_name,
	o.order_date,
	s.shipping_date,
	DATEDIFF(day, o.order_date, s.shipping_date) AS delivery_days,
	CASE
		WHEN DATEDIFF(day, o.order_date, s.shipping_date) <= 3 Then 'Fast'
		WHEN DATEDIFF(day, o.order_date, s.shipping_date) <= 7 THEN 'Standard'
		ELSE 'Slow'
	END AS delivery_speed
from orders o 
INNER JOIN customers c on o.customer_id = c.id
INNER JOIN shipping s on o.id = s.order_id
Where s.status = 'delivered'
Order by delivery_days DESC;



-- =============================================
-- 1. TOTAL REVENUE CALCULATION
-- (All completed orders, excluding cancellations)
-- =============================================
SELECT 
    ROUND(SUM(od.quantity * od.unit_price), 2) AS total_sales_revenue,
    COUNT(DISTINCT o.id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    ROUND(SUM(od.quantity * od.unit_price) / NULLIF(COUNT(DISTINCT o.id), 0), 2) AS avg_order_value
FROM 
    orders o
JOIN 
    order_details od ON o.id = od.order_id
WHERE 
    o.status != 'cancelled';

-- =============================================
-- 2. TOP 5 PRODUCTS BY SALES VOLUME
-- (Ranked by units sold, with revenue)
-- =============================================
SELECT TOP 5 
    p.id AS product_id,
    p.name AS product_name,
    SUM(od.quantity) AS total_units_sold,
    ROUND(SUM(od.quantity * od.unit_price), 2) AS total_revenue
FROM 
    order_details od
JOIN 
    products p ON od.product_id = p.id
JOIN 
    orders o ON od.order_id = o.id
WHERE 
    o.status != 'cancelled'
GROUP BY 
    p.id, p.name
ORDER BY 
    total_units_sold DESC;

-- =============================================
-- 3. 30-DAY CUSTOMER RETENTION RATE
-- (% of customers who repurchased within 30 days)
-- =============================================
WITH 
-- First purchase date per valid customer
FirstPurchase AS (
    SELECT 
        customer_id, 
        MIN(order_date) AS first_purchase_date
    FROM 
        orders
    WHERE 
        status != 'cancelled'
        AND customer_id NOT LIKE 'test%'  -- Exclude test accounts
    GROUP BY 
        customer_id
),

-- Customers who made a follow-up purchase within 30 days
RetainedCustomers AS (
    SELECT DISTINCT 
        o.customer_id
    FROM 
        orders o
    JOIN 
        FirstPurchase fp ON o.customer_id = fp.customer_id
    WHERE 
        o.order_date > fp.first_purchase_date  -- Exclude same-day purchases
        AND o.order_date <= DATEADD(day, 30, fp.first_purchase_date)
        AND o.status != 'cancelled'
)

-- Final retention rate calculation
SELECT 
    COUNT(DISTINCT fp.customer_id) AS total_customers,
    COUNT(DISTINCT rc.customer_id) AS retained_customers,
    ROUND(COUNT(DISTINCT rc.customer_id) * 100.0 / 
          NULLIF(COUNT(DISTINCT fp.customer_id), 0), 1) AS retention_rate_pct
FROM 
    FirstPurchase fp
LEFT JOIN 
    RetainedCustomers rc ON fp.customer_id = rc.customer_id;






-- Generate an alert for products with stock quantities below 20 units

SELECT
    RANK() OVER (ORDER BY p.stock_quantity ASC) AS stock_rank,
    p.id AS product_id,
    p.name AS product_name,
    p.stock_quantity,
    c.name AS category_name,
    s.name AS supplier_name,
    p.price,
    CASE 
        WHEN p.stock_quantity < 20 THEN 'Low'
        ELSE 'OK'
    END AS stock_status
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
LEFT JOIN suppliers s ON p.supplier_id = s.id
ORDER BY p.stock_quantity ASC;






--Track inventory turnover trends using a 30-day moving average

WITH DailySales AS (
    SELECT 
        product_id,
        CAST(movement_date AS DATE) AS sale_date,
        SUM(-quantity) AS daily_units_sold  -- Convert negative to positive sales
    FROM 
        inventory_movements
    WHERE 
        movement_type = 'sale'
    GROUP BY 
        product_id, CAST(movement_date AS DATE)
)

SELECT 
    product_id,
    sale_date,
    daily_units_sold,
    AVG(daily_units_sold * 1.0) OVER (
        PARTITION BY product_id 
        ORDER BY sale_date
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS moving_avg_30day
FROM 
    DailySales
ORDER BY 
    product_id, sale_date;





--Determine the percentage of orders that used a discount

WITH DiscountedOrders AS (
    SELECT DISTINCT od.order_id
    FROM order_details od
    JOIN discounts d ON od.product_id = d.product_id
    JOIN orders o ON od.order_id = o.id
    WHERE 
        d.is_active = 1
)

-- Final percentage calculation
SELECT 
    COUNT(DISTINCT do.order_id) AS discounted_orders,
    (SELECT COUNT(DISTINCT id) FROM orders) AS total_orders,
    ROUND(
        COUNT(DISTINCT do.order_id) * 100.0 / 
        NULLIF((SELECT COUNT(DISTINCT id) FROM orders), 0), 2
    ) AS discount_usage_percentage
FROM 
    DiscountedOrders do;





   --Calculate the average rating for each product.
select
p.id as Product_id,
p.name as Product_name,
avg(r.rating) as average_rating
from products p 
inner join reviews r
on p.id=r.product_id
group by p.name ,p.id


-- Find pairs of products commonly bought together in the same order.

SELECT
    od1.product_id AS product_1,
    od2.product_id AS product_2,
    COUNT(*) AS times_bought_together
FROM
    order_details od1
JOIN
    order_details od2
    ON od1.order_id = od2.order_id AND od1.product_id < od2.product_id
GROUP BY
    od1.product_id, od2.product_id
ORDER BY
    times_bought_together DESC;

	--Identify customers who have purchased every product in a specific category
SELECT 
    c.id AS customer_id,
    c.first_name,
    c.last_name,
    cat.id AS category_id,
    cat.name AS category_name
FROM 
    customers c
    JOIN orders o ON c.id = o.customer_id
    JOIN order_details od ON o.id = od.order_id
    JOIN products p ON od.product_id = p.id
    JOIN categories cat ON p.category_id = cat.id
WHERE 
    cat.name = 'Window' -- Replace with the desired category name
GROUP BY 
    c.id, c.first_name, c.last_name, cat.id, cat.name
