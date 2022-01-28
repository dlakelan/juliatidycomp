# Comparing Julia and R+Tidyverse for data analysis

Based on [discussions at Andrew Gelman's blog](https://statmodeling.stat.columbia.edu/2022/01/25/im-skeptical-of-that-claim-that-cash-aid-to-poor-mothers-increases-brain-activity-in-babies/#comment-2043556), here is a comparison of how you might carry out some basic data analysis tasks in Julia compared to R+Tidyverse. The commentary will be on the blog, thanks to Phil Price!

Problem 1) The olympics

Reproduce the basic idea of the graph Phil used to evaluate trends in sprint speeds through time based on things like track materials improving through time. 

1) Original graph [can be seen here](https://statmodeling.stat.columbia.edu/2021/08/04/how-much-faster-is-the-tokyo-track/) and the code phil uploaded towards the end has been placed here in the repo as olympics.R and the data in data/olympicsdata.csv my Julia solution is olympics.jl

2) A problem to illustrate how having Julia's language features and fast compiler makes doing even simple simulations much more feasible. My example is in simulate.jl. The problem is that objects start distributed Normal(0,0.1) around the point (0,0) and diffuse around through time radiating energy either out of the system, or to another random particle... until they hit the boundary and are frozen in place. After all of them are frozen, we plot the distribution of log(Energy) and the spatial distribution of the particles around the "keyhole" shaped region, together with a representation of the spatial energy distribution by using color and alpha to show something like a "temperature"

3) Thinking of some other projects. I'd like to see one where we get several data files together and have to munge them into a form to do some graphs. And another final one where we run some regressions (I guess maybe on the data from the munging problem would be fine)
