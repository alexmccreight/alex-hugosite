library(dplyr)
library(ggplot2)
library(readr)
library(tidyr)
library(tibble)
library(purrr)
library(lmtest)
library(sandwich)
library(xtable)
library(broom)

gfr <- read_csv('covariates2.csv')

# Use Baseline Piped Water
gfr <- gfr %>%
  #rename(Id = `scrambled Id`) %>%
  arrange(Id,Years) %>%
  group_by(Id) %>%
  mutate(`Piped water source only` = `Piped water source only`[1]) %>% ungroup()



gfr <- gfr %>% filter(!is.na(eGFR_cre)) %>% 
  mutate(Age_Base = `Age at baseline` - 22.8) %>%
  mutate(Pregnant = if_else(is.na(Pregnant) | Pregnant == '','No',Pregnant)) %>%
  mutate(PregnantYes = if_else(Pregnant == 'Yes',1,0)) %>% 
  mutate(Sex = factor(Sex, levels=c('Male','Female'))) %>% 
  mutate(ValidationSet = if_else(Cohort == 1 & Years > 5,1,0)) #validation is visit 9 and 10 for cohort 1

#gfr %>% distinct(Id,Age_Base) %>% pull(Age_Base) %>% mean()

gfr %>%
  group_by(Id,Cohort,ValidationSet) %>%
  dplyr::summarize(Count = dplyr::n())  %>% filter(Count > 3 & ValidationSet == 0) %>% ungroup() %>% group_by(Cohort) %>% dplyr::summarize(dplyr::n())


gfr_sub <- gfr %>%
  filter(ValidationSet == 0) %>%
  group_by(Id) %>%
  dplyr::mutate(Count = dplyr::n()) %>%
  ungroup() %>%
  filter(Count > 3) %>%
  select(-Count)

gfr_sub <- gfr_sub %>% 
  filter(Years <= 1 & PregnantYes == 0) %>%   
  group_by(Id) %>% 
  arrange(Visit) %>%
  slice(1) %>%
  mutate(Baseline = eGFR_cre) %>% 
  ungroup() %>% 
  distinct(Baseline,Id) %>% 
  right_join(gfr_sub) %>%
  filter(!is.na(Baseline)) 

gfr_sub_both <- gfr_sub %>%
  filter(!is.na(eGFR_cre)) %>%
  mutate(egfrChg = eGFR_cre  - Baseline) %>% 
  mutate(egfrPer = (eGFR_cre - Baseline)/Baseline) %>%
  select(Id,Years,egfrChg,egfrPer,eGFR_cre,Baseline,Sex,Age_Base ,PregnantYes, Visit) %>% 
  arrange(Id,Years) 

gfr_sub_both <- gfr_sub_both %>%
  mutate(eGFRCat = factor(case_when(
    eGFR_cre > 90 ~ "Normal",
    eGFR_cre <= 90 ~ "Low"),levels=c('Normal','Low')))%>%
  mutate(eGFRPerCat = factor(case_when(
    egfrPer > -.10 ~ "Normal",
    egfrPer <= -.10 ~ "Low"),levels=c('Normal','Low')))

require(Matrix)

reorderLCMM = function(x,neworder,K){
  NPROB <- x$N[1] # number of class covariates
  NEF <- x$N[2] # number of covariates
  NVC <- x$N[3] # variance covariance matrix
  NW <- x$N[4]
  ncor <- x$N[5]
  NPM <- length(x$best) # total number of covariates, variance covariance, and standard error
  
  C1 = matrix(0,NPROB,NPROB) #create a nprob x nprob matrix of 0's
  tmp = neworder[-K] # what is the format of the neworder vector?
  tmp[tmp == K] = NA # is K the number of groups?
  indx2 = as.vector(matrix(1:NPROB,nrow=K-1)[tmp,])
  for(i in 1:NPROB){
    if(neworder[K] < K){
      indx1 = rep(matrix(1:NPROB,nrow=K-1)[neworder[K],],each=K-1)
      C1[i,indx1[i]] = -1 #subtracting new last group
    }
    C1[i,indx2[i]] = 1 
  }
  C = list(C1)
  
  C2 = matrix(0,NEF,NEF)
  indx = as.vector(matrix(1:NEF,nrow=K)[neworder,])
  for(i in 1:NEF){
    C2[i,indx[i]] = 1 
  }
  C[['C2']] = C2 
  
  if(NVC>0){
    C3 = diag(NVC)
    C[['C3']] = C3
  }
  if(NW>0){ 
    C4 = diag(NW)
    C[['C4']] = C4 
  }
  if(ncor>0){ 
    C5 = diag(ncor)
    C[['C5']] = C5
  }
  C[['C6']] = diag(1) 
  
  
  Cfull = bdiag(C) #Not touching the Random Effect proportions
  tmpnames = names(x$best)
  x$best = as.matrix(Cfull %*% x$best)      
  names(x$best) = tmpnames
  
  
  fullV = diag(NPM)
  fullV[upper.tri(fullV,diag=TRUE)] = x$V[1:(NPM*(NPM+1)/2)] #only upper triangle info
  fullV <- fullV + t(fullV) - diag(diag(fullV))
  newfullV = Cfull %*% fullV %*% t(Cfull)
  
  x$V = newfullV[upper.tri(newfullV,diag=TRUE)]
  
  
  x$pprob$class = plyr::mapvalues(x$pprob$class, from = neworder, to = 1:K)
  x$pprob[,-(1:2)] = x$pprob[,-(1:2)][,neworder]
  
  x$pred[,-(1:6)] = x$pred[,-(1:6)][,c(neworder,K+neworder)]
  return(x)       
}


