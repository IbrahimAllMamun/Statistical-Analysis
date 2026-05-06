library(tidyverse)
library(haven)

hyper <- read_dta("hyper.dta")


hyper$dtsbp[72] <- 146.75

hyper %>% 
  mutate(
    activity = factor(activity, labels = c("Active", "Inactive"))
  ) -> hyper

hyper %>% 
  ggplot(aes(x=activity, y=dtsbp))+
  geom_boxplot(fill="#59a89c") +
  xlab("Physical Activity")+
  ylab("SBP in Day")+
  theme_minimal()
hyper %>% 
  ggplot(aes(x=activity, y=ntsbp))+
  geom_boxplot(fill="#59a89c") +
  xlab("Physical Activity")+
  ylab("SBP at Night")+
  theme_minimal()
hyper %>% 
  ggplot(aes(x=activity, y=dtdbp))+
  geom_boxplot(fill="#59a89c") +
  xlab("Physical Activity")+
  ylab("DBP in Day")+
  theme_minimal()
hyper %>% 
  ggplot(aes(x=activity, y=ntdbp))+
  geom_boxplot(fill="#59a89c") +
  xlab("Physical Activity")+
  ylab("DBP at Night")+
  theme_minimal()

hyper[hyper$dtsbp>200,'hyper'] <- 146.75
which(hyper$dtsbp>200)


