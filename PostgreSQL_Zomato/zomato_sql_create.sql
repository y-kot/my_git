--Анализ данных компании  доставки еды Zoomato

create table customers
 (
	customer_id INT PRIMARY KEY,
	customer_name VARCHAR(25),
	reg_date DATE
 );

CREATE TABLE restaurants 
	(
	restaurant_id INT PRIMARY KEY,   
	restaurant_name VARCHAR(55),  
	city  VARCHAR(25),
	opening_hours VARCHAR(55)
	);

ALTER TABLE orders
ADD CONSTRAINT fk_restaurants
FOREIGN KEY(restaurant_id)
REFERENCES restaurants(restaurant_id);
	
CREATE TABLE orders 
(
	order_id INT PRIMARY KEY,
	customer_id INT,--такой же в  customers
	restaurant_id INT, --restaurant
	order_item VARCHAR(55),
	order_date DATE,
	order_time TIME,
	order_status VARCHAR(55),
	total_amount FLOAT
);

ALTER TABLE orders
ADD CONSTRAINT fk_customers
FOREIGN KEY(customer_id)
REFERENCES customers(customer_id);

CREATE TABLE riders
( 
	rider_id INT PRIMARY KEY,
	rider_name VARCHAR(55),
	sign_up DATE

);	
--drop table if exists deliveries;
CREATE TABLE deliveries
(
	delivery_id INT  PRIMARY KEY,
	order_id INT,-- из orders
	delivery_status VARCHAR(35),
	delivery_time TIME,
	rider_id INT,--riders
	CONSTRAINT fk_orders FOREIGN KEY(order_id) REFERENCES orders(order_id),
	CONSTRAINT fk_riders FOREIGN KEY(rider_id) REFERENCES riders(rider_id)
);



