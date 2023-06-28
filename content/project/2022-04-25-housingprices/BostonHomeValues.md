---
title: "Analyzing Boston Home Values"
date: '2022-04-25'
excerpt: Using regression, classification, and clustering to analyze Boston home values
---

<script src="/rmarkdown-libs/htmlwidgets/htmlwidgets.js"></script>
<script src="/rmarkdown-libs/plotly-binding/plotly.js"></script>
<script src="/rmarkdown-libs/typedarray/typedarray.min.js"></script>
<script src="/rmarkdown-libs/jquery/jquery.min.js"></script>
<link href="/rmarkdown-libs/crosstalk/css/crosstalk.min.css" rel="stylesheet" />
<script src="/rmarkdown-libs/crosstalk/js/crosstalk.min.js"></script>
<link href="/rmarkdown-libs/plotly-htmlwidgets-css/plotly-htmlwidgets.css" rel="stylesheet" />
<script src="/rmarkdown-libs/plotly-main/plotly-latest.min.js"></script>

## Data Context

We chose to use Boston housing data from the ‘mlbench’ library for our research project. The data set contains 506 cases and 14 variables. Each case represents a census tract of Boston from the 1970 census. The variables include per capita crime rate, nitric oxide concentration, the average number of rooms per place of residence, the pupil-teacher ratio by census tract, the median value of homes, and more. The Census Bureau collects all census data through a variety of methods. They utilize business data, census surveys, federal/state/local government data, and other commercial agencies. The Census Bureau collects this data once a decade to “determine the number of seats each state has in the U.S. House of Representatives and is also used to distribute hundreds of billions of dollars in federal funds to local communities” (Bureau 2021).

## Research Questions

For our project, we will analyze three research questions using regression, classification methods, and unsupervised learning methods. For our regression analysis, we will have two models examining the effects of various predictors on median home value per census tract (measured in USD 1000s). Our first model will be an OLS including all predictors from the data set. For our second model, we will utilize LASSO to find the variables that most affect median home value and then add in natural splines to account for nonlinearity amongst the remaining predictors. For our classification methods, we use both a logistic LASSO model and a random forest to predict whether or not a census tract is above or below the top 75% of median home values for Boston census tracts. Finally, we will use k-means clustering to see if we can get an insight into significant clusters of census tracts based on the most significant variables as determined by the classification model.

## Code Book

| variable | description                                                           |
|:---------|:----------------------------------------------------------------------|
| medv     | median value of owner-occupied homes in USD 1000’s                    |
| crim     | per capita crime rate by town                                         |
| zn       | proportion of residential land zoned for lots over 25,000 sq.ft       |
| indus    | proportion of non-retail business acres per town                      |
| chas     | Charles River dummy variable (= 1 if tract bounds river; 0 otherwise) |
| nox      | nitric oxides concentration (parts per 10 million)                    |
| rm       | average number of rooms per dwelling                                  |
| age      | proportion of owner-occupied units built prior to 1940                |
| dis      | weighted distances to five Boston employment centres                  |
| rad      | index of accessibility to radial highways                             |
| tax      | full-value property-tax rate per USD 10,000                           |
| ptratio  | pupil-teacher ratio by town                                           |
| b        | 1000(B - 0.63)^2 where B is the proportion of blacks by town          |
| lstat    | percentage of lower status of the population                          |

## Regression: Methods

### OLS Model Creation

    ## # A tibble: 14 × 5
    ##    term          estimate std.error statistic  p.value
    ##    <chr>            <dbl>     <dbl>     <dbl>    <dbl>
    ##  1 (Intercept)  36.5        5.10       7.14   3.28e-12
    ##  2 crim         -0.108      0.0329    -3.29   1.09e- 3
    ##  3 zn            0.0464     0.0137     3.38   7.78e- 4
    ##  4 indus         0.0206     0.0615     0.334  7.38e- 1
    ##  5 chas1         2.69       0.862      3.12   1.93e- 3
    ##  6 nox         -17.8        3.82      -4.65   4.25e- 6
    ##  7 rm            3.81       0.418      9.12   1.98e-18
    ##  8 age           0.000692   0.0132     0.0524 9.58e- 1
    ##  9 dis          -1.48       0.199     -7.40   6.01e-13
    ## 10 rad           0.306      0.0663     4.61   5.07e- 6
    ## 11 tax          -0.0123     0.00376   -3.28   1.11e- 3
    ## 12 ptratio      -0.953      0.131     -7.28   1.31e-12
    ## 13 b             0.00931    0.00269    3.47   5.73e- 4
    ## 14 lstat        -0.525      0.0507   -10.3    7.78e-23

For our first model, we use ordinary least-squares to predict the median value of Boston owner-occupied homes by census tract using all 14 predictors in our data set. We can see that `indus` (the proportion of non-retail business acres per town) and `age` (the proportion of owner-occupied units built prior to 1940) are not statistically significant as their p-values are greater than 0.05.

### GAM + LASSO Model Creation

<img src="/project/2022-04-25-housingprices/BostonHomeValues_files/figure-html/unnamed-chunk-4-1.png" width="672" />

To begin our second model, we must first tune our penalty term, `\(\lambda\)`. The visualization shows the value of the penalty term along the x-axis and the cross-validated MAE values on the y-axis.

    ## # A tibble: 8 × 3
    ##   term        estimate penalty
    ##   <chr>          <dbl>   <dbl>
    ## 1 (Intercept)  22.4      0.574
    ## 2 crim         -0.0601   0.574
    ## 3 rm            2.95     0.574
    ## 4 dis          -0.0344   0.574
    ## 5 ptratio      -1.56     0.574
    ## 6 b             0.487    0.574
    ## 7 lstat        -3.61     0.574
    ## 8 chas_X1       1.39     0.574

<img src="/project/2022-04-25-housingprices/BostonHomeValues_files/figure-html/unnamed-chunk-6-1.png" width="672" />

The dotted line of our LASSO variable significance graph is our penalty term, `\(\lambda\)` = 0.5736153. We can see that only seven predictors remain after applying our penalty term: `crim`, `rm`, `dis`, `ptratio`, `b`, `lstat`, and `chas_x1`. We will now examine the relationships between these predictors and the outcome, `medv`, to determine whether or not a natural spline is necessary, except for `chas_x1` as it is binary.

<img src="/project/2022-04-25-housingprices/BostonHomeValues_files/figure-html/unnamed-chunk-7-1.png" width="672" />

    ## 
    ## Method: GCV   Optimizer: magic
    ## Smoothing parameter selection converged after 16 iterations.
    ## The RMS GCV score gradient at convergence was 1.344817e-06 .
    ## The Hessian was positive definite.
    ## Model rank =  56 / 56 
    ## 
    ## Basis dimension (k) checking results. Low p-value (k-index<1) may
    ## indicate that k is too low, especially if edf is close to k'.
    ## 
    ##              k'  edf k-index p-value    
    ## s(crim)    9.00 1.47    1.03   0.780    
    ## s(rm)      9.00 7.35    0.90   0.020 *  
    ## s(dis)     9.00 8.66    0.99   0.330    
    ## s(ptratio) 9.00 3.81    0.65  <2e-16 ***
    ## s(b)       9.00 6.28    0.94   0.085 .  
    ## s(lstat)   9.00 5.83    1.01   0.565    
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

There are no extreme patterns in the Q-Q plot, and since they are close to the line, we know that the residuals are approximately normal. The residuals versus linear prediction plot looks relatively fine, and the histogram of the residuals plot is normal, which is ideal. Finally, the response versus fitted values is positively correlated, which they should be.

    ## 
    ## Family: gaussian 
    ## Link function: identity 
    ## 
    ## Formula:
    ## medv ~ chas + s(crim) + s(rm) + s(dis) + s(ptratio) + s(b) + 
    ##     s(lstat)
    ## 
    ## Parametric coefficients:
    ##             Estimate Std. Error t value Pr(>|t|)    
    ## (Intercept)  22.4053     0.1717 130.489  < 2e-16 ***
    ## chas1         1.8433     0.6900   2.671  0.00781 ** 
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## Approximate significance of smooth terms:
    ##              edf Ref.df      F  p-value    
    ## s(crim)    1.471  1.790 22.729 1.22e-06 ***
    ## s(rm)      7.352  8.339 22.714  < 2e-16 ***
    ## s(dis)     8.657  8.963  7.398  < 2e-16 ***
    ## s(ptratio) 3.809  4.662  6.504 1.92e-05 ***
    ## s(b)       6.278  7.402  2.026   0.0516 .  
    ## s(lstat)   5.832  7.024 41.110  < 2e-16 ***
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## R-sq.(adj) =  0.837   Deviance explained = 84.8%
    ## GCV = 14.801  Scale est. = 13.765    n = 506

<img src="/project/2022-04-25-housingprices/BostonHomeValues_files/figure-html/unnamed-chunk-8-1.png" width="672" />

From our summary, we can see that census tracts that bound the Charles River have, on average, a \$1,843 higher median home value than census tracts that do not bound the Charles River, keeping all other predictors fixed. Also, based on the smooth terms, `b` may not be a strong predictor after considering other variables in the model. However, the p-value is nearly less than 0.05, so we will include it for now. Looking at our graphs, the relationship between the median home value and the predictors `rm`, `dis`, and `lstat` appear to be nonlinear, suggesting that we will need splines for these variables. We will use rounded estimated degrees of freedom to apply these natural splines and add them to the final GAM + LASSO model.

    ## 
    ## Family: gaussian 
    ## Link function: identity 
    ## 
    ## Formula:
    ## medv ~ chas + crim + s(rm) + s(dis) + ptratio + b + s(lstat)
    ## 
    ## Parametric coefficients:
    ##              Estimate Std. Error t value Pr(>|t|)    
    ## (Intercept) 30.677173   1.952623  15.711  < 2e-16 ***
    ## chas1        1.709641   0.695387   2.459   0.0143 *  
    ## crim        -0.154559   0.025805  -5.989 4.13e-09 ***
    ## ptratio     -0.496793   0.097629  -5.089 5.19e-07 ***
    ## b            0.004106   0.002189   1.876   0.0613 .  
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## Approximate significance of smooth terms:
    ##            edf Ref.df      F p-value    
    ## s(rm)    6.819  7.939 27.339  <2e-16 ***
    ## s(dis)   8.569  8.947  6.899  <2e-16 ***
    ## s(lstat) 5.812  7.005 41.430  <2e-16 ***
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## R-sq.(adj) =  0.831   Deviance explained = 83.9%
    ## GCV = 15.095  Scale est. = 14.314    n = 506

## Regression: Results + Conclusions

### Cross-Validated Metrics

    ## # A tibble: 3 × 6
    ##   .metric .estimator  mean     n std_err .config             
    ##   <chr>   <chr>      <dbl> <int>   <dbl> <chr>               
    ## 1 mae     standard   3.50     10  0.235  Preprocessor1_Model1
    ## 2 rmse    standard   4.90     10  0.366  Preprocessor1_Model1
    ## 3 rsq     standard   0.721    10  0.0234 Preprocessor1_Model1

    ## # A tibble: 3 × 6
    ##   .metric .estimator  mean     n std_err .config             
    ##   <chr>   <chr>      <dbl> <int>   <dbl> <chr>               
    ## 1 mae     standard   2.76     10  0.154  Preprocessor1_Model1
    ## 2 rmse    standard   4.05     10  0.257  Preprocessor1_Model1
    ## 3 rsq     standard   0.804    10  0.0244 Preprocessor1_Model1

Our GAM + LASSO model has a lower cross-validated MAE, RMSE, and a higher R-Squared value than our OLS model. This means that the magnitude of the residuals is smaller for the GAM + LASSO model, and it also accounts for 80.417% of the variation in the median value of Boston owner-occupied homes per census tract compared to the OLS model’s 72.103%.

### Residual Plots

<img src="/project/2022-04-25-housingprices/BostonHomeValues_files/figure-html/unnamed-chunk-12-1.png" width="672" />

Our OLS model generally does a good job of predicting the median home values for Boston census tracts. However, we can see that our OLS model begins to underpredict median home values as they increase past 35,000 USD. From our GAM residual plot, we can see that the magnitude of the residuals is much smaller, especially for median home values that are greater than 35,000 USD.

### Slope Coefficient Interpreations

    ## # A tibble: 27 × 5
    ##    term        estimate std.error statistic  p.value
    ##    <chr>          <dbl>     <dbl>     <dbl>    <dbl>
    ##  1 (Intercept) 60.4       3.68       16.4   1.98e-48
    ##  2 chas1        1.17      0.677       1.73  8.34e- 2
    ##  3 crim        -0.138     0.0251     -5.50  6.24e- 8
    ##  4 ptratio     -0.562     0.0942     -5.96  4.90e- 9
    ##  5 b            0.00364   0.00213     1.71  8.88e- 2
    ##  6 rm_ns_1     -1.85      2.47       -0.748 4.55e- 1
    ##  7 rm_ns_2     -1.02      2.67       -0.383 7.02e- 1
    ##  8 rm_ns_3     -1.88      2.60       -0.723 4.70e- 1
    ##  9 rm_ns_4     -1.86      2.61       -0.712 4.77e- 1
    ## 10 rm_ns_5      9.68      2.00        4.83  1.84e- 6
    ## # … with 17 more rows
    ## # ℹ Use `print(n = ...)` to see more rows

`crim`: On average, for a 1 percent increase in per capita crime rate, the median home values of a census tract will fall by around \$138, keeping all other predictors fixed.

`ptratio`: On average, for a 1 unit increase in the pupil-teacher ratio by census tract, the median home values will fall by around \$562, keeping all other predictors fixed.

### Non-linear Predictor Visualizations

<img src="/project/2022-04-25-housingprices/BostonHomeValues_files/figure-html/unnamed-chunk-14-1.png" width="672" /><img src="/project/2022-04-25-housingprices/BostonHomeValues_files/figure-html/unnamed-chunk-14-2.png" width="672" /><img src="/project/2022-04-25-housingprices/BostonHomeValues_files/figure-html/unnamed-chunk-14-3.png" width="672" />

While we cannot interpret our coefficients with natural splines, we can examine their relationships with the outcome, median home values. For our first graph, `rm` vs. `medv`, we see a positive slope for dwellings with an average of 4 - 6.5 rooms. Once the average number of rooms per dwelling exceeds 6.5, the median home values increase at a faster rate. Our second graph, `dis` vs. `medv`, shows that census tracts that are closer to the five selected employment centers tend to have lower median home values until they reach a distance of 3 units. After this point, the weighted distance to the employment centers has almost no effect. Our final graph, `lstat` vs. `medv`, shows a significant negative relationship between the percentage of the lower status population and median home values that eventually flattens out as the percentage of the lower status population increases.

### Conclusion

Our GAM + LASSO model does a great job examining which predictors most affect the median value of owner-occupied homes in Boston. We found that as the crime in a census tract increases, the pupil-teacher ratio increases, and the proportion of the lower status population living in a census tract increases, the median value of homes will decrease. These results indicate that we should look into the history of redlining in Boston and see if there is a correlation between neighborhoods that have been redlined in the past and a low median house value.

## Classification: Methods

We will run a logistic LASSO and random forest to see which predictors are most useful when predicting whether or not a census tract is above or below the top 75% of Boston median home values. We created a classification data set with our new outcome variable, `Top75`, and we removed the `medv` variable as it would be taken into consideration when implementing our LASSO.

### Logistic LASSO Creation

<img src="/project/2022-04-25-housingprices/BostonHomeValues_files/figure-html/unnamed-chunk-16-1.png" width="672" />

To begin our logistic LASSO model, we must first tune our penalty term, `\(\lambda\)`. The visualization shows the value of the penalty term along the x-axis and the cross-validated accuracy and ROC_auc values on the y-axis.

    ## # A tibble: 3 × 3
    ##   term        estimate penalty
    ##   <chr>          <dbl>   <dbl>
    ## 1 (Intercept)  -1.21     0.155
    ## 2 rm            0.577    0.155
    ## 3 lstat        -0.0693   0.155

    ## # A tibble: 2 × 7
    ##   penalty .metric  .estimator  mean     n std_err .config               
    ##     <dbl> <chr>    <chr>      <dbl> <int>   <dbl> <chr>                 
    ## 1   0.155 accuracy binary     0.795    10  0.0190 Preprocessor1_Model059
    ## 2   0.155 roc_auc  binary     0.928    10  0.0116 Preprocessor1_Model059

After running our LASSO using a `\(\lambda\)` value within one standard error of the highest cross-validated roc_auc, we have two variables remaining: `rm`, the average number of rooms per dwelling, and `lstat`, the percentage of the lower status of the population. We have a 92.789% test AUC value using these two predictors, which is promising.

<img src="/project/2022-04-25-housingprices/BostonHomeValues_files/figure-html/unnamed-chunk-18-1.png" width="672" />

    ##           Truth
    ## Prediction  No Yes
    ##        No  366  30
    ##        Yes  16  94

    ## # A tibble: 3 × 3
    ##   .metric  .estimator .estimate
    ##   <chr>    <chr>          <dbl>
    ## 1 sens     binary         0.758
    ## 2 spec     binary         0.958
    ## 3 accuracy binary         0.909

Our confusion matrix shows us that our logistic LASSO model correctly predicts 366 census tracts and incorrectly predicts 16 (false positives) of the census tracts that are not in the top 75% of Boston median home values. Furthermore, our model correctly predicts 94 census tracts and incorrectly predicts 30 census tracts (false negatives) of the census tracts in the top 75% of Boston median home values. So, of all the census tracts that are truly below the top 75% of Boston median home values, we correctly predicted 95.812% (specificity) of them. Moreover, of all the census tracts that are truly at or above the top 75% of Boston median home values, we correctly predicted 75.806% (sensitivity) of them. In the data context, we would expect to have a higher specificity than sensitivity as, inherently, there are more houses below the top 75% of Boston median home values than above, meaning that we are more likely to predict a house as below the top 75% rather than at or above this mark.

### Random Forest Creation

We are going to create four random forest models. Each model will use 1000 trees and will have 2 (minimum number), 4 ($\approx \sqrt{13}$), 7 ($\approx \frac{13}{2}$), and 13 randomly sampled predictors respectively.

    ## # A tibble: 4 × 4
    ##   model  .metric  .estimator .estimate
    ##   <chr>  <chr>    <chr>          <dbl>
    ## 1 mtry2  accuracy binary         0.943
    ## 2 mtry4  accuracy binary         0.939
    ## 3 mtry7  accuracy binary         0.939
    ## 4 mtry13 accuracy binary         0.929

<img src="/project/2022-04-25-housingprices/BostonHomeValues_files/figure-html/unnamed-chunk-22-1.png" width="672" />

After creating creating all 4 random forest models, we have the accuracy estimates for each model. The random forest with 2 randomly sampled variables has the highest accuracy at 94.269%. The random forest models with 4 and 7 randomly sampled variables have an accuracy of 93.874%, and the model with 13 randomly sampled variables has the lowest accuracy at 92.885%.

    ##           Truth
    ## Prediction  No Yes
    ##        No  373  20
    ##        Yes   9 104

    ## [1] 0.8387097

    ## [1] 0.9764398

Our confusion matrix shows us that our random forest with two randomly sampled variables correctly predicts 373 census tracts and incorrectly predicts 9 (false positives) of the census tracts that are not in the top 75% of Boston median home values. Furthermore, our random forest correctly predicts 104 census tracts and incorrectly predicts 20 census tracts (false negatives) of the census tracts in the top 75% of Boston median home values. So, of all the census tracts that are truly below the top 75% of Boston median home values, we correctly predicted 97.644% (specificity) of them. Moreover, of all the census tracts that are truly at or above the top 75% of Boston median home values, we correctly predicted 83.871% (sensitivity) of them.

## Classification: Results + Conclusions

### Confusion Matrices Results

    ##            Model Sensitivity Specificity Overall_Accuracy
    ## 1 Logistic LASSO       0.758       0.958            0.909
    ## 2  Random Forest       0.838       0.976            0.942

When reviewing the confusion matrices for both the Logistic LASSO and random forest models, we found that our random forest model with two randomly sampled variables produces the highest sensitivity (83.8%), specificity (97.6%), and overall accuracy (94.2%). This means that our random forest model more correctly classifies census tracts above/at and below the top 75% of Boston median home values than the Logistic LASSO model.

### Variable Importance

<img src="/project/2022-04-25-housingprices/BostonHomeValues_files/figure-html/unnamed-chunk-25-1.png" width="672" />

When looking at the variable importance we utilize two approaches: impurity and permutation. Our first graph shows the variable importance of the random forest model looking at the “total decrease in node impurities (as measured by the Gini index) from splitting on the variable, averaged over all trees” (Greenwell and Boehmke 2020). Using this approach, we find that `rm`, the average number of rooms per dwelling, and `lstat`, the percentage of lower status population, are considered the most important variables when classifying census tracts as either below or at/above the top 75% of Boston median home values. These predictors were also considered the most significant for our Logistic LASSO model. After two predictors, we see a large drop in importance for remaining variables.

<img src="/project/2022-04-25-housingprices/BostonHomeValues_files/figure-html/unnamed-chunk-26-1.png" width="672" />

Our second graph shows a permutation approach to variable importance. We consider a variable important if it has a positive effect on the prediction performance. We find that `rm` and `lstat` are still considered to be the most important variables. Additionally, there is still a significant drop-off in variable importance between `lstat` and the next most important variable `indus`, the proportion of non-retail business acres per town. Both the impurity and permutation variable importance graphs show that `chas`, whether or not the census tract bounds the Charles River, has the least effect when classifying census tracts as either below or at/above the top 75% of Boston median home values.

### Conclusion

Both our random forest model and our logistic LASSO model show that `rm` and `lstat` have the largest effect when determining if a census tract is below or at/above the top 75% of Boston median home values. Using our logistic LASSO Model, we found that that the estimated odds of a census tract being at/above the top 75% of Boston median home values is higher when the average number of rooms per dwelling is higher. Additionally, we found that the estimated odds of a census tract being at/above the top 75% of Boston median home values is lower when the percentage of lower status of the population of a census tract increases (which is consistent with our findings from the regression analysis). It is important to note that our random forest model found that `indus` was the third most important variable. While it was not included into the final model, the Boston area has struggled with industrial-caused pollution. Up until recently, Boston has had many problems with companies dropping PCBs into rivers, specifically the Neponset River in the South Boston area (Chanatry 2022). Exposure to PCBs might cause thyroid hormone toxicity in humans (“Polychlorinated Biphenyls (PCBS) Toxicity” 2014) which is why census tracts that have a smaller proportion of industrial acres might be classified as at/above 75% of Boston median home values more often.

## Unsupervised Learning: Clustering

### Clustering Model & Feature Selection

As identified earlier in the GAM + LASSO model the crime of a census tract, the pupil-teacher ratio, and the proportion of the lower status population living in a census tract have the most significant effect on the median value of homes. We would like to see if K-means clustering can identify any groups of districts which are similar and how many of those groups we may identify. In our research of finding more general clusters of districts we might want to favor parsimony - favor a fewer number of clusters.

To start, we select the variables of interest and make sure that only numeric variables are included.

### K-value Choice

As we choose the k number of clusters, we want to stop at a number where we no longer see meaningful decreases in heterogeneity by increasing k. After k=4 the decreases seem to be much smaller than at lesser k values.

<img src="/project/2022-04-25-housingprices/BostonHomeValues_files/figure-html/unnamed-chunk-28-1.png" width="672" />

### Visualization

We assign values of clusters to every district and create a 3-d plot, where color represents a cluster, and x,y,z coordinate represent the values of interest (crim,ptratio,lstat).

<div id="htmlwidget-1" style="width:672px;height:480px;" class="plotly html-widget"></div>
<script type="application/json" data-for="htmlwidget-1">{"x":{"visdat":{"10d9e68315537":["function () ","plotlyVisDat"]},"cur_data":"10d9e68315537","attrs":{"10d9e68315537":{"x":[0.00632,0.02731,0.02729,0.03237,0.06905,0.02985,0.08829,0.14455,0.21124,0.17004,0.22489,0.11747,0.09378,0.62976,0.63796,0.62739,1.05393,0.7842,0.80271,0.7258,1.25179,0.85204,1.23247,0.98843,0.75026,0.84054,0.67191,0.95577,0.77299,1.00245,1.13081,1.35472,1.38799,1.15172,1.61282,0.06417,0.09744,0.08014,0.17505,0.02763,0.03359,0.12744,0.1415,0.15936,0.12269,0.17142,0.18836,0.22927,0.25387,0.21977,0.08873,0.04337,0.0536,0.04981,0.0136,0.01311,0.02055,0.01432,0.15445,0.10328,0.14932,0.17171,0.11027,0.1265,0.01951,0.03584,0.04379,0.05789,0.13554,0.12816,0.08826,0.15876,0.09164,0.19539,0.07896,0.09512,0.10153,0.08707,0.05646,0.08387,0.04113,0.04462,0.03659,0.03551,0.05059,0.05735,0.05188,0.07151,0.0566,0.05302,0.04684,0.03932,0.04203,0.02875,0.04294,0.12204,0.11504,0.12083,0.08187,0.0686,0.14866,0.11432,0.22876,0.21161,0.1396,0.13262,0.1712,0.13117,0.12802,0.26363,0.10793,0.10084,0.12329,0.22212,0.14231,0.17134,0.13158,0.15098,0.13058,0.14476,0.06899,0.07165,0.09299,0.15038,0.09849,0.16902,0.38735,0.25915,0.32543,0.88125,0.34006,1.19294,0.59005,0.32982,0.97617,0.55778,0.32264,0.35233,0.2498,0.54452,0.2909,1.62864,3.32105,4.0974,2.77974,2.37934,2.15505,2.36862,2.33099,2.73397,1.6566,1.49632,1.12658,2.14918,1.41385,3.53501,2.44668,1.22358,1.34284,1.42502,1.27346,1.46336,1.83377,1.51902,2.24236,2.924,2.01019,1.80028,2.3004,2.44953,1.20742,2.3139,0.13914,0.09178,0.08447,0.06664,0.07022,0.05425,0.06642,0.0578,0.06588,0.06888,0.09103,0.10008,0.08308,0.06047,0.05602,0.07875,0.12579,0.0837,0.09068,0.06911,0.08664,0.02187,0.01439,0.01381,0.04011,0.04666,0.03768,0.0315,0.01778,0.03445,0.02177,0.0351,0.02009,0.13642,0.22969,0.25199,0.13587,0.43571,0.17446,0.37578,0.21719,0.14052,0.28955,0.19802,0.0456,0.07013,0.11069,0.11425,0.35809,0.40771,0.62356,0.6147,0.31533,0.52693,0.38214,0.41238,0.29819,0.44178,0.537,0.46296,0.57529,0.33147,0.44791,0.33045,0.52058,0.51183,0.08244,0.09252,0.11329,0.10612,0.1029,0.12757,0.20608,0.19133,0.33983,0.19657,0.16439,0.19073,0.1403,0.21409,0.08221,0.36894,0.04819,0.03548,0.01538,0.61154,0.66351,0.65665,0.54011,0.53412,0.52014,0.82526,0.55007,0.76162,0.7857,0.57834,0.5405,0.09065,0.29916,0.16211,0.1146,0.22188,0.05644,0.09604,0.10469,0.06127,0.07978,0.21038,0.03578,0.03705,0.06129,0.01501,0.00906,0.01096,0.01965,0.03871,0.0459,0.04297,0.03502,0.07886,0.03615,0.08265,0.08199,0.12932,0.05372,0.14103,0.06466,0.05561,0.04417,0.03537,0.09266,0.1,0.05515,0.05479,0.07503,0.04932,0.49298,0.3494,2.63548,0.79041,0.26169,0.26938,0.3692,0.25356,0.31827,0.24522,0.40202,0.47547,0.1676,0.18159,0.35114,0.28392,0.34109,0.19186,0.30347,0.24103,0.06617,0.06724,0.04544,0.05023,0.03466,0.05083,0.03738,0.03961,0.03427,0.03041,0.03306,0.05497,0.06151,0.01301,0.02498,0.02543,0.03049,0.03113,0.06162,0.0187,0.01501,0.02899,0.06211,0.0795,0.07244,0.01709,0.04301,0.10659,8.98296,3.8497,5.20177,4.26131,4.54192,3.83684,3.67822,4.22239,3.47428,4.55587,3.69695,13.5222,4.89822,5.66998,6.53876,9.2323,8.26725,11.1081,18.4982,19.6091,15.288,9.82349,23.6482,17.8667,88.9762,15.8744,9.18702,7.99248,20.0849,16.8118,24.3938,22.5971,14.3337,8.15174,6.96215,5.29305,11.5779,8.64476,13.3598,8.71675,5.87205,7.67202,38.3518,9.91655,25.0461,14.2362,9.59571,24.8017,41.5292,67.9208,20.7162,11.9511,7.40389,14.4383,51.1358,14.0507,18.811,28.6558,45.7461,18.0846,10.8342,25.9406,73.5341,11.8123,11.0874,7.02259,12.0482,7.05042,8.79212,15.8603,12.2472,37.6619,7.36711,9.33889,8.49213,10.0623,6.44405,5.58107,13.9134,11.1604,14.4208,15.1772,13.6781,9.39063,22.0511,9.72418,5.66637,9.96654,12.8023,10.6718,6.28807,9.92485,9.32909,7.52601,6.71772,5.44114,5.09017,8.24809,9.51363,4.75237,4.66883,8.20058,7.75223,6.80117,4.81213,3.69311,6.65492,5.82115,7.83932,3.1636,3.77498,4.42228,15.5757,13.0751,4.34879,4.03841,3.56868,4.64689,8.05579,6.39312,4.87141,15.0234,10.233,14.3337,5.82401,5.70818,5.73116,2.81838,2.37857,3.67367,5.69175,4.83567,0.15086,0.18337,0.20746,0.10574,0.11132,0.17331,0.27957,0.17899,0.2896,0.26838,0.23912,0.17783,0.22438,0.06263,0.04527,0.06076,0.10959,0.04741],"y":[15.3,17.8,17.8,18.7,18.7,18.7,15.2,15.2,15.2,15.2,15.2,15.2,15.2,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,19.2,19.2,19.2,19.2,18.3,18.3,17.9,17.9,17.9,17.9,17.9,17.9,17.9,17.9,17.9,16.8,16.8,16.8,16.8,21.1,17.9,17.3,15.1,19.7,19.7,19.7,19.7,19.7,19.7,18.6,16.1,16.1,18.9,18.9,18.9,19.2,19.2,19.2,19.2,18.7,18.7,18.7,18.7,18.7,18.7,19,19,19,19,18.5,18.5,18.5,18.5,17.8,17.8,17.8,17.8,18.2,18.2,18.2,18,18,18,18,18,20.9,20.9,20.9,20.9,20.9,20.9,20.9,20.9,20.9,20.9,20.9,17.8,17.8,17.8,17.8,17.8,17.8,17.8,17.8,17.8,19.1,19.1,19.1,19.1,19.1,19.1,19.1,21.2,21.2,21.2,21.2,21.2,21.2,21.2,21.2,21.2,21.2,21.2,21.2,21.2,21.2,21.2,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,16.6,16.6,16.6,16.6,16.6,16.6,16.6,17.8,17.8,17.8,17.8,17.8,17.8,17.8,17.8,15.2,15.2,15.2,15.2,15.2,15.2,15.6,15.6,14.4,12.6,12.6,12.6,17,17,14.7,14.7,14.7,14.7,18.6,18.6,18.6,18.6,18.6,18.6,18.6,18.6,18.6,18.6,18.6,16.4,16.4,16.4,16.4,17.4,17.4,17.4,17.4,17.4,17.4,17.4,17.4,17.4,17.4,17.4,17.4,17.4,17.4,17.4,17.4,17.4,17.4,16.6,16.6,16.6,16.6,16.6,16.6,19.1,19.1,19.1,19.1,19.1,19.1,19.1,19.1,19.1,19.1,16.4,16.4,15.9,13,13,13,13,13,13,13,13,13,13,13,13,18.6,18.6,18.6,18.6,18.6,17.6,17.6,17.6,17.6,17.6,14.9,14.9,14.9,14.9,13.6,15.3,15.3,18.2,16.6,16.6,16.6,19.2,19.2,19.2,16,16,16,16,16,14.8,14.8,14.8,16.1,16.1,16.1,18.4,18.4,18.4,18.4,18.4,18.4,18.4,18.4,18.4,18.4,18.4,18.4,18.4,18.4,18.4,18.4,19.6,19.6,19.6,19.6,19.6,19.6,19.6,19.6,16.9,16.9,16.9,16.9,16.9,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,15.5,15.9,17.6,17.6,18.8,18.8,17.9,17,19.7,19.7,18.3,18.3,17,22,22,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.1,20.1,20.1,20.1,20.1,19.2,19.2,19.2,19.2,19.2,19.2,19.2,19.2,21,21,21,21,21],"z":[4.98,9.14,4.03,2.94,5.33,5.21,12.43,19.15,29.93,17.1,20.45,13.27,15.71,8.26,10.26,8.47,6.58,14.67,11.69,11.28,21.02,13.83,18.72,19.88,16.3,16.51,14.81,17.28,12.8,11.98,22.6,13.04,27.71,18.35,20.34,9.68,11.41,8.77,10.13,4.32,1.98,4.84,5.81,7.44,9.55,10.21,14.15,18.8,30.81,16.2,13.45,9.43,5.28,8.43,14.8,4.81,5.77,3.95,6.86,9.22,13.15,14.44,6.73,9.5,8.05,4.67,10.24,8.1,13.09,8.79,6.72,9.88,5.52,7.54,6.78,8.94,11.97,10.27,12.34,9.1,5.29,7.22,6.72,7.51,9.62,6.53,12.86,8.44,5.5,5.7,8.81,8.2,8.16,6.21,10.59,6.65,11.34,4.21,3.57,6.19,9.42,7.67,10.63,13.44,12.33,16.47,18.66,14.09,12.27,15.55,13,10.16,16.21,17.09,10.45,15.76,12.04,10.3,15.37,13.61,14.37,14.27,17.93,25.41,17.58,14.81,27.26,17.19,15.39,18.34,12.6,12.26,11.12,15.03,17.31,16.96,16.9,14.59,21.32,18.46,24.16,34.41,26.82,26.42,29.29,27.8,16.65,29.53,28.32,21.45,14.1,13.28,12.12,15.79,15.12,15.02,16.14,4.59,6.43,7.39,5.5,1.73,1.92,3.32,11.64,9.81,3.7,12.14,11.1,11.32,14.43,12.03,14.69,9.04,9.64,5.33,10.11,6.29,6.92,5.04,7.56,9.45,4.82,5.68,13.98,13.15,4.45,6.68,4.56,5.39,5.1,4.69,2.87,5.03,4.38,2.97,4.08,8.61,6.62,4.56,4.45,7.43,3.11,3.81,2.88,10.87,10.97,18.06,14.66,23.09,17.27,23.98,16.03,9.38,29.55,9.47,13.51,9.69,17.92,10.5,9.71,21.46,9.93,7.6,4.14,4.63,3.13,6.36,3.92,3.76,11.65,5.25,2.47,3.95,8.05,10.88,9.54,4.73,6.36,7.37,11.38,12.4,11.22,5.19,12.5,18.46,9.16,10.15,9.52,6.56,5.9,3.59,3.53,3.54,6.57,9.25,3.11,5.12,7.79,6.9,9.59,7.26,5.91,11.25,8.1,10.45,14.79,7.44,3.16,13.65,13,6.59,7.73,6.58,3.53,2.98,6.05,4.16,7.19,4.85,3.76,4.59,3.01,3.16,7.85,8.23,12.93,7.14,7.6,9.51,3.33,3.56,4.7,8.58,10.4,6.27,7.39,15.84,4.97,4.74,6.07,9.5,8.67,4.86,6.93,8.93,6.47,7.53,4.54,9.97,12.64,5.98,11.72,7.9,9.28,11.5,18.33,15.94,10.36,12.73,7.2,6.87,7.7,11.74,6.12,5.08,6.15,12.79,9.97,7.34,9.09,12.43,7.83,5.68,6.75,8.01,9.8,10.56,8.51,9.74,9.29,5.49,8.65,7.18,4.61,10.53,12.67,6.36,5.99,5.89,5.98,5.49,7.79,4.5,8.05,5.57,17.6,13.27,11.48,12.67,7.79,14.19,10.19,14.64,5.29,7.12,14,13.33,3.26,3.73,2.96,9.53,8.88,34.77,37.97,13.44,23.24,21.24,23.69,21.78,17.21,21.08,23.6,24.56,30.63,30.81,28.28,31.99,30.62,20.85,17.11,18.76,25.68,15.17,16.35,17.12,19.37,19.92,30.59,29.97,26.77,20.32,20.31,19.77,27.38,22.98,23.34,12.13,26.4,19.78,10.11,21.22,34.37,20.08,36.98,29.05,25.79,26.64,20.62,22.74,15.02,15.7,14.1,23.29,17.16,24.39,15.69,14.52,21.52,24.08,17.64,19.69,12.03,16.22,15.17,23.27,18.05,26.45,34.02,22.88,22.11,19.52,16.59,18.85,23.79,23.98,17.79,16.44,18.13,19.31,17.44,17.73,17.27,16.74,18.71,18.13,19.01,16.94,16.23,14.7,16.42,14.65,13.99,10.29,13.22,14.13,17.15,21.32,18.13,14.76,16.29,12.87,14.36,11.66,18.14,24.1,18.68,24.91,18.03,13.11,10.74,7.74,7.01,10.42,13.34,10.58,14.98,11.45,18.06,23.97,29.68,18.07,13.35,12.01,13.59,17.6,21.14,14.1,12.92,15.1,14.33,9.67,9.08,5.64,6.48,7.88],"mode":"markers","scale":true,"color":[1,4,4,4,4,4,1,1,3,1,1,1,1,4,4,4,4,4,4,4,3,4,3,3,3,3,4,3,4,4,3,4,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,3,3,4,1,1,1,1,4,4,4,1,4,4,4,4,4,4,4,1,1,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,3,3,3,4,3,3,3,3,4,4,4,4,3,3,3,4,3,3,3,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,4,4,4,4,4,4,4,4,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,4,4,3,4,3,4,3,4,4,3,4,1,1,1,1,4,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,1,1,1,1,1,1,4,3,4,4,4,4,4,4,4,4,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,4,4,4,4,4,4,4,4,4,4,1,1,1,1,1,1,1,4,1,1,1,4,4,4,1,1,1,1,1,1,1,1,1,1,1,4,4,4,4,4,4,4,4,4,4,4,4,3,4,4,4,4,4,4,4,4,4,4,4,1,1,1,1,1,4,4,4,4,4,4,4,4,1,1,4,4,4,4,4,1,4,4,4,4,1,4,4,3,4,4,4,4,4,4,3,4,4,4,3,4,4,4,4,4,3,3,3,3,3,3,3,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,2,3,3,3,3,3,2,2,3,3,3,3,2,3,3,3,2,3,3,3,2,3,3,3,3,3,3,3,3,2,3,3,3,3,4,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,3,4,3,4,3,3,3,3,3,4,4,4,3,3,3,3,3,3,4,4,4,4,4,4,3,4,3,3,3,3,4,4,4,3,3,4,4,4,4,4,4,4,4,4],"alpha_stroke":1,"sizes":[10,100],"spans":[1,20],"type":"scatter3d"}},"layout":{"margin":{"b":40,"l":60,"t":25,"r":10},"scene":{"xaxis":{"title":[]},"yaxis":{"title":[]},"zaxis":{"title":[]}},"hovermode":"closest","showlegend":false,"legend":{"yanchor":"top","y":0.5}},"source":"A","config":{"modeBarButtonsToAdd":["hoverclosest","hovercompare"],"showSendToCloud":false},"data":[{"x":[0.00632,0.02731,0.02729,0.03237,0.06905,0.02985,0.08829,0.14455,0.21124,0.17004,0.22489,0.11747,0.09378,0.62976,0.63796,0.62739,1.05393,0.7842,0.80271,0.7258,1.25179,0.85204,1.23247,0.98843,0.75026,0.84054,0.67191,0.95577,0.77299,1.00245,1.13081,1.35472,1.38799,1.15172,1.61282,0.06417,0.09744,0.08014,0.17505,0.02763,0.03359,0.12744,0.1415,0.15936,0.12269,0.17142,0.18836,0.22927,0.25387,0.21977,0.08873,0.04337,0.0536,0.04981,0.0136,0.01311,0.02055,0.01432,0.15445,0.10328,0.14932,0.17171,0.11027,0.1265,0.01951,0.03584,0.04379,0.05789,0.13554,0.12816,0.08826,0.15876,0.09164,0.19539,0.07896,0.09512,0.10153,0.08707,0.05646,0.08387,0.04113,0.04462,0.03659,0.03551,0.05059,0.05735,0.05188,0.07151,0.0566,0.05302,0.04684,0.03932,0.04203,0.02875,0.04294,0.12204,0.11504,0.12083,0.08187,0.0686,0.14866,0.11432,0.22876,0.21161,0.1396,0.13262,0.1712,0.13117,0.12802,0.26363,0.10793,0.10084,0.12329,0.22212,0.14231,0.17134,0.13158,0.15098,0.13058,0.14476,0.06899,0.07165,0.09299,0.15038,0.09849,0.16902,0.38735,0.25915,0.32543,0.88125,0.34006,1.19294,0.59005,0.32982,0.97617,0.55778,0.32264,0.35233,0.2498,0.54452,0.2909,1.62864,3.32105,4.0974,2.77974,2.37934,2.15505,2.36862,2.33099,2.73397,1.6566,1.49632,1.12658,2.14918,1.41385,3.53501,2.44668,1.22358,1.34284,1.42502,1.27346,1.46336,1.83377,1.51902,2.24236,2.924,2.01019,1.80028,2.3004,2.44953,1.20742,2.3139,0.13914,0.09178,0.08447,0.06664,0.07022,0.05425,0.06642,0.0578,0.06588,0.06888,0.09103,0.10008,0.08308,0.06047,0.05602,0.07875,0.12579,0.0837,0.09068,0.06911,0.08664,0.02187,0.01439,0.01381,0.04011,0.04666,0.03768,0.0315,0.01778,0.03445,0.02177,0.0351,0.02009,0.13642,0.22969,0.25199,0.13587,0.43571,0.17446,0.37578,0.21719,0.14052,0.28955,0.19802,0.0456,0.07013,0.11069,0.11425,0.35809,0.40771,0.62356,0.6147,0.31533,0.52693,0.38214,0.41238,0.29819,0.44178,0.537,0.46296,0.57529,0.33147,0.44791,0.33045,0.52058,0.51183,0.08244,0.09252,0.11329,0.10612,0.1029,0.12757,0.20608,0.19133,0.33983,0.19657,0.16439,0.19073,0.1403,0.21409,0.08221,0.36894,0.04819,0.03548,0.01538,0.61154,0.66351,0.65665,0.54011,0.53412,0.52014,0.82526,0.55007,0.76162,0.7857,0.57834,0.5405,0.09065,0.29916,0.16211,0.1146,0.22188,0.05644,0.09604,0.10469,0.06127,0.07978,0.21038,0.03578,0.03705,0.06129,0.01501,0.00906,0.01096,0.01965,0.03871,0.0459,0.04297,0.03502,0.07886,0.03615,0.08265,0.08199,0.12932,0.05372,0.14103,0.06466,0.05561,0.04417,0.03537,0.09266,0.1,0.05515,0.05479,0.07503,0.04932,0.49298,0.3494,2.63548,0.79041,0.26169,0.26938,0.3692,0.25356,0.31827,0.24522,0.40202,0.47547,0.1676,0.18159,0.35114,0.28392,0.34109,0.19186,0.30347,0.24103,0.06617,0.06724,0.04544,0.05023,0.03466,0.05083,0.03738,0.03961,0.03427,0.03041,0.03306,0.05497,0.06151,0.01301,0.02498,0.02543,0.03049,0.03113,0.06162,0.0187,0.01501,0.02899,0.06211,0.0795,0.07244,0.01709,0.04301,0.10659,8.98296,3.8497,5.20177,4.26131,4.54192,3.83684,3.67822,4.22239,3.47428,4.55587,3.69695,13.5222,4.89822,5.66998,6.53876,9.2323,8.26725,11.1081,18.4982,19.6091,15.288,9.82349,23.6482,17.8667,88.9762,15.8744,9.18702,7.99248,20.0849,16.8118,24.3938,22.5971,14.3337,8.15174,6.96215,5.29305,11.5779,8.64476,13.3598,8.71675,5.87205,7.67202,38.3518,9.91655,25.0461,14.2362,9.59571,24.8017,41.5292,67.9208,20.7162,11.9511,7.40389,14.4383,51.1358,14.0507,18.811,28.6558,45.7461,18.0846,10.8342,25.9406,73.5341,11.8123,11.0874,7.02259,12.0482,7.05042,8.79212,15.8603,12.2472,37.6619,7.36711,9.33889,8.49213,10.0623,6.44405,5.58107,13.9134,11.1604,14.4208,15.1772,13.6781,9.39063,22.0511,9.72418,5.66637,9.96654,12.8023,10.6718,6.28807,9.92485,9.32909,7.52601,6.71772,5.44114,5.09017,8.24809,9.51363,4.75237,4.66883,8.20058,7.75223,6.80117,4.81213,3.69311,6.65492,5.82115,7.83932,3.1636,3.77498,4.42228,15.5757,13.0751,4.34879,4.03841,3.56868,4.64689,8.05579,6.39312,4.87141,15.0234,10.233,14.3337,5.82401,5.70818,5.73116,2.81838,2.37857,3.67367,5.69175,4.83567,0.15086,0.18337,0.20746,0.10574,0.11132,0.17331,0.27957,0.17899,0.2896,0.26838,0.23912,0.17783,0.22438,0.06263,0.04527,0.06076,0.10959,0.04741],"y":[15.3,17.8,17.8,18.7,18.7,18.7,15.2,15.2,15.2,15.2,15.2,15.2,15.2,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,19.2,19.2,19.2,19.2,18.3,18.3,17.9,17.9,17.9,17.9,17.9,17.9,17.9,17.9,17.9,16.8,16.8,16.8,16.8,21.1,17.9,17.3,15.1,19.7,19.7,19.7,19.7,19.7,19.7,18.6,16.1,16.1,18.9,18.9,18.9,19.2,19.2,19.2,19.2,18.7,18.7,18.7,18.7,18.7,18.7,19,19,19,19,18.5,18.5,18.5,18.5,17.8,17.8,17.8,17.8,18.2,18.2,18.2,18,18,18,18,18,20.9,20.9,20.9,20.9,20.9,20.9,20.9,20.9,20.9,20.9,20.9,17.8,17.8,17.8,17.8,17.8,17.8,17.8,17.8,17.8,19.1,19.1,19.1,19.1,19.1,19.1,19.1,21.2,21.2,21.2,21.2,21.2,21.2,21.2,21.2,21.2,21.2,21.2,21.2,21.2,21.2,21.2,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,14.7,16.6,16.6,16.6,16.6,16.6,16.6,16.6,17.8,17.8,17.8,17.8,17.8,17.8,17.8,17.8,15.2,15.2,15.2,15.2,15.2,15.2,15.6,15.6,14.4,12.6,12.6,12.6,17,17,14.7,14.7,14.7,14.7,18.6,18.6,18.6,18.6,18.6,18.6,18.6,18.6,18.6,18.6,18.6,16.4,16.4,16.4,16.4,17.4,17.4,17.4,17.4,17.4,17.4,17.4,17.4,17.4,17.4,17.4,17.4,17.4,17.4,17.4,17.4,17.4,17.4,16.6,16.6,16.6,16.6,16.6,16.6,19.1,19.1,19.1,19.1,19.1,19.1,19.1,19.1,19.1,19.1,16.4,16.4,15.9,13,13,13,13,13,13,13,13,13,13,13,13,18.6,18.6,18.6,18.6,18.6,17.6,17.6,17.6,17.6,17.6,14.9,14.9,14.9,14.9,13.6,15.3,15.3,18.2,16.6,16.6,16.6,19.2,19.2,19.2,16,16,16,16,16,14.8,14.8,14.8,16.1,16.1,16.1,18.4,18.4,18.4,18.4,18.4,18.4,18.4,18.4,18.4,18.4,18.4,18.4,18.4,18.4,18.4,18.4,19.6,19.6,19.6,19.6,19.6,19.6,19.6,19.6,16.9,16.9,16.9,16.9,16.9,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,15.5,15.9,17.6,17.6,18.8,18.8,17.9,17,19.7,19.7,18.3,18.3,17,22,22,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.2,20.1,20.1,20.1,20.1,20.1,19.2,19.2,19.2,19.2,19.2,19.2,19.2,19.2,21,21,21,21,21],"z":[4.98,9.14,4.03,2.94,5.33,5.21,12.43,19.15,29.93,17.1,20.45,13.27,15.71,8.26,10.26,8.47,6.58,14.67,11.69,11.28,21.02,13.83,18.72,19.88,16.3,16.51,14.81,17.28,12.8,11.98,22.6,13.04,27.71,18.35,20.34,9.68,11.41,8.77,10.13,4.32,1.98,4.84,5.81,7.44,9.55,10.21,14.15,18.8,30.81,16.2,13.45,9.43,5.28,8.43,14.8,4.81,5.77,3.95,6.86,9.22,13.15,14.44,6.73,9.5,8.05,4.67,10.24,8.1,13.09,8.79,6.72,9.88,5.52,7.54,6.78,8.94,11.97,10.27,12.34,9.1,5.29,7.22,6.72,7.51,9.62,6.53,12.86,8.44,5.5,5.7,8.81,8.2,8.16,6.21,10.59,6.65,11.34,4.21,3.57,6.19,9.42,7.67,10.63,13.44,12.33,16.47,18.66,14.09,12.27,15.55,13,10.16,16.21,17.09,10.45,15.76,12.04,10.3,15.37,13.61,14.37,14.27,17.93,25.41,17.58,14.81,27.26,17.19,15.39,18.34,12.6,12.26,11.12,15.03,17.31,16.96,16.9,14.59,21.32,18.46,24.16,34.41,26.82,26.42,29.29,27.8,16.65,29.53,28.32,21.45,14.1,13.28,12.12,15.79,15.12,15.02,16.14,4.59,6.43,7.39,5.5,1.73,1.92,3.32,11.64,9.81,3.7,12.14,11.1,11.32,14.43,12.03,14.69,9.04,9.64,5.33,10.11,6.29,6.92,5.04,7.56,9.45,4.82,5.68,13.98,13.15,4.45,6.68,4.56,5.39,5.1,4.69,2.87,5.03,4.38,2.97,4.08,8.61,6.62,4.56,4.45,7.43,3.11,3.81,2.88,10.87,10.97,18.06,14.66,23.09,17.27,23.98,16.03,9.38,29.55,9.47,13.51,9.69,17.92,10.5,9.71,21.46,9.93,7.6,4.14,4.63,3.13,6.36,3.92,3.76,11.65,5.25,2.47,3.95,8.05,10.88,9.54,4.73,6.36,7.37,11.38,12.4,11.22,5.19,12.5,18.46,9.16,10.15,9.52,6.56,5.9,3.59,3.53,3.54,6.57,9.25,3.11,5.12,7.79,6.9,9.59,7.26,5.91,11.25,8.1,10.45,14.79,7.44,3.16,13.65,13,6.59,7.73,6.58,3.53,2.98,6.05,4.16,7.19,4.85,3.76,4.59,3.01,3.16,7.85,8.23,12.93,7.14,7.6,9.51,3.33,3.56,4.7,8.58,10.4,6.27,7.39,15.84,4.97,4.74,6.07,9.5,8.67,4.86,6.93,8.93,6.47,7.53,4.54,9.97,12.64,5.98,11.72,7.9,9.28,11.5,18.33,15.94,10.36,12.73,7.2,6.87,7.7,11.74,6.12,5.08,6.15,12.79,9.97,7.34,9.09,12.43,7.83,5.68,6.75,8.01,9.8,10.56,8.51,9.74,9.29,5.49,8.65,7.18,4.61,10.53,12.67,6.36,5.99,5.89,5.98,5.49,7.79,4.5,8.05,5.57,17.6,13.27,11.48,12.67,7.79,14.19,10.19,14.64,5.29,7.12,14,13.33,3.26,3.73,2.96,9.53,8.88,34.77,37.97,13.44,23.24,21.24,23.69,21.78,17.21,21.08,23.6,24.56,30.63,30.81,28.28,31.99,30.62,20.85,17.11,18.76,25.68,15.17,16.35,17.12,19.37,19.92,30.59,29.97,26.77,20.32,20.31,19.77,27.38,22.98,23.34,12.13,26.4,19.78,10.11,21.22,34.37,20.08,36.98,29.05,25.79,26.64,20.62,22.74,15.02,15.7,14.1,23.29,17.16,24.39,15.69,14.52,21.52,24.08,17.64,19.69,12.03,16.22,15.17,23.27,18.05,26.45,34.02,22.88,22.11,19.52,16.59,18.85,23.79,23.98,17.79,16.44,18.13,19.31,17.44,17.73,17.27,16.74,18.71,18.13,19.01,16.94,16.23,14.7,16.42,14.65,13.99,10.29,13.22,14.13,17.15,21.32,18.13,14.76,16.29,12.87,14.36,11.66,18.14,24.1,18.68,24.91,18.03,13.11,10.74,7.74,7.01,10.42,13.34,10.58,14.98,11.45,18.06,23.97,29.68,18.07,13.35,12.01,13.59,17.6,21.14,14.1,12.92,15.1,14.33,9.67,9.08,5.64,6.48,7.88],"mode":"markers","scale":true,"type":"scatter3d","marker":{"colorbar":{"title":"","ticklen":2},"cmin":1,"cmax":4,"colorscale":[["0","rgba(68,1,84,1)"],["0.0416666666666667","rgba(70,19,97,1)"],["0.0833333333333333","rgba(72,32,111,1)"],["0.125","rgba(71,45,122,1)"],["0.166666666666667","rgba(68,58,128,1)"],["0.208333333333333","rgba(64,70,135,1)"],["0.25","rgba(60,82,138,1)"],["0.291666666666667","rgba(56,93,140,1)"],["0.333333333333333","rgba(49,104,142,1)"],["0.375","rgba(46,114,142,1)"],["0.416666666666667","rgba(42,123,142,1)"],["0.458333333333333","rgba(38,133,141,1)"],["0.5","rgba(37,144,140,1)"],["0.541666666666667","rgba(33,154,138,1)"],["0.583333333333333","rgba(39,164,133,1)"],["0.625","rgba(47,174,127,1)"],["0.666666666666667","rgba(53,183,121,1)"],["0.708333333333333","rgba(79,191,110,1)"],["0.75","rgba(98,199,98,1)"],["0.791666666666667","rgba(119,207,85,1)"],["0.833333333333333","rgba(147,214,70,1)"],["0.875","rgba(172,220,52,1)"],["0.916666666666667","rgba(199,225,42,1)"],["0.958333333333333","rgba(226,228,40,1)"],["1","rgba(253,231,37,1)"]],"showscale":false,"color":[1,4,4,4,4,4,1,1,3,1,1,1,1,4,4,4,4,4,4,4,3,4,3,3,3,3,4,3,4,4,3,4,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,3,3,4,1,1,1,1,4,4,4,1,4,4,4,4,4,4,4,1,1,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,3,3,3,4,3,3,3,3,4,4,4,4,3,3,3,4,3,3,3,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,4,4,4,4,4,4,4,4,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,4,4,3,4,3,4,3,4,4,3,4,1,1,1,1,4,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,1,1,1,1,1,1,4,3,4,4,4,4,4,4,4,4,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,4,4,4,4,4,4,4,4,4,4,1,1,1,1,1,1,1,4,1,1,1,4,4,4,1,1,1,1,1,1,1,1,1,1,1,4,4,4,4,4,4,4,4,4,4,4,4,3,4,4,4,4,4,4,4,4,4,4,4,1,1,1,1,1,4,4,4,4,4,4,4,4,1,1,4,4,4,4,4,1,4,4,4,4,1,4,4,3,4,4,4,4,4,4,3,4,4,4,3,4,4,4,4,4,3,3,3,3,3,3,3,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,2,3,3,3,3,3,2,2,3,3,3,3,2,3,3,3,2,3,3,3,2,3,3,3,3,3,3,3,3,2,3,3,3,3,4,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,3,4,3,4,3,3,3,3,3,4,4,4,3,3,3,3,3,3,4,4,4,4,4,4,3,4,3,3,3,3,4,4,4,3,3,4,4,4,4,4,4,4,4,4],"line":{"colorbar":{"title":"","ticklen":2},"cmin":1,"cmax":4,"colorscale":[["0","rgba(68,1,84,1)"],["0.0416666666666667","rgba(70,19,97,1)"],["0.0833333333333333","rgba(72,32,111,1)"],["0.125","rgba(71,45,122,1)"],["0.166666666666667","rgba(68,58,128,1)"],["0.208333333333333","rgba(64,70,135,1)"],["0.25","rgba(60,82,138,1)"],["0.291666666666667","rgba(56,93,140,1)"],["0.333333333333333","rgba(49,104,142,1)"],["0.375","rgba(46,114,142,1)"],["0.416666666666667","rgba(42,123,142,1)"],["0.458333333333333","rgba(38,133,141,1)"],["0.5","rgba(37,144,140,1)"],["0.541666666666667","rgba(33,154,138,1)"],["0.583333333333333","rgba(39,164,133,1)"],["0.625","rgba(47,174,127,1)"],["0.666666666666667","rgba(53,183,121,1)"],["0.708333333333333","rgba(79,191,110,1)"],["0.75","rgba(98,199,98,1)"],["0.791666666666667","rgba(119,207,85,1)"],["0.833333333333333","rgba(147,214,70,1)"],["0.875","rgba(172,220,52,1)"],["0.916666666666667","rgba(199,225,42,1)"],["0.958333333333333","rgba(226,228,40,1)"],["1","rgba(253,231,37,1)"]],"showscale":false,"color":[1,4,4,4,4,4,1,1,3,1,1,1,1,4,4,4,4,4,4,4,3,4,3,3,3,3,4,3,4,4,3,4,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,3,3,4,1,1,1,1,4,4,4,1,4,4,4,4,4,4,4,1,1,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,3,3,3,4,3,3,3,3,4,4,4,4,3,3,3,4,3,3,3,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,4,4,4,4,4,4,4,4,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,4,4,3,4,3,4,3,4,4,3,4,1,1,1,1,4,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,1,1,1,1,1,1,4,3,4,4,4,4,4,4,4,4,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,4,4,4,4,4,4,4,4,4,4,1,1,1,1,1,1,1,4,1,1,1,4,4,4,1,1,1,1,1,1,1,1,1,1,1,4,4,4,4,4,4,4,4,4,4,4,4,3,4,4,4,4,4,4,4,4,4,4,4,1,1,1,1,1,4,4,4,4,4,4,4,4,1,1,4,4,4,4,4,1,4,4,4,4,1,4,4,3,4,4,4,4,4,4,3,4,4,4,3,4,4,4,4,4,3,3,3,3,3,3,3,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,2,3,3,3,3,3,2,2,3,3,3,3,2,3,3,3,2,3,3,3,2,3,3,3,3,3,3,3,3,2,3,3,3,3,4,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,3,4,3,4,3,3,3,3,3,4,4,4,3,3,3,3,3,3,4,4,4,4,4,4,3,4,3,3,3,3,4,4,4,3,3,4,4,4,4,4,4,4,4,4]}},"frame":null},{"x":[0.00632,88.9762],"y":[12.6,22],"type":"scatter3d","mode":"markers","opacity":0,"hoverinfo":"none","showlegend":false,"marker":{"colorbar":{"title":"","ticklen":2,"len":0.5,"lenmode":"fraction","y":1,"yanchor":"top"},"cmin":1,"cmax":4,"colorscale":[["0","rgba(68,1,84,1)"],["0.0416666666666667","rgba(70,19,97,1)"],["0.0833333333333333","rgba(72,32,111,1)"],["0.125","rgba(71,45,122,1)"],["0.166666666666667","rgba(68,58,128,1)"],["0.208333333333333","rgba(64,70,135,1)"],["0.25","rgba(60,82,138,1)"],["0.291666666666667","rgba(56,93,140,1)"],["0.333333333333333","rgba(49,104,142,1)"],["0.375","rgba(46,114,142,1)"],["0.416666666666667","rgba(42,123,142,1)"],["0.458333333333333","rgba(38,133,141,1)"],["0.5","rgba(37,144,140,1)"],["0.541666666666667","rgba(33,154,138,1)"],["0.583333333333333","rgba(39,164,133,1)"],["0.625","rgba(47,174,127,1)"],["0.666666666666667","rgba(53,183,121,1)"],["0.708333333333333","rgba(79,191,110,1)"],["0.75","rgba(98,199,98,1)"],["0.791666666666667","rgba(119,207,85,1)"],["0.833333333333333","rgba(147,214,70,1)"],["0.875","rgba(172,220,52,1)"],["0.916666666666667","rgba(199,225,42,1)"],["0.958333333333333","rgba(226,228,40,1)"],["1","rgba(253,231,37,1)"]],"showscale":true,"color":[1,4],"line":{"color":"rgba(255,127,14,1)"}},"z":[1.73,37.97],"frame":null}],"highlight":{"on":"plotly_click","persistent":false,"dynamic":false,"selectize":false,"opacityDim":0.2,"selected":{"opacity":1},"debounce":0},"shinyEvents":["plotly_hover","plotly_click","plotly_selected","plotly_relayout","plotly_brushed","plotly_brushing","plotly_clickannotation","plotly_doubleclick","plotly_deselect","plotly_afterplot","plotly_sunburstclick"],"base_url":"https://plot.ly"},"evals":[],"jsHooks":[]}</script>

### Conclusion

The plot presents an informative clustering representation of observations into 4 following groups:

1)  The most notable cluster is represented by purple color, and those observations have relatively high values of x (crim), medium-high values of y (ptratio), and medium-high values of z (lstat). There are relatively few observations in this cluster, and they are best described as higher-crime districts.

2)  The cluster colored in green represents observations with low values of all variables, and those can best be described by low lower-status population percentage, low crime rate, and low pupil/teacher ratio.

3)  The yellow colored cluster represents observations with relatively high lower-status population percentage, but relatively low pupil/teacher ratio and crime rate.

4)  The blue cluster can best be described as observations with a high pupil/teacher ratio, but low crime rates. The “lstat” values are somewhat low too.

## References

Bureau, US Census. 2021. “Combining Data – a General Overview.” Census.gov. https://www.census.gov/about/what/admin-data.html.

Chanatry, Hannah. 2022. “EPA Designates Lower Neponset River in Boston and Milton a Superfund Site.” WBUR News. WBUR.
https://www.wbur.org/news/2022/03/14/neponset-river-boston-superfund-epa.

Greenwell, Brandon M., and Bradley C. Boehmke. 2020. “Variable Importance Plots—an Introduction to the Vip Package.” The R Journal 12 (1): 343–66. https://doi.org/10.32614/RJ-2020-013.

“Polychlorinated Biphenyls (PCBS) Toxicity.” 2014. Centers for Disease Control and Prevention. Centers for Disease Control; Prevention. https://www.atsdr.cdc.gov/csem/polychlorinated-biphenyls/adverse_health.html.
