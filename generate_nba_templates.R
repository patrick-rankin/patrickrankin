# Run this script once to generate all 30 NBA team QMD templates.
# After adding a team's CSV to nba_data/, update the csv_path in that team's QMD.

library(tidyverse)

nba_teams <- tribble(
  ~team_name,                  ~slug,                      ~primary,   ~secondary, ~abbr,
  "Atlanta Hawks",             "atlanta-hawks",             "#C1D32F",  "#E03A3E",  "ATL",
  "Boston Celtics",            "boston-celtics",            "#007A33",  "#BA9653",  "BOS",
  "Brooklyn Nets",             "brooklyn-nets",             "#000000",  "#FFFFFF",  "BKN",
  "Charlotte Hornets",         "charlotte-hornets",         "#1D1160",  "#00788C",  "CHA",
  "Chicago Bulls",             "chicago-bulls",             "#CE1141",  "#000000",  "CHI",
  "Cleveland Cavaliers",       "cleveland-cavaliers",       "#860038",  "#FDBB30",  "CLE",
  "Dallas Mavericks",          "dallas-mavericks",          "#0053BC",  "#00285E",  "DAL",
  "Denver Nuggets",            "denver-nuggets",            "#0E2240",  "#FEC524",  "DEN",
  "Detroit Pistons",           "detroit-pistons",           "#C8102E",  "#1D42BA",  "DET",
  "Golden State Warriors",     "golden-state-warriors",     "#1D428A",  "#FFC72C",  "GSW",
  "Houston Rockets",           "houston-rockets",           "#CE1141",  "#000000",  "HOU",
  "Indiana Pacers",            "indiana-pacers",            "#002D62",  "#FDBB30",  "IND",
  "LA Clippers",               "la-clippers",               "#C8102E",  "#1D428A",  "LAC",
  "Los Angeles Lakers",        "los-angeles-lakers",        "#552583",  "#FDB927",  "LAL",
  "Memphis Grizzlies",         "memphis-grizzlies",         "#5D76A9",  "#12173F",  "MEM",
  "Miami Heat",                "miami-heat",                "#98002E",  "#F9A01B",  "MIA",
  "Milwaukee Bucks",           "milwaukee-bucks",           "#00471B",  "#EEE1C6",  "MIL",
  "Minnesota Timberwolves",    "minnesota-timberwolves",    "#0C2340",  "#236192",  "MIN",
  "New Orleans Pelicans",      "new-orleans-pelicans",      "#0C2340",  "#C8102E",  "NOP",
  "New York Knicks",           "new-york-knicks",           "#006BB6",  "#F58426",  "NYK",
  "Oklahoma City Thunder",     "oklahoma-city-thunder",     "#007AC1",  "#EF3B24",  "OKC",
  "Orlando Magic",             "orlando-magic",             "#0077C0",  "#C4CED4",  "ORL",
  "Philadelphia 76ers",        "philadelphia-76ers",        "#006BB6",  "#ED174C",  "PHI",
  "Phoenix Suns",              "phoenix-suns",              "#1D1160",  "#E56020",  "PHX",
  "Portland Trail Blazers",    "portland-trail-blazers",    "#E03A3E",  "#000000",  "POR",
  "Sacramento Kings",          "sacramento-kings",          "#5A2D81",  "#63727A",  "SAC",
  "San Antonio Spurs",         "san-antonio-spurs",         "#C4CED4",  "#000000",  "SAS",
  "Toronto Raptors",           "toronto-raptors",           "#CE1141",  "#000000",  "TOR",
  "Utah Jazz",                 "utah-jazz",                 "#002B5C",  "#00471B",  "UTA",
  "Washington Wizards",        "washington-wizards",        "#002B5C",  "#E31837",  "WAS"
)

generate_qmd <- function(team_name, slug, primary, secondary, abbr) {

  # Derive CSV path convention (user fills real path when data is ready)
  csv_path <- glue::glue(
    "C:/Users/Pat/Desktop/basketball_script/nba_data/team_stats/team_{abbr}_2026.csv"
  )

  glue::glue('---
title: "{team_name}"
subtitle: "2025\\u201326 NBA Season Team Statistics"
date: today
format:
  html:
    toc: true
    toc-title: "On This Page"
    code-fold: true
    code-summary: "Show Code"
---

```{{r setup, include=FALSE}}
library(tidyverse)
library(scales)

# ── Update this path when the CSV is available ──────────────────────────────
# team <- read_csv("{csv_path}", show_col_types = FALSE) |>
#   mutate(
#     game_date   = as.Date(game_date, "%m/%d/%Y"),
#     team_winner = as.logical(team_winner),
#     result      = if_else(team_winner, "Win", "Loss"),
#     point_diff  = team_score - opponent_team_score,
#     game_label  = paste0(format(game_date, "%b %d"), " vs ", opponent_team_short_display_name)
#   ) |>
#   arrange(game_date)

team_primary   <- "{primary}"
team_secondary <- "{secondary}"
win_color      <- team_primary
loss_color     <- "#c0392b"
```

## Season Overview

The **{team_name}** had an eventful 2025\\u201326 NBA season. Below is a data-driven breakdown of their performance across key statistical categories.

::: {{.callout-note appearance="minimal"}}
**Record:** — | **Avg Points:** — PPG | **FG%:** —% | **Rebounds:** — RPG | **Assists:** — APG
:::

> Add narrative context about the team\\u2019s season here once data is loaded.

---

## Shooting Efficiency vs. Points Scored {{#shooting}}

The scatterplot below examines the relationship between field goal percentage and points scored each game, colored by win or loss.

```{{r scatterplot, fig.width=9, fig.height=5.5}}
# Uncomment after loading data:
# ggplot(team, aes(x = field_goal_pct, y = team_score, color = result)) +
#   geom_vline(xintercept = 50, linetype = "dashed", color = "gray60", linewidth = 0.6) +
#   geom_point(size = 3.5, alpha = 0.85) +
#   geom_smooth(aes(group = 1), method = "lm", se = TRUE,
#               color = "gray30", fill = "gray85", linewidth = 0.8) +
#   scale_color_manual(values = c("Win" = win_color, "Loss" = loss_color)) +
#   scale_x_continuous(labels = function(x) paste0(x, "%")) +
#   labs(
#     title    = "Field Goal % vs. Points Scored",
#     subtitle = "{team_name} | 2025\\u201326 NBA Season",
#     x = "Field Goal Percentage", y = "Points Scored", color = "Result",
#     caption = "Dashed line at 50% FG | Trend line across all games"
#   ) +
#   theme_minimal(base_size = 13) +
#   theme(plot.title = element_text(face = "bold", color = team_primary),
#         plot.subtitle = element_text(color = "gray40"),
#         legend.position = "top", panel.grid.minor = element_blank())

message("Data not yet loaded — uncomment the plot code above after adding the CSV.")
```

> **Insight:** Add shooting efficiency insights here after reviewing the data.

---

## Points Scored Per Game {{#scoring}}

A game-by-game look at scoring output across the season, colored by result.

```{{r scoring-chart, fig.width=10, fig.height=5.5}}
# Uncomment after loading data:
# team |>
#   mutate(game_label = fct_inorder(game_label)) |>
#   ggplot(aes(x = game_label, y = team_score, fill = result)) +
#   geom_col(width = 0.75) +
#   geom_hline(yintercept = mean(team$team_score), linetype = "dashed",
#              color = "gray30", linewidth = 0.7) +
#   scale_fill_manual(values = c("Win" = win_color, "Loss" = loss_color)) +
#   scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
#   labs(
#     title    = "Points Scored Per Game",
#     subtitle = "{team_name} | 2025\\u201326 NBA Season",
#     x = NULL, y = "Points Scored", fill = "Result",
#     caption = "Dashed line = season average"
#   ) +
#   theme_minimal(base_size = 12) +
#   theme(plot.title = element_text(face = "bold", color = team_primary),
#         plot.subtitle = element_text(color = "gray40"),
#         axis.text.x = element_text(angle = 55, hjust = 1, size = 8),
#         legend.position = "top",
#         panel.grid.major.x = element_blank(), panel.grid.minor = element_blank())

message("Data not yet loaded — uncomment the plot code above after adding the CSV.")
```

> **Insight:** Add scoring trend insights here after reviewing the data.

---

## Assists vs. Turnovers {{#ball-movement}}

Comparing ball movement and ball security on a game-by-game basis.

```{{r ast-tov-chart, fig.width=10, fig.height=5.5}}
# Uncomment after loading data:
# team |>
#   select(game_label, game_date, assists, turnovers, result) |>
#   pivot_longer(cols = c(assists, turnovers), names_to = "stat", values_to = "value") |>
#   mutate(game_label = fct_reorder(game_label, game_date), stat = str_to_title(stat)) |>
#   ggplot(aes(x = game_label, y = value, fill = stat)) +
#   geom_col(position = "dodge", width = 0.7) +
#   scale_fill_manual(values = c("Assists" = team_primary, "Turnovers" = team_secondary)) +
#   scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
#   labs(
#     title    = "Assists vs. Turnovers Per Game",
#     subtitle = "{team_name} | 2025\\u201326 NBA Season",
#     x = NULL, y = "Count", fill = NULL,
#     caption = "Games in chronological order"
#   ) +
#   theme_minimal(base_size = 12) +
#   theme(plot.title = element_text(face = "bold", color = team_primary),
#         plot.subtitle = element_text(color = "gray40"),
#         axis.text.x = element_text(angle = 55, hjust = 1, size = 8),
#         legend.position = "top",
#         panel.grid.major.x = element_blank(), panel.grid.minor = element_blank())

message("Data not yet loaded — uncomment the plot code above after adding the CSV.")
```

> **Insight:** Add ball movement insights here after reviewing the data.

---

## Key Takeaways

Add your season summary and key statistical takeaways here once the data is loaded and the visuals are reviewed.
', .trim = FALSE)
}

# Generate one QMD file per team, each in its own folder: nba/<slug>/index.qmd
walk(seq_len(nrow(nba_teams)), function(i) {
  row      <- nba_teams[i, ]
  content  <- generate_qmd(row$team_name, row$slug, row$primary, row$secondary, row$abbr)
  team_dir <- file.path("C:/Users/Pat/Desktop/mywebsite1", "nba", row$slug)
  dir.create(team_dir, recursive = TRUE, showWarnings = FALSE)
  writeLines(content, file.path(team_dir, "index.qmd"))
  cat("Created:", file.path("nba", row$slug, "index.qmd"), "\n")
})

cat("\nAll 30 NBA team templates generated.\n")
cat("Next steps:\n")
cat("  1. Add each team's CSV to nba_data/team_stats/\n")
cat("  2. Uncomment the data loading and plot code in each QMD\n")
cat("  3. Run quarto render and push to GitHub\n")
