---
title: "Introduction to Doubly Robust Estimation"
author: "Alex McCreight"
date: '2023-05-10'
excerpt: For my causal inference capstone, I simulated data and used an incorrectly specified outcome regression model and a correctly specified inverse probability weighting model to show the robustness of doubly robust estimation (and vice-versa.)
---

# Introduction

Estimating causal effects from nonrandomized experiments and observational studies is difficult as they are often riddled with confounders that could potentially bias our data and results. We could employ methods such as regression and inverse probability weighting to help control for confounding, but their effectiveness depends on correct model specification, which is not easy to achieve. Doubly robust estimation offers a unique advantage in this context, as it combines both of these approaches, providing consistent causal effect estimates even if only one of the two models is correctly specified. This robustness makes it an attractive choice for those looking to draw causal inferences from observational data with greater confidence and reliability.

# Simulating the Data & Specifying its Casual Structure

We will generate simulated data to illustrate the limitations of traditional methods in estimating causal effects and demonstrate how the application of doubly robust estimation can effectively address these shortcomings, offering a more reliable approach. We will use ten different simulated data sets and run each model over each data set and take the average of any estimates found to show the properties of the methods used on average. This will eliminate some of the variability from the data, thus making the results more robust. 

When creating my outcome variable, I first create two random variables, a poisson and normal, and use those variables to create my treatment variable. I then take the product of my initial random variables and add five times the treatment variable to get my outcome. Thus, `randomVar1` and `randomVar2` affect treatment and outcome, but not each other. Additionally, treatment only affects the outcome, and the outcome does not affect anything.



```r
library(tidyverse)
library(AIPW)
library(SuperLearner)

# Create 10 data frames of simulated data
for(i in 1:10){
  
  # Create two random variables
  randomVar1 <- rnorm(1000, mean = 0, sd = 1)
  randomVar2 <- rpois(1000, lambda = 3)
  
  # Create a treatment variable using random variables and calculate probability
  treatmentProb <- exp(0.5*randomVar1 + 0.5*randomVar2) / (1 + exp(0.5*randomVar1 + 0.5*randomVar2 ))
  treatment <- rbinom(1000, 1, treatmentProb)
  
  # Define that receiving treatment will result in an ACE of 5
  outcome <- randomVar1*randomVar2 + 5*treatment

  # Create a data frame for this iteration
  assign(paste0("sim_data_", i), data.frame(randomVar1, randomVar2, treatment, outcome))
}
```

# Outcome Regression Approach

## Correctly Specifying our Regression Model


```r
# Place to store the treatment coefficients
treatment_coefficients <- numeric(10)

# Loop through the 10 data frames, run the linear regression and store the results
for (i in 1:10) {
  sim_data <- get(paste0("sim_data_", i))
  lm_result <- lm(outcome ~ randomVar1 * randomVar2 + treatment, data = sim_data)
  treatment_coefficients[i] <- lm_result$coefficients["treatment"]
}

# Calculate the average of the treatment coefficients
mean_treatment_coefficient <- mean(treatment_coefficients)
mean_treatment_coefficient
```

```
## [1] 5
```

To begin the analysis, I ran ten ordinary least squares with the treatment variable and an interaction term of our two random variables. Then I took the average of the treatment coefficient estimates. We know this model was correctly specified, as I defined it during the simulation. So, the result of 5 confirms that the ordinary least squares accurately predicted the average causal effect when properly specified. 

## Incorrectly Specifying our Regression Model


```r
# Place to store the treatment coefficients
treatment_coefficients <- numeric(10)

# Loop through the 10 data frames, run the linear regression, and store the results
for (i in 1:10) {
  sim_data <- get(paste0("sim_data_", i))
  lm_result <- lm(outcome ~ randomVar1 + randomVar2 + treatment, data = sim_data)
  treatment_coefficients[i] <- lm_result$coefficients["treatment"]
}

# Calculate the average of the treatment coefficients
mean_treatment_coefficient <- mean(treatment_coefficients)
mean_treatment_coefficient
```

```
## [1] 4.738624
```

Now, I intentionally misspecified the ordinary least squares model to show that the average causal effect no longer equals 5 when the model is incorrect. In practice, it is not always apparent whether or not to include certain variables or an interaction term. We see that while we included both `randomVar1` and `randomVar2`, the average causal effect is not 5 because we did not include the interaction term as well. 

# IPW Approach

## Correctly Specifying our IPW Model


```r
# Place to store the estimated ACE values
estimated_ACE <- numeric(10)

# Run the IPW 10 times 
for (i in 1:10) {
  sim_data <- get(paste0("sim_data_", i))
  psModCorrect <- glm(treatment ~ randomVar1 * randomVar2, data = sim_data, family = "binomial")
  sim_dataCorrect <- sim_data %>%
    mutate(
      prob = predict(psModCorrect, newdata = sim_data, type = "response")) %>%
    summarize(
      ExpIPWTreatYes = mean(outcome * treatment / prob),
      ExpIPWTreatNo = mean(outcome * (1 - treatment) / (1 - prob))
    ) %>%
    mutate(EstimatedACE = ExpIPWTreatYes - ExpIPWTreatNo)
  
  # Store the estimated ACE in the vector
  estimated_ACE[i] <- sim_dataCorrect$EstimatedACE
}

# Calculate the average of the estimated ACE values
mean_estimated_ACE <- mean(estimated_ACE)
mean_estimated_ACE
```

```
## [1] 5.101151
```

Similarly, we can run an analysis using inverse probability weighting. I created a propensity score model with the treatment variable as the outcome and included the interaction term between the two random variables (thus, the model is properly specified). I then can calculate the expected IPW for the treatment yes group and the treatment no group and take the difference to find the expected average causal effect of around 5.

## Incorrectly Specifying our IPW Model


```r
# Place to store the estimated ACE values
estimated_ACE <- numeric(10)

# Run the IPW 10 times 
for (i in 1:10) {
  sim_data <- get(paste0("sim_data_", i))
  psModIncorrect <- glm(treatment ~ randomVar2, data = sim_data, family = "binomial")
  sim_dataIncorrect <- sim_data %>%
    mutate(
      prob = predict(psModIncorrect, newdata = sim_data, type = "response")) %>%
  summarize(
    ExpIPWTreatYes = mean(outcome * treatment / prob),
    ExpIPWTreatNo = mean(outcome * (1-treatment) / (1-prob))
  ) %>%
  mutate(EstimatedACE = ExpIPWTreatYes - ExpIPWTreatNo)
  
  # Store the estimated ACE in the vector
  estimated_ACE[i] <- sim_dataIncorrect$EstimatedACE
}

# Calculate the average of the estimated ACE values
mean_estimated_ACE <- mean(estimated_ACE)
mean_estimated_ACE
```

```
## [1] 6.513908
```

In this example, I ran a similar inverse probability weighting analysis, but instead of neglecting the interaction term, I only included `randomVar2`. This is another example of model misspecification, and we can see that even when we properly run the estimation process, our estimated expected average causal effect is even further away from the truth.  

# Doubly Robust Estimation using the AIPW package

For my simulation, the ACE (average causal effect) and ATT (the average treatment effect specifically among those who were treated) will be equivalent because there is no treatment effect heterogeneity (treatment effects are the same for all units, as I specified when setting up my simulation.) Thus, we can interpret the ATT and ACE as the same for this case.


```r
# Initialize a vector to store the ATT estimates
att_estimates <- numeric(10)
atc_estimates <- numeric(10)

# Loop through the 10 data frames and run the AIPW estimation
for (i in 1:10) {
  
  # Get the data frame for this iteration
  sim_data <- get(paste0("sim_data_", i))
  
  outcome <- sim_data$outcome
  exposure <- sim_data$treatment

  # Create an interaction term (because we need to take the matrix of the variables we include into our model)
  sim_data <- sim_data %>% 
    mutate(interaction = randomVar1 * randomVar2)

  # Covariates for both outcome model (Q) and exposure model (g)
  outcomeCovariates <- as.matrix(sim_data[5])
  ipwCovariates <- as.matrix(sim_data[1:2])

  AIPW_SL_att <- AIPW$new(Y = outcome,
                          A = exposure,
                          W.Q = outcomeCovariates, #correctly specified 
                          W.g = ipwCovariates, #incorrectly specified, not including the interaction term
                          Q.SL.library = c("SL.mean","SL.glm"),
                          g.SL.library = c("SL.mean","SL.glm"),
                          k_split = 3,
                          verbose = FALSE)
  tmp <- suppressWarnings({
    AIPW_SL_att$stratified_fit()$summary()
  })

  # Store the ATT estimate in the vector
  att_estimates[i] <- tmp[["ATT_estimates"]][["RD"]][["Estimate"]]
  atc_estimates[i] <- tmp[["ATC_estimates"]][["RD"]][["Estimate"]]
}

# Calculate the average of the ATT estimates
mean_att_estimate <- mean(att_estimates)
mean_att_estimate
```

```
## [1] 5
```

Finally, I use doubly robust estimation (also known as augmented inverse probability weighting) to allow two chances to specify the model properly. First, I created ten regression models similar to those from above, and then I created ten IPW models. After the model yielded the ATT estimates, I calculated their averages which is the estimated average causal effect of the truth (contingent upon one of the models being properly specified). After running this simulation, we can see that when misspecifying our IPW model (by not including the interaction term between `randomVar1` and `randomVar2`), I still get estimates of 5 for the ATT, which matches the true average causal effect of the treatment variable. 


```r
# Initialize a vector to store the ATT estimates
att_estimates <- numeric(10)
atc_estimates <- numeric(10)

# Loop through the 10 data frames and run the AIPW estimation
for (i in 1:10) {
  
  # Get the data frame for this iteration
  sim_data <- get(paste0("sim_data_", i))
  
  outcome <- sim_data$outcome
  exposure <- sim_data$treatment

  # Create an interaction term (because we need to take the matrix of the variables we include into our model)
  sim_data <- sim_data %>% 
    mutate(interaction = randomVar1 * randomVar2)

  # Covariates for both outcome model (Q) and exposure model (g)
  ipwCovariates <- as.matrix(sim_data[5])
  outcomeCovariates <- as.matrix(sim_data[1:2])

  AIPW_SL_att <- AIPW$new(Y = outcome,
                          A = exposure,
                          W.Q = outcomeCovariates, #incorrectly specified, not including the interaction term
                          W.g = ipwCovariates, #correctly specified
                          Q.SL.library = c("SL.mean","SL.glm"),
                          g.SL.library = c("SL.mean","SL.glm"),
                          k_split = 3,
                          verbose = FALSE)
  tmp <- suppressWarnings({
    AIPW_SL_att$stratified_fit()$summary()
  })

  # Store the ATT estimate in the vector
  att_estimates[i] <- tmp[["ATT_estimates"]][["RD"]][["Estimate"]]
  atc_estimates[i] <- tmp[["ATC_estimates"]][["RD"]][["Estimate"]]
}

# Calculate the average of the ATT estimates
mean_att_estimate <- mean(att_estimates)
mean_att_estimate
```

```
## [1] 5.046649
```

Similarly, when I misspecify the ordinary least squares model (by not including the interaction term between `randomVar1` and `randomVar2`) and properly specify the IPW model, I find that the final result is still around the true average causal effect of five.

# Final Thoughts

In conclusion, I have shown the advantages of using doubly robust estimation. Using simulated data, I demonstrated the limitations of traditional methods, such as ordinary least squares and inverse probability weighting, when models are misspecified. Furthermore, I showed how we could build upon our traditional methods to create a model that combines the two approaches making for a robust estimation of average causal effects. Doubly robust estimation is particularly useful in real-world scenarios where model specification is uncertain, and it can be a useful tool for researchers to understand causal relationships between variables with more confidence.

# Sources

1) https://journals.sagepub.com/doi/full/10.1177/0272989X211027181
2) https://www.youtube.com/watch?v=5rSTEzp_n48&t=931s&ab_channel=LanderAnalytics
3) https://www.youtube.com/watch?v=IfZHUFFlsGc&t=2s&ab_channel=StanfordGraduateSchoolofBusiness
4) http://www2.stat.duke.edu/~fl35/teaching/640/Chap3.5_Doubly%20Robust%20Estimation.pdf
5) https://matheusfacure.github.io/python-causality-handbook/12-Doubly-Robust-Estimation.html
