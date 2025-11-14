-- Q1. Who is the senior most employee based on job title ?
SELECT * 
FROM employee
ORDER BY levels DESC
LIMIT 1;


-- Q2. Which countries have the most Invoices ?
SELECT COUNT(invoice_id) AS invoice, billing_country
FROM invoice
GROUP BY billing_country
ORDER BY invoice DESC;


-- Q3. What are top 3 values of total invoice ?
SELECT *
FROM invoice
ORDER BY total DESC
LIMIT 3;


/* Q4. Which city has the best customers ? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. Return both the city name & sum of all invoice totals.*/
SELECT billing_city, 
	   ROUND(SUM(total),2) AS total
FROM invoice
GROUP BY billing_city
ORDER BY total DESC
LIMIT 1;


-- Q5. Who is the best customer ? The customer who has spent the most money will be declared the best customer. Write a query that returns the person who has spent the most money.
SELECT c.customer_id, 
	   c.first_name, 
       c.last_name, 
       ROUND(SUM(i.total),2) AS total
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id,
	     c.first_name, 
         c.last_name
ORDER BY total DESC
LIMIT 1;


-- Q6. Write a query to return the email, first name, last name, & Genre of all Rock Music listeners. Return your list ordered alphabetically by email starting with A.
SELECT DISTINCT email, 
	   first_name, 
	   last_name 
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
WHERE track_id IN (
		SELECT track_id 
        FROM track t
        JOIN genre g ON g.genre_id = t.genre_id
        WHERE g.name LIKE 'Rock')
ORDER BY email;


-- Q7. Let's invite the artists who have written the most rock music in our dataset. Write a query that returns the Artist name and total track count of the top 10 rock bands.
SELECT ar.artist_id, 
	   ar.name, 
       COUNT(t.track_id) AS num_of_songs
FROM artist ar
JOIN album al ON al.artist_id = ar.artist_id
JOIN track t ON t.album_id = al.album_id
WHERE t.genre_id IN (
		SELECT genre_id 
        FROM genre
        WHERE name LIKE 'Rock')
GROUP BY ar.artist_id,
		 ar.name
ORDER BY num_of_songs DESC
LIMIT 10;


-- Q8. Return all the track names that have a song length longer than the average song length. Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first.
SELECT name, 
	   milliseconds
FROM track
WHERE milliseconds > (SELECT AVG(milliseconds) as avg_track_length
					  FROM track)
ORDER BY milliseconds DESC;


-- Q9. Find how much amount spent by each customer on artists. Write a query to return the customer name, artist name, and total spent.
WITH best_selling_artist AS 
    (SELECT ar.artist_id, 
			ar.name AS artist_name, 
			SUM(il.unit_price * il.quantity) AS total_spent
    FROM invoice_line il
    JOIN track t ON t.track_id = il.track_id
    JOIN album al ON al.album_id = t.album_id
    JOIN artist ar ON ar.artist_id = al.artist_id
    GROUP BY 1,2
    ORDER BY 3 DESC)
SELECT c.customer_id, 
	   CONCAT(c.first_name," ",c.last_name) AS name, 
       bsa.artist_name AS artist_name, 
       ROUND(SUM(il.unit_price * il.quantity),2) AS total_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album al ON al.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = al.artist_id
GROUP BY 1, 2, 3
ORDER BY 4 DESC;


/* Q10. We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre with the highest amount of purchases. 
Write a query that returns each country along with the top Genre. For countries where the maximum number of purchases is shared return all Genres.*/
WITH popular_genre AS (
    SELECT COUNT(il.quantity) AS purchases, 
            c.country, 
            g.name AS genre_name,
            ROW_NUMBER() 
            OVER(PARTITION BY c.country ORDER BY COUNT(il.quantity) DESC) 
            AS row_num 
    FROM invoice_line il
    JOIN invoice i ON i.invoice_id = il.invoice_id
    JOIN customer c ON c.customer_id = i.customer_id
    JOIN track t ON t.track_id = il.track_id
    JOIN genre g ON g.genre_id = t.genre_id
    GROUP BY 2,3
    ORDER BY 2 ASC, 1 DESC)
SELECT country, 
	   genre_name, 
       purchases 
FROM popular_genre 
WHERE row_num <= 1;


/* Q11. Write a query that determines the customer that has spent the most on music for each country. Write a query that returns the country along 
with the top customer and how much they spent. For countries where the top amount spent is shared, provide all customers who spent this amount.*/
WITH customer_with_country AS (
    SELECT  c.customer_id, 
			CONCAT(first_name," ", last_name) AS name, 
            billing_country, 
            SUM(total) AS total_spent,
			ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS row_num
    FROM invoice i
    JOIN customer c ON c.customer_id = i.customer_id
    GROUP BY 1,2,3
    ORDER BY 3, 4 DESC)
SELECT customer_id, 
	   name, 
       billing_country, 
       ROUND(total_spent,2) AS total_spent
FROM customer_with_country
WHERE row_num = 1;


-- Q12. List top 10 most popular artists?
SELECT ar.name AS artist_name,
	   COUNT(il.quantity) AS purchases
FROM invoice_line il
JOIN track t ON t.track_id = il.track_id
JOIN album al ON al.album_id = t.album_id
JOIN artist ar ON ar.artist_id = al.artist_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;


-- Q13. List top 10 the most popular song?
SELECT t.name AS song_name,
	   COUNT(il.quantity) AS purchases
FROM invoice_line il
JOIN track t ON t.track_id = il.track_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;


-- Q14. What are the average prices of different types of music?
WITH purchases AS
    (SELECT g.name AS genre, 
			SUM(total) AS total_spent
    FROM invoice i
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    JOIN track t ON t.track_id = il.track_id
    JOIN genre g ON g.genre_id = t.genre_id
    GROUP BY 1
    ORDER BY 2)
SELECT genre, 
		CONCAT('$ ', ROUND(AVG(total_spent),2)) AS total_spent
FROM purchases
GROUP BY genre;


-- Q15. What are the most popular countries for music purchases?
SELECT c.country,
	   COUNT(il.quantity) AS purchases
FROM invoice_line il 
JOIN invoice i ON i.invoice_id = il.invoice_id
JOIN customer c ON c.customer_id = i.customer_id
GROUP BY country
ORDER BY purchases DESC;