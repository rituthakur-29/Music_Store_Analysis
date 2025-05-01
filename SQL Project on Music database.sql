--Question Set 1 - Easy
--Q1: Who is the senior most employee based on job title?
SELECT Top 1 Title, Last_name, First_name 
FROM employee
ORDER BY levels DESC

--Q2: Which countries have the most Invoices?
SELECT COUNT(*) AS C, billing_country 
FROM invoice
GROUP BY billing_country
ORDER BY C DESC

--Q3: What are top 3 values of total invoice?
SELECT Top 3 Round(total,2) as Total 
FROM invoice
ORDER BY total DESC

--Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. Write a query that returns one city that has the highest sum of invoice totals. Return both the city name & sum of all invoice totals
SELECT Top 1 Billing_city,Round(SUM(total),2) AS InvoiceTotal
FROM invoice
GROUP BY billing_city
ORDER BY InvoiceTotal DESC

--Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. Write a query that returns the person who has spent the most money.
SELECT Top 1 C.Customer_id, First_name, Last_name, SUM(total) AS Total_spending
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, first_name, last_name
ORDER BY total_spending DESC

--Question Set 2 - Moderate
--Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. Return your list ordered alphabetically by email starting with A
--Method 1
SELECT DISTINCT Email,First_name, Last_name
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
WHERE track_id IN(
	SELECT track_id FROM track t
	JOIN genre g ON t.genre_id = g.genre_id
	WHERE g.name LIKE 'Rock'
)
ORDER BY email;

--Method 2
SELECT DISTINCT email AS Email,First_name AS FirstName, last_name AS LastName, g.name AS Name
FROM customer c
JOIN invoice i ON i.customer_id = c.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN genre g ON g.genre_id = t.genre_id
WHERE g.name LIKE 'Rock'
ORDER BY email;


--Q2: Let's invite the artists who have written the most rock music in our dataset. Write a query that returns the Artist name and total track count of the top 10 rock bands
SELECT Top 10 a.Artist_id, a.Name,COUNT(a.artist_id) AS Number_of_songs
FROM track t
JOIN album al ON al.album_id = t.album_id
JOIN artist a ON a.artist_id = al.artist_id
JOIN genre g ON g.genre_id = t.genre_id
WHERE g.name LIKE 'Rock'
GROUP BY a.artist_id, a.name
ORDER BY number_of_songs DESC

--Q3: Return all the track names that have a song length longer than the average song length. Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first.
SELECT Name,Milliseconds
FROM track
WHERE milliseconds > (
	SELECT AVG(milliseconds) AS avg_track_length
	FROM track )
ORDER BY milliseconds DESC;


--Question Set 3 - Advance 
--Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent
--Steps to Solve: First, find which artist has earned the most according to the InvoiceLines.Now use this artist to find which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price for each artist.

WITH best_selling_artist AS (
	SELECT TOP 1 a.artist_id AS Artist_id, a.name AS Artist_name, SUM(il.unit_price*il.quantity) AS Total_sales
	FROM invoice_line il
	JOIN track t ON t.track_id = il.track_id
	JOIN album al ON al.album_id = t.album_id
	JOIN artist a ON a.artist_id = al.artist_id
	GROUP BY a.artist_id,a.name
	ORDER BY Total_sales DESC
)
SELECT c.Customer_id, c.First_name, c.Last_name, bsa.Artist_name, Round(SUM(il.unit_price*il.quantity),2) AS Amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY c.customer_id, c.first_name, c.last_name, bsa.artist_name
ORDER BY amount_spent DESC;

--Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre with the highest amount of purchases. 
--Write a query that returns each country along with the top Genre. For countries where the maximum number of purchases is shared return all Genres.
--Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. 

--Method 1: Using CTE

WITH popular_genre AS (
    SELECT 
        COUNT(invoice_line.quantity) AS Purchases,
        customer.Country,
        genre.Name,
        genre.Genre_id,
        ROW_NUMBER() OVER (
            PARTITION BY customer.country 
            ORDER BY COUNT(invoice_line.quantity) DESC
        ) AS RowNo
    FROM invoice_line
    JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
    JOIN customer ON customer.customer_id = invoice.customer_id
    JOIN track ON track.track_id = invoice_line.track_id
    JOIN genre ON genre.genre_id = track.genre_id
    GROUP BY customer.country, genre.name, genre.genre_id
)
SELECT * FROM popular_genre
WHERE RowNo <= 1;

--Q3: Write a query that determines the customer that has spent the most on music for each country. Write a query that returns the country along with the top customer and how much they spent. For countries where the top amount spent is shared, provide all customers who spent this amount
--Steps to Solve:  Similar to the above question. There are two parts in question- first find the most spent on music for each country and second filter the data for respective customers. 

WITH Customter_with_country AS (
		SELECT customer.Customer_id,First_name,Last_name,Billing_country,SUM(total) AS Total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY customer.customer_id,first_name,last_name,billing_country
		)
SELECT * FROM Customter_with_country WHERE RowNo <= 1
ORDER BY billing_country ASC,total_spending DESC
