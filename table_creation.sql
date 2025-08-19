-- DROP TABLE command
DROP TABLE IF EXISTS warranty;
DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS category; --parent table
DROP TABLE IF EXISTS stores; --parent table

--STORES TABLE

create table stores(
store_id varchar(10) Primary key,
store_name varchar(30),
city varchar(30),
country varchar(30)
);

--CAREGORIES TABLE

create table category(
category_id varchar(20) primary key,
category_name varchar(30)
);


--PRODUCTS TABLE

create table products(
product_id varchar(10) primary key,
product_name varchar(35),
category_id varchar(10),
launch_date date,
price float,
constraint fk_category foreign key (category_id) references category(category_id)
);

--SALES TABLE

create table sales(
sale_id varchar(10) primary key,
sale_date date,
store_id varchar(10),
product_id varchar(10),
quantity int,
constraint fk_store foreign key (store_id) references stores(store_id),
constraint fk_product foreign key (product_id) references products(product_id)
);

--WARRANTY TABLE

create table warranty(
claim_id varchar(10) primary key,
claim_date date,
sale_id varchar(10),
repair_status varchar(20),
constraint fk_sale foreign key (sale_id) references sales(sale_id)
);
