-- Check for Impossible or Suspicious Values

-- Negative or zero prices
SELECT * FROM products
WHERE price <= 0;

-- Orders with zero or negative total
SELECT * FROM orders
WHERE total_amount <= 0;

-- Inventory movements with zero quantity
SELECT * FROM inventory_movements
WHERE quantity = 0;

-- customers with no orders
select * from customers c where not exists (select 1 from orders o where c.id = o.customer_id)



-- Check Foreign Key Violations

-- Orders without valid customers
SELECT * FROM orders
WHERE customer_id NOT IN (SELECT id FROM customers);

-- Order details with invalid products
SELECT * FROM order_details
WHERE product_id NOT IN (SELECT id FROM products);


-- Check for Unused Products
SELECT * FROM products p
WHERE NOT EXISTS (SELECT 1 FROM order_details od WHERE od.product_id = p.id)
  AND NOT EXISTS (SELECT 1 FROM wishlists w WHERE w.product_id = p.id)
  AND NOT EXISTS (SELECT 1 FROM reviews r WHERE r.product_id = p.id);
