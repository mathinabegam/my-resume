create database capstone;
use capstone;
use capstone;
rename table `customers id` to customers,
`order` to orders,
procudess to products,
srores to stores,
staffss to staff,
stockss to stock;
-- 3. Inner Join for Order Details
SELECT o.Order_id, o.Order_date, o.Customer_id,
       p.Product_id, p.Product_name,
       oi.Quantity, oi.`Iist_price`, oi.Discount, oi.`Total price`
FROM orders o
INNER JOIN order_items oi ON o.Order_id = oi.Order_id
INNER JOIN products p ON oi.Product_id = p.Product_id;

-- 4. Total Sales by Store
SELECT o.Store_id, s.Store_name,
       SUM(oi.`Total price`) AS total_sales
FROM orders o
JOIN order_items oi ON o.Order_id = oi.Order_id
JOIN stores s ON o.Store_id = s.Store_id
GROUP BY o.Store_id, s.Store_name
ORDER BY total_sales DESC;

-- 5. Top 5 Selling Products
SELECT p.Product_id, p.Product_name,
       SUM(oi.Quantity) AS total_qty
FROM order_items oi
JOIN products p ON oi.Product_id = p.Product_id
GROUP BY p.Product_id, p.Product_name
ORDER BY total_qty DESC
LIMIT 5;

-- 6. Customer Purchase Summary
SELECT o.Customer_id,
       COUNT(DISTINCT o.Order_id) AS total_orders,
       SUM(oi.Quantity) AS total_items,
       SUM(oi.`Total price`) AS total_revenue
FROM orders o
JOIN order_items oi ON o.Order_id = oi.Order_id
GROUP BY o.Customer_id
ORDER BY total_revenue DESC;

-- 7. Segment Customers by Total Spend
SELECT Customer_id, total_spend,
  CASE
    WHEN total_spend < 5000  THEN 'Low'
    WHEN total_spend < 15000 THEN 'Medium'
    ELSE 'High'
  END AS spending_segment
FROM (
  SELECT o.Customer_id, SUM(oi.`Total price`) AS total_spend
  FROM orders o
  JOIN order_items oi ON o.Order_id = oi.Order_id
  GROUP BY o.Customer_id
) t
ORDER BY total_spend DESC;

-- 8. Staff Performance Analysis
SELECT st.Staff_id,
       CONCAT(st.First_name, ' ', st.Last_name) AS staff_name,
       COUNT(DISTINCT o.Order_id) AS orders_handled,
       SUM(oi.`Total price`) AS total_revenue
FROM staff st
JOIN orders o ON st.Staff_id = o.Staff_id
JOIN order_items oi ON o.Order_id = oi.Order_id
GROUP BY st.Staff_id, st.First_name, st.Last_name
ORDER BY total_revenue DESC;

-- 9. Stock Alert Query
SELECT k.Store_id, s.Store_name,
       p.Product_id, p.Product_name, k.Quantity
FROM stock k
JOIN products p ON k.Product_id = p.Product_id
JOIN stores s ON k.Store_id = s.Store_id
WHERE k.Quantity < 10
ORDER BY k.Quantity;

-- 10. Final Segmentation Table
CREATE TABLE IF NOT EXISTS customer_segments (
  customer_id INT PRIMARY KEY,
  total_spend DOUBLE,
  total_orders INT,
  cluster_id INT,
  segment_label VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

## primary key
ALTER TABLE brands ADD PRIMARY KEY (Brand_id);
ALTER TABLE category ADD PRIMARY KEY (Category_id);
ALTER TABLE customers ADD PRIMARY KEY (Customer_id);
ALTER TABLE stores ADD PRIMARY KEY (Store_id);
ALTER TABLE staff ADD PRIMARY KEY (Staff_id);
ALTER TABLE products ADD PRIMARY KEY (Product_id);
ALTER TABLE orders ADD PRIMARY KEY (Order_id);
ALTER TABLE order_items ADD PRIMARY KEY (Order_id, Item_id);
ALTER TABLE stock ADD PRIMARY KEY (Store_id, Product_id);
## foreing key
ALTER TABLE products ADD FOREIGN KEY (Brand_id) REFERENCES brands(Brand_id);
ALTER TABLE products ADD FOREIGN KEY (Category_id) REFERENCES category(Category_id);
ALTER TABLE staff ADD FOREIGN KEY (Store_id) REFERENCES stores(Store_id);
ALTER TABLE orders ADD FOREIGN KEY (Customer_id) REFERENCES customers(Customer_id);
ALTER TABLE orders ADD FOREIGN KEY (Store_id) REFERENCES stores(Store_id);
ALTER TABLE orders ADD FOREIGN KEY (Staff_id) REFERENCES staff(Staff_id);
ALTER TABLE order_items ADD FOREIGN KEY (Order_id) REFERENCES orders(Order_id);
ALTER TABLE order_items ADD FOREIGN KEY (Product_id) REFERENCES products(Product_id);
ALTER TABLE stock ADD FOREIGN KEY (Store_id) REFERENCES stores(Store_id);
ALTER TABLE stock ADD FOREIGN KEY (Product_id) REFERENCES products(Product_id);
ALTER TABLE customer_segments ADD FOREIGN KEY (customer_id) REFERENCES customers(Customer_id);
USE capstone;
