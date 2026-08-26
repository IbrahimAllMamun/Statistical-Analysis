# ============================================================
# Project 14 - univariate distribution figures
# ------------------------------------------------------------
#   Graph/Fig3_AgeGroup_distribution.png   bar
#   Graph/Fig4_Sex_distribution.png        pie
#   Graph/Fig5_Survival_distribution.png   bar
#
# Run script.R first - it writes Data/sepsis_clean.rds.
#
# All three describe the same analysis set used by Tables 1-4
# (patients with a recorded outcome), so the denominators match
# the tables.  Sex is one patient short of the others because
# that field was left blank on the form.
#
# Palette is Okabe-Ito blue / amber (colour-blind safe, no red),
# matching the ROC figures produced by script.R.
# ============================================================

library(dplyr)
library(tidyr)
library(ggplot2)
library(scales)

CLEAN <- "Data/sepsis_clean.rds"
dir.create("Graph", showWarnings = FALSE)

BLUE       <- "#0072B2"
AMBER      <- "#E69F00"
PALETTE_OS <- c(Survivor = BLUE, `Non-survivor` = AMBER)
PALETTE_SEX <- c(Male = BLUE, Female = AMBER)

dat <- readRDS(CLEAN) %>% filter(analysis_set)

# ----------------------------------------------------------
# Helper: one-variable frequency table
# ----------------------------------------------------------
freq <- function(d, var) {
  d %>%
    filter(!is.na(.data[[var]])) %>%
    count(grp = .data[[var]], name = "n", .drop = FALSE) %>%
    mutate(pct = n / sum(n))
}

# ----------------------------------------------------------
# Univariate bar chart
# ----------------------------------------------------------
# `fills` is only supplied when the categories carry their own meaning
# (survivor vs non-survivor); a plain frequency bar stays one colour.
bar_plot <- function(d, var, x_title, fills = NULL) {
  cnt    <- freq(d, var)
  mapped <- !is.null(fills)

  ggplot(cnt, if (mapped) aes(x = grp, y = n, fill = grp) else aes(x = grp, y = n)) +
    (if (mapped) geom_col(width = 0.62) else geom_col(width = 0.62, fill = BLUE)) +
    (if (mapped) scale_fill_manual(values = fills)) +
    geom_text(aes(label = sprintf("%d\n(%s)", n, percent(pct, accuracy = 0.1))),
              vjust = -0.25, size = 3.4, lineheight = 0.95) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.18))) +
    labs(x = x_title, y = "Number of patients",
         caption = paste0("N = ", sum(cnt$n), ".")) +
    theme_bw(base_size = 12) +
    theme(
      legend.position    = "none",
      panel.grid.major.x = element_blank(),
      panel.grid.minor   = element_blank(),
      plot.caption       = element_text(size = 8, colour = "grey30", hjust = 0)
    )
}

# ----------------------------------------------------------
# Univariate pie chart
# ----------------------------------------------------------
pie_plot <- function(d, var, fills) {
  cnt <- freq(d, var)
  ggplot(cnt, aes(x = "", y = n, fill = grp)) +
    geom_col(width = 1, colour = "white", linewidth = 0.9) +
    coord_polar(theta = "y", start = 0) +
    geom_text(aes(label = sprintf("%s\n%d (%s)", grp, n,
                                  percent(pct, accuracy = 0.1))),
              position = position_stack(vjust = 0.5),
              size = 4, colour = "white", fontface = "bold", lineheight = 1) +
    scale_fill_manual(values = fills) +
    labs(caption = paste0("N = ", sum(cnt$n), ".")) +
    theme_void(base_size = 12) +
    theme(
      legend.position = "none",
      plot.caption    = element_text(size = 8, colour = "grey30", hjust = 0.5)
    )
}

# ----------------------------------------------------------
# Figure 3 - age group distribution (bar)
# ----------------------------------------------------------
p_age <- bar_plot(dat, "age_grp", "Age group (years)")
ggsave("Graph/Fig3_AgeGroup_distribution.png", p_age,
       width = 7, height = 5, dpi = 300)

# ----------------------------------------------------------
# Figure 4 - sex distribution (pie)
# ----------------------------------------------------------
p_sex <- pie_plot(dat, "sex", PALETTE_SEX)
ggsave("Graph/Fig4_Sex_distribution.png", p_sex,
       width = 5.5, height = 5.5, dpi = 300)

# ----------------------------------------------------------
# Figure 5 - in-hospital outcome distribution (bar)
# ----------------------------------------------------------
p_os <- bar_plot(dat, "outcome", "In-hospital outcome", fills = PALETTE_OS)
ggsave("Graph/Fig5_Survival_distribution.png", p_os,
       width = 6, height = 5, dpi = 300)

# ----------------------------------------------------------
# Figures 6 & 7 - NLR / NLPR by outcome, one panel per day
# ----------------------------------------------------------
# The two outcome groups are overlaid within each panel and the x scale is
# shared across days, so the day-1 -> day-5 drift apart is readable directly.
long_ratio <- function(d, prefix) {
  cols <- paste0(prefix, "_day", c(1, 3, 5))
  d %>%
    filter(!is.na(outcome)) %>%
    select(outcome, all_of(cols)) %>%
    pivot_longer(all_of(cols), names_to = "day", values_to = "value") %>%
    mutate(day = factor(day, levels = cols,
                        labels = c("Day 1", "Day 3", "Day 5"))) %>%
    filter(!is.na(value))
}

density_plot <- function(d, prefix, x_title) {
  ld <- long_ratio(d, prefix)
  n_lab <- ld %>% count(day, name = "n")
  ggplot(ld, aes(x = value, fill = outcome, colour = outcome)) +
    geom_density(alpha = 0.35, linewidth = 0.7, adjust = 1) +
    facet_wrap(~ day, nrow = 1) +
    scale_fill_manual(values = PALETTE_OS, name = NULL) +
    scale_colour_manual(values = PALETTE_OS, name = NULL) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.06))) +
    labs(x = x_title, y = "Density",
         caption = paste0("Kernel density estimates. ",
                          paste(sprintf("%s n = %d", n_lab$day, n_lab$n), collapse = "; "),
                          ". Survivors and non-survivors are shown on a common x scale.")) +
    theme_bw(base_size = 12) +
    theme(
      legend.position  = "top",
      panel.grid.minor = element_blank(),
      strip.background = element_rect(fill = "grey92", colour = NA),
      strip.text       = element_text(face = "bold"),
      plot.caption     = element_text(size = 8, colour = "grey30", hjust = 0)
    )
}

p_nlr <- density_plot(dat, "nlr", "NLR")
ggsave("Graph/Fig6_NLR_density_by_outcome.png", p_nlr,
       width = 9.5, height = 4.2, dpi = 300)

p_nlpr <- density_plot(dat, "nlpr", "NLPR")
ggsave("Graph/Fig7_NLPR_density_by_outcome.png", p_nlpr,
       width = 9.5, height = 4.2, dpi = 300)

message("Saved -> Graph/Fig3_AgeGroup_distribution.png")
message("Saved -> Graph/Fig4_Sex_distribution.png")
message("Saved -> Graph/Fig5_Survival_distribution.png")
message("Saved -> Graph/Fig6_NLR_density_by_outcome.png")
message("Saved -> Graph/Fig7_NLPR_density_by_outcome.png")
