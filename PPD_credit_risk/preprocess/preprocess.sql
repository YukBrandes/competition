# log_info
## loginfo_tag
create table loginfo_tag
SELECT 
    Idx,
    log_tag,
    COUNT(*) log_tag_num,
	sum(case when LogInfo3_week in ('saturday','sunday') then 0 else 1 end)/COUNT(*) log_tag_inweek,
    MAX(diffdays) log_diffdays_tag_max,
    MIN(diffdays) log_diffdays_tag_min,
    std(diffdays) log_diffdays_tag_std,
    case when std(diffdays)=0 then 0 else 1 end log_diffdays_tag_std_flag
FROM
    temp.loginfo
GROUP BY Idx,log_tag;

## loginfo_all
create table loginfo_all
select a.*,b.fre_log_tag,b.fre from
(SELECT 
    Idx,
    COUNT(*) log_num,
    sum(case when Listinginfo1_week in ('saturday','sunday') then 0 else 1 end)/COUNT(*) apply_inweek,
	sum(case when LogInfo3_week in ('saturday','sunday') then 0 else 1 end)/COUNT(*) log_inweek,
    MAX(diffdays) log_diffdays_max,
    MIN(diffdays) log_diffdays_min,
    std(diffdays) log_diffdays_std,
    case when std(diffdays)=0 then 0 else 1 end log_diffdays_std_flag
FROM
    temp.loginfo
GROUP BY Idx) a
left join
(select Idx,max(log_tag_num) fre,log_tag fre_log_tag from loginfo_tag group by Idx) b
on a.Idx = b.Idx;

## 主流行为标签
SELECT log_tag,target,sum(log_tag_num) total FROM
(
SELECT a.Idx,log_tag,log_tag_num,target FROM
(SELECT Idx,log_tag,log_tag_num FROM temp.loginfo_tag) a
left join
(SELECT Idx, target FROM temp.target) b
on a.Idx=b.Idx
) c where target = 1
group by log_tag;

SELECT log_tag,target,sum(log_tag_num) total FROM
(
SELECT a.Idx,log_tag,log_tag_num,target FROM
(SELECT Idx,log_tag,log_tag_num FROM temp.loginfo_tag) a
left join
(SELECT Idx, target FROM temp.target) b
on a.Idx=b.Idx
) c where target = 0
group by log_tag;

# user_update
## userupdate_item
create table userupdate_item
SELECT 
    Idx,
    UserupdateInfo1 update_item,
    COUNT(*) update_item_num,
	sum(case when UserupdateInfo2_week in ('saturday','sunday') then 0 else 1 end)/COUNT(*) update_item_inweek,
    MAX(diffdays) update_diffdays_item_max,
    MIN(diffdays) update_diffdays_item_min,
    std(diffdays) update_diffdays_item_std,
    case when std(diffdays)=0 then 0 else 1 end update_diffdays_item_std_flag
FROM
    temp.userupdate
GROUP BY Idx , UserupdateInfo1;

## userupdate_all
create table userupdate_all
SELECT a.*,b.fre_update_item,b.fre FROM
(SELECT 
    Idx,
    COUNT(*) update_num,
	sum(case when UserupdateInfo2_week in ('saturday','sunday') then 0 else 1 end)/COUNT(*) update_inweek,
    MAX(diffdays) update_diffdays_max,
    MIN(diffdays) update_diffdays_min,
    std(diffdays) update_diffdays_std,
    case when std(diffdays)=0 then 0 else 1 end update_diffdays_std_flag
FROM
    temp.userupdate
GROUP BY Idx) a
left join
(select Idx,max(update_item_num) fre,update_item fre_update_item from userupdate_item group by Idx) b
on a.Idx = b.Idx;

## 主流更新标签
SELECT update_item,target,sum(update_item_num) total FROM
(
SELECT a.Idx,update_item,update_item_num,target FROM
(SELECT Idx,update_item,update_item_num FROM temp.userupdate_item) a
left join
(SELECT Idx, target FROM temp.target) b
on a.Idx=b.Idx
) c where target = 1
group by update_item;

SELECT update_item,target,sum(update_item_num) total FROM
(
SELECT a.Idx,update_item,update_item_num,target FROM
(SELECT Idx,update_item,update_item_num FROM temp.userupdate_item) a
left join
(SELECT Idx, target FROM temp.target) b
on a.Idx=b.Idx
) c where target = 0
group by update_item;