library(readxl)
library(dplyr)
library(ggplot2)
library(ggimage)

winners <- read_excel("champions_of_different_leagues.xlsx", sheet = "winners")
logos <- read_excel("champions_of_different_leagues.xlsx", sheet = "logos")
league_logos <- read_excel("champions_of_different_leagues.xlsx", sheet = "league_logos")

# Merge data
winners <- winners %>%
  left_join(logos, by = c("League", "Winner")) %>%
  rename(WinnerLogo = Logo) %>%
  left_join(league_logos, by = "League") %>%
  rename(LeagueLogo = Logo) %>%
  mutate(
    WinnerLogo = file.path("images", WinnerLogo),
    LeagueLogo = file.path("images", LeagueLogo)
  )

# --- decrease size of Juventus and Milan logos as they are larger ---
# --- increase size of AGF logo as that's the main motivation to create this visualization ---
winners <- winners %>%
  mutate(LogoSize = case_when(
    Winner == "Juventus" ~ 0.01,
    Winner == "Milan"    ~ 0.01,
    Winner == 'AGF'      ~ 0.02,
    TRUE                 ~ 0.015  
  ))

league_order <- c("Turkish Super Lig", "Danish Superliga", "Premier League",
                  "Bundesliga", "La Liga", "Ligue 1", 'Serie A') 

winners <- winners %>% 
  mutate(League = factor(League, levels = league_order))

# Y-axis explicit ordering (League on top)
chronological_seasons <- unique(winners$Season)
y_axis_order <- c(rev(chronological_seasons), "League")

winners <- winners %>% mutate(Season = as.character(Season))

league_logo_df <- winners %>%
  distinct(League, LeagueLogo) %>%
  mutate(Season = "League")

# --- THE TUNED PLOT ---
p <- ggplot(winners, aes(x = League, y = Season)) +
  # League logos layer
  geom_image(
    data = league_logo_df,
    aes(image = LeagueLogo),
    size = 0.02,            
    by = "width"
  ) +
  # Winner logos layer
  geom_image(
    aes(image = WinnerLogo, size = LogoSize),
    by = "width"
  ) +
  
  scale_size_identity() + 
  scale_y_discrete(limits = y_axis_order) + 
  scale_x_discrete(expand = expansion(mult = c(0.15, 0.15))) +
  
  labs(x = NULL, y = "Season") +
  theme_minimal() +
  theme(
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    panel.grid.major = element_blank(), 
    panel.grid.minor = element_blank()
  )

# Save the final square canvas
ggsave("images/champions_of_different_leagues.png", plot = p, width = 12, height = 12, dpi = 300, bg = "white")