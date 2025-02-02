﻿create database superMarket;

create table Customer(

	customer_ID integer primary key,
	first_Name nvarchar(200) not null, /*The data type is nvarchar, which means National varchar. 
	                                     I can add data in any language I want, provided that I put
										 a capital letter “N” before the data in the insert statement.*/
	last_Name nvarchar(200) not null,
	email varchar(300) unique,
	phone varchar(20)
);

create table employee(

	employee_ID integer primary key,
	first_Name nvarchar(200) not null,
	last_Name nvarchar(200) not null,
	hire_Date date default getdate(),
	gender nchar check (gender in ('M','F')),
	contract_Type nvarchar(20) check(contract_Type in ('Fixed','Hourly'))
);

create table employee_Fixed(

	employee_ID integer primary key references employee(employee_ID),
	monthly_Salary decimal(7,2) check(monthly_Salary between 700 and 5000)
);

create table employee_Hourly(

	employee_ID integer primary key references employee(employee_ID),
	working_Hours decimal(5,2) check(working_hours>0),
	hourly_Salary decimal(5,2) check(hourly_Salary >0)
);

create table product_Categories(

	category_ID integer primary key,
	category_Name nvarchar(200) unique not null
);

create table product (

	product_ID integer primary key,
	product_Name nvarchar(300),
	market_Price decimal(8,2) check(market_Price>0),
	category_ID integer references product_Categories(category_ID)
);

create table sales (

	sale_ID integer primary key identity(1,1),/*Start from 1 and auto increment by 1 each time */
	sale_Date date default getdate(),
	total_Price decimal(8,2),
	discount decimal(8,2) default 0,
	final_Price decimal(8,2),
	customer_ID integer references customer(customer_ID),
	employee_ID integer references employee(employee_ID)
);

create table sales_Products(

	sale_ID integer references sales(sale_ID),
	product_ID integer references product(product_ID),
	quantity decimal(8,2) check(quantity > 0),
	unit_Price decimal(8,2) check(unit_Price >= 0)
);

insert into Customer values (1,'Shyam','Almawajdeh','shyamalm@gmail.com','0791235678');

/*In order for me to add data in Arabic, I must add the capital letter “N” before adding*/
insert into Customer values (2,N'سلاف',N'المواجده','sulaf@gmail.com','0778652340');

/*(inserted.coulmn_Name) is used in the insert 
  statement to display last data that has been 
  added by specifying the column to be displayed,
  and it is often used with the identity(start,increment) 
  instead of using the Max function.*/
insert into Customer output inserted.customer_ID values (3,'Alia','Refaie','alia@gmail.com','0799876543'); 

insert into employee (employee_ID,first_Name,last_Name) values(1,'Jana','Ashraf');

/*I cannot add data to the sale_ID because it is automatically incremented*/
insert into sales (sale_Date,total_Price,discount,final_Price,customer_ID,employee_ID) values('2024/07/05',1000,30,970,1,1);

/*if i want to insert on identity ,I have to use IDENTITY_INSERT and change it to ON*/
SET IDENTITY_INSERT sales ON;
insert into sales (sale_ID,sale_Date,total_Price,discount,final_Price,customer_ID,employee_ID) values(2,'2024/07/05',1000,30,970,1,1);
/*Then i can change it to OFF*/
set identity_insert sales off;

insert into product_Categories values(1,'Fruits');
insert into product_Categories values(2,'Juice');
insert into product_Categories values(3,'Chocolate');

insert into product values (5,'Orange',106.5,1);
insert into product values (10,'Apple',50.4,2);
insert into product values (3,'Merci',70.0,3);
insert into product(product_ID,product_Name,market_Price) values (1,'Rice',35.0);

select * from product_Categories

create view V1 as select product_ID,product_Name from product;

select * from V1;

select customer_ID,email,phone from Customer; 

select top 3 * from sales; /*Get the first 3 lines of data*/

select top 3 percent * from sales; /*Get 3% of the data*/

select * from sales order by sale_ID offset 3 rows fetch next 5 rows only; /*Skip the first 3 lines and retrieve the first 5 lines after them ,
                                                                             i can't use fetch without order by clause*/
select count(sale_ID) from sales;
select avg(sale_ID) from sales;

select 
    p.product_ID,
    p.product_Name,
    p.market_Price,
    pc.category_Name
from 
    product p
left join
    product_Categories pc
on 
    p.category_ID = pc.category_ID;


select 
    p.product_ID,
    p.product_Name,
    p.market_Price,
    pc.category_Name
from 
    product p
 join
    product_Categories pc
on 
    p.category_ID = pc.category_ID;


/*Simple Function: Calculate Discounted Price
This function calculates the final price after applying a discount to a product's market price.*/

CREATE FUNCTION dbo.CalculateDiscountedPrice (
    @product_ID INT,
    @discount DECIMAL(8,2)
)
RETURNS DECIMAL(8,2)
AS
BEGIN
    DECLARE @market_Price DECIMAL(8,2);
    SELECT @market_Price = market_Price FROM product WHERE product_ID = @product_ID;
    RETURN @market_Price - (@market_Price * @discount / 100);
END;

/*we can call this function as follows:*/
SELECT dbo.CalculateDiscountedPrice(5, 10); -- Calculates the price of product with ID 5 with a 10% discount


/*Complex Function: Retrieve Sales Summary
This function returns a summary of sales, including the total price, discount, final price, customer details, and employee details.*/

CREATE FUNCTION dbo.GetSalesSummary (
    @sale_ID INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        s.sale_ID,
        s.sale_Date,
        s.total_Price,
        s.discount,
        s.final_Price,
        c.customer_ID,
        c.first_Name AS customer_FirstName,
        c.last_Name AS customer_LastName,
        c.email AS customer_Email,
        c.phone AS customer_Phone,
        e.employee_ID,
        e.first_Name AS employee_FirstName,
        e.last_Name AS employee_LastName,
        e.hire_Date,
        e.gender,
        e.contract_Type
    FROM 
        sales s
    JOIN 
        Customer c ON s.customer_ID = c.customer_ID
    JOIN 
        employee e ON s.employee_ID = e.employee_ID
    WHERE 
        s.sale_ID = @sale_ID
);

/*we can call this function as follows:*/
SELECT * FROM dbo.GetSalesSummary(1); -- Retrieves the sales summary for sale with ID 1


/*Stored Procedure: Update Product Market Price
This procedure updates the market price of a product.*/
CREATE PROCEDURE dbo.UpdateProductMarketPrice
    @product_ID INT,
    @new_Market_Price DECIMAL(8,2)
AS
BEGIN
    -- Ensure the new market price is valid
    IF @new_Market_Price <= 0
    BEGIN
        RAISERROR('Market price must be greater than 0.', 16, 1);
        RETURN;
    END
    
    -- Update the market price
    UPDATE product
    SET market_Price = @new_Market_Price
    WHERE product_ID = @product_ID;

    -- Check if the update was successful
    IF @@ROWCOUNT = 0
    BEGIN
        RAISERROR('Product ID not found.', 16, 1);
    END
END;

/*we can call this procedure as follows:*/
EXEC dbo.UpdateProductMarketPrice @product_ID = 5, @new_Market_Price = 120.00;
