---
title: Intro to Plotting
teaching: 15
exercises: 10
questions:
    - "How do I plot my data?"
    - "How can I plot summaries of my data?"
objectives:
    - "Learn how to make basic plots with ggplot2"
    - "Learn how to combine dplyr summaries with ggplot2 plots"
keypoints:
    - "You can feed output from dplyr's data manipulation functions into ggplot using pipes."
    - "Plotting various summaries and groupings of your data is good practice at the exploratory phase, and dplyr and ggplot make iterating different ideas straightforward."	  
---
**Note to instructors: please choose the relevant Network below when teaching**

## ACT Node

### Background

Now that we have learned how to import, inspect, and manipulate our data, we are next going to learn how to visualize it. R provides a robust plotting suite in the library `ggplot2`. `ggplot2` takes advantage of tidyverse pipes and chains of data manipulation to build plotting code. Additionally, it separates the aesthetics of the plot (what are we plotting) from the styling of the plot (what the plot looks like). What this means is that data aesthetics and styles can be built separately and then combined and recombined to produce modular, reusable plotting code.

While `ggplot2` function calls can look daunting at first, they follow a single formula, detailed below.

~~~
#Anything within <> braces will be replaced in an actual function call.
ggplot(data = <DATA>, mapping = aes(<MAPPINGS>)) + <GEOM_FUNCTION>
~~~
{: .language-r}

In the above example, there are three important parts: `<DATA>`, `<MAPPINGS>`, and `<GEOM_FUNCTION>`.

`<DATA>` refers to the data that we'll be plotting. In general, this will be held in a dataframe like the one we prepared in the previous lessons.

`<MAPPINGS>` refers to the aesthetic mappings for the data- that is, which columns in the data will be used to determine which attributes of the graph. For example, if you have columns for latitude and longitude, you may want to map these onto the X and Y axes of the graph. We'll cover how to do exactly that in a moment.

Finally, `<GEOM_FUNCTION>` refers to the style of the plot: what type of plot are we going to make. GEOM is short for "geometry" and `ggplot2` contains many different 'geom' functions that you can use. For this lesson, we'll be using `geom_point()`, which produces a scatterplot, but in the future you may want to use `geom_path()`, `geom_bar()`, `geom_boxplot()` or any of ggplots other geom functions. Remember, since these are functions, you can use the help syntax (i.e `?geom_point`) in the R console to find out more about them and what you need to pass to them.

Now that we've introduced `ggplot2`, let's build a functional example with our data.

~~~
# Begin by importing the ggplot2 library, which you should have installed as part of setup.
library(ggplot2)

# Build the plot and assign it to a variable.
proj58_matched_full_plot <- ggplot(data = proj58_matched_full,
                  mapping = aes(x = longitude, y = latitude)) #can assign a base
~~~
{:. language-r}

With a couple of lines of code, we've already mostly completed a simple scatter plot of our data. The 'data' parameter takes our dataframe, and the mapping parameter takes the output of the `aes()` function, which itself takes a mapping of our data onto the axes of the graph. That can be a bit confusing, so let's briefly break this down. `aes()` is short for 'aesthetics'- the function constructs the aesthetic mappings of our data, which describe how variables in the data are mapped to visual properties of the plot. For example, above, we are setting the 'x' attribute to 'longitude', and the 'y' attribute to latitude. This means that the X axis of our plot will represent longitude, and the Y axis will represent latitude. Depending on the type of plot you're making, you may want different values there, and different types of geom functions can require different aesthetic mappings (colour, for example, is another common one). You can always type `?aes()` at the console if you want more information.

We still have one step to add to our plotting code: the geom function. We'll be making a scatterplot, so we want to use `geom_point()`.

~~~
proj58_matched_full_plot +
  geom_point(alpha=0.1,
             colour = "blue")
#This will layer our chosen geom onto our plot template.
#alpha is a transparency argument in case points overlap. Try alpha = 0.02 to see how it works!
~~~
{: .language-r}

With just the above code, we've added our geom to our aesthetic and made our plot ready for display. We've built only a very simple plot here, but `ggplot2` provides many, many options for building more complex, illustrative plots.

### Basic plots

As a minor syntactic note, you can build your plots iteratively, without assigning them to a variable in-between. For this, we make use of `tidyverse` pipes.
~~~
proj58_matched_full %>%  
  ggplot(aes(longitude, latitude)) +
  geom_point() #geom = the type of plot

proj58_matched_full %>%  
  ggplot(aes(longitude, latitude, colour = commonname)) +
  geom_point()


#anything you specify in the aes() is applied to the actual data points/whole plot,
#anything specified in geom() is applied to that layer only (colour, size...). sometimes you have >1 geom layer so this makes more sense!

~~~
{: .language-r}

You can see that all we need to do to make this work is omit the 'data' parameter, since that's being passed in by the pipe. Note also that we've added `colour = commonname` to the second plot's aesthetic, meaning that the output will be coloured based on the species of the animal (if there is more than one included).

Remembering which of the `aes` or the `geom` controls which variable can be difficult, but here's a handy rule of thumb: anything specified in `aes()` will apply to the data points themselves, or the whole plot. They are broad statements about how the plot is to be displayed. Anything in the `geom_` function will apply only to that `geom_` layer. Keep this in mind, since it's possible for your plot to have more than one `geom_`!

> ## Plotting and dplyr Challenge
>
> Try combining with `dplyr` functions in this challenge!
> Try making a scatterplot showing the lat/long for animal "PROJ58-1218515-2015-10-13", coloured by detection array
> > ## Solution
> > ~~~
> > proj58_matched_full %>%  
> >  filter(catalognumber=="PROJ58-1218515-2015-10-13") %>%
> >  ggplot(aes(longitude, latitude, colour = detectedby)) +
> >  geom_point()
> > ~~~
> > {: .language-r}
> {: .solution}
>
> What other geoms are there? Try typing `geom_` into R to see what it suggests!
{: .challenge}


## FACT Node

### Background

Now that we have learned how to import, inspect, and manipulate our data, we are next going to learn how to visualize it. R provides a robust plotting suite in the library `ggplot2`. `ggplot2` takes advantage of tidyverse pipes and chains of data manipulation to build plotting code. Additionally, it separates the aesthetics of the plot (what are we plotting) from the styling of the plot (what the plot looks like). What this means is that data aesthetics and styles can be built separately and then combined and recombined to produce modular, reusable plotting code.

While `ggplot2` function calls can look daunting at first, they follow a single formula, detailed below.

~~~
#Anything within <> braces will be replaced in an actual function call.
ggplot(data = <DATA>, mapping = aes(<MAPPINGS>)) + <GEOM_FUNCTION>
~~~
{: .language-r}

In the above example, there are three important parts: `<DATA>`, `<MAPPINGS>`, and `<GEOM_FUNCTION>`.

`<DATA>` refers to the data that we'll be plotting. In general, this will be held in a dataframe like the one we prepared in the previous lessons.

`<MAPPINGS>` refers to the aesthetic mappings for the data- that is, which columns in the data will be used to determine which attributes of the graph. For example, if you have columns for latitude and longitude, you may want to map these onto the X and Y axes of the graph. We'll cover how to do exactly that in a moment.

Finally, `<GEOM_FUNCTION>` refers to the style of the plot: what type of plot are we going to make. GEOM is short for "geometry" and `ggplot2` contains many different 'geom' functions that you can use. For this lesson, we'll be using `geom_point()`, which produces a scatterplot, but in the future you may want to use `geom_path()`, `geom_bar()`, `geom_boxplot()` or any of ggplots other geom functions. Remember, since these are functions, you can use the help syntax (i.e `?geom_point`) in the R console to find out more about them and what you need to pass to them.

Now that we've introduced `ggplot2`, let's build a functional example with our data.

~~~
# Begin by importing the ggplot2 library, which you should have installed as part of setup.
library(ggplot2)

# Build the plot and assign it to a variable.
tqcs_10_11_plot <- ggplot(data = tqcs_matched_10_11,
                          mapping = aes(x = longitude, y = latitude)) #can assign a base
~~~
{:. language-r}

With a couple of lines of code, we've already mostly completed a simple scatter plot of our data. The 'data' parameter takes our dataframe, and the mapping parameter takes the output of the `aes()` function, which itself takes a mapping of our data onto the axes of the graph. That can be a bit confusing, so let's briefly break this down. `aes()` is short for 'aesthetics'- the function constructs the aesthetic mappings of our data, which describe how variables in the data are mapped to visual properties of the plot. For example, above, we are setting the 'x' attribute to 'longitude', and the 'y' attribute to latitude. This means that the X axis of our plot will represent longitude, and the Y axis will represent latitude. Depending on the type of plot you're making, you may want different values there, and different types of geom functions can require different aesthetic mappings (colour, for example, is another common one). You can always type `?aes()` at the console if you want more information.

We still have one step to add to our plotting code: the geom function. We'll be making a scatterplot, so we want to use `geom_point()`.

~~~
tqcs_10_11_plot +
  geom_point(alpha=0.1,
             colour = "blue")  
#This will layer our chosen geom onto our plot template.
#alpha is a transparency argument in case points overlap. Try alpha = 0.02 to see how it works!
~~~
{: .language-r}

With just the above code, we've added our geom to our aesthetic and made our plot ready for display. We've built only a very simple plot here, but `ggplot2` provides many, many options for building more complex, illustrative plots.

### Basic plots

As a minor syntactic note, you can build your plots iteratively, without assigning them to a variable in-between. For this, we make use of `tidyverse` pipes.
~~~
tqcs_matched_10_11 %>%  
  ggplot(aes(longitude, latitude)) +
  geom_point() #geom = the type of plot

tqcs_matched_10_11 %>%  
  ggplot(aes(longitude, latitude, colour = commonname)) +
  geom_point()


#anything you specify in the aes() is applied to the actual data points/whole plot,
#anything specified in geom() is applied to that layer only (colour, size...). sometimes you have >1 geom layer so this makes more sense!

~~~
{: .language-r}

You can see that all we need to do to make this work is omit the 'data' parameter, since that's being passed in by the pipe. Note also that we've added `colour = commonname` to the second plot's aesthetic, meaning that the output will be coloured based on the species of the animal (if there is more than one included).

Remembering which of the `aes` or the `geom` controls which variable can be difficult, but here's a handy rule of thumb: anything specified in `aes()` will apply to the data points themselves, or the whole plot. They are broad statements about how the plot is to be displayed. Anything in the `geom_` function will apply only to that `geom_` layer. Keep this in mind, since it's possible for your plot to have more than one `geom_`!

> ## Plotting and dplyr Challenge
>
> Try combining with `dplyr` functions in this challenge!
> Try making a scatterplot showing the lat/long for animal "TQCS-1049258-2008-02-14", coloured by detection array
> > ## Solution
> > ~~~
> > tqcs_matched_10_11  %>%  
> >  filter(catalognumber=="TQCS-1049258-2008-02-14") %>%
> >  ggplot(aes(longitude, latitude, colour = detectedby)) +
> >  geom_point()
> > ~~~
> > {: .language-r}
> {: .solution}
>
> What other geoms are there? Try typing `geom_` into R to see what it suggests!
{: .challenge}

## GLATOS Network

### Background

Now that we have learned how to import, inspect, and manipulate our data, we are next going to learn how to visualize it. R provides a robust plotting suite in the library `ggplot2`. `ggplot2` takes advantage of tidyverse pipes and chains of data manipulation to build plotting code. Additionally, it separates the aesthetics of the plot (what are we plotting) from the styling of the plot (what the plot looks like). What this means is that data aesthetics and styles can be built separately and then combined and recombined to produce modular, reusable plotting code.

While `ggplot2` function calls can look daunting at first, they follow a single formula, detailed below.

~~~
#Anything within <> braces will be replaced in an actual function call.
ggplot(data = <DATA>, mapping = aes(<MAPPINGS>)) + <GEOM_FUNCTION>
~~~
{: .language-r}

In the above example, there are three important parts: `<DATA>`, `<MAPPINGS>`, and `<GEOM_FUNCTION>`.

`<DATA>` refers to the data that we'll be plotting. In general, this will be held in a dataframe like the one we prepared in the previous lessons.

`<MAPPINGS>`refers to the aesthetic mappings for the data- that is, which columns in the data will be used to determine which attributes of the graph. For example, if you have columns for latitude and longitude, you may want to map these onto the X and Y axes of the graph. We'll cover how to do exactly that in a moment.

Finally, `<GEOM_FUNCTION>` refers to the style of the plot: what type of plot are we going to make. GEOM is short for "geometry" and `ggplot2` contains many different 'geom' functions that you can use. For this lesson, we'll be using `geom_point()`, which produces a scatterplot, but in the future you may want to use `geom_path()`, `geom_bar()`, `geom_boxplot()` or any of ggplots other geom functions. Remember, since these are functions, you can use the help syntax (i.e `?geom_point`) in the R console to find out more about them and what you need to pass to them.

Now that we've introduced `ggplot2`, let's build a functional example with our data.

~~~
# Begin by importing the ggplot2 library, which you should have installed as part of setup.
library(ggplot2)

# Build the plot and assign it to a variable.
lamprey_dets_plot <- ggplot(data = lamprey_dets,
                                   mapping = aes(x = deploy_long, y = deploy_lat)) #can assign a base

~~~
{:. language-r}

With a couple of lines of code, we've already mostly completed a simple scatter plot of our data. The 'data' parameter takes our dataframe, and the mapping parameter takes the output of the `aes()` function, which itself takes a mapping of our data onto the axes of the graph. That can be a bit confusing, so let's briefly break this down. `aes()` is short for 'aesthetics'- the function constructs the aesthetic mappings of our data, which describe how variables in the data are mapped to visual properties of the plot. For example, above, we are setting the 'x' attribute to 'deploy_long', and the 'y' attribute to 'deploy_lat'. This means that the X axis of our plot will represent longitude, and the Y axis will represent latitude. Depending on the type of plot you're making, you may want different values there, and different types of geom functions can require different aesthetic mappings (colour, for example, is another common one). You can always type `?aes()` at the console if you want more information.

We still have one step to add to our plotting code: the geom function. We'll be making a scatterplot, so we want to use `geom_point()`.

~~~
lamprey_dets_plot +
  geom_point(alpha=0.1,
             colour = "blue")  
#This will layer our chosen geom onto our plot template.
#alpha is a transparency argument in case points overlap. Try alpha = 0.02 to see how it works!
~~~
{: .language-r}

With just the above code, we've added our geom to our aesthetic and made our plot ready for display. We've built only a very simple plot here, but `ggplot2` provides many, many options for building more complex, illustrative plots.

### Basic plots

As a minor syntactic note, you can build your plots iteratively, without assigning them to a variable in-between. For this, we make use of `tidyverse` pipes.
~~~
all_dets %>%  
  ggplot(aes(deploy_long, deploy_lat)) +
  geom_point() #geom = the type of plot

all_dets %>%  
  ggplot(aes(deploy_long, deploy_lat, colour = common_name_e)) +
  geom_point()


#anything you specify in the aes() is applied to the actual data points/whole plot,
#anything specified in geom() is applied to that layer only (colour, size...). sometimes you have >1 geom layer so this makes more sense!

~~~
{: .language-r}

You can see that all we need to do to make this work is omit the 'data' parameter, since that's being passed in by the pipe. Note also that we've added `colour = common_name_e` to the second plot's aesthetic, meaning that the output will be coloured based on the species of the animal.

Remembering which of the `aes` or the `geom` controls which variable can be difficult, but here's a handy rule of thumb: anything specified in `aes()` will apply to the data points themselves, or the whole plot. They are broad statements about how the plot is to be displayed. Anything in the `geom_` function will apply only to that `geom_` layer. Keep this in mind, since it's possible for your plot to have more than one `geom_`!

> ## Plotting and dplyr Challenge
>
> Try combining with `dplyr` functions in this challenge!
> Try making a scatterplot showing the lat/long for animal "A69-1601-1363", coloured by detection array
> > ## Solution
> > ~~~
> > all_dets  %>%  
> >  filter(animal_id=="A69-1601-1363") %>%
> >  ggplot(aes(deploy_long, deploy_lat, colour = glatos_array)) +
> >  geom_point()
> > ~~~
> > {: .language-r}
> {: .solution}
>
> What other geoms are there? Try typing `geom_` into R to see what it suggests!
{: .challenge}
