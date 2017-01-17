# library packages
library(psych)
library(RMySQL)
library(woe)
library(gbm)
library(Hmisc)
library(dplyr)
library(pROC)

# dbconnect
conn <- dbConnect(MySQL(),
                  host='127.0.0.1',
                  dbname='temp',
                  user='root',
                  password='8755')

# load data
## province
province <- read.csv('province.csv',
                     header = T,
                     stringsAsFactors = F)
## Master
master_train <- read.csv('data/master_train_1st.csv',
                   header = T,
                   stringsAsFactors = F,
                   na.strings = c('不详',' ',''))
master_train$flag <- 'train'
master_test <- read.csv('data/master_test_1st.csv',
                   header = T,
                   stringsAsFactors = F,
                   na.strings = c('不详',' ',''))
master_test$flag <- 'test'
master <- rbind(master_train,master_test)
master$ListingInfo <- NULL
master$UserInfo_2 <- NULL
master$UserInfo_4 <- NULL
master$UserInfo_8 <- NULL
master$UserInfo_20 <- NULL
master$UserInfo_24 <- NULL
## Log Info
loginfo_train <- read.csv('data/loginfo_train_1st.csv',
                          header = T,
                          stringsAsFactors = F)
loginfo_test <- read.csv('data/loginfo_test_1st.csv',
                         header = T,
                         stringsAsFactors = F)
loginfo <- rbind(loginfo_train,loginfo_test)
loginfo$Listinginfo1 <- as.Date(loginfo$Listinginfo1)
loginfo$LogInfo3 <- as.Date(loginfo$LogInfo3)
## UserupdateInfo
userupdate_train <- read.csv('data/userupdate_info_train_1st.csv',
                             header = T,
                             stringsAsFactors = F)
userupdate_test <- read.csv('data/userupdate_info_test_1st.csv',
                            header = T,
                            stringsAsFactors = F)
userupdate <- rbind(userupdate_train,userupdate_test)
userupdate$ListingInfo1 <- as.Date(userupdate$ListingInfo1)
userupdate$UserupdateInfo2 <- as.Date(userupdate$UserupdateInfo2)

# preprocess 1st
## Master
factor_var <- c('UserInfo_1',
                'UserInfo_2',
                'UserInfo_3',
                'UserInfo_4',
                'UserInfo_5',
                'UserInfo_6',
                'UserInfo_7',
                'UserInfo_8',
                'UserInfo_9',
                'UserInfo_11',
                'UserInfo_12',
                'UserInfo_13',
                'UserInfo_14',
                'UserInfo_15',
                'UserInfo_16',
                'UserInfo_17',
                'UserInfo_19',
                'UserInfo_20',
                'UserInfo_21',
                'UserInfo_22',
                'UserInfo_23',
                'UserInfo_24',
                'Education_Info1',
                'Education_Info2',
                'Education_Info3',
                'Education_Info4',
                'Education_Info5',
                'Education_Info6',
                'Education_Info7',
                'Education_Info8',
                'WeblogInfo_19',
                'WeblogInfo_20',
                'WeblogInfo_21',
                'SocialNetwork_1',
                'SocialNetwork_2',
                'SocialNetwork_7',
                'SocialNetwork_12',
                'target')
### UserInfo_9
master$UserInfo_9[master$UserInfo_9 %in% c("中国移动 ","中国移动")] <- '10086'
master$UserInfo_9[master$UserInfo_9 %in% c("中国电信 ","中国电信")] <- '10000'
master$UserInfo_9[master$UserInfo_9 %in% c("中国联通 ","中国联通")] <- '10010'
unique(master$UserInfo_9)
### UserInfo_7&19
province$province <- substring(province$province,1,2)
master$UserInfo_7 <- substring(master$UserInfo_7,1,2)
master$UserInfo_19 <- substring(master$UserInfo_19,1,2)
for(i in 1:length(province$code)){
  master$UserInfo_7[master$UserInfo_7 %in% province$province[i]] = province$code[i]
  master$UserInfo_19[master$UserInfo_19 %in% province$province[i]] = province$code[i]
}
unique(master$UserInfo_7)
unique(master$UserInfo_19)
master[names(master) %in% factor_var] <- data.frame(lapply(master[names(master) %in% factor_var],factor))
summary(master)
dbWriteTable(conn,
             'target',
             master[,c(1,227)],
             overwrite = T,
             row.names=FALSE)
## Log Info
loginfo$log_tag <- paste(loginfo$LogInfo1,loginfo$LogInfo2,sep='_')
loginfo$log_tag <- sub(' ','',loginfo$log_tag)
loginfo$log_tag <- factor(loginfo$log_tag)
unique(loginfo$log_tag)
loginfo$diffdays <- as.numeric(loginfo$Listinginfo1-loginfo$LogInfo3)
loginfo$Listinginfo1_week <- factor(weekdays(loginfo$Listinginfo1))
loginfo$LogInfo3_week <- factor(weekdays(loginfo$LogInfo3))
levels(loginfo$Listinginfo1_week) <- c('tuesday','saturday','sunday','wednesday','thursday','friday','monday')
levels(loginfo$LogInfo3_week) <- c('tuesday','saturday','sunday','wednesday','thursday','friday','monday')
summary(loginfo)
dbWriteTable(conn,
             'loginfo',
             loginfo[,c(1,6:9)],
             overwrite = T,
             row.names=FALSE)
write.csv(prop.table(table(loginfo$log_tag)),'tag_common.csv')
## UserupdateInfo
userupdate$UserupdateInfo1 <- sub(pattern = "_", replacement = "",userupdate$UserupdateInfo1)
userupdate$UserupdateInfo1 <- factor(userupdate$UserupdateInfo1)
userupdate$UserupdateInfo2_week <- factor(weekdays(userupdate$UserupdateInfo2))
levels(userupdate$UserupdateInfo2_week) <- c('tuesday','saturday','sunday','wednesday','thursday','friday','monday')
userupdate$diffdays <- as.numeric(userupdate$ListingInfo1-userupdate$UserupdateInfo2)
summary(userupdate)
dbWriteTable(conn,
             'userupdate',
             userupdate[,c(1,3,5:7)],
             overwrite = T,
             row.names=FALSE)
write.csv(prop.table(table(userupdate$UserupdateInfo1)),'update_common.csv')

# preprocess 2nd
loginfo <- dbReadTable(conn,'loginfo_all')
loginfo$fre_log_tag <- factor(loginfo$fre_log_tag)
userupdate <- dbReadTable(conn,'userupdate_all')
userupdate$fre_update_item <- factor(userupdate$fre_update_item)
base <- merge(master,loginfo,by='Idx',all.x = T)
base <- merge(base,userupdate,by='Idx',all.x = T)
## output sta
factor_var <- NA
for(i in 1:length(base)){
  if(is.factor(base[,i])){
    print(i)
    factor_var <- c(factor_var,names(base)[i])
  }
}
factor_var <- factor_var[-1]

write.csv(data.frame(describe(base)),
          'base_describe.csv')
write.csv(summary(base[,!names(base) %in% factor_var]),
          'base_numeric_summary.csv')
write.csv(summary(base[,names(base) %in% factor_var]),
          'base_factor_summary.csv')
write.csv(data.frame(lapply(base[,-1],function(x) { return(names(which.max(table(x)))) })),
          'max_frequencyVar.csv')
write.csv(data.frame(lapply(base[,-1],function(x) { return(max(prop.table(table(x)))) })),
          'sparse_degree.csv')
## woe
dbDisconnect(conn)
train <- base[base$flag=='train',]
train <- data.frame(lapply(train,function(x){x <- as.numeric(x)-1}))
row.names(train) <- NULL
train$flag <- NULL
train.iv <- iv.mult(train[,-1],
                    'target',
                    summary=TRUE)
iv.plot.summary(train.iv)
write.csv(train.iv,
          'train.iv.csv')
## delete variables
base_model <- base[,c('Idx',
                      'target',
                      'UserInfo_12',
                      'UserInfo_13',
                      'UserInfo_14',
                      'UserInfo_15',
                      'UserInfo_16',
                      'WeblogInfo_20',
                      'ThirdParty_Info_Period1_10',
                      'ThirdParty_Info_Period1_13',
                      'ThirdParty_Info_Period1_15',
                      'ThirdParty_Info_Period1_3',
                      'ThirdParty_Info_Period1_6',
                      'ThirdParty_Info_Period1_8',
                      'ThirdParty_Info_Period1_9',
                      'ThirdParty_Info_Period2_1',
                      'ThirdParty_Info_Period2_10',
                      'ThirdParty_Info_Period2_11',
                      'ThirdParty_Info_Period2_13',
                      'ThirdParty_Info_Period2_15',
                      'ThirdParty_Info_Period2_17',
                      'ThirdParty_Info_Period2_2',
                      'ThirdParty_Info_Period2_3',
                      'ThirdParty_Info_Period2_6',
                      'ThirdParty_Info_Period2_8',
                      'ThirdParty_Info_Period2_9',
                      'ThirdParty_Info_Period3_1',
                      'ThirdParty_Info_Period3_10',
                      'ThirdParty_Info_Period3_15',
                      'ThirdParty_Info_Period3_2',
                      'ThirdParty_Info_Period3_3',
                      'ThirdParty_Info_Period3_6',
                      'ThirdParty_Info_Period3_8',
                      'ThirdParty_Info_Period3_9',
                      'ThirdParty_Info_Period4_1',
                      'ThirdParty_Info_Period4_10',
                      'ThirdParty_Info_Period4_13',
                      'ThirdParty_Info_Period4_14',
                      'ThirdParty_Info_Period4_15',
                      'ThirdParty_Info_Period4_16',
                      'ThirdParty_Info_Period4_17',
                      'ThirdParty_Info_Period4_2',
                      'ThirdParty_Info_Period4_3',
                      'ThirdParty_Info_Period4_4',
                      'ThirdParty_Info_Period4_5',
                      'ThirdParty_Info_Period4_6',
                      'ThirdParty_Info_Period4_7',
                      'ThirdParty_Info_Period4_8',
                      'ThirdParty_Info_Period4_9',
                      'ThirdParty_Info_Period5_1',
                      'ThirdParty_Info_Period5_10',
                      'ThirdParty_Info_Period5_11',
                      'ThirdParty_Info_Period5_13',
                      'ThirdParty_Info_Period5_14',
                      'ThirdParty_Info_Period5_15',
                      'ThirdParty_Info_Period5_16',
                      'ThirdParty_Info_Period5_17',
                      'ThirdParty_Info_Period5_2',
                      'ThirdParty_Info_Period5_3',
                      'ThirdParty_Info_Period5_4',
                      'ThirdParty_Info_Period5_5',
                      'ThirdParty_Info_Period5_6',
                      'ThirdParty_Info_Period5_7',
                      'ThirdParty_Info_Period5_8',
                      'ThirdParty_Info_Period5_9',
                      'ThirdParty_Info_Period6_1',
                      'ThirdParty_Info_Period6_10',
                      'ThirdParty_Info_Period6_11',
                      'ThirdParty_Info_Period6_12',
                      'ThirdParty_Info_Period6_13',
                      'ThirdParty_Info_Period6_14',
                      'ThirdParty_Info_Period6_15',
                      'ThirdParty_Info_Period6_16',
                      'ThirdParty_Info_Period6_17',
                      'ThirdParty_Info_Period6_2',
                      'ThirdParty_Info_Period6_3',
                      'ThirdParty_Info_Period6_4',
                      'ThirdParty_Info_Period6_5',
                      'ThirdParty_Info_Period6_6',
                      'ThirdParty_Info_Period6_7',
                      'ThirdParty_Info_Period6_8',
                      'ThirdParty_Info_Period6_9',
                      'WeblogInfo_15',
                      'flag')]
base_model$WeblogInfo_20[base_model$WeblogInfo_20==''] <- NA
base_model$WeblogInfo_20 <- factor(as.character(base_model$WeblogInfo_20))
summary(base_model)

# output data
rm(list = c('master_train',
            'master_test',
            'loginfo_train',
            'loginfo_test',
            'userupdate_train',
            'userupdate_test',
            'factor_var',
            'conn',
            'i'))

# model
## train & test
summary(base_model[2:8])
base_model[2:8] <- data.frame(lapply(base_model[2:8],function(x){ as.numeric(x)-1 }))
train <- base_model[base_model$flag=='train',]
test <- base_model[base_model$flag=='test',]
train$flag <- NULL
row.names(train) <- NULL
test$flag <- NULL
row.names(test) <- NULL
prop.table(table(train$target))
prop.table(table(test$target))
summary(train)
## GBM
set.seed(7)
gbm_demo <- gbm(formula = target ~ .,
                data = train[,-1],
                distribution = "bernoulli",
                interaction.depth = 10,
                n.minobsinnode = 2,
                shrinkage = 0.1,
                bag.fraction = 0.5,
                n.trees = 120,
                cv.folds = 10,
                keep.data = TRUE,
                verbose = FALSE,
                n.cores = 4)

gbm.perf(gbm_demo,method = 'cv')

## ks evaluate
Ks <- function(train.df,test.df,model,ntree){
  train.predict <- data.frame(actual = train.df$target,
                              predict = predict(model,train.df,n.trees = ntree))
  
  test.predict <- data.frame(actual = test.df$target,
                             predict = predict(model,test.df,n.trees = ntree))
  
  train.roc <- gbm.roc.area(train.predict$actual,train.predict$predict)
  test.roc <- gbm.roc.area(test.predict$actual,test.predict$predict)
  
  train.predict$group <- as.numeric(cut2(rank(train.predict$predict,ties.method = "random"),g=10))
  
  test.predict$group <- as.numeric(cut2(rank(test.predict$predict,ties.method = "random"),g=10))
  
  train.predict <- group_by(train.predict,group) %>% 
    summarise(.,
              target_0 = length(actual[actual == 0]),
              target_1 = length(actual[actual == 1]),
              target_0_percent = target_0 / 27802,
              target_1_percent = target_1 / 2198)
  
  test.predict <- group_by(test.predict,group) %>% 
    summarise(.,
              target_0 = length(actual[actual == 0]),
              target_1 = length(actual[actual == 1]),
              target_0_percent = target_0 / 18479,
              target_1_percent = target_1 / 1520)
  
  train.predict$differ <- cumsum(train.predict$target_0_percent) - cumsum(train.predict$target_1_percent)
  test.predict$differ <- cumsum(test.predict$target_0_percent) - cumsum(test.predict$target_1_percent)
  
  train.ks <- max(train.predict$differ)
  test.ks <- max(test.predict$differ)
  
  return(c(train.roc,test.roc,train.ks,test.ks,ntree))
}

for(i in 1:70) {
  print(Ks(train,test,gbm_demo,i))  ## 47 may be better
}

## 召回率
train$predict <- predict(gbm_demo,train,n.trees = 70,type='response')
test$predict <- predict(gbm_demo,test,n.trees = 70,type='response')
gbm_demo_train_roc <- roc(train$target,train$predict)
plot(gbm_demo_train_roc,
     print.auc=TRUE,
     auc.polygon=TRUE,
     print.thres=T,
     max.auc.polygon=T,
     auc.polygon.col="#66CCFF")
train$class <- ifelse(train$predict < 0.08,0,1)
test$class <- ifelse(test$predict < 0.08,0,1)
train.recall <-  sum(train$class[train$target == 1])/2198
test.recall <- sum(test$class[test$target == 1])/1520

train$predict <- predict(gbm_demo,train,n.trees = 47,type='response')
test$predict <- predict(gbm_demo,test,n.trees = 47,type='response')
gbm_demo_train_roc <- roc(train$target,train$predict)
plot(gbm_demo_train_roc,
     print.auc=TRUE,
     auc.polygon=TRUE,
     print.thres=T,
     max.auc.polygon=T,
     auc.polygon.col="#66CCFF")
train$class <- ifelse(train$predict < 0.07,0,1)
test$class <- ifelse(test$predict < 0.07,0,1)
train.recall <-  sum(train$class[train$target == 1])/2198
test.recall <- sum(test$class[test$target == 1])/1520
write.csv(summary(gbm_demo),'gbm_demo_rel.csv',row.names = F)

# modeling round2
train <- train[,c('Idx',
                  'ThirdParty_Info_Period2_6',
                  'ThirdParty_Info_Period1_6',
                  'ThirdParty_Info_Period4_15',
                  'WeblogInfo_20',
                  'ThirdParty_Info_Period2_2',
                  'ThirdParty_Info_Period3_3',
                  'ThirdParty_Info_Period2_13',
                  'ThirdParty_Info_Period2_15',
                  'ThirdParty_Info_Period5_5',
                  'WeblogInfo_15',
                  'UserInfo_14',
                  'ThirdParty_Info_Period3_8',
                  'ThirdParty_Info_Period4_2',
                  'ThirdParty_Info_Period2_8',
                  'ThirdParty_Info_Period2_17',
                  'ThirdParty_Info_Period1_8',
                  'ThirdParty_Info_Period1_15',
                  'ThirdParty_Info_Period4_5',
                  'ThirdParty_Info_Period2_1',
                  'ThirdParty_Info_Period5_1',
                  'ThirdParty_Info_Period2_3',
                  'ThirdParty_Info_Period5_3',
                  'ThirdParty_Info_Period1_13',
                  'ThirdParty_Info_Period3_15',
                  'ThirdParty_Info_Period4_6',
                  'ThirdParty_Info_Period5_6',
                  'ThirdParty_Info_Period4_14',
                  'ThirdParty_Info_Period1_3',
                  'ThirdParty_Info_Period2_11',
                  'ThirdParty_Info_Period6_1',
                  'ThirdParty_Info_Period3_2',
                  'ThirdParty_Info_Period5_15',
                  'ThirdParty_Info_Period5_14',
                  'ThirdParty_Info_Period5_8',
                  'UserInfo_16',
                  'ThirdParty_Info_Period5_2',
                  'ThirdParty_Info_Period6_5',
                  'ThirdParty_Info_Period3_1',
                  'ThirdParty_Info_Period4_4',
                  'ThirdParty_Info_Period6_14',
                  'ThirdParty_Info_Period4_16',
                  'ThirdParty_Info_Period4_13',
                  'ThirdParty_Info_Period4_17',
                  'ThirdParty_Info_Period4_3',
                  'ThirdParty_Info_Period4_8',
                  'UserInfo_15',
                  'UserInfo_12',
                  'target')]

gbm_final <- gbm(formula = target ~ .,
                 data = train[,-1],
                 distribution = "bernoulli",
                 interaction.depth = 10,
                 n.minobsinnode = 2,
                 shrinkage = 0.1,
                 bag.fraction = 0.5,
                 n.trees = 120,
                 cv.folds = 10,
                 keep.data = TRUE,
                 verbose = FALSE,
                 n.cores = 4)
## KS
summary(gbm_final)
for(i in 1:86) {
  print(Ks(train,test,gbm_final,i))  ## 48 61 86
}
## 召回率
train$predict <- predict(gbm_final,train,n.trees = 86,type='response') # 48 61 86
test$predict <- predict(gbm_final,test,n.trees = 86,type='response')
gbm_final_train_roc <- roc(train$target,train$predict)
plot(gbm_final_train_roc,
     print.auc=TRUE,
     auc.polygon=TRUE,
     print.thres=T,
     max.auc.polygon=T,
     auc.polygon.col="#66CCFF")
train$class <- ifelse(train$predict < 0.069,0,1)
test$class <- ifelse(test$predict < 0.069,0,1)
sum(train$class[train$target == 1])/2198
sum(test$class[test$target == 1])/1520

# predict
test$predict <- predict(gbm_final,test,n.trees = 86,type='response')
Ks(train,test,gbm_final,i)
Ks(train,test,gbm_demo,86)[2]
Ks(train,test,gbm_demo,86)[4]
sum(test$class[test$target == 1])/1520
