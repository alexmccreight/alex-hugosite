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

#Joint Probabilities P(State j at time t-1, State k at time t | data)
#Posterior Probabilities P(State j at time t | data)
SwitchProbs <- function(mod){
  #Can I adjust this for new data?
  
  #Calculate Transition Probabilities based on Model Estimates
  tranprobs <- function(x,t,A){
    #browser()
    #If there are covariates, incorporate into transition probability calculations
    if(!is.na(t)&!is.null(A) & 'qcov' %in% names(x$paramdata$estimates.t) ){
      as.vector(pmatrix.msm(x = x,t = t, covariates = A))
    }else if(!is.na(t)&is.null(A)){
      as.vector(pmatrix.msm(x=x,t=t))
    }else{ rep(NA,4)}
  }
  
  #Organize Data to Calculate Difference in Time and Covariate Values
  
  if(length(all.vars(mod$covariates)) > 0){
    tmp <- model.matrix(mod$covariates,mod$data$mf) %>% 
      as.data.frame() %>% select(-`(Intercept)`) %>% 
      bind_cols(mod$data$mf %>% select(`(subject)`, `(time)`)) %>% 
      group_by(`(subject)`, `(time)`) %>%
      nest() %>% ungroup()
  }else{ tmp <- mod$data$mf; tmp$data = NA }
  tmp <- tmp %>% 
    arrange(`(subject)`, `(time)`) %>%
    group_by(`(subject)`) %>%
    mutate(t = `(time)` - lag(`(time)`) ) %>% 
    mutate(A = lag(data)) %>%
    ungroup() 
  
  
  newdata <- tmp %>%
    select(t, A) %>%
    pmap(.f = tranprobs, x=mod) %>% 
    enframe() %>% 
    mutate(transition = list(c('s1s1', 's2s1', 's1s2', 's2s2'))) %>% 
    bind_cols(select(tmp, `(subject)`, `(time)`)) %>% 
    unnest() %>% pivot_wider(names_from = transition, values_from = value) %>% 
    select(-name) %>% right_join(mod$data$mf)
  
  
  # Emission probabilities [Manually coded for 2 states with same dist effects]
  modelparams <- mod$hmodel$pars
  hcovparams <- mod$hmodel$coveffect
  
  
  if(length(hcovparams) > 0){      
    newdata <- newdata %>% bind_cols(data.frame(mean=model.matrix(mod$hcovariates[[1]],newdata)[,-1] %*% matrix(hcovparams,ncol=2)))
    
    newdata <- newdata %>% 
      mutate(resid1 = `(state)` - mean.1,
             resid2 = `(state)` - mean.2,
             pdf1 = dnorm(resid1, mean = modelparams[1], sd = modelparams[2]),
             pdf2 = dnorm(resid2, mean = modelparams[3], sd = modelparams[4])) 
  }else{
    newdata <- newdata %>%
      mutate(resid1 = `(state)`,
             resid2 = `(state)`,
             pdf1 = dnorm(resid1,mean = modelparams[1],sd = modelparams[2]),
             pdf2 = dnorm(resid2,mean = modelparams[3],sd = modelparams[4]))
  }
  
  #start probs
  newdata <- newdata %>%
    mutate(f1=0,f2=0,b1=0,b2=0,
           s1s1 = if_else(is.na(s1s1), .95,s1s1),
           s2s1 = if_else(is.na(s2s1), 0,s2s1),
           s1s2 = if_else(is.na(s1s2), 0,s1s2),
           s2s2 = if_else(is.na(s2s2), .05,s2s2))
  
  
  #forward probability
  create_f <- function(data){
    data$f1[1] <- data$pdf1[1]*data$s1s1[1]
    data$f2[1] <- data$pdf2[1]*data$s2s2[1]
    
    for(i in 2:nrow(data)){
      data$f1[i] <- data$pdf1[i]*(data$s1s1[i]*data$f1[i-1] + data$s2s1[i]*data$f2[i-1])
      data$f2[i] <- data$pdf2[i]*(data$s1s2[i]*data$f1[i-1] + data$s2s2[i]*data$f2[i-1])
    }
    return(data)
  }
  
  
  newdata <- newdata %>% 
    split(.$`(subject)`) %>%
    map_dfr(.f = ~create_f(data = .x), .id = '(subject)')
  
  #newdata <- newdata %>% 
  #mutate(pastProb1 = f1 /(f1+f2), pastProb2 = f2 /(f1+f2))
  
  #backward probability
  create_b <- function(data){
    n <- nrow(data)
    data$b1[n] <- 1
    data$b2[n] <- 1 
    
    for(i in (n-1):1){
      data$b1[i] <- data$pdf1[i+1]*data$s1s1[i+1]*data$b1[i+1] + data$pdf2[i+1]*data$s1s2[i+1]*data$b2[i+1]
      data$b2[i] <- data$pdf1[i+1]*data$s2s1[i+1]*data$b1[i+1] + data$pdf2[i+1]*data$s2s2[i+1]*data$b2[i+1]
    }
    return(data)
  }
  
  newdata <- newdata %>% 
    split(.$`(subject)`) %>%
    map_dfr(.f = ~create_b(data = .x), .id = '(subject)')
  
  
  #Joint Transition Probability (conditional on data)
  ##lag forward prob f1, and use b2 and pdf2 and s1s2
  newdata <- 
    newdata %>% 
    arrange(`(subject)`,`(time)`) %>%
    group_by(`(subject)`) %>%
    mutate(f1lag = lag(f1), f2lag = lag(f2)) %>% 
    ungroup() %>%
    mutate(joint.s1s1 = b1*pdf1*s1s1*f1lag,
           joint.s1s2 = b2*pdf2*s1s2*f1lag,
           joint.s2s1 = b1*pdf1*s2s1*f2lag,
           joint.s2s2 = b2*pdf2*s2s2*f2lag) %>%
    mutate(jointprob.s1s1 = joint.s1s1/(joint.s1s1+joint.s1s2+joint.s2s1+joint.s2s2),
           jointprob.s1s2 = joint.s1s2/(joint.s1s1+joint.s1s2+joint.s2s1+joint.s2s2),
           jointprob.s2s1 = joint.s2s1/(joint.s1s1+joint.s1s2+joint.s2s1+joint.s2s2),
           jointprob.s2s2 = joint.s2s2/(joint.s1s1+joint.s1s2+joint.s2s1+joint.s2s2))
  
  newdata <- newdata %>% 
    mutate(pp1 = f1*b1, pp2 = f2*b2) %>%
    mutate(postprob1 = pp1/(pp1+pp2), postprob2 = pp2/(pp1+pp2)) %>%
    mutate(fitted = if_else(postprob1 > postprob2, 1, 2)) %>%
    mutate(Certainty = if_else(postprob1 > postprob2, postprob1, postprob2)) %>%
    mutate(Certainty = round(Certainty*100)/100)
  
  newdata
}