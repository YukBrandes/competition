本项目基于网络借贷信息数据评估贷款风险。
## data
**Master.csv** :
1. idx : 每一笔贷款的unique key
2. UserInfo_*:借款人特征字段
3. WeblogInfo_*:Info网络行为字段
4. Education_Info*:学历学籍字段
5. ThirdParty_Info_PeriodN_*:第三方数据时间段N字段
6. SocialNetwork_*:社交网络字段
7. LinstingInfo:借款成交时间
8. Target:违约标签(1=贷款违约,0=正常还款)

**LogInfo.csv** :
1. idx : 每一笔贷款的unique key
2. ListingInfo : 借款成交时间
3. LogInfo1 : 操作代码
4. LogInfo2 : 操作类别
5. LogInfo3 : 登陆时间

**Userupdate_Info.csv** :
1. idx : 每一笔贷款的unique key
2. ListingInfo1 : 借款成交时间
3. UserupdateInfo1 : 修改内容
4. UserupdateInfo2 : 修改时间

**data_type.csv** : 各表中数据字段的数据类型

## preprocess
### Log Info preprocess
1. 将一级标签(LogInfo1)与二级标签(LogInfo2)合并为62个联合标签(log_tag)
2. 计算借款时间(Listinginfo1)与log时间(LogInfo3)的时间差,因全都>0，无需拆分成审批前和审批后
3. 变更次数、工作日占比、最远天差、最近天差、天差波动、天差波动标记、多次行为
4. 主流行为(target-0/1独有，target-1多频):无突出特征

### User update Info preprocess
1. 计算借款时间(Listinginfo1)与update时间(UserupdateInfo2)的时间差,因全都>0，无需拆分成审批前和审批后
2. 更新次数、工作日占比、最远天差、最近天差、天差波动、天差波动标记、多次更新项目
3. 主流项目(target-0/1独有，target-1多频):无突出特征

### Master
与Log Info preprocess、User update Info preprocess表合并，计算Information Value 挑选变量

## gbm.R
R语言源代码

## Instructions 
1. 为了保护借款人隐私目的，数据字段已经过脱敏处理。
2. 因为目标变量分布极度偏差，不适合使用AUC评判，在此我使用了KS和召回率。
3. data collected from : [PPD](https://kesci.com/apps/home_log/index.html#!/competition/56cd5f02b89b5bd026cb39c9/content/1)