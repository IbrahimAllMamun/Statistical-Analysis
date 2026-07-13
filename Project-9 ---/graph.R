library(tidyverse)

data_mod <- readRDS("data/model_data.RDS")



# Department — grouped bars, faceted by knowledge/practice x cancer
dept_grp <- bind_rows(
  data_mod %>% transmute(cancer = "Prostate", metric = "Knowledge", score = know_prostate, dept),
  data_mod %>% transmute(cancer = "Prostate", metric = "Practice",  score = prac_prostate, dept),
  data_mod %>% transmute(cancer = "Colon",    metric = "Knowledge", score = know_colon,    dept),
  data_mod %>% transmute(cancer = "Colon",    metric = "Practice",  score = prac_colon,    dept)
) %>%
  filter(!is.na(score), !is.na(dept)) %>%
  count(cancer, metric, score, dept) %>%
  group_by(cancer, metric, score) %>%
  mutate(pct = n / sum(n))

ggplot(dept_grp, aes(score, pct, fill = dept)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6) +
  facet_grid(metric ~ cancer) +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_manual(values = c("Non Clinical" = "#2a78d6", "Clinical" = "#1baf7a")) +
  labs(x = NULL, y = NULL, fill = "Department",
       title = "Department composition by knowledge/practice score") +
  theme_bw(base_size = 12) +
  theme(legend.position = "bottom")

# Duration of graduation — grouped bars, same facet structure
dur_grp <- bind_rows(
  data_mod %>% transmute(cancer = "Prostate", metric = "Knowledge", score = know_prostate, dgraduation),
  data_mod %>% transmute(cancer = "Prostate", metric = "Practice",  score = prac_prostate, dgraduation),
  data_mod %>% transmute(cancer = "Colon",    metric = "Knowledge", score = know_colon,    dgraduation),
  data_mod %>% transmute(cancer = "Colon",    metric = "Practice",  score = prac_colon,    dgraduation)
) %>%
  filter(!is.na(score), !is.na(dgraduation)) %>%
  count(cancer, metric, score, dgraduation) %>%
  group_by(cancer, metric, score) %>%
  mutate(pct = n / sum(n))

ggplot(dur_grp, aes(score, pct, fill = dgraduation)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6) +
  facet_grid(metric ~ cancer) +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_manual(values = c("<6" = "#2a78d6", "6-10" = "#1baf7a", ">10" = "#eda100")) +
  labs(x = NULL, y = NULL, fill = "Years since graduation",
       title = "Graduation duration by knowledge/practice score") +
  theme_bw(base_size = 12) +
  theme(legend.position = "bottom")



























# Prostate - Colon
library(tidyverse)

# Department — grouped bars with labels
dept_grp <- bind_rows(
  data_mod %>% transmute(cancer = "Prostate Cancer",      metric = "Knowledge", score = know_prostate, dept),
  data_mod %>% transmute(cancer = "Prostate Cancer",      metric = "Practice",  score = prac_prostate, dept),
  data_mod %>% transmute(cancer = "Colorectal Cancer",    metric = "Knowledge", score = know_colon,    dept),
  data_mod %>% transmute(cancer = "Colorectal Cancer",    metric = "Practice",  score = prac_colon,    dept)
) %>%
  filter(!is.na(score), !is.na(dept)) %>%
  count(cancer, metric, score, dept) %>%
  group_by(cancer, metric, score) %>%
  mutate(pct = n / sum(n))

dept_graph <- ggplot(dept_grp, aes(score, pct, fill = dept)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6) +
  geom_text(aes(label = scales::percent(pct, accuracy = 1)),
            position = position_dodge(width = 0.7),
            vjust = -0.4, size = 3.2) +
  facet_grid(metric ~ cancer) +
  scale_y_continuous(labels = scales::percent, expand = expansion(mult = c(0, 0.15))) +
  scale_fill_manual(values = c("Non Clinical" = "#2a78d6", "Clinical" = "#1baf7a")) +
  labs(x = NULL, y = NULL, fill = "Department",
       title = "") +
  theme_bw(base_size = 12) +
  theme(legend.position = "bottom")

# Duration of graduation — grouped bars with labels
dur_grp <- bind_rows(
  data_mod %>% transmute(cancer = "Prostate Cancer",      metric = "Knowledge", score = know_prostate, dgraduation),
  data_mod %>% transmute(cancer = "Prostate Cancer",      metric = "Practice",  score = prac_prostate, dgraduation),
  data_mod %>% transmute(cancer = "Colorectal Cancer",    metric = "Knowledge", score = know_colon,    dgraduation),
  data_mod %>% transmute(cancer = "Colorectal Cancer",    metric = "Practice",  score = prac_colon,    dgraduation)
) %>%
  filter(!is.na(score), !is.na(dgraduation)) %>%
  count(cancer, metric, score, dgraduation) %>%
  group_by(cancer, metric, score) %>%
  mutate(pct = n / sum(n))

grad_graph <- ggplot(dur_grp, aes(score, pct, fill = dgraduation)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6) +
  geom_text(aes(label = scales::percent(pct, accuracy = 1)),
            position = position_dodge(width = 0.7),
            vjust = -0.4, size = 3.2) +
  facet_grid(metric ~ cancer) +
  scale_y_continuous(labels = scales::percent, expand = expansion(mult = c(0, 0.15))) +
  scale_fill_manual(values = c("<6" = "#2a78d6", "6-10" = "#1baf7a", ">10" = "#eda100")) +
  labs(x = NULL, y = NULL, fill = "Duration since graduation",
       title = "") +
  theme_bw(base_size = 12) +
  theme(legend.position = "bottom")


ggsave("graph/fig1_graduation_year.png", grad_graph,
                  width = 8, height = 6, dpi = 300)

ggsave("graph/fig2_department.png", dept_graph,
                  width = 8, height = 6, dpi = 300)




















data_mod$know


# Breast - Cervical
library(tidyverse)

# Department — grouped bars with labels
dept_grp <- bind_rows(
  data_mod %>% transmute(cancer = "Breast Cancer",      metric = "Knowledge", score = know_breast,      dept),
  data_mod %>% transmute(cancer = "Breast Cancer",      metric = "Practice",  score = prac_breast,      dept),
  data_mod %>% transmute(cancer = "Cervical Cancer",    metric = "Knowledge", score = know_cervical,    dept),
  data_mod %>% transmute(cancer = "Cervical Cancer",    metric = "Practice",  score = prac_cervical,    dept)
) %>%
  filter(!is.na(score), !is.na(dept)) %>%
  count(cancer, metric, score, dept) %>%
  group_by(cancer, metric, score) %>%
  mutate(pct = n / sum(n)) %>%   # denominator = Clinical + Non-Clinical, computed BEFORE filtering
  ungroup() %>%
  filter(dept == "Clinical")     # now drop Non-Clinical, keeping the correct pct

dept_graph <- ggplot(dept_grp, aes(score, pct, fill = metric)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6) +
  geom_text(aes(label = scales::percent(pct, accuracy = 1)),
            position = position_dodge(width = 0.7),
            vjust = -0.4, size = 3.2) +
  facet_grid(~ cancer) +
  scale_y_continuous(labels = scales::percent, expand = expansion(mult = c(0, 0.15))) +
  scale_fill_manual(values = c("Knowledge" = "#2a78d6", "Practice" = "#1baf7a")) +
  labs(x = NULL, y = NULL, fill = "", title = "") +
  theme_bw(base_size = 12) +
  theme(legend.position = "bottom")


# Duration of graduation — grouped bars with labels
dur_grp <- bind_rows(
    data_mod %>% transmute(cancer = "Breast Cancer",      metric = "Knowledge", score = know_breast,      dgraduation),
    data_mod %>% transmute(cancer = "Breast Cancer",      metric = "Practice",  score = prac_breast,      dgraduation),
    data_mod %>% transmute(cancer = "Cervical Cancer",    metric = "Knowledge", score = know_cervical,    dgraduation),
    data_mod %>% transmute(cancer = "Cervical Cancer",    metric = "Practice",  score = prac_cervical,    dgraduation)
  ) %>%
  filter(!is.na(score), !is.na(dgraduation)) %>%
  count(cancer, metric, score, dgraduation) %>%
  group_by(cancer, metric, score) %>%
  mutate(pct = n / sum(n))

grad_graph <- ggplot(dur_grp, aes(score, pct, fill = dgraduation)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6) +
  geom_text(aes(label = scales::percent(pct, accuracy = 1)),
            position = position_dodge(width = 0.7),
            vjust = -0.4, size = 3.2) +
  facet_grid(metric ~ cancer) +
  scale_y_continuous(labels = scales::percent, expand = expansion(mult = c(0, 0.15))) +
  scale_fill_manual(values = c("<6" = "#2a78d6", "6-10" = "#1baf7a", ">10" = "#eda100")) +
  labs(x = NULL, y = NULL, fill = "Duration since graduation",
       title = "") +
  theme_bw(base_size = 12) +
  theme(legend.position = "bottom")


ggsave("graph/fig1_graduation_year_br_ser.png", grad_graph,
                  width = 8, height = 6, dpi = 300)

ggsave("graph/fig2_department_br_ser.png", dept_graph,
                  width = 8, height = 6, dpi = 300)


