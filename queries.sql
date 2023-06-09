--#8WeekSQLChallenge
--Danny's Diner


--Total amount each customer spent at the restaurant

SELECT customer_id, SUM(price) AS total_spent
FROM dd_sales
JOIN dd_menu
    ON dd_sales.product_id = dd_menu.product_id
GROUP BY customer_id;


--Number of days each customer visited the restaurant

SELECT customer_id, COUNT(DISTINCT(order_date)) AS days_visited
FROM dd_sales
GROUP BY customer_id;


--First item purchased by each customer

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
GROUP BY customer_id, product_name;


--The most purchased item on the menu, and how many times it was purchased by customers

SELECT COUNT(s.product_id) AS most_purchased, product_name
FROM dd_sales s
JOIN dd_menu m
    ON s.product_id = m.product_id
GROUP BY s.product_id, product_name
ORDER BY most_purchased DESC;


--The most popular item for each customer

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
WHERE rank = 1;


--The item that was first purchased by a customer after they became a member

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
WHERE rank = 1;


--The item that was purchased just before the customer became a member

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
WHERE rank = 1;


--Total items and amount spent for each member, before they became one

SELECT s.customer_id, COUNT(DISTINCT(s.product_id)) AS menu_item, SUM(m2.price) AS total_sales
FROM dd_sales s
JOIN dd_members m
    ON s.customer_id = m.customer_id
JOIN dd_menu m2
    ON s.product_id = m2.product_id
WHERE s.order_date < m.join_date
GROUP BY s.customer_id;


--How many points would each customer have
--$1 spent = 10 points, and sushi has 2x multiplier

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
GROUP BY s.customer_id;


--How many points to customer A and B have at the end of January
--in the first week after they join, they earn 2x points on all items (not just sushi)

SELECT *
FROM dd_members;

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
GROUP BY dates_CTE.customer_id;


--Join all the tables
--customer_id, order_date, product_name, price, member (Y/N)

SELECT customer_id, order_date, product_name, price,
    CASE WHEN join_date > order_date THEN 'N'
    WHEN join_date <= order_date THEN 'Y'
    ELSE 'N'
    END AS member
FROM dd_sales s
LEFT JOIN dd_menu m
    ON s.product_id = m.product_id
LEFT JOIN dd_members m2
    ON s.customer_id = m2.customer_id;
