# Import core libraries for Vanna AI, Flask, database access, and SQL parsing
from vanna.remote import VannaDefault
from vanna.flask import VannaFlaskApp
import pyodbc
import pandas as pd
import re  # Used for fixing SQL string literal issues

# Initialize the Vanna AI model for our ecommerce database project
vn = VannaDefault(model='myecommerce', api_key='09a9a328d55343fd9ab3261d30b0731c')

# Connection string to connect to our local SQL Server database
connection_string = (
    "Driver={SQL Server};"
    "Server=DESKTOP-0ID224E\\SQLEXPRESS;"
    "Database=ecommerce_db1;"
    "Trusted_Connection=yes;"
)

# Automatically fix common SQL syntax issues (e.g., unquoted string literals)
def fix_sql_literals(sql):
    # Regex to find unquoted values (e.g., status != cancelled) and wrap them with single quotes
    pattern = r"(=|!=|<>|<|>)\s*([a-zA-Z_]+)\b(?!\s*\.)"
    return re.sub(pattern, lambda m: f"{m.group(1)} '{m.group(2)}'", sql)

# Function to execute SQL queries using pandas and pyodbc
def run_sql(sql: str):
    print("🛠️ Original SQL:", sql)
    sql = fix_sql_literals(sql)  # Apply auto-fix before executing
    print("✅ Fixed SQL:", sql)
    with pyodbc.connect(connection_string) as conn:
        return pd.read_sql(sql, conn)

# Register the custom run_sql function with the Vanna instance
vn.run_sql = run_sql
vn.run_sql_is_set = True

# Function to train Vanna on our database schema (tables + columns)
def train_database_schema():
    # Get all table names in the database
    tables = vn.run_sql("""
        SELECT TABLE_NAME 
        FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_TYPE = 'BASE TABLE'
    """)
    
    # For each table, get its column metadata and build a CREATE TABLE definition
    for table in tables['TABLE_NAME']:  
        columns = vn.run_sql(f"""
            SELECT 
                COLUMN_NAME, DATA_TYPE, 
                CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_NAME = '{table}'
            ORDER BY ORDINAL_POSITION
        """)
        
        column_defs = []
        for _, col in columns.iterrows():  
            col_def = f"{col['COLUMN_NAME']} {col['DATA_TYPE']}"
            if col['CHARACTER_MAXIMUM_LENGTH']:
                # Add size for variable-length types like varchar
                if col['DATA_TYPE'].lower() in ['varchar','char','nvarchar','nchar']:
                    col_def += f"({int(col['CHARACTER_MAXIMUM_LENGTH'])})"
            if col['IS_NULLABLE'] == 'NO':
                col_def += " NOT NULL"
            column_defs.append(col_def)
        
        # Build and train the CREATE TABLE statement
        ddl = f"CREATE TABLE {table} (\n    " + ",\n    ".join(column_defs) + "\n);"
        vn.train(ddl=ddl)
        print(f"✓ Trained table: {table}")

# Provide example questions and the correct SQL to train the model with business logic
def train_example_queries():
    examples = [
        {
            "question": "Calculate total revenue",
            "sql": """
            SELECT SUM(total_amount) AS total_revenue 
            FROM orders 
            WHERE status NOT IN ('cancelled', 'returned')
            """
        },
        {
            "question": "How many customers do we have?",
            "sql": "SELECT COUNT(*) FROM customers"
        },
        {
            "question": "Show top 5 products by sales",
            "sql": """
            SELECT TOP 5 p.product_name, SUM(od.quantity * od.unit_price) as total_sales
            FROM products p
            JOIN order_details od ON p.product_id = od.product_id
            GROUP BY p.product_name
            ORDER BY total_sales DESC
            """
        }
    ]
    
    # Train Vanna with the provided example question-to-SQL pairs
    for ex in examples:
        vn.train(question=ex["question"], sql=ex["sql"])

# Run the application setup and launch
try:
    # Test that the SQL connection works
    test_result = vn.run_sql("SELECT 1 AS test")
    print("✅ Connection successful! Test result:")
    print(test_result.head())  
    
    # Train Vanna with the database schema and business examples
    train_database_schema()
    train_example_queries()
    
    # Test Vanna's SQL generation with a known question
    revenue_sql = vn.generate_sql("Calculate total revenue")
    print("\nGenerated revenue query:")
    print(revenue_sql)
    
    # Run the generated SQL and display the result
    revenue = vn.run_sql(revenue_sql)
    print("\nRevenue calculation result:")
    print(revenue)
    
    # Launch the Flask web app to interact with Vanna through a UI
    app = VannaFlaskApp(vn, allow_llm_to_see_data=True)
    app.run()
    
except Exception as e:
    # Handle and display any error that occurs during setup or execution
    print("❌ Error:", e)
