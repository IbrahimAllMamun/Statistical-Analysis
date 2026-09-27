library(tidyverse)
library(gtsummary)

library(haven)
library(flextable)
library(officer)

library(labelled)

library(dplyr)
library(broom)
library(gt)

library(readxl)

save_gph <- function(plot_obj, graph_name, kind){
  ggsave(
    filename = paste0(paste("graph", kind, graph_name, sep="/"),".jpg"),
    plot     = plot_obj,   # or the plot object, e.g. gph_1
    device   = "jpeg",
    width    = 8,
    height   = 5,
    units    = "in",
    dpi      = 600,
    quality  = 100
  )
}


bdl <- function(x){
  ifelse(x<=1, "BDL", x %>% round(2))
}

detection <- function(x) {
  n <- length(x)
  n_n <- sum(x > 1)
  n_n / n * 100
}

anova_res <- function(data, fml, type_name) {
  data %>%
    aov(fml, data = .) %>%
    broom::tidy() %>%
    select(term, df, sumsq, meansq, statistic, p.value) %>%
    rename(
      Term = term,
      `DF` = df,
      `Sum Sq` = sumsq,
      `Mean Sq` = meansq,
      `F value` = statistic,
      `Pr(>F)` = p.value
    ) %>%
    mutate(across(where(is.numeric), ~ round(.x, 3))) %>%
    flextable::flextable() %>%
    flextable::set_caption(
      paste(
        "Anova", type_name
      )
    ) %>%
    flextable::autofit()
}


result <- function(data, data_aov, vars, fml, type_name) {
  tab1 <- tibble()
  
  for (i in 4:17) {
    var_name <- vars$var_name[i]
    x <- pull(data, var_name)
    comp_name <- vars$ocp[i]
    mean_val <- mean(x) %>% round(2)
    sd_val <- sd(x) %>% round(2)
    min_val <- min(x) %>% round(2)
    min_val <- ifelse(min_val < 1, "BDL", min_val %>% round(2) %>% as.character())
    max_val <- max(x) %>% round(2)
    detect <- detection(x) %>% round(2)
    
    tab1 <- rbind(tab1, c(
      comp_name,
      paste(mean_val, "±", sd_val),
      paste(min_val, "-", max_val),
      detect
    ))
  }
  
  names(tab1) <- c("Compound", "Mean ± SD", "Range", "Detection frequency (%)")
  
  tab11 <- tab1 %>% 
    flextable::flextable() %>%
    flextable::set_caption(
      paste(
        "Table-1", type_name
      )
    ) %>%
    flextable::autofit()
  
  
  plot_df <- tab1 %>%
    mutate(
      group = case_when(
        Compound %in% c(
          "o,p'-DDT",
          "p,p'-DDT",
          "o,p'-DDD",
          "p,p'-DDD",
          "o,p'-DDE",
          "p,p'-DDE"
        ) ~ "DDTs",
        Compound %in% c("α-HCH", "β-HCH", "γ-HCH (Lindane)", "δ-HCH") ~ "HCHs",
        Compound %in% c("Aldrin", "Dieldrin") ~ "DRNs",
        .default = "HPTs"
      ),
      Compound = factor(
        Compound,
        levels = c(
          "o,p'-DDT",
          "p,p'-DDT",
          "o,p'-DDD",
          "p,p'-DDD",
          "o,p'-DDE",
          "p,p'-DDE",
          "α-HCH",
          "β-HCH",
          "γ-HCH (Lindane)",
          "δ-HCH",
          "Aldrin",
          "Dieldrin",
          "Heptachlor",
          "Heptachlor epoxide"
        ) %>% rev()
      ),
      `Detection frequency (%)` = as.numeric(`Detection frequency (%)`)
    ) %>% 
    separate_wider_delim(`Mean ± SD`, delim = "\u00b1", names = c("mean", "sd")) |>
    mutate(across(c(mean, sd), readr::parse_number))
  
  gph_1 <- ggplot(plot_df, aes(Compound, mean, fill = group)) +
    geom_col(width = 0.7, colour = "black") +
    geom_errorbar(aes(ymin = pmax(mean - sd, 0), ymax = mean + sd), width = 0.25) +
    labs(x = NULL, y = "Concentration (mean ± SD)") +
    coord_flip() +
    theme_classic() +
    theme(axis.text.x = element_text(hjust = 1))
  
  gph_2 <- ggplot(plot_df, aes(Compound, `Detection frequency (%)`)) +
    geom_col(width = 0.7, fill = "grey40", colour = "black") +
    geom_text(aes(label = round(`Detection frequency (%)`, 1)),
              hjust = -0.2, size = 3.5) +
    # scale_y_continuous(expand = expansion(mult = c(0, 100))) +
    labs(x = NULL, y = "Detection frequency (%)") +
    coord_flip() +
    theme_classic()
  
  
  
  donut_df <- plot_df %>% 
    group_by(group) %>% 
    summarise(total_ocp = sum(mean)) %>% 
    mutate(ocp_p = total_ocp / sum(total_ocp))
  
  don <- ggplot(donut_df, aes(x = 2, y = ocp_p, fill = group)) +
    geom_col(width = 1, colour = "black") +
    geom_text(aes(label = scales::percent(ocp_p, accuracy = 0.1)),
              position = position_stack(vjust = 0.5), size = 3.5) +
    coord_polar(theta = "y", start = 0) +
    xlim(0.5, 2.5) +
    labs(fill = NULL) +
    theme_void()
  

  list(tbl = tab11, anova_tbl = anova_res(data_aov, fml, type_name), graph_1 = gph_1, graph_2 = gph_2, don=don)
}










# Fish
vars_fish <- read_xlsx("data_fish.xlsx", sheet = "vars")
data_fish <- read_xlsx(
  "data_fish.xlsx",
  sheet = "data",
  skip = 1,
  col_names = vars_fish$var_name
)
hi_data_fish <- read_xlsx("data_fish.xlsx", sheet = "hi_data")

data_fish_clean <- data_fish %>%
  rowwise() %>%
  mutate(
    ocp = sum(
      op_ddt,
      pp_ddt,
      op_ddd,
      pp_ddd,
      op_dde,
      pp_dde,
      a_hch,
      b_hch,
      g_hch,
      d_hch,
      aldrin,
      dieldrin,
      heptachlor,
      heptachlor_epox
    )
  ) %>%
  select(
    -c(
      op_ddt,
      pp_ddt,
      op_ddd,
      pp_ddd,
      op_dde,
      pp_dde,
      a_hch,
      b_hch,
      g_hch,
      d_hch,
      aldrin,
      dieldrin,
      heptachlor,
      heptachlor_epox,
      Sample_ID
    )
  )

res_fish <- result(data_fish, data_fish_clean, vars_fish, as.formula("ocp ~ Fish + Zone + Fish:Zone"), "Fish")


res_fish$tbl
res_fish$anova_tbl
res_fish$graph_1
res_fish$graph_2


res_fish$graph_1 %>% 
  save_gph("g1", kind="Fish")
res_fish$graph_2 %>% 
  save_gph("g2", kind="Fish")
res_fish$don %>% 
  save_gph("g2_2", kind="Fish")












# Sediment
vars_sediment <- read_xlsx("data_sediment.xlsx", sheet = "vars")
data_sediment <- read_xlsx(
  "data_sediment.xlsx",
  sheet = "data",
  skip = 1,
  col_names = vars_sediment$var_name
)
hi_data_sediment <- read_xlsx("data_sediment.xlsx", sheet = "hi_data")


data_sediment_clean <- data_sediment %>%
  rowwise() %>%
  mutate(
    ddt = sum(op_ddt, pp_ddt, op_ddd, pp_ddd, op_dde, pp_dde),
    hch = sum(a_hch, b_hch, g_hch, d_hch),
    drn = sum(aldrin, dieldrin),
    hpt = sum(heptachlor, heptachlor_epox)
  ) %>%
  select(Zone, Location, ddt, hch, drn, hpt) %>%
  pivot_longer(!c(Zone, Location), names_to = "class", values_to = "ocp")

res_sediment <- result(data_sediment,
                       data_sediment_clean,
                       vars_sediment,
                       as.formula("ocp ~ class + Zone + class:Zone"),
                       "Sediment")






sed_tab2 <- data_sediment %>% 
  rowwise() %>% 
  mutate(
    ocp = sum(op_ddt, pp_ddt, op_ddd, pp_ddd, op_dde, pp_dde,
               a_hch, b_hch, g_hch, d_hch,
               aldrin, dieldrin,
               heptachlor, heptachlor_epox)
  ) %>% 
  group_by(Location, Zone) %>% 
  summarise(
    mean_val = mean(ocp),
    sd_val = sd(ocp),
    min_val = min(ocp),
    max_val = max(ocp)
  ) %>% 
  arrange(desc(Zone), Location) %>% 
  ungroup() %>% 
  mutate(
    `Mean ± SD` = paste(bdl(mean_val), "±",sd_val %>% round(2)),
    Range = paste(bdl(min_val), "-",bdl(max_val) %>% round(2))
  ) %>% 
  select(-c(mean_val, sd_val, min_val, max_val)) %>% 
  flextable::flextable() %>%
  flextable::set_caption(
    paste(
      "Table-2 Sediment"
    )
  ) %>%
  flextable::autofit()

res_sediment$tbl
res_sediment$anova_tbl
res_sediment$graph_1
res_sediment$graph_2
sed_tab2


res_sediment$graph_1 %>% 
  save_gph("g1", kind="Sediment")
res_sediment$graph_2 %>% 
  save_gph("g2", kind="Sediment")
res_sediment$don %>% 
  save_gph("g2_2", "Sediment")

# Water
vars_water <- read_xlsx("data_water.xlsx", sheet = "vars")
data_water <- read_xlsx(
  "data_water.xlsx",
  sheet = "data",
  skip = 1,
  col_names = vars_water$var_name
)
hi_data_water <- read_xlsx("data_water.xlsx", sheet = "hi_data")


data_water_clean <- data_water %>%
  rowwise() %>%
  mutate(
    ddt = sum(op_ddt, pp_ddt, op_ddd, pp_ddd, op_dde, pp_dde),
    hch = sum(a_hch, b_hch, g_hch, d_hch),
    drn = sum(aldrin, dieldrin),
    hpt = sum(heptachlor, heptachlor_epox)
  ) %>%
  select(Zone, ddt, hch, drn, hpt) %>%
  pivot_longer(!Zone, names_to = "class", values_to = "ocp")

res_water <- result(data_water,
                       data_water_clean,
                       vars_water,
                       as.formula("ocp ~ class + Zone + class:Zone"), 
                    "Water")

wat_tab2 <- data_water %>% 
  rowwise() %>% 
  mutate(
    ocp = sum(op_ddt, pp_ddt, op_ddd, pp_ddd, op_dde, pp_dde,
              a_hch, b_hch, g_hch, d_hch,
              aldrin, dieldrin,
              heptachlor, heptachlor_epox)
  ) %>% 
  group_by(Location, Zone) %>% 
  summarise(
    mean_val = mean(ocp),
    sd_val = sd(ocp),
    min_val = min(ocp),
    max_val = max(ocp)
  ) %>% 
  arrange(desc(Zone), Location) %>% 
  ungroup() %>% 
  mutate(
    `Mean ± SD` = paste(bdl(mean_val), "±",sd_val %>% round(2)),
    Range = paste(bdl(min_val), "-",bdl(max_val) %>% round(2))
  ) %>% 
  select(-c(mean_val, sd_val, min_val, max_val)) %>% 
  flextable::flextable() %>%
  flextable::set_caption(
    paste(
      "Table-2 Water"
    )
  ) %>%
  flextable::autofit()




res_water$tbl
res_water$anova_tbl
res_water$graph_1
res_water$graph_2
wat_tab2

res_water$graph_1 %>% 
  save_gph("g1", kind="Water")
res_water$graph_2 %>% 
  save_gph("g2", kind="Water")
res_water$don %>% 
  save_gph("g2_2", kind="Water")

fish_tab3 <- bind_rows(
  hi_data_fish %>%
    filter(Zone %in% c("Down-stream", "Mid-stream", "Up-stream")) %>%
    group_by(Zone, Type) %>%
    summarise(HI = sum(HI), CR = sum(CR)) %>%
    ungroup(),
  
  hi_data_fish %>%
    filter(Zone %in% c("Catla", "Rui", "Mrigal")) %>%
    group_by(Zone, Type) %>%
    summarise(HI = sum(HI), CR = sum(CR)) %>%
    ungroup(),
  
  hi_data_fish %>%
    filter(Zone %in% c("Overall")) %>%
    group_by(Zone, Type) %>%
    summarise(HI = sum(HI), CR = sum(CR)) %>%
    ungroup()
) %>% 
  mutate(
    HI = HI %>% round(2),
    CR = format(CR, scientific = TRUE, digits=3) %>% toupper(),
  ) %>% 
flextable::flextable() %>%
  flextable::set_caption(
    paste(
      "Table-3 HI Fish"
    )
  ) %>%
  flextable::autofit()





sed_tab3 <- hi_data_sediment %>% 
  mutate(
    HI = format(HI, scientific = TRUE, digits=3) %>% toupper(),
    CR = format(CR, scientific = TRUE, digits=3) %>% toupper(),
  ) %>% 
  flextable::flextable() %>%
  flextable::set_caption(
    paste(
      "Table-3 HI Sediment"
    )
  ) %>%
  flextable::autofit()




wat_tab3 <- hi_data_water %>% 
  mutate(
    HI = format(HI, scientific = TRUE, digits=3) %>% toupper(),
    CR = format(CR, scientific = TRUE, digits=3) %>% toupper(),
  ) %>% 
  flextable::flextable() %>%
  flextable::set_caption(
    paste(
      "Table-3 HI Water"
    )
  ) %>%
  flextable::autofit()



res_fish$tbl
res_fish$anova_tbl
fish_tab3


















































library(purrr)


cor_sed <- data_sediment %>% 
  select(-Zone, -Sample_ID) %>% 
  group_by(Location) %>% 
  nest() %>% 
  mutate(
    data = map(data, \(x) {
      x %>% slice(1:3) %>% t() %>% as.vector()   # row-wise flatten of first 3 samples
    })
  ) %>% 
  unnest(cols = data) %>% 
  mutate(id = row_number()) %>%   # still grouped by Location, so this restarts per location
  ungroup() %>% 
  pivot_wider(id_cols = id, names_from = Location, values_from = data) %>% 
  select(-id) %>% 
  cor() %>% 
  as_tibble() %>% 
  mutate_all(~round(.x,2)) %>% 
  mutate(
    vars = names(.),
    .before = 1
  ) %>% 
  flextable::flextable() %>%
  flextable::set_caption(
    paste(
      "Table-1 Correlation Table Sediment"
    )
  ) %>%
  flextable::autofit()

cor_wat <- data_water %>% 
  select(-Zone, -Sample_ID) %>% 
  group_by(Location) %>% 
  nest() %>% 
  mutate(
    data = map(data, \(x) {
      x %>% slice(1:3) %>% t() %>% as.vector()   # row-wise flatten of first 3 samples
    })
  ) %>% 
  unnest(cols = data) %>% 
  mutate(id = row_number()) %>%   # still grouped by Location, so this restarts per location
  ungroup() %>% 
  pivot_wider(id_cols = id, names_from = Location, values_from = data) %>% 
  select(-id) %>% 
  cor() %>% 
  as_tibble() %>% 
  mutate_all(~round(.x,2)) %>% 
  mutate(
    vars = names(.),
    .before = 1
  ) %>% 
  flextable::flextable() %>%
  flextable::set_caption(
    paste(
      "Table-1 Correlation Table Water"
    )
  ) %>%
  flextable::autofit()



read_docx() %>% 
  body_add_par(value = "SEDIMENT") %>%
  body_add_flextable(value = cor_sed)       %>% body_add_par(value = "") %>%
  body_add_par(value = "WATER") %>%
  body_add_flextable(value = cor_wat)       %>% body_add_par(value = "") %>%
  print(target = "cor.docx")






read_docx() %>% 
  body_add_par(value = "FISH") %>%
  body_add_flextable(value = res_fish$tbl)       %>% body_add_par(value = "") %>%
  body_add_flextable(value = res_fish$anova_tbl) %>% body_add_par(value = "") %>%
  body_add_flextable(value = fish_tab3)          %>% body_add_par(value = "") %>%
  body_add_par(value = "SEDIMENT") %>%
  body_add_flextable(value = res_sediment$tbl)       %>% body_add_par(value = "") %>%
  body_add_flextable(value = res_sediment$anova_tbl) %>% body_add_par(value = "") %>%
  body_add_flextable(value = sed_tab2)          %>% body_add_par(value = "") %>%
  body_add_flextable(value = sed_tab3)          %>% body_add_par(value = "") %>%
  body_add_par(value = "WATER") %>%
  body_add_flextable(value = res_water$tbl)       %>% body_add_par(value = "") %>%
  body_add_flextable(value = res_water$anova_tbl) %>% body_add_par(value = "") %>%
  body_add_flextable(value = wat_tab2)          %>% body_add_par(value = "") %>%
  body_add_flextable(value = wat_tab3)          %>% body_add_par(value = "") %>%
  print(target = "res.docx")




