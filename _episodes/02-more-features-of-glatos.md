---
title: More Features of glatos
teaching: 15
exercises: 0
questions:
    - "What other features does glatos offer?"
---
**Note to instructors: please choose the relevant Network below when teaching**

`glatos` has more advanced analytic tools that let you manipulate your data further. We'll cover a few of these features now, to show you how to take your data beyond just filtering and event creation. By combining the `glatos` package's powerful built-in functions with its interoperability across scientific R packages, we'll show you how to derive powerful insights from your data, and format it in a way that lets you demonstrate them.

`glatos` can be used to get the residence index of your animals at all the different stations. In fact, `glatos` offers five different methods for calculating Residence Index. For this lesson, we will showcase two of them, but more information on the others can be found in the `glatos` documentation.

The `residence_index()` function requires an events object to create a residence index. We will start by creating a subset like we did in the last lesson. This will save us some time, since running the residence index on the full set is prohibitively long for the scope of this workshop.

First we will decide which animals to base our subset on. To help us with this, we can use `group_by` on the events object to make it easier to identify good candidates.

~~~
#Using all the events data will take too long, so we will subset to just use a couple animals

events %>% group_by(animal_id) %>% summarise(count=n()) %>% arrange(desc(count))

#In this case, we have already decided to use these three animal IDs as the basis for our subset.

subset_animals <- c('PROJ59-1191631-2014-07-09', 'PROJ59-1191628-2014-07-07', 'PROJ64-1218527-2016-06-07')
events_subset <- events %>% filter(animal_id %in% subset_animals)

events_subset
~~~
{: .language-r}

Now that we have a subset of our events object, we can apply the `residence_index()` functions.

~~~
# Calc residence index using the Kessel method

rik_data <- residence_index(events_subset,
                            calculation_method = 'kessel')
# "Kessel" method is a special case of "time_interval" where time_interval_size = "1 day"
rik_data

# Calc residence index using the time interval method, interval set to 6 hours
rit_data <- residence_index(events_subset,
                            calculation_method = 'time_interval',
                            time_interval_size = "6 hours")

rit_data
~~~
{: .language-r}

Although the code we've written for each method of calculating the residence index is similar, the different parameters and calculation methods mean that these will return different results. It is up to you to investigate which of the methods within `glatos` best suits your data and its intended application.

We will continue with `glatos` for one more lesson, in which we will cover some basic, but very versatile visualization functions provided by the package.