---
title: "In-Class Activity: Sufficient Estimators"
author: "Alex McCreight, Hongyi Liu, Ting Huang"
date: '2023-05-04'
excerpt: For my mathematical statistics capstone, my group gave a presentation on sufficiency and the factorization theorem. After our presentation, we handed out the following worksheet to connect sufficiency to other properties of estimators and the Rao-Blackwell theorem.
---



# Review: Properties of Estimators

1. Please state the definition of unbiasedness. Please list the difference between unbiased estimator and asymptotically estimator. 

2. Please state the definition of an estimator's efficiency. When do we know that an estimator is most efficient?

# Sufficiency via Factorization Theorem

3. If `\(X_1, \cdots, X_n\)` are independent Poisson-distributed random variables with expected value `\(\lambda\)`, please propose a sufficient statistic for `\(\lambda\)`, and prove it. 

4. If `\(X_1, \cdots, X_n\)` are independent Normal-distributed random variables with **known**expected value `\(\mu\)` and **unknown** variance `\(\sigma^2\)`, please propose a sufficient statistic for `\(\sigma^2\)`, and prove it. 

    
5. If `\(X_1, \cdots, X_n\)` are independent Uniform-distributed random variables  `\(U(0,\theta)\)`, please propose a sufficient statistic for `\(\theta\)`, and prove it. 

*Corollary*: we can multiply a sufficient statistic by a nonzero constant and get another sufficient statistic.

6. What are the properties of the estimators you found in 3-5? What can be said about their unbiasedness, efficiency or consistency? Can you propose other sufficient estimators?

# Optional: Property of Sufficient Estimator

Consider a sample `\(X_1, ..., X_n\)` from a Bernoulli distribution with parameter `\(p\)`. We want to estimate the parameter `\(p\)`. 


7. Let's us a wild estimator for `\(p\)`, `\(\theta_1 = X_1\)`. Please comment on the unbiasedness and efficiency of `\(\theta_1\)`.

8. Let `\(T(X) = \frac{1}{n}\sum_{i=1}^n X_i\)`. 

We claim that `\(T(X)\)` is a sufficient statistic for `\(p\)`. Consider a more refined estimator

$$
\theta_2 = \mathbb{E}[\theta_1 \mid T(X)].
$$

Please simplify `\(\theta_2\)` and comment on its properties. 

**Hint**: If `\(X\)` and `\(Y\)` are independent random variables, we have `\(E(X|Y)=E(X)\)`.

**Note**: This is a special case of the *Rao-Blackwell Theorem*, which states that if `\(g(X)\)` is any kind of estimator of a parameter `\(\theta\)`, then the conditional expectation of `\(g(X)\)` given `\(T(X)\)`, where `\(T\)` is a sufficient statistic, is typically a better estimator of `\(\theta\)` in terms of variance, and is never worse.
