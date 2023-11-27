#Commercial Motivation: https://www.brainhq.com/world-class-science/published-research/active-study?utm_source=google&utm_medium=cpc&utm_campaign=brand&utm_content=46467711+572620444765&utm_term=active%20study&gclid=CjwKCAiAxJSPBhAoEiwAeO_fP9nFK_SpJg5-aBE4F_RdfWbPJSM0-9HspNtaSC181Bdj30StzwM3AhoCYp0QAvD_BwE

#Recent Paper: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4055506/
#Overview Paper: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3934012/

#Data Source: https://www.icpsr.umich.edu/web/ICPSR/studies/36036
#List of Data-related Papers: https://www.icpsr.umich.edu/web/ICPSR/studies/36036/publications

library(dplyr)
library(tidyr)
library(ggplot2)

load('active.rda')
active <- da36036.0023
names(active) <- sub('_BL','_1',names(active))
names(active) <- sub('MMSETOTL','MMSE_1',names(active))
names(active) <- sub('WS_COR','WSCOR',names(active))
names(active) <- sub('LS_COR','LSCOR',names(active))
names(active) <- sub('LT_COR','LTCOR',names(active))

active <- active %>%
  mutate(INTGRP = recode_factor(INTGRP, `1` = 'Memory Training', `2` = 'Reasoning Training', `3` = 'Speed of Processing Training', `4` = 'Control'))
table(active$INTGRP)

activeLong <- active %>% select(-ends_with('_DATE')) %>% gather(var,value,-c('AGE','AID','BOOSTER','DEATH_DUR','DEATH_INDICAT','REPLCODE','SITE','YRSEDUC','INTGRP','GENDER'))  %>%
  separate(var,c('var','time')) %>%
  spread(var,value)

activeLong <- activeLong %>%
  mutate(Years = case_when(
    time == 1 ~ 0,
    time == 2 ~ 0.25,
    time == 3 ~ 1,
    time == 4 ~ 2,
    time == 5 ~ 3,
    time == 6 ~ 5,
    time == 7 ~ 10,
  )) %>%
  mutate(Age = AGE + Years) %>%
  rename(AgeAtBaseline = AGE)


#Goal: Develop a research question about aging related to the clinical trial.

#Outcome Ideas: Reasoning, Memory, Speed of Processing, Functional Outcomes

#Predictors: Treatment Group, Years, Baseline Age, Gender, Baseline Values [of any outcome], Interactions, Reasoning, Memory, Speed of Processing, Functional Outcomes




#MMSE: Cognitive Score (Mini-Mental State Examination)
summary(activeLong$MMSE)

activeLong %>% 
  filter(Years == 0 ) %>% 
  ggplot(aes(x = MMSE, color = factor(INTGRP))) +
  geom_boxplot() + labs(color = 'Treatment Group', title='Baseline MMSE') + theme_classic()

activeLong %>%
  group_by(AID) %>%
  mutate(MMSEBase = MMSE[Years == 0]) %>%
  ungroup() %>%
  mutate(MMSEDiff = MMSE - MMSEBase) %>%
  mutate(AgeCat = cut(AgeAtBaseline,3)) %>%
  filter(Years > .5) %>%
  group_by(AgeCat,INTGRP,GENDER,Years) %>%
  summarize(MMSEDiff = median(MMSEDiff,na.rm=TRUE)) %>%
  ggplot(aes(x = Years, y = MMSEDiff, color = factor(INTGRP))) +
  geom_point()  + geom_line() + facet_grid(AgeCat~GENDER) + theme_classic()

#MEMORY
#AVLT: Rey Auditory-Verbal Learning Test
summary(activeLong$AVLTT)
#HVLT: Hopkins Verbal Learning Test
summary(activeLong$HVLTT)
#IMM: Rivermead Behavioral Paragraph Recall Test
summary(activeLong$IMMRAW)

activeLong <- activeLong %>% 
  mutate(Memory = AVLTT + HVLTT + IMMRAW)

activeLong %>%
  ggplot(aes(x = Years, y = Memory, color = factor(INTGRP), group = AID)) +
  geom_point(alpha = .2)  + geom_line(alpha = .2)  + labs(color = 'Treatment Group') + theme_classic()

activeLong %>%
group_by(INTGRP,Years) %>%
  summarize(Memory = median(Memory,na.rm=TRUE)) %>%
  ggplot(aes(x = Years, y = Memory, color = factor(INTGRP))) +
  geom_point()  + geom_line()  + labs(color = 'Treatment Group') + theme_classic()


#REASONING
#LS: Letter Series
summary(activeLong$LSCOR)
#LT: Letter Sets
summary(activeLong$LTCOR)
#WS: Word Series
summary(activeLong$WSCOR)

activeLong <- activeLong %>% 
  mutate(Reasoning = LSCOR + LTCOR + WSCOR)

activeLong %>%
  ggplot(aes(x = Years, y = Reasoning, color = factor(INTGRP), group = AID)) +
  geom_point(alpha = .2)  + geom_line(alpha = .2)  + labs(color = 'Treatment Group') + theme_classic()


activeLong %>%
  group_by(INTGRP,Years) %>%
  summarize(Reasoning = median(Reasoning,na.rm=TRUE)) %>%
  ggplot(aes(x = Years, y = Reasoning, color = factor(INTGRP))) +
  geom_point()  + geom_line() + labs(color = 'Treatment Group') + theme_classic()


#SPEED-OF-PROCESSING
#UFOV: Useful Field of View (amount of time for correct performance of both the identification and localization tasks was determined)
summary(activeLong$UFOV1)
summary(activeLong$UFOV2)
summary(activeLong$UFOV3)
summary(activeLong$UFOV4)

activeLong <- activeLong %>% 
  mutate(Speed = UFOV1 + UFOV2 + UFOV3 + UFOV4)

activeLong %>%
  ggplot(aes(x = Years, y = Speed, color = factor(INTGRP), group = AID)) +
  geom_point(alpha = .2)  + geom_line(alpha = .2)  + labs(color = 'Treatment Group') + theme_classic()

activeLong %>%
  group_by(INTGRP,Years) %>%
  summarize(Speed = median(Speed, na.rm=TRUE)) %>%
  ggplot(aes(x = Years, y = Speed, color = factor(INTGRP))) +
  geom_point()  + geom_line() + labs(color = 'Treatment Group') + theme_classic()



#FUNCTIONAL OUTCOMES
#ADL: Activities of Daily Living (MDS ADL Total Performance)
summary(activeLong$ADLT)
#DTOTP: MDS IADL Total Difficulty
summary(activeLong$DTOTP) 
#PTOTP: MDS IADL Total Performance
summary(activeLong$PTOTP) 

#EPT: Everyday Problems Test
summary(activeLong$EPT) 

#CRT: Complex Reaction Time
summary(activeLong$CRT1) 
summary(activeLong$CRT2) 

#OTDL: Observed Tasks of Daily Living
summary(activeLong$OTDL) 

#TIADL: Timed IADL
summary(activeLong$TIADL) 

#TOTDS: Total Driving Space (Miles per week)
summary(activeLong$TOTDS) 

#TOTDD: Difficulty of driving conditions
summary(activeLong$TOTDD) 

#DRIVER: Current Driver? Yes (1) or no (0)
summary(activeLong$DRIVER) #yes or no

#DAVOID: #how much a driver avoids difficult driving situations
summary(activeLong$DAVOID) 

#Explanation of Missing Values

#DEATH_INDICAT: MORTALITY status (1=yes, 0=no at the end of the study) 
table(activeLong$DEATH_INDICAT)

#DEATH_DUR: days from randomization date to death date (among those who died before the end of the study)
summary(activeLong$DEATH_DUR)
