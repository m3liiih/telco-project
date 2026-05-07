-- 1. Tariff-Based Customer Queries
-- 1.1 List the customers who are subscribed to the 'Kobiye Destek' tariff.

SELECT * FROM CUSTOMERS
WHERE TARIFF_ID = (SELECT TARIFF_ID FROM TARIFFS WHERE NAME = 'Kobiye Destek');

-- Here we want to find all information about the customers since there is no criteria.
-- We select all columns using the "*" to list all from the CUSTOMERS table for this query result.
-- We match the TARIFF_ID in CUSTOMERS as a foreign key to the primary key from TARIFFS.
-- Here I decided to use a subquery to find the TARIFF_ID for the "Kobiye Destek" tariff from the TARIFFS table.
-- This can also be done using a JOIN condition with WHERE clause.

-- 1.2 Find the newest customer who subscribed to this tariff.

SELECT * FROM CUSTOMERS C
JOIN TARIFFS T ON C.TARIFF_ID = T.TARIFF_ID
WHERE T.NAME = 'Kobiye Destek'
-- ORDER BY SIGNUP_DATE DESC;
AND SIGNUP_DATE = (SELECT MAX(SIGNUP_DATE) FROM CUSTOMERS);

-- We could start off using the same base query as we need the same tariff filtered but this time we'll use a JOIN.
-- Firstly we select all columns from the CUSTOMERS table and give it an alias "C" for easier reference using JOINs.
-- Then we join the CUSTOMERS and TARIFFS tables using the TARIFF_ID as the common column.
-- We filter the results with a WHERE condition to only include customers signed up to the 'Kobiye Destek' tariff.
-- Here we could order the results by SIGNUP_DATE in descending order and fetch one row.
-- Since there are no exact timestamps in the SIGNUP_DATE column, I will not be doing that not to miss any customers.
-- Instead of it I went for is using the MAX(SIGNUP_DATE) as a subquery to find all the customers on the latest date.

-- 2. Tariff Distribution
-- 2.1 Find the distribution of tariffs among the customers.

SELECT T.NAME, T.TARIFF_ID, COUNT(CUSTOMER_ID) AS CUSTOMER_COUNT
FROM CUSTOMERS C
JOIN TARIFFS T ON C.TARIFF_ID = T.TARIFF_ID
GROUP BY T.NAME, T.TARIFF_ID;

-- Here we want to find the customer distribution so we would ideally want to see the tariff name and customer count.
-- Without a join we could only select TARIFF_ID from CUSTOMERS, but that wouldn't be clear without the tariff name.
-- So we join the CUSTOMERS and TARIFFS tables using the TARIFF_ID as the mutual column.
-- We group by the tariff name and also the tariff id so we can select it in our SELECT statement as well.

-- 3. Customer Signup Analysis
-- 3.1 Identify the earliest customers to sign up.

SELECT * FROM CUSTOMERS
WHERE SIGNUP_DATE = (SELECT MIN(SIGNUP_DATE) FROM CUSTOMERS);

-- We select all columns from the CUSTOMERS table to get all the information on our results.
-- To identify the earliest customers we use a subquery to find the MIN(SIGNUP_DATE) from the CUSTOMERS table.
-- We match it with our main query using a WHERE condition to find all the customers who signed up on the earliest date.

-- 3.2 Find the distribution of these earliest customers across different cities, including the total count for each city.

SELECT CITY, COUNT(CUSTOMER_ID) AS CUSTOMER_COUNT
FROM CUSTOMERS WHERE SIGNUP_DATE = (SELECT MIN(SIGNUP_DATE) FROM CUSTOMERS)
GROUP BY CITY;

-- Starting off with our SELECT statement to view the cities and the customer count for each city.
-- Since we have the same search criteria, we can use the same subquery from the previous question.
-- Using it to filter our SIGNUP_DATE with the MIN(SIGNUP_DATE) from the subquery to find the earliest signups.
-- Lastly we group our output by CITY to get the count for each city.

-- 4. Missing Monthly Records
-- 4.1 Every customer has a monthly fee, and the dataset contains this month's usage values.
-- However, an insertion error occurred, and some customers' monthly records are missing.
-- Identify the IDs of these missing customers.

SELECT CUSTOMER_ID FROM CUSTOMERS
WHERE CUSTOMER_ID NOT IN (SELECT CUSTOMER_ID FROM MONTHLY_STATS);

-- Here we especially want to identify the missing customers by their IDs.
-- So we select CUSTOMER_ID from the CUSTOMERS table for our output.
-- We use a subquery to select all customers that are in MONTHLY_STATS with their CUSTOMER_ID.
-- With this result we can use the WHERE condition with NOT IN to find the missing customers in the MONTHLY_STATS table.
-- That way we get the list of CUSTOMER_IDs that are in CUSTOMERS but not in MONTHLY_STATS.

-- 4.2 Find the distribution of these missing customers across different cities.

SELECT CITY, COUNT(CUSTOMER_ID) AS CUSTOMER_COUNT
FROM CUSTOMERS WHERE CUSTOMER_ID NOT IN (SELECT CUSTOMER_ID FROM MONTHLY_STATS)
GROUP BY CITY;

-- 5. Usage Analysis
-- 5.1 Find the customers who have used at least 75% of their data limit.

SELECT C.CUSTOMER_ID, C.NAME, T.DATA_LIMIT, M.DATA_USAGE,
       CAST((M.DATA_USAGE / T.DATA_LIMIT) * 100 AS DECIMAL (4,2)) AS USED_PERCENTAGE
FROM CUSTOMERS C
JOIN MONTHLY_STATS M ON C.CUSTOMER_ID = M.CUSTOMER_ID
JOIN TARIFFS T ON C.TARIFF_ID = T.TARIFF_ID
WHERE M.DATA_USAGE >= 0.75 * T.DATA_LIMIT
-- Excluding the Kurumsal SMS tariff
-- To prevent division by zero error and unnecessary clutter
AND T.DATA_LIMIT > 0;

-- Now we want to find the customers who used up 75% of their data limit.
-- To achieve this we will need to find the ratio of DATA_USAGE and DATA_LIMITs.
-- That means we will have to join the tables to get the necessary columns for our calculations and output.
-- For this we start by selecting the CUSTOMER_ID and NAME from CUSTOMERS.
-- As the output I also want to select the DATA_LIMIT and DATA_USAGE from TARIFFS and MONTHLY_STATS.
-- For a better visual I also want to calculate the percentage of data used and include it in the output.
-- After we calculate the percentage we cast it as a DECIMAL with 4 digits and 2 floating points for readability.
-- We join the CUSTOMERS and MONTHLY_STATS tables using their CUSTOMER_ID column to get the DATA_USAGE for each customer.
-- We also join the TARIFFS table to get the DATA_LIMIT for our customers using the TARIFF_ID.
-- Using the WHERE condition we filter the results where used data is greater than or equal to 75% of the data limit.
-- Since customers using the "Kurumsal SMS" don't have a data limit we exclude them by setting DATA_LIMIT > 0.
-- We go on by adding this to our WHERE statement using AND so both conditions must apply.
-- This way we prevent clutter from all "Kurumsal SMS" customers. Dropping from 4447 results to 1880 results.

-- 5.2 Identify the customers who have completely exhausted all of their package limits (data, minutes, and SMS).

SELECT C.CUSTOMER_ID, C.NAME,
       T.DATA_LIMIT, M.DATA_USAGE,
       T.MINUTE_LIMIT, M.MINUTE_USAGE,
       T.SMS_LIMIT, M.SMS_USAGE
FROM CUSTOMERS C
JOIN MONTHLY_STATS M ON C.CUSTOMER_ID = M.CUSTOMER_ID
JOIN TARIFFS T ON C.TARIFF_ID = T.TARIFF_ID
WHERE M.DATA_USAGE >= T.DATA_LIMIT -- * 0.99
AND M.MINUTE_USAGE >= T.MINUTE_LIMIT -- * 0.99
AND M.SMS_USAGE >= T.SMS_LIMIT; -- [* 0.99] / * 0.95 / * 0.90

-- Here we want to find the customers who have exhausted all of their limits.
-- We start selecting all the information we want to view in our output from our tables.
-- Next we join the MONTHLY_STATS and TARIFFS tables to get the necessary USAGE and LIMIT columns for our comparisons.
-- Using the WHERE statement we set the condition for all limits to be reached or exceeded.

-- This condition isn't met by any customer in the dataset.
-- If we check for 99% of all limits we get 31 rows from the "Kurumsal SMS" tariff only.
-- Using 95% as the condition results in 123 rows, from which only 3 are not from the "Kurumsal SMS" tariff.
-- 90% returns 259 rows, with only 9 of them having data and minute limits. The rest being from "Kurumsal SMS".

-- If we want any of the limits to be exhausted, we could use OR condition instead of AND.
-- Upon further analysis we can see that none of the customers have exactly exhausted any of their limits.
-- So it would be safe to say that using %99 condition is the most logical accepting it as a margin of error.

-- 6. Payment Analysis
-- 6.1 Find the customers who have unpaid fees.

SELECT C.*, M.PAYMENT_STATUS FROM CUSTOMERS C
JOIN MONTHLY_STATS M ON C.CUSTOMER_ID = M.CUSTOMER_ID
WHERE M.PAYMENT_STATUS = 'UNPAID';

-- Here we start by selecting all customer info and the PAYMENT_STATUS from MONTHLY_STATS for our output.
-- We join the CUSTOMERS and MONTHLY_STATS tables using their CUSTOMER_ID.
-- Using the WHERE condition to filter the results for customers with "UNPAID" fees as their PAYMENT_STATUS.

-- 6.2 Find the distribution of all payment statuses across the different tariffs.

SELECT T.NAME, M.PAYMENT_STATUS, COUNT(C.CUSTOMER_ID) AS CUSTOMER_COUNT
FROM CUSTOMERS C
JOIN MONTHLY_STATS M ON C.CUSTOMER_ID = M.CUSTOMER_ID
JOIN TARIFFS T ON C.TARIFF_ID = T.TARIFF_ID
GROUP BY T.NAME, M.PAYMENT_STATUS
ORDER BY T.NAME, M.PAYMENT_STATUS;

-- For this question we want to find the distribution of payment statuses across tariffs.
-- To start off we select the tariff name, payment status and customer count for our output.
-- We join the CUSTOMERS and MONTHLY_STATS tables to get the PAYMENT_STATUS for each customer.
-- We also join the TARIFFS table to get the tariff name for each customer using the TARIFF_ID.
-- Grouping our results by tariff name and payment status to get the distribution for each of them.
-- Lastly we order the results by tariff name and payment status for better readability.