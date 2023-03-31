## Business questions:
### 1. What is the total amount each customer spent at the restaurant?
```sql
SELECT customer_id, SUM(price) AS total_spent
FROM dd_sales
JOIN dd_menu
    ON dd_sales.product_id = dd_menu.product_id
GROUP BY customer_id
```
Answer:
* customer A spent $76
* customer B spent $74
* customer C spent $36

### 2. How many days has each customer visited the restaurant?
```sql
SELECT customer_id, COUNT(DISTINCT(order_date)) AS days_visited
FROM dd_sales
GROUP BY customer_id
```
Answer:
* customer A visited 4 times
* customer B visited 6 times
* customer C visited 2 times

### 3. What was the first item from the menu purchased by each customer?
```sql
WITH ordered_sales_CTE AS
(
SELECT customer_id, order_date, product_name,
    DENSE_RANK() OVER(PARTITION BY customer_id
    ORDER BY order_date) AS rank
FROM dd_sales
JOIN dd_menu
    ON dd_sales.product_id = dd_menu.product_id
GROUP BY customer_id
)

SELECT customer_id, product_name
FROM ordered_sales_CTE
WHERE rank = 1
GROUP BY customer_id, product_name
```
Answer:
* customer A's first order was sushi
* customer B's first order was curry
* customer C's first order was ramen

### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
```sql
SELECT COUNT(s.product_id) AS most_purchased, product_name
FROM dd_sales s
JOIN dd_menu m
    ON s.product_id = m.product_id
GROUP BY s.product_id, product_name
ORDER BY most_purchased DESC
```
Answer:
* The most purchased item on the menu is ramen (8 times)

### 5. Which item was the most popular for each customer?
```sql
WITH favorite_item_CTE AS
(
SELECT customer_id, product_name, COUNT(m.product_id) AS order_count,
    DENSE_RANK() OVER(PARTITION BY customer_id
    ORDER BY COUNT(customer_id) DESC) AS rank
FROM dd_sales s
JOIN dd_menu m
    ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name
)

SELECT customer_id, product_name, order_count
FROM favorite_item_CTE
WHERE rank = 1
```
Answer:
* customer A's favorite item is ramen
* customer B's favorite item is sushi, curry and ramen
* customer C's favorite item is ramen

### 6. Which item was purchased first by the customer after they became a member?
```sql
WITH member_sales_CTE AS
(
SELECT s.customer_id, s.order_date, s.product_id, m.join_date,
    DENSE_RANK() OVER(PARTITION BY s.customer_id
    ORDER BY s.order_date) AS rank
FROM dd_sales s
JOIN dd_members m
    ON s.customer_id = m.customer_id
WHERE s.order_date >= m.join_date
)

SELECT member_sales_CTE.customer_id, member_sales_CTE.order_date, dd_menu.product_name
FROM member_sales_CTE
JOIN dd_menu
    ON member_sales_CTE.product_id = dd_menu.product_id
WHERE rank = 1
```
Answer:
* customer A's first order as a member was curry
* customer B's first order as a member was sushi

### 7. Which item was purchased just before the customer became a member?
```sql
WITH before_member_CTE AS
(
SELECT s.customer_id, s.order_date, s.product_id, m.join_date,
    DENSE_RANK() OVER(PARTITION BY s.customer_id
    ORDER BY s.order_date DESC) AS rank
FROM dd_sales s
JOIN dd_members m
    ON s.customer_id = m.customer_id
WHERE s.order_date < m.join_date
)

SELECT before_member_CTE.customer_id, before_member_CTE.order_date, dd_menu.product_name
FROM before_member_CTE
JOIN dd_menu
    ON before_member_CTE.product_id = dd_menu.product_id
WHERE rank = 1
```
Answer:
* customer A's last order before becoming a member was sushi and curry
* customer B's last order before becoming a memer was sushi

### 8. What is the total items and amount spent for each member before they became a member?
```sql
SELECT s.customer_id, COUNT(DISTINCT(s.product_id)) AS menu_item, SUM(m2.price) AS total_sales
FROM dd_sales s
JOIN dd_members m
    ON s.customer_id = m.customer_id
JOIN dd_menu m2
    ON s.product_id = m2.product_id
WHERE s.order_date < m.join_date
GROUP BY s.customer_id
```
Answer:
* customer A bought 2 items for $25 before becoming a member
* customer B bought 2 items for $40 before becoming a member

### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
```sql
WITH price_point_CTE AS
(
SELECT *,
    CASE WHEN product_id = 1 THEN price * 20
    ELSE price * 10
    END AS points
FROM dd_menu
)

SELECT customer_id, SUM(points) AS total_points
FROM price_point_CTE p
JOIN dd_sales s
    ON p.product_id = s.product_id
GROUP BY s.customer_id
```
Answer:
* customer A would have 860 points
* customer B would have 940 points
* customer C would have 360 points

### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
```sql
WITH dates_CTE AS
(
SELECT *,
DATE('2021-01-07', '+6 days') AS valid_a,
DATE('2021-01-09', '+6 days') AS valid_b,
DATE('2021-01-31') AS last_day
FROM dd_members
)

SELECT dates_CTE.customer_id,
SUM(CASE WHEN m.product_name = 'sushi' THEN 2*10*m.price
    WHEN s.order_date BETWEEN dates_CTE.join_date AND dates_CTE.valid_a THEN 2*10*m.price
    WHEN s.order_date BETWEEN dates_CTE.join_date AND dates_CTE.valid_b THEN 2*10*m.price
    ELSE 10*m.price
    END) AS points
FROM dates_CTE
JOIN dd_sales s
    ON dates_CTE.customer_id = s.customer_id
JOIN dd_menu m
    ON s.product_id = m.product_id
WHERE s.order_date < dates_CTE.last_day
GROUP BY dates_CTE.customer_id
```
Answer:
* customer A has 1,370 points at the end of January
* customer B has 820 points at the end of January

### BONUS: Combine the three datasets to show customer_id, order_date, product_name, price and member (Y/N).
```sql
SELECT customer_id, order_date, product_name, price,
    CASE WHEN join_date > order_date THEN 'N'
    WHEN join_date <= order_date THEN 'Y'
    ELSE 'N'
    END AS member
FROM dd_sales s
LEFT JOIN dd_menu m
    ON s.product_id = m.product_id
LEFT JOIN dd_members m2
    ON s.customer_id = m2.customer_id
```
