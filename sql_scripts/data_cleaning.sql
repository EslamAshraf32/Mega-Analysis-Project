-- check for duplicates
SELECT id, COUNT(*) FROM categories GROUP BY id HAVING COUNT(*) > 1;
SELECT id, COUNT(*) FROM customers GROUP BY id HAVING COUNT(*) > 1;
SELECT id, COUNT(*) FROM customer_sessions GROUP BY id HAVING COUNT(*) > 1;
SELECT id, COUNT(*) FROM discounts GROUP BY id HAVING COUNT(*) > 1;
SELECT id, COUNT(*) FROM inventory_movements GROUP BY id HAVING COUNT(*) > 1;
SELECT id, COUNT(*) FROM order_details GROUP BY id HAVING COUNT(*) > 1;
SELECT id, COUNT(*) FROM orders GROUP BY id HAVING COUNT(*) > 1;
SELECT id, COUNT(*) FROM payments GROUP BY id HAVING COUNT(*) > 1;
SELECT id, COUNT(*) FROM products GROUP BY id HAVING COUNT(*) > 1;
SELECT id, COUNT(*) FROM returns GROUP BY id HAVING COUNT(*) > 1;
SELECT id, COUNT(*) FROM reviews GROUP BY id HAVING COUNT(*) > 1;
SELECT id, COUNT(*) FROM shipping GROUP BY id HAVING COUNT(*) > 1;
SELECT id, COUNT(*) FROM suppliers GROUP BY id HAVING COUNT(*) > 1;
SELECT id, COUNT(*) FROM wishlists GROUP BY id HAVING COUNT(*) > 1;

-- check for nulls
SELECT * FROM customers
WHERE first_name IS NULL 
   OR last_name IS NULL 
   OR email IS NULL 
   OR phone IS NULL 
   OR registration_date IS NULL;

SELECT * FROM orders
WHERE customer_id IS NULL 
   OR order_date IS NULL 
   OR total_amount IS NULL 
   OR status IS NULL;

SELECT * FROM categories
WHERE id IS NULL
   OR name IS NULL
   OR description IS NULL
   OR parent_id IS NULL;

SELECT * FROM customer_sessions
WHERE id IS NULL
   OR customer_id IS NULL
   OR session_start IS NULL
   OR session_end IS NULL
   OR ip_address IS NULL;

SELECT * FROM discounts
WHERE id IS NULL
   OR code IS NULL
   OR percentage IS NULL
   OR start_date IS NULL
   OR end_date IS NULL
   OR is_active IS NULL
   OR product_id IS NULL
   OR category_id IS NULL;

SELECT * FROM inventory_movements
WHERE id IS NULL
   OR product_id IS NULL
   OR quantity IS NULL
   OR movement_type IS NULL
   OR movement_date IS NULL;

SELECT * FROM order_details
WHERE id IS NULL
   OR order_id IS NULL
   OR product_id IS NULL
   OR quantity IS NULL
   OR unit_price IS NULL;

SELECT * FROM orders
WHERE id IS NULL
   OR customer_id IS NULL
   OR order_date IS NULL
   OR total_amount IS NULL
   OR status IS NULL;

SELECT * FROM payments
WHERE id IS NULL
   OR order_id IS NULL
   OR customer_id IS NULL
   OR amount IS NULL
   OR payment_date IS NULL
   OR payment_method IS NULL
   OR status IS NULL;

SELECT * FROM products
WHERE id IS NULL
   OR name IS NULL
   OR description IS NULL
   OR price IS NULL
   OR category_id IS NULL
   OR supplier_id IS NULL
   OR sku IS NULL
   OR stock_quantity IS NULL;

SELECT * FROM returns
WHERE id IS NULL
   OR order_id IS NULL
   OR return_date IS NULL
   OR reason IS NULL
   OR status IS NULL;

SELECT * FROM reviews
WHERE id IS NULL
   OR product_id IS NULL
   OR customer_id IS NULL
   OR rating IS NULL
   OR comment IS NULL
   OR review_date IS NULL;

SELECT * FROM shipping
WHERE id IS NULL
   OR order_id IS NULL
   OR shipping_date IS NULL
   OR tracking_number IS NULL
   OR carrier IS NULL
   OR status IS NULL;

SELECT * FROM suppliers
WHERE id IS NULL
   OR name IS NULL
   OR contact_person IS NULL
   OR email IS NULL
   OR phone IS NULL
   OR address IS NULL;

SELECT * FROM wishlists
WHERE id IS NULL
   OR customer_id IS NULL
   OR product_id IS NULL
   OR added_date IS NULL;



-- Dynamic SQL to check all columns in a table

DECLARE @sql NVARCHAR(MAX) = '';
SELECT @sql = @sql + 
    'SELECT ''' + COLUMN_NAME + ''' AS column_name, COUNT(*) AS null_count ' +
    'FROM ' + TABLE_NAME + ' WHERE ' + COLUMN_NAME + ' IS NULL UNION ALL '
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'products';

SET @sql = LEFT(@sql, LEN(@sql) - 10); -- Remove last UNION ALL
EXEC sp_executesql @sql;




-- Dynamic SQL to check all tables in a database

DECLARE @sql NVARCHAR(MAX) = '';

SELECT @sql = @sql +
    'SELECT ''' + TABLE_NAME + ''' AS table_name, ''' + COLUMN_NAME + ''' AS column_name, COUNT(*) AS null_count ' +
    'FROM [' + TABLE_NAME + '] WHERE [' + COLUMN_NAME + '] IS NULL UNION ALL '
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'; 
SET @sql = LEFT(@sql, LEN(@sql) - 10); -- Remove last UNION ALL

EXEC sp_executesql @sql;



-- check for outliers

SELECT 
    id,
    name,
    price
FROM products
WHERE price > (
    SELECT AVG(price) + (3 * STDEV(price)) 
    FROM products
)
OR price < (
    SELECT AVG(price) - (3 * STDEV(price)) 
    FROM products
);


SELECT 
    id,
    customer_id,
    total_amount
FROM orders
WHERE total_amount > (
    SELECT AVG(total_amount) + (3 * STDEV(total_amount)) 
    FROM orders
)
OR total_amount < (
    SELECT AVG(total_amount) - (3 * STDEV(total_amount)) 
    FROM orders
);
