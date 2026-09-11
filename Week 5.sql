--Lab 1  
WITH ranked_films AS (
    SELECT
        c.category_id,
        c.name AS category_name,
        f.film_id,
        f.title,
        f.length,
        DENSE_RANK() OVER (
            PARTITION BY c.category_id
            ORDER BY f.length DESC
        ) AS length_rank
    FROM film AS f
    JOIN film_category AS fc
        ON fc.film_id = f.film_id
    JOIN category AS c
        ON c.category_id = fc.category_id
)
SELECT
    category_name,
    film_id,
    title,
    length,
    length_rank
FROM ranked_films
WHERE length_rank <= 3
ORDER BY category_name, length_rank, title;

--Lab 2
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', payment_date)::date AS revenue_month,
        SUM(amount) AS current_revenue
    FROM payment
    GROUP BY DATE_TRUNC('month', payment_date)::date
),
revenue_with_lag AS (
    SELECT
        revenue_month,
        current_revenue,
        LAG(current_revenue) OVER (
            ORDER BY revenue_month
        ) AS previous_revenue
    FROM monthly_revenue
)
SELECT
    revenue_month,
    current_revenue,
    previous_revenue,
    ROUND(
        (current_revenue - previous_revenue)
        / NULLIF(previous_revenue, 0) * 100,
        2
    ) AS mom_growth_pct
FROM revenue_with_lag
ORDER BY revenue_month;

--Lab 3
SELECT
    payment_id,
    customer_id,
    payment_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY customer_id
        ORDER BY payment_date, payment_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_spending
FROM payment
ORDER BY customer_id, payment_date, payment_id;

--Lab 4
WITH customer_spending AS (
    SELECT
        co.country_id,
        co.country,
        cu.customer_id,
        CONCAT_WS(' ', cu.first_name, cu.last_name) AS customer_name,
        SUM(p.amount) AS total_spending
    FROM customer AS cu
    JOIN payment AS p
        ON p.customer_id = cu.customer_id
    JOIN address AS a
        ON a.address_id = cu.address_id
    JOIN city AS ci
        ON ci.city_id = a.city_id
    JOIN country AS co
        ON co.country_id = ci.country_id
    GROUP BY
        co.country_id,
        co.country,
        cu.customer_id,
        cu.first_name,
        cu.last_name
),
ranked_customers AS (
    SELECT
        country_id,
        country,
        customer_id,
        customer_name,
        total_spending,
        RANK() OVER (
            PARTITION BY country_id
            ORDER BY total_spending DESC
        ) AS spending_rank
    FROM customer_spending
)
SELECT
    country,
    customer_id,
    customer_name,
    total_spending,
    spending_rank
FROM ranked_customers
WHERE spending_rank = 1
ORDER BY country, customer_id;
