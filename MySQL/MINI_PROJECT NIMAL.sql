create database mp_nimal;
use mp_nimal;

#PART 1 : SALES & DELIVERY

#Imported Tables
select * from cust_dimen;
select * from market_fact;
select * from orders_dimen;
select * from prod_dimen;
select * from shipping_dimen;


#Question 1: Find the top 3 customers who have the maximum number of orders

select * from
(select * , dense_rank()over(order by cnt desc) as renk from
(select cd.Cust_id , cd.Customer_name , count(distinct od.Order_ID) as cnt
from cust_dimen cd
join market_fact mf
using (Cust_id)
join orders_dimen od
using (Ord_id)
group by cd.Cust_id , cd.Customer_name
order by count(od.Order_ID) desc) as t1) as t2
where renk<4;

#Question 2: Create a new column DaysTakenForDelivery that contains the date difference between Order_Date and Ship_Date.

select od.Order_ID , od.Order_Date , od.Ord_id , sd.Ship_Date , sd.Ship_Mode , Ship_ID ,
 datediff(str_to_date(Ship_Date , '%d-%m-%Y') , str_to_date(Order_Date , '%d-%m-%Y' )) as DaysTakenForDelivery
from orders_dimen od
join shipping_dimen sd
using (Order_Id)
order by DaysTakenForDelivery desc;

#Question 3: Find the customer whose order took the maximum time to get delivered.

select * from
(select cd.Cust_id , cd.customer_Name , t1.*
from cust_dimen cd
join market_fact mf
using (Cust_id)
join (select od.Order_ID , od.Order_Date , od.Ord_id , sd.Ship_Date , sd.Ship_Mode , Ship_ID ,
 datediff(str_to_date(Ship_Date , '%d-%m-%Y') , str_to_date(Order_Date , '%d-%m-%Y' )) as DaysTakenForDelivery
from orders_dimen od
join shipping_dimen sd
using (Order_Id))  as t1
using (Ord_id)) t2
order by DaysTakenForDelivery desc limit 1;

#Question 4: Retrieve total sales made by each product from the data (use Windows function)

#Using Window Function
select distinct mf.Prod_id , pd.Product_Sub_Category as Product  , sum(mf.Sales)over(partition by mf.Prod_id) as Total_Sales
from market_fact mf
join prod_dimen pd
using(Prod_id)
order by Total_Sales;


#Using Aggregate Function
select mf.Prod_id , pd.Product_Sub_Category as Product  , sum(mf.Sales) as Total_Sales
from market_fact mf
join prod_dimen pd
using(Prod_id)
group by mf.Prod_id , pd.Product_Sub_Category
order by Total_Sales;

#Question 5: Retrieve the total profit made from each product from the data (use windows function)

select * , if(Total_Profit > 0 , 'Profit','Loss') as `Profit/Loss` from
(select distinct mf.Prod_id ,pd.Product_Sub_Category , sum(profit)over(partition by mf.Prod_id) as Total_Profit 
from market_fact mf
join prod_dimen pd
using(Prod_id)
order by Total_Profit desc ) as t1;

#Question 6: Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011

select * from cust_dimen;
select * from market_fact;
select * from orders_dimen;
select * from prod_dimen;
select * from shipping_dimen;


#JAN
select 'January' , count(distinct cust_id) as Customer_count from market_fact 
where Ord_id in 
(select Ord_id from orders_dimen 
where year(str_to_date(Order_Date,'%d-%m-%Y'))=2011 and month(str_to_date(Order_Date,'%d-%m-%Y'))=1 );



select 'count of repetition' as Description , count(*) from 
((select 'count' as Descirption,count(distinct month) cnt from 
(select customer_name,cd.Cust_id,year(str_to_date(Order_Date,'%d-%m-%Y')) year ,month(str_to_date(Order_Date,'%d-%m-%Y')) month 
from cust_dimen cd 
left join market_fact  mf 
on mf.Cust_id = cd.Cust_id 
left join orders_dimen od 
on od.Ord_id=mf.Ord_id order by 1,2,3,4) t 
where year = 2011 
group  by  customer_name,Cust_id 
having cnt>=12 order by 1)) as y
union all    
(select 'total in january' , count(distinct cust_id) from market_fact 
where Ord_id in 
(select Ord_id from orders_dimen 
where year(str_to_date(Order_Date,'%d-%m-%Y'))=2011 and month(str_to_date(Order_Date,'%d-%m-%Y'))=1 ));




#PART 2 : RESTAURANT

select * from chefmozaccepts;
select * from chefmozcuisine;
select * from chefmozhours4;
select * from chefmozparking;
select * from geoplaces2;
select * from rating_final;
select * from usercuisine;
select * from userpayment;
select * from userprofile;





#Question 1: - We need to find out the total visits to all restaurants under all alcohol categories available.

select * from rating_final;
select * from geoplaces2;

select alcohol as Alcohol_Category , count(alcohol) as `Count of Category` from
(select r.* , g.alcohol from rating_final r
join geoplaces2 g
using (placeID)) as t1
group by alcohol; 



#Question 2: - Let's find out the average rating according to alcohol and price so that we can understand the rating in respective price categories as well.


select alcohol , price , avg(rating) from 
(select r.* , g.alcohol , g.price from rating_final r
join geoplaces2 g
using (placeID)) as t1
group by price , alcohol
order by alcohol;

#Question 3:  Let’s write a query to quantify that what are the parking availability as well in different alcohol categories along with the total number of restaurants.



select Name , alcohol , parking_lot , count(placeID)over(partition by alcohol) `Count of Places` from 
(select g.name , g.placeID , g.alcohol , cp.parking_lot
from geoplaces2 g
join chefmozparking cp
using (placeID)) as t1
order by alcohol;

select alcohol , parking_lot , count(placeID) from 
(select g.name , g.placeID , g.alcohol , cp.parking_lot
from geoplaces2 g
join chefmozparking cp
using (placeID)) as t1
group by alcohol , parking_lot
order by alcohol;

#Question 4: -Also take out the percentage of different cuisine in each alcohol type.

select Alcohol , count(Cuisine) from
(select  g.alcohol as Alcohol ,  cc.Rcuisine as Cuisine
from geoplaces2 g 
join chefmozcuisine cc
using (placeID)) as t1
group by Alcohol
order by Alcohol;

select * , sum(count_restaurant)over(partition by Alcohol) as Total_count , round((count_restaurant / sum(count_restaurant)over(partition by Alcohol)) * 100 , 2)  as percent
from 
(select Alcohol , Cuisine , count(placeID) as count_restaurant from
(select  g.alcohol as Alcohol , placeID , cc.Rcuisine as Cuisine
from geoplaces2 g 
join chefmozcuisine cc
using (placeID)) as t1
group by Alcohol , Cuisine
order by Alcohol) as t2;

#Questions 5: - let’s take out the average rating of each state.

select state , avg(rating) as average
from geoplaces2 g
join rating_final rf
using (placeID)
group by state
order by average;

#Questions 6: -' Tamaulipas' Is the lowest average rated state. 
#Quantify the reason why it is the lowest rated by providing the summary on the basis of State, alcohol, and Cuisine.

select State , Alcohol , Cuisine , avg(Rating) as Average_Rating , count(Rating) as Count_of_Rating from
(select g.placeID as Place_ID, g.state as State, g.alcohol as Alcohol , cc.Rcuisine as Cuisine, r.rating as Rating
from geoplaces2 g
join chefmozcuisine cc
using (placeID)
join rating_final r 
using(placeID)
where state = 'Tamaulipas'
order by rating) as t1
group by State , Alcohol , Cuisine
order by Average_Rating;

#Question 7:  - Find the average weight, food rating, and service rating of the customers who have visited KFC and tried Mexican or Italian types of cuisine, 
#and also their budget level is low.
#We encourage you to give it a try by not using joins.

select distinct u.userid, avg(weight) over( partition by u.userID) as average_weight, name, food_rating, service_rating 
from userprofile u 
join rating_final r
using (userid) 
join geoplaces2 g 
using (placeid)
join usercuisine uc
using (userid) 
where name =  'kfc' and Rcuisine in ('mexican', 'italian') and budget='low';

#Part 3:  Triggers
#Question 1:
#Create two called Student_details and Student_details_backup.

create table Student_details 
(student_id int not null primary key,
student_name varchar(20),
mail_id varchar(20),
mobile_no varchar(20));
create table Student_details_backup
(student_id int not null,
student_name varchar(20),
mail_id varchar(20),
mobile_no varchar(20),
foreign key (student_id) references Student_details(student_id));
create trigger aft_insert after insert
on student_details for each row 
insert into student_details_backup values 
(new.student_id, new.student_name, new.mail_id, new.mobile_no);
insert into student_details values 
(101, 'ABC', 'pqr@gmail.com', '9887900988');
insert into student_details values 
(102, 'DEF', 'stu@gmail.com', '8393848899'),
(103, 'GHI', 'xyz@gmail.com', '7446788539');
select * from student_details;
select * from student_details_backup; 