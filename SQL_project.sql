-- Senior most employee based on the Job title

select first_name, last_name 
from employee
order by levels desc
limit 1 

-- countries with the most invoices

select count(*) as a, billing_country
from invoice
group by billing_country
order by a desc
limit 10

-- top 3 values of total invoices

select total from invoice
order by total desc
limit 3

-- city with best customer. 

select billing_city, sum(total) as invoice_total from invoice
group by billing_city
order by invoice_total desc

-- who's best customer.
select customer.customer_id, first_name, last_name, sum(total) as total
from customer join invoice
on customer.customer_id = invoice.customer_id
group by 1,2 
order by total desc
limit 1

-- Query to return email, name, genre of all rock music listeners. return email alphabetically

select distinct email, first_name, last_name
from customer c join invoice i
on c.customer_id = i.customer_id join invoice_line e 
on i.invoice_id = e.invoice_id

where track_id in (select track_id
	from track 
	join genre on track.genre_id = genre.genre_id
	where genre.name = 'Rock')
order by email

-- top 10 artists with most rock music albums

select a.artist_id, a.name, count(a.artist_id) as num_of_songs 
from artist a join album b on a.artist_id = b.artist_id
join track t on b.album_id = t.album_id

where track_id in (select track_id
	from track 
	join genre on track.genre_id = genre.genre_id
	where genre.name = 'Rock')
group by a.artist_id
order by num_of_songs desc
limit 10

-- track names that have song length longer than the average, return name and milliseconds 
-- for each songs. order by song length (from longest to shortest)

select name, milliseconds
from track
where milliseconds > (
	select avg(milliseconds) as milliseconds
	from track
)
order by milliseconds desc

-- amount spent by each customer on artists, return customer name, artist name 
-- and total amount spent.

with top_artists as (
	select a.artist_id, a.name, sum(i.unit_price * i.quantity) as total_sales
	from invoice_line i
	join track on i.track_id = track.track_id
	join album on track.album_id = album.album_id
	join artist a on album.artist_id = a.artist_id
	group by 1
	order by 3 desc 
	limit 1
)

select c.customer_id, c.first_name, c.last_name, ta.name, sum(d.unit_price * d.quantity) as total_amount
from customer c 
join invoice e on c.customer_id = e.customer_id
join invoice_line d on e.invoice_id = d.invoice_id
join track t on d.track_id = t.track_id
join album b on t.album_id = b.album_id
join top_artists ta on b.artist_id = ta.artist_id
group by 1,2,3,4
order by 5 desc 

-- Country with the most popular genre. (popular genre is determined by highest amount of purchase)

with popular_genre as (
	select customer.country, count(invoice_line.quantity) as purchases, genre.name, genre.genre_id,
	row_number() over( partition by customer.country order by count(invoice_line.quantity) desc) as rank_value
	from invoice_line
	join invoice on invoice_line.invoice_id = invoice.invoice_id
	join customer on invoice.customer_id = customer.customer_id
	join track on track.track_id = invoice_line.track_id 
	join genre on genre.genre_id = track.genre_id
	group by 1,3,4
	order by 1 asc, 2 desc
)
select * from popular_genre
where rank_value <= 1

-- customer that spends the most on music for each country. return with country along with top customer

with recursive 
most_aud as (
	select c.customer_id, c.first_name, c.last_name, c.country, sum(i.total) as spendings
	from customer c 
	join invoice i on c.customer_id = i.customer_id
	group by 1,2,3,4
	order by 5 desc
),
max_by_country as (
	select country, max(spendings) as max_spending
	from most_aud
	group by 1
)

select m.first_name, m.last_name, m.country, m.spendings
from most_aud m 
join max_by_country mb on m.country = mb.country 
order by 3 

-- or can also be solved as 

with top_customers as (
	select first_name, last_name, country, sum(total) as spendings, 
	row_number () over (partition by country order by sum(total)) as rank_value
	from customer c 
	join invoice i on c.customer_id = i.customer_id
	group by 1,2,3
	order by 3,4
)
select first_name, last_name, country, spendings
from top_customers where rank_value <= 1