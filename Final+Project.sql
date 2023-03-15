use orders;

show tables;

/*# 1. Write a query to display customer full name with their title (Mr/Ms),
-- both first name and last name are in upper case, customer email id,
-- customer creation date and display customer’s category after applying below
-- categorization rules:
-- 1) IF customer creation date Year <2005 Then Category A
-- 2) IF customer creation date Year >=2005 and <2011 Then Category B
-- 3) IF customer creation date Year>= 2011 Then Category C
# Hint: Use CASE statement, no permanent change in table required.
# NOTE: TABLES to be used - ONLINE_CUSTOMER TABLE]*/

SELECT
	CONCAT (
			(case customer_gender when 'M' then 'Mr' when 'F' then 'Ms'end),' ',
			UCASE(customer_fname)," ",UCASE(customer_lname)) AS customer_full_name,
	customer_email,
    customer_creation_date,
    CASE
    WHEN YEAR(customer_creation_date)<2005 THEN 'Category A'
    WHEN YEAR(customer_creation_date)>='2005'AND YEAR(customer_creation_date)<'2011' THEN 'Category B'
    WHEN YEAR(customer_creation_date)>='2011' THEN 'Category C'
    END AS category
FROM 
	online_customer;


/*#2. Write a query to display the following information for the products, which have not been sold:
product_id, product_desc, product_quantity_avail, product_price, inventory values
-- (product_quantity_avail*product_price), New_Price after applying discount as per below criteria.
-- Sort the output with respect to decreasing value of Inventory_Value.
-- 1) IF Product Price > 200,000 then apply 20% discount
-- 2) IF Product Price > 100,000 then apply 15% discount
-- 3) IF Product Price =< 100,000 then apply 10% discount
# Hint: Use CASE statement, no permanent change in table required.
# [NOTE: TABLES to be used - PRODUCT, ORDER_ITEMS TABLE]*/

SELECT 
	p.product_id,
    p.product_desc,
    p.product_quantity_avail,
    p.product_price,
	CASE 
    WHEN (p.product_price)>'200000' THEN (1-0.2)*(p.product_price)
    WHEN (p.product_price)>'100000' THEN (1-0.15)*(p.product_price)
    WHEN (p.product_price)<='100000' THEN (1-0.1)*(p.product_price)
    END AS new_product_price,
   (p.product_quantity_avail*p.product_price) as inventory_values,
    CASE 
    WHEN (p.product_price)>'200000' THEN (1-0.2)*(p.product_quantity_avail*p.product_price)
    WHEN (p.product_price)>'100000' THEN (1-0.15)*(p.product_quantity_avail*p.product_price)
    WHEN (p.product_price)<='100000' THEN (1-0.1)*(p.product_quantity_avail*p.product_price)
    END AS new_inventory_price
FROM product p
WHERE product_id not in(
SELECT DISTINCT(product_id) from order_items)
-- group by 1
ORDER BY inventory_values desc;


/*#3. Write a query to display Product_class_code, Product_class_description, Count of Product type in
each product
-- class, Inventory Value (p.product_quantity_avail*p.product_price). Information should be
displayed for only those product_class_code which have more than 1,00,000
-- Inventory Value. Sort the output with respect to decreasing value of Inventory_Value.
# NOTE: TABLES to be used - PRODUCT_CLASS, PRODUCT_CLASS_CODE]*/

SELECT 
	pc.product_class_code,
    pc.product_class_desc,
    count(pc.product_class_desc) as product_count,
    sum((p.product_quantity_avail*p.product_price)) as inventory_value
FROM product_class pc
LEFT JOIN product p
ON pc.product_class_code = p.product_class_code 
WHERE 
	product_quantity_avail*product_price > 100000 
GROUP BY 1,2
ORDER BY inventory_value desc;


/*#4. Write a query to display customer_id, full name, customer_email, customer_phone and country of
customers who
-- have cancelled all the orders placed by them
-- (USE SUB-QUERY)
-- [NOTE: TABLES to be used - ONLINE_CUSTOMER, ADDRESSS, OREDER_HEARDER]*/

SELECT 
	oc.customer_id,
    CONCAT(oc.customer_fname,' ',oc.customer_lname) as full_name,
    oc.customer_email,
    oc.customer_phone,
    a.country
FROM online_customer oc
JOIN address a
ON a.address_id = oc.address_id
WHERE customer_id IN (SELECT customer_id
FROM order_header
WHERE order_status = 'cancelled');


/*#5. Write a query to display Shipper name, City to which it is catering, num of customer catered by
the
-- shipper in the city and number of consignments delivered to that city for Shipper DHL
-- [NOTE: TABLES to be used - SHIPPER,ONLINE_CUSTOMER, ADDRESSS,
OREDER_HEARDER]*/

SELECT 
	a.city,
	'DHL' AS shipper_name,
	count(oc.customer_id) AS no_of_orders
FROM online_customer oc
JOIN address a
ON oc.address_id = a.address_id
WHERE customer_id in 
	(SELECT customer_id
	FROM order_header
	WHERE shipper_id in 
		(SELECT shipper_id 
		FROM shipper 
        WHERE shipper_name = 'DHL'))
GROUP BY a.city;


/*#6. Write a query to display product_id, product_desc, product_quantity_avail, quantity sold, quantity
available and
-- show inventory Status of products as below as per below condition:
-- a. For Electronics and Computer categories, 
if sales till date is Zero then show 'No Sales in past, give discount to reduce inventory', 
if inventory quantity is less than 10% of quantity sold,show 'Low inventory, need to add inventory', 
if inventory quantity is less than 50% of quantity sold,show 'Medium inventory, need to add some inventory', 
if inventory quantity is more or equal to 50% of quantity sold,show 'Sufficient inventory'

-- b. For Mobiles and Watches categories, 
if sales till date is Zero then show'No Sales in past, give discount to reduce inventory', 
if inventory quantity is less than 20% of quantity sold,show 'Low inventory, need to add inventory', 
if inventory quantity is less than 60% of quantity sold,show 'Medium inventory, need to add some inventory', 
if inventory quantity is more or equal to 60% of quantity sold,show 'Sufficient inventory'

-- c. Rest of the categories, 
if sales till date is Zero then show 'No Sales in past, give discount to reduce inventory', 
if inventory quantity is less than 30% of quantity sold,show 'Low inventory, need to add inventory', 
if inventory quantity is less than 70% of quantity sold,show 'Medium inventory, need to add some inventory', 
if inventory quantity is more or equal to 70% of quantity sold,show 'Sufficient inventory'
-- (USE SUB-QUERY)
-- [NOTE: TABLES to be used - PRODUCT, PRODUCT_CLASS, ORDER_HEADER]*/

with cte as ( select aa.product_id,
	aa.product_desc,
	aa.product_quantity_avail,
	aa.quantity_sold,
	aa.quantity_available,
	aa.product_class_desc from (
select 
p.product_id,
	p.product_desc,
	p.product_quantity_avail,
	ot.product_quantity as quantity_sold,
	p.product_quantity_avail-ot.product_quantity as quantity_available,
	pc.product_class_desc,
    ot.order_id
from product p
left join order_items ot
on p.product_id = ot.product_id
left join product_class pc
on p.product_class_code = pc.product_class_code) aa
where aa.order_id in (select order_id from order_header))

select 
	product_id,
    product_desc,
    sum(product_quantity_avail) as product_quantity_avail,
    sum(quantity_sold) as quantity_sold,
    sum(quantity_available) as quantity_available,
    product_class_desc,
case 
when (product_class_desc = 'Electronics' OR product_class_desc ='Computer') and quantity_sold = 0 then 'No Sales in past, give discount to reduce inventory'
when (product_class_desc = 'Electronics' OR product_class_desc ='Computer') and quantity_available < (0.1*quantity_sold) then 'Low inventory, need to add inventory'
when (product_class_desc = 'Electronics' OR product_class_desc ='Computer') and quantity_available < (0.5*quantity_sold) then 'Medium inventory, need to add some inventory'
when (product_class_desc = 'Electronics' OR product_class_desc ='Computer') and quantity_available >= (0.5*quantity_sold) then 'Sufficient Inventory'

when (product_class_desc = 'Mobiles' OR product_class_desc ='Watches') and quantity_sold = 0 then 'No Sales in past, give discount to reduce inventory'
when (product_class_desc = 'Mobiles' OR product_class_desc ='Watches') and quantity_available < (0.2*quantity_sold) then 'Low inventory, need to add inventory'
when (product_class_desc = 'Mobiles' OR product_class_desc ='Watches') and quantity_available < (0.6*quantity_sold) then 'Medium inventory, need to add some inventory'
when (product_class_desc = 'Mobiles' OR product_class_desc ='Watches') and quantity_available >= (0.6*quantity_sold) then 'Sufficient Inventory'

when (product_class_desc NOT IN ('Electronics','computer','Mobiles','Watches')) and quantity_sold = 0 then 'No Sales in past, give discount to reduce inventory'
when (product_class_desc NOT IN ('Electronics','computer','Mobiles','Watches')) and quantity_available < (0.3*quantity_sold) then 'Low inventory, need to add inventory'
when (product_class_desc NOT IN ('Electronics','computer','Mobiles','Watches')) and quantity_available < (0.7*quantity_sold) then 'Medium inventory, need to add inventory'
when (product_class_desc NOT IN ('Electronics','computer','Mobiles','Watches')) and quantity_available >= (0.7*quantity_sold) then 'Sufficient inventory'
else '' end as inventory_status
from cte
group by 1,2,6,7;


/*#7. Write a query to display order_id and volume of the biggest order (in terms of volume) that can fit
in carton id 10
-- [NOTE: TABLES to be used - CARTON, ORDER_ITEMS, PRODUCT]*/

SELECT 
	ORDER_ITEMS.order_id,
	(len*width*height) AS volume
FROM product, order_items
WHERE 
	product.product_id = ORDER_ITEMS.product_id
GROUP BY  1,2
HAVING volume <= (select (len*width*height) from carton where carton_id=10)
ORDER BY volume desc limit 3;


/*#8. Write a query to display customer id, customer full name, total quantity and total value
(quantity*price) shipped
-- where mode of payment is Cash and customer last name starts with 'G'
-- [NOTE: TABLES to be used - ONLINE_CUSTOMER, ORDER_ITEMS, PRODUCT,
ORDER_HEADER]*/

SELECT 
	oh.customer_id, 
    concat(customer_fname,' ',customer_lname) AS customer_fullname,
    sum(oi.product_quantity) as total_quantity,
    sum((oi.product_quantity*p.product_price)) AS total_value
FROM online_customer oc
INNER JOIN order_header oh
ON oh.customer_id = oc.customer_id
JOIN order_items oi
ON oi.order_id = oh.order_id
JOIN product p
ON p.product_id = oi.product_id
WHERE oh.payment_mode = 'Cash' AND customer_lname LIKE 'G%'
GROUP BY 1,2;


/*#9. Write a query to display product_id, product_desc and total quantity of products
-- which are sold together with product id 201 and are not shipped to city Bangalore and New Delhi.
-- Display the output in descending order with respect to tot_qty.
-- (USE SUB-QUERY)
-- [NOTE: TABLES to be used - order_items, product,order_head, online_customer, address]*/

select 
	oi.product_id, 
    p.product_desc, 
    sum(oi.product_quantity) as tot_qty
from product p
join order_items oi
on oi.product_id = p.product_id
where oi.order_id in (select order_id from order_header where order_id in (
	select order_id from ORDER_ITEMS where product_id = '201') and customer_id in (
		select customer_id from online_customer where address_id in (
			select address_id from address where city !='Bangalore' and city !='New Delhi')))
group by 1,2;

/*#10 Write a query to display the order_id,customer_id and customer fullname
-- as total quantity of products shipped for order ids which are even
-- and shipped to address where pincode is not starting with "5"
-- [NOTE: TABLES to be used - online_customer,Order_header, order_items,address]*/

with cte_orderID as (
select 
	order_id, 
	sum(product_quantity) as tot_qty
from order_items where order_id in(
select order_id
from order_header
where order_status = 'shipped' and customer_id in (select customer_id
from online_customer
where address_id in (select address_id from address where pincode not like ('5%'))))
group by 1
having tot_qty%2 = 0)

select 
ct.order_id, oh.customer_id, concat(oc.customer_fname,' ',oc.customer_lname)as customer_fullname,
tot_qty
from cte_orderID as ct
left join order_header as oh
on oh.order_id = ct.order_id
left join ONLINE_CUSTOMER oc
on oc.customer_id = oh.customer_id;

