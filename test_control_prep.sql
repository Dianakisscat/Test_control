

--check if some item level incentives are beyond the offer bank incentive max and min
select * from (
select a.*,b.incentive_max,b.incentive_min from
(select distinct precima_ofb_id,type,precimaofferid,incentive_tmp from final_offer_assgmt_window_dm1 where type in ('vendor','product'))a
left join
msn_campaign_offer_bank_ty_incentive b
on a.precima_ofb_id=b.precima_ofb_id)a
where incentive_tmp>incentive_max or incentive_tmp <incentive_min;





--transpose Garcia's PE table
create temp table dy_pe_1 as select cust_acct_key,ofb_id,pe,1 as incentive_level,incentive_min as incentive,incentive_per_min as inc_percent from garcia_cust_ofb_incentive_lift_new; 
create temp table dy_pe_2 as select cust_acct_key,ofb_id,pe,2 as incentive_level,incentive_1 as incentive,incentive_per_1 as inc_percent from garcia_cust_ofb_incentive_lift_new ;
create temp table dy_pe_3 as select cust_acct_key,ofb_id,pe,3 as incentive_level,incentive_2 as incentive,incentive_per_2 as inc_percent from garcia_cust_ofb_incentive_lift_new;
create temp table dy_pe_4 as select cust_acct_key,ofb_id,pe,4 as incentive_level,incentive_3 as incentive,incentive_per_3 as inc_percent from garcia_cust_ofb_incentive_lift_new ;
create temp table dy_pe_5 as select cust_acct_key,ofb_id,pe,5 as incentive_level,incentive_max as incentive,incentive_per_max as inc_percent from garcia_cust_ofb_incentive_lift_new; 

create temp table dy_pe_transpose as
select * from dy_pe_1
union
select * from dy_pe_2
union
select * from dy_pe_3
union
select * from dy_pe_4
union
select * from dy_pe_5;


--MERGE BACK TO FINAL OFFER ASSGMT TABLE
--on all version, including vendor and pe
drop table final_offer_assgmt_dm1_ofb_incentive;
create temp table final_offer_assgmt_dm1_ofb_incentive as
(select *,incentive_min as incentive_min_1, incentive_max as incentive_max_1 from final_offer_assgmt_window_dm1 where type='ofb')
union
(select a.*, b.incentive_min as incentive_min_1,b.incentive_max as incentive_max_1 from 
(select * from final_offer_assgmt_window_dm1 where type in ('vendor', 'product'))a
left join
msn_campaign_offer_bank_ty_incentive b
on a.precima_ofb_id=b.precima_ofb_id);

--For item level offers, restraint to offer bank max and min
drop table final_offer_assgmt_dm1_ofb_incentive_1;
create temp table final_offer_assgmt_dm1_ofb_incentive_1 as
	select *,case 
	when incentive_print>incentive_max_1 then incentive_max_1  
	when incentive_print<incentive_min_1 then incentive_min_1
	else incentive_print end as incentive_print_1
	from final_offer_assgmt_dm1_ofb_incentive;


drop table final_offer_assgmt_dm1_pe_ofb;
create table final_offer_assgmt_dm1_pe_ofb as
select a.*,b.inc_percent from
final_offer_assgmt_dm1_ofb_incentive_1 a
left join
dy_pe_transpose b
on a.cust_acct_key=b.cust_acct_key and a.precima_ofb_id=b.ofb_id and a.incentive_print_1=b.incentive; --16083848



select cust_acct_key, avg(inc_percent) from final_offer_assgmt_dm1_pe_ofb group by 1



