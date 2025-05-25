-- This creates a comprehensive customer feature set 

CREATE VIEW vw_CustomerFeatures AS
SELECT 
    c.id AS customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.registration_date,
    DATEDIFF(DAY, c.registration_date, GETDATE()) AS customer_tenure_days,
    
    -- Order behavior
    COUNT(DISTINCT o.id) AS total_orders,
    SUM(o.total_amount) AS total_spend,
    CASE WHEN COUNT(DISTINCT o.id) > 0 THEN SUM(o.total_amount)/COUNT(DISTINCT o.id) ELSE 0 END AS avg_order_value,
    MAX(o.order_date) AS last_order_date,
    DATEDIFF(DAY, MAX(o.order_date), GETDATE()) AS days_since_last_order,
    
    -- Return behavior
    COUNT(DISTINCT r.id) AS total_returns,
    CASE WHEN COUNT(DISTINCT o.id) > 0 THEN CAST(COUNT(DISTINCT r.id) AS FLOAT)/COUNT(DISTINCT o.id) ELSE 0 END AS return_rate,
    
    -- Session behavior
    COUNT(DISTINCT cs.id) AS total_sessions,
    AVG(DATEDIFF(MINUTE, cs.session_start, cs.session_end)) AS avg_session_duration,
    
    -- Wishlist behavior
    COUNT(DISTINCT w.id) AS wishlist_items,
    
    -- Payment behavior
    COUNT(DISTINCT CASE WHEN p.status = 'completed' THEN p.id END) AS successful_payments,
    COUNT(DISTINCT CASE WHEN p.status = 'failed' THEN p.id END) AS failed_payments,
    
    -- Calculate customer value metrics
    SUM(o.total_amount) / NULLIF(DATEDIFF(DAY, MIN(o.order_date), GETDATE()), 0) * 30 AS monthly_revenue,
    DATEDIFF(DAY, MIN(o.order_date), MAX(o.order_date)) / NULLIF(COUNT(DISTINCT o.id) - 1, 0) AS avg_days_between_orders
FROM 
    customers c
LEFT JOIN orders o ON c.id = o.customer_id
LEFT JOIN returns r ON o.id = r.order_id
LEFT JOIN customer_sessions cs ON c.id = cs.customer_id
LEFT JOIN wishlists w ON c.id = w.customer_id
LEFT JOIN payments p ON c.id = p.customer_id
GROUP BY 
    c.id, c.first_name, c.last_name, c.email, c.registration_date;



-- This creates a wide table with categories as columns

CREATE VIEW vw_CustomerCategoryPivot AS
WITH CategoryPurchases AS (
    SELECT 
        o.customer_id,
        p.category_id,
        c.name AS category_name,
        COUNT(DISTINCT o.id) AS purchase_count,
        SUM(od.quantity) AS items_purchased
    FROM 
        orders o
    JOIN order_details od ON o.id = od.order_id
    JOIN products p ON od.product_id = p.id
    JOIN categories c ON p.category_id = c.id
    GROUP BY 
        o.customer_id, p.category_id, c.name
)
SELECT 
    cp.customer_id,
    MAX(CASE WHEN cp.category_name = 'Adult' THEN cp.purchase_count ELSE 0 END) AS Adult_purchases,
    MAX(CASE WHEN cp.category_name = 'Almost' THEN cp.purchase_count ELSE 0 END) AS Almost_purchases,
    MAX(CASE WHEN cp.category_name = 'Base' THEN cp.purchase_count ELSE 0 END) AS Base_purchases,
	MAX(CASE WHEN cp.category_name = 'Born' THEN cp.purchase_count ELSE 0 END) AS Born_purchases,
	MAX(CASE WHEN cp.category_name = 'Carry' THEN cp.purchase_count ELSE 0 END) AS Carry_purchases,
	MAX(CASE WHEN cp.category_name = 'Choose' THEN cp.purchase_count ELSE 0 END) AS Choose_purchases,
	MAX(CASE WHEN cp.category_name = 'Energy' THEN cp.purchase_count ELSE 0 END) AS Energy_purchases,
	MAX(CASE WHEN cp.category_name = 'Fire' THEN cp.purchase_count ELSE 0 END) AS Fire_purchases,
	MAX(CASE WHEN cp.category_name = 'Free' THEN cp.purchase_count ELSE 0 END) AS Free_purchases,
	MAX(CASE WHEN cp.category_name = 'Game' THEN cp.purchase_count ELSE 0 END) AS Game_purchases,
	MAX(CASE WHEN cp.category_name = 'Glass' THEN cp.purchase_count ELSE 0 END) AS Glass_purchases,
	MAX(CASE WHEN cp.category_name = 'Half' THEN cp.purchase_count ELSE 0 END) AS Half_purchases,
	MAX(CASE WHEN cp.category_name = 'Himself' THEN cp.purchase_count ELSE 0 END) AS Himself_purchases,
	MAX(CASE WHEN cp.category_name = 'Hold' THEN cp.purchase_count ELSE 0 END) AS Hold_purchases,
	MAX(CASE WHEN cp.category_name = 'Large' THEN cp.purchase_count ELSE 0 END) AS Large_purchases,
	MAX(CASE WHEN cp.category_name = 'Letter' THEN cp.purchase_count ELSE 0 END) AS Letter_purchases,
	MAX(CASE WHEN cp.category_name = 'Marriage' THEN cp.purchase_count ELSE 0 END) AS Marriage_purchases,
	MAX(CASE WHEN cp.category_name = 'Mission' THEN cp.purchase_count ELSE 0 END) AS Mission_purchases,
	MAX(CASE WHEN cp.category_name = 'Onto' THEN cp.purchase_count ELSE 0 END) AS Onto_purchases,
	MAX(CASE WHEN cp.category_name = 'Or' THEN cp.purchase_count ELSE 0 END) AS Or_purchases,
	MAX(CASE WHEN cp.category_name = 'Over' THEN cp.purchase_count ELSE 0 END) AS Over_purchases,
	MAX(CASE WHEN cp.category_name = 'Part' THEN cp.purchase_count ELSE 0 END) AS Part_purchases,
	MAX(CASE WHEN cp.category_name = 'Program' THEN cp.purchase_count ELSE 0 END) AS Program_purchases,
	MAX(CASE WHEN cp.category_name = 'Recent' THEN cp.purchase_count ELSE 0 END) AS Recent_purchases,
	MAX(CASE WHEN cp.category_name = 'Remember' THEN cp.purchase_count ELSE 0 END) AS Remember_purchases,
	MAX(CASE WHEN cp.category_name = 'Share' THEN cp.purchase_count ELSE 0 END) AS Share_purchases,
	MAX(CASE WHEN cp.category_name = 'Speech' THEN cp.purchase_count ELSE 0 END) AS Speech_purchases,
	MAX(CASE WHEN cp.category_name = 'Table' THEN cp.purchase_count ELSE 0 END) AS Table_purchases,
	MAX(CASE WHEN cp.category_name = 'Who' THEN cp.purchase_count ELSE 0 END) AS Who_purchases,
	MAX(CASE WHEN cp.category_name = 'Window' THEN cp.purchase_count ELSE 0 END) AS Window_purchases,
   COUNT(DISTINCT cp.category_id) AS unique_categories_purchased
FROM 
    CategoryPurchases cp
GROUP BY 
    cp.customer_id;



--  CUSTOMER CHURN  DATASET

CREATE VIEW vw_CustomerChurnDataset AS
WITH ChurnDefinition AS (
    SELECT 
        c.id AS customer_id,
        CASE WHEN MAX(o.order_date) IS NULL OR DATEDIFF(DAY, MAX(o.order_date), GETDATE()) > 90 THEN 1 ELSE 0 END AS is_churned
    FROM 
        customers c
    LEFT JOIN orders o ON c.id = o.customer_id
    GROUP BY 
        c.id
)
SELECT 
    cf.customer_id,
    cf.customer_tenure_days,
    cf.total_orders,
    cf.total_spend,
    cf.avg_order_value,
    cf.days_since_last_order,
    cf.return_rate,
    cf.total_sessions,
    cf.avg_session_duration,
    cf.wishlist_items,
    cf.successful_payments,
    cf.failed_payments,
    cf.monthly_revenue,
    cf.avg_days_between_orders,
    ccp.unique_categories_purchased,
    ccp.Adult_purchases,
    ccp.Almost_purchases,
    ccp.Base_purchases,
	ccp.Born_purchases,
	ccp.Carry_purchases,
	ccp.Choose_purchases,
	ccp.Energy_purchases,
	ccp.Fire_purchases,
	ccp.Free_purchases,
	ccp.Game_purchases,
	ccp.Glass_purchases,
	ccp.Half_purchases,
	ccp.Himself_purchases,
	ccp.Hold_purchases,
	ccp.Large_purchases,
	ccp.Letter_purchases,
	ccp.Marriage_purchases,
	ccp.Mission_purchases,
	ccp.Onto_purchases,
	ccp.Or_purchases,
	ccp.Over_purchases,
	ccp.Part_purchases,
	ccp.Program_purchases,
	ccp.Recent_purchases,
	ccp.Remember_purchases,
	ccp.Share_purchases,
	ccp.Speech_purchases,
	ccp.Table_purchases,
	ccp.Who_purchases,
	ccp.Window_purchases,
    -- Target variable
    cd.is_churned
FROM 
    vw_CustomerFeatures cf
JOIN ChurnDefinition cd ON cf.customer_id = cd.customer_id
LEFT JOIN vw_CustomerCategoryPivot ccp ON cf.customer_id = ccp.customer_id;

-- VIEW THE FULL REPORT
SELECT * FROM vw_CustomerChurnDataset
ORDER BY customer_id;