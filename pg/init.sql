
-- Create schema
CREATE SCHEMA IF NOT EXISTS ALT_CAP;


-- create and populate tables
create table if not exists ALT_CAP.OLIST_CUSTOMERS
(
    customer_id uuid primary key,
    customer_unique_id uuid not null,
    customer_zip_code_prefix varchar not null,
    customer_city varchar not null,
    customer_state varchar (2) not null
);

-- Copy data from the CSV file into the table
COPY ALT_CAP.OLIST_CUSTOMERS (customer_id, customer_unique_id, customer_zip_code_prefix, 
customer_city, customer_state)
FROM '.pg/data/olist_customers_dataset.csv' WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);


-- Create the final table with the composite primary key
CREATE TABLE IF NOT EXISTS ALT_CAP.OLIST_GEOLOCATION
(
    geolocation_zip_code_prefix varchar not null,
    geolocation_lat decimal(18,15) not null,
    geolocation_lng decimal(18,15) not null,
    geolocation_city varchar not null,
    geolocation_state varchar(2) not null,
    PRIMARY KEY (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng)
);

-- Create a temporary staging table
CREATE TEMP TABLE staging_olist_geolocation
(
    geolocation_zip_code_prefix varchar,
    geolocation_lat decimal(18,15),
    geolocation_lng decimal(18,15),
    geolocation_city varchar,
    geolocation_state varchar(2)
);

-- Copy data from the CSV file into the staging table
COPY staging_olist_geolocation (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, 
geolocation_city, geolocation_state)
FROM '.pg/data/olist_geolocation_dataset.csv' WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);

-- Insert data from the staging table into the final table with conflict handling
INSERT INTO ALT_CAP.OLIST_GEOLOCATION (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, 
geolocation_city, geolocation_state)
SELECT 
    geolocation_zip_code_prefix, 
    geolocation_lat, 
    geolocation_lng, 
    geolocation_city, 
    geolocation_state
FROM 
    staging_olist_geolocation
ON CONFLICT (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng) 
DO NOTHING;

-- Drop the staging table
DROP TABLE staging_olist_geolocation;


create table if not exists ALT_CAP.OLIST_ORDER_ITEMS
(
    order_id uuid not null,
    order_item_id INT not null,
    product_id uuid not null,
    seller_id uuid not null,
    shipping_limit_date timestamp,
    price decimal(10,2) not null,
    freight_value decimal(10,2) not null,
    PRIMARY KEY (order_id, order_item_id)
);

-- Copy data from the CSV file into the table
COPY ALT_CAP.OLIST_ORDER_ITEMS (order_id, order_item_id, product_id, seller_id, 
shipping_limit_date, price, freight_value)
FROM '.pg/data/olist_order_items_dataset.csv' WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);


create table if not exists ALT_CAP.OLIST_ORDER_PAYMENTS
(
    order_id uuid not null,
    payment_sequential int not null,
    payment_type varchar not null,
    payment_installments int not null,
    payment_value decimal(10,2) not null,
    PRIMARY KEY (order_id, payment_sequential)
);

-- Copy data from the CSV file into the table
COPY ALT_CAP.OLIST_ORDER_PAYMENTS (order_id, payment_sequential, payment_type, 
payment_installments, payment_value)
FROM '.pg/data/olist_order_payments_dataset.csv' WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);


create table if not exists ALT_CAP.OLIST_ORDER_REVIEWS
(
    review_id uuid not null,
    order_id uuid not null,
    review_score smallint not null,
    review_comment_title varchar(255),
    review_comment_message text,
    review_creation_date timestamp,
    review_answer_timestamp timestamp
);

-- Copy data from the CSV file into the table
COPY ALT_CAP.OLIST_ORDER_REVIEWS (review_id, order_id, review_score, review_comment_title, 
review_comment_message, review_creation_date, review_answer_timestamp)
FROM '.pg/data/olist_order_reviews_dataset.csv' WITH(
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);


create table if not exists ALT_CAP.OLIST_ORDERS
(
    order_id uuid primary key,
    customer_id uuid not null,
    order_status varchar(15),
    order_purchase_timestamp timestamp,
    order_approved_at timestamp,
    order_delivered_carrier_date timestamp,
    order_delivered_customer_date timestamp,
    order_estimated_delivery_date timestamp
);

-- Copy data from the CSV file into the table
COPY ALT_CAP.OLIST_ORDERS (order_id, customer_id, order_status, order_purchase_timestamp, order_approved_at, 
order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date)
FROM '.pg/data/olist_orders_dataset.csv' WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);


create table if not exists ALT_CAP.OLIST_PRODUCTS
(
    product_id UUID primary key,
    product_category_name varchar(50),
    product_name_lenght int,
    product_description_lenght int,
    product_photos_qty int,
    product_weight_g decimal(10, 2),
    product_length_cm decimal(10, 2),
    product_height_cm decimal(10, 2),
    product_width_cm decimal(10, 2)
);

-- Copy data from the CSV file into the table
COPY ALT_CAP.OLIST_PRODUCTS (product_id, product_category_name, product_name_lenght, product_description_lenght, 
product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm)
FROM '.pg/data/olist_products_dataset.csv' WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);


create table if not exists ALT_CAP.OLIST_SELLERS
(
    seller_id uuid primary key,
    seller_zip_code_prefix varchar(5) not null,
    seller_city varchar(255),
    seller_state varchar(2)
);

-- Copy data from the CSV file into the table
COPY ALT_CAP.OLIST_SELLERS (seller_id, seller_zip_code_prefix, seller_city, seller_state)
FROM '.pg/data/olist_sellers_dataset.csv' WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);


create table if not exists ALT_CAP.PRODUCT_CATEGORY_NAME_TRANSLATION
(
    product_category_name varchar(255),
    product_category_name_english varchar(255)
);

-- Copy data from the CSV file into the table
COPY ALT_CAP.PRODUCT_CATEGORY_NAME_TRANSLATION (product_category_name, product_category_name_english)
FROM '.pg/data/product_category_name_translation.csv' WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);
