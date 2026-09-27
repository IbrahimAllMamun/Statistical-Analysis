

graph_builder_fish <- function(data) {
  dodge <- position_dodge(width = 0.8)
  data %>%
    group_by(Zone, Fish) %>%
    summarise(across(op_ddt:heptachlor_epox, \(x) mean(x, na.rm = TRUE)), .groups = "drop") %>%
    mutate(
      mean = rowSums(pick(op_ddt:heptachlor_epox), na.rm = TRUE),
      sd   = apply(pick(op_ddt:heptachlor_epox), 1, sd, na.rm = TRUE),
      Fish = factor(Fish, levels = c("Rui", "Catla", "Mrigal")),
      Zone = factor(Zone, levels = c(
        "Up-stream", "Mid-stream", "Down-stream"
      )),
    ) %>%
    select(Zone, Fish, mean, sd) %>%
    arrange(Zone, Fish) %>%
    ggplot(aes(Zone, mean, fill = Fish)) +
    geom_col(position = dodge,
             width = 0.7,
             colour = "black") +
    geom_errorbar(aes(ymin = pmax(mean - sd, 0), ymax = mean + sd),
                  position = dodge,
                  width = 0.25) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
    labs(x = NULL, y = "Concentration (mean ± SD)", fill = "Fish") +
    theme_classic()
}





graph_builder <- function(data) {
  data %>%
    group_by(Zone, Location) %>%
    summarise(across(op_ddt:heptachlor_epox, \(x) mean(x, na.rm = TRUE)), .groups = "drop") %>%
    mutate(
      mean = rowSums(pick(op_ddt:heptachlor_epox), na.rm = TRUE),
      sd   = apply(pick(op_ddt:heptachlor_epox), 1, sd, na.rm = TRUE),
      Location = factor(
        Location,
        levels = c(
          "Bhujpur Dam",
          "Ekkhuliya",
          "Nazirhat",
          "Sekandar Para",
          "Nichintapur",
          "Nadimpur",
          "West Binajuri",
          "Napiter Ghona",
          "Horekrishno Mohajoner Tek",
          "Chayar Char",
          "Kalurghat"
        )
      ),
      Zone = factor(Zone, levels = c(
        "Up-stream", "Mid-stream", "Down-stream"
      )),
    ) %>%
    select(Zone, Location, mean, sd) %>%
    arrange(Zone, Location) %>%
    ggplot(aes(Location, mean, fill = Zone)) +
    geom_col(width = 0.7, colour = "black") +
    geom_errorbar(aes(ymin = pmax(mean - sd, 0), ymax = mean + sd), width = 0.25) +
    labs(x = NULL, y = "Concentration (mean ± SD)") +
    theme_classic() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
}



graph_builder(data_sediment) %>% 
  save_gph("g3", kind="Sediment")
graph_builder(data_water) %>% 
  save_gph("g3", kind="Water")
graph_builder_fish(data_fish) %>% 
  save_gph("g3", kind="Fish")






compound <- vars_sediment[4:17,]

heat_df_fish <- data_fish %>%
  select(-Sample_ID) %>%
  pivot_longer(-c(Zone, Fish), names_to = "Compound", values_to = "conc") %>%
  group_by(Zone, Fish, Compound) %>%
  summarise(conc = mean(conc, na.rm = TRUE), .groups = "drop") %>%
  left_join(compound, by = c("Compound" = "var_name")) %>%
  mutate(
    Zone     = factor(Zone, levels = c("Up-stream", "Mid-stream", "Down-stream")),
    Fish     = factor(Fish, levels = c("Rui", "Catla", "Mrigal")),
    Compound = factor(ocp, levels = rev(compound$ocp))
  ) %>%
  select(-ocp)






g4 <- ggplot(heat_df_fish, aes(Fish, Compound, fill = conc)) +
  geom_tile(colour = "white", linewidth = 0.5) +
  geom_text(aes(label = ifelse(conc==0.5, "BDL", round(conc,1)),
                colour = conc > max(conc) * 0.6),
            size = 2.8, show.legend = FALSE) +
  scale_colour_manual(values = c(`TRUE` = "white", `FALSE` = "black"))+
  scale_fill_distiller(palette = "Blues", direction = 1, name = "Conc.")+
  facet_grid(cols = vars(Zone), scales = "free_x", space = "free_x", switch = "x") +
  labs(x = NULL, y = NULL) +
  theme_minimal() +
  theme(axis.text.x = element_text(hjust = 1),
        panel.grid = element_blank(),
        strip.placement = "outside",
        strip.text.y.left = element_text(angle = 0, face = "bold"),
        panel.spacing = unit(0.3, "lines")) 


save_gph(g4, "g4", kind="Fish")












location_levels <- c(
  "Bhujpur Dam",
  "Ekkhuliya",
  "Nazirhat",
  "Sekandar Para",
  "Nichintapur",
  "Nadimpur",
  "West Binajuri",
  "Napiter Ghona",
  "Horekrishno Mohajoner Tek",
  "Chayar Char",
  "Kalurghat"
)


heat_df <- data_sediment %>%
  select(-Zone, -Sample_ID) %>%
  pivot_longer(-Location, names_to = "Compound", values_to = "conc") %>%
  group_by(Location, Compound) %>%
  summarise(conc = mean(conc, na.rm = TRUE), .groups = "drop") %>%
  left_join(compound, by=c("Compound"="var_name")) %>% 
  mutate(
    Location = factor(Location, levels = location_levels),
    Compound = factor(ocp, levels = rev(compound$ocp))
  ) %>% 
  select(-ocp)

g4 <- ggplot(heat_df, aes(Location, Compound, fill = conc)) +
  geom_tile(colour = "white", linewidth = 0.5) +
  geom_text(aes(label = ifelse(conc==0.5, "BDL", round(conc,1)),
                colour = conc > max(conc) * 0.6),
            size = 2.8, show.legend = FALSE) +
  scale_colour_manual(values = c(`TRUE` = "white", `FALSE` = "black"))+
  scale_fill_distiller(palette = "Blues", direction = 1, name = "Conc.")+
  labs(x = NULL, y = NULL) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        panel.grid = element_blank()) 
  save_gph(g4, "g4", kind="Sediment")


heat_df <- data_water %>%
  select(-Zone, -Sample_ID) %>%
  pivot_longer(-Location, names_to = "Compound", values_to = "conc") %>%
  group_by(Location, Compound) %>%
  summarise(conc = mean(conc, na.rm = TRUE), .groups = "drop") %>%
  left_join(compound, by=c("Compound"="var_name")) %>% 
  mutate(
    Location = factor(Location, levels = location_levels),
    Compound = factor(ocp, levels = rev(compound$ocp))
  ) %>% 
  select(-ocp)

g4 <- ggplot(heat_df, aes(Location, Compound, fill = conc)) +
  geom_tile(colour = "white", linewidth = 0.5) +
  geom_text(aes(label = ifelse(conc==0.5, "BDL", round(conc,1)),
                colour = conc > max(conc) * 0.6),
            size = 2.8, show.legend = FALSE) +
  scale_colour_manual(values = c(`TRUE` = "white", `FALSE` = "black"))+
  scale_fill_distiller(palette = "Blues", direction = 1, name = "Conc.")+
  labs(x = NULL, y = NULL) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        panel.grid = element_blank())

  save_gph(g4, "g4", kind="Water")












hi_cr_plot <- function(data){
  dodge <- position_dodge(width = 0.8)
  baseline_hi <- 10^floor(log10(min(data$HI, na.rm = TRUE)))
  baseline_cr <- 10^floor(log10(min(data$CR, na.rm = TRUE)))
  
  hi_plot <- data %>%
    mutate(
      x    = as.numeric(Group) + ifelse(Type == "Adult", -0.2, 0.2),
      xmin = x - 0.18,
      xmax = x + 0.18
    ) %>%
    ggplot() +
    geom_rect(aes(xmin = xmin, xmax = xmax, ymin = baseline_hi, ymax = HI, fill = Type),
              colour = "black") +
    geom_text(aes(x = x, y = HI, label = scales::label_scientific(digits = 2)(HI)),
              vjust = -0.5, size = 3) +
    geom_hline(yintercept = 1, linetype = "dotted", colour = "red", linewidth = 0.8) +
    annotate("text", x = Inf, y = 1, label = "HI = 1 threshold",
             hjust = 1.05, vjust = -0.5, colour = "red", size = 3.5) +
    scale_x_continuous(breaks = 1:3, labels = levels(data$Group)) +
    scale_y_log10(
      breaks = 10^(-10:2),
      labels = scales::label_math(10^.x, format = log10),
      expand = expansion(mult = c(0, 0.1))
    ) +
    annotation_logticks(sides = "l") +
    scale_fill_manual(values = c(Adult = "#6baed6", Child = "#08519c")) +
    labs(x = NULL, y = "Hazard Index (HI, log scale)", fill = NULL) +
    theme_classic()
  
  cr_plot <- data %>%
    mutate(
      x    = as.numeric(Group) + ifelse(Type == "Adult", -0.2, 0.2),
      xmin = x - 0.18,
      xmax = x + 0.18
    ) %>%
    ggplot() +
    annotate("rect", xmin = -Inf, xmax = Inf, ymin = 1e-6, ymax = 1e-4,
             fill = "orange", alpha = 0.2) +
    geom_hline(yintercept = c(1e-6, 1e-4), linetype = "dotted", colour = "red", linewidth = 0.6) +
    geom_rect(aes(xmin = xmin, xmax = xmax, ymin = baseline_cr, ymax = CR, fill = Type),
              colour = "black") +
    geom_text(aes(x = x, y = CR, label = scales::label_scientific(digits = 2)(CR)),
              vjust = -0.5, size = 3) +
    annotate("text", x = Inf, y = 1e-6, label = "10^-6 (acceptable)", parse = FALSE,
             hjust = 1.05, vjust = 1.5, colour = "red", size = 3.2) +
    annotate("text", x = Inf, y = 1e-4, label = "10^-4 (unacceptable)",
             hjust = 1.05, vjust = -0.5, colour = "red", size = 3.2) +
    scale_x_continuous(breaks = 1:3, labels = levels(data$Group)) +
    scale_y_log10(
      breaks = 10^(-10:2),
      labels = scales::label_math(10^.x, format = log10),
      expand = expansion(mult = c(0, 0.1))
    ) +
    annotation_logticks(sides = "l") +
    scale_fill_manual(values = c(Adult = "#6baed6", Child = "#08519c")) +
    labs(x = NULL, y = "Cancer Risk (CR, log scale)", fill = NULL) +
    theme_classic()
  
  list(hi_plot, cr_plot)
}


hi_data_sediment_plot <- hi_data_sediment %>%
  filter(Group %in% c("Up-stream", "Mid-stream", "Down-stream")) %>%
  mutate(
    Group   = factor(Group, levels = c("Up-stream", "Mid-stream", "Down-stream")),
    Type    = factor(Type, levels = c("Adult", "Child"))
  ) 

g5 <- hi_cr_plot(hi_data_sediment_plot)

save_gph(g5[[1]], "g5_HI", kind="Sediment")
save_gph(g5[[2]], "g5_CR", kind="Sediment")



hi_data_water_plot <- hi_data_water %>%
  filter(Group %in% c("Up-stream", "Mid-stream", "Down-stream")) %>%
  mutate(
    Group   = factor(Group, levels = c("Up-stream", "Mid-stream", "Down-stream")),
    Type    = factor(Type, levels = c("Adult", "Child"))
  ) 

hi_cr_plot(hi_data_water_plot)

g5 <- hi_cr_plot(hi_data_water_plot)

save_gph(g5[[1]], "g5_HI", kind="Water")
save_gph(g5[[2]], "g5_CR", kind="Water")



g6 <- hi_data_fish %>%
  filter(Zone %in% c("Down-stream", "Mid-stream", "Up-stream")) %>%
  group_by(Zone, Type) %>%
  summarise(HI = sum(HI), CR = sum(CR), .groups = "drop") %>%
  rename(Group = Zone) %>% 
  mutate(
    Group   = factor(Group, levels = c("Up-stream", "Mid-stream", "Down-stream")),
    Type    = factor(Type, levels = c("Adult", "Child"))
  ) %>% 
hi_cr_plot()

save_gph(g6[[1]], "g6_HI", kind="Fish")



g7 <- plot_a <- hi_data_fish %>%
  filter(Zone %in% c("Rui", "Catla", "Mrigal")) %>%
  group_by(Zone, Type) %>%
  summarise(HI = sum(HI), CR = sum(CR), .groups = "drop") %>%
  rename(Group = Zone) %>% 
  mutate(
    Group   = factor(Group, levels = c("Rui", "Catla", "Mrigal")),
    Type    = factor(Type, levels = c("Adult", "Child"))
  ) %>% 
hi_cr_plot()

save_gph(g7[[1]], "g7_HI", kind="Fish")






