###############################################################################
# NHL — TEAM DATA INGESTION SCRIPT
# Purpose: Pull ONE team's season game-by-game results from hockeyR
# play-by-play data and save it as a CSV. This file does NOT include
# individual player stats — only team-level totals, one row per game. Use
# 02_ingest_nhl_player.R for player-level stats.
###############################################################################

# -----------------------------------------------------------------------------
# STEP 1: INSTALL PACKAGES (only run this section the FIRST time)
# -----------------------------------------------------------------------------
# Remove the # in front of each line below and run it once. After that, you
# can leave these lines commented out (with the # in front) since the
# packages will already be installed on your computer.

# install.packages("pak")
# pak::pak("sportsdataverse/hockeyR")
# install.packages("dplyr")
# install.packages("readr")


# -----------------------------------------------------------------------------
# STEP 2: LOAD PACKAGES (run this every time you use the script)
# -----------------------------------------------------------------------------
install.packages("hockeyR")

library(hockeyR)
library(dplyr)
library(readr)


###############################################################################
# STEP 3: VARIABLES YOU CAN CHANGE
# This is the only section you need to touch for a new team/season pull.
###############################################################################

# Which team do you want? Use the 3-letter team abbreviation ESPN / NHL use.
# Examples: "BOS", "NYR", "TOR", "EDM", "COL", "VGK", "TBL"
# IMPORTANT: capitalization and spelling need to match how hockeyR lists
# the team. If you're not sure, run the NAME CHECK code near the bottom of
# this script first, and it will print all the team abbreviations
# available so you can copy/paste the exact one you want.
my_team <- "BOS"

# Which season? Use the year the season STARTS.
# Example: the 2024-25 season is written as 2024.
season_year <- 2024

# <<< PUT YOUR FOLDER NAME HERE >>>
# This is the folder where the CSV file will be saved.
# It will be created automatically if it doesn't already exist.
# Use a FULL path with forward slashes, e.g. "C:/Users/you/Documents/nhl_data"
output_folder <- "C:/Users/Pat/Desktop/website/hockey_scripts/team_data"


###############################################################################
# STEP 4: CREATE THE OUTPUT FOLDER (if it doesn't already exist)
###############################################################################

if (!dir.exists(output_folder)) {
  dir.create(output_folder, recursive = TRUE)
}


###############################################################################
# STEP 5: PULL THE FULL SEASON OF PLAY-BY-PLAY AND AGGREGATE TO TEAM GAMES
# -----------------------------------------------------------------------------
# hockeyR downloads the whole season's play-by-play at once (there's no way
# to ask it for just one team upfront). We aggregate it to one row per game
# and filter down to your team right after. This is a big file — the first
# run for a new season can take a couple of minutes.
###############################################################################

pbp <- hockeyR::load_pbp(seasons = season_year)

game_scores <- pbp %>%
  group_by(game_id, home_abbreviation, away_abbreviation) %>%
  summarise(
    home_goals    = max(home_final, na.rm = TRUE),
    away_goals    = max(away_final, na.rm = TRUE),
    home_shots    = sum(event_type %in% c("SHOT", "GOAL") & team == home_abbreviation, na.rm = TRUE),
    away_shots    = sum(event_type %in% c("SHOT", "GOAL") & team == away_abbreviation, na.rm = TRUE),
    home_pp_goals = sum(event_type == "GOAL" & team == home_abbreviation &
                           strength_code %in% c("PP", "PP2"), na.rm = TRUE),
    away_pp_goals = sum(event_type == "GOAL" & team == away_abbreviation &
                           strength_code %in% c("PP", "PP2"), na.rm = TRUE),
    home_pp_opps  = sum(event_type == "PENALTY" & team == away_abbreviation, na.rm = TRUE),
    away_pp_opps  = sum(event_type == "PENALTY" & team == home_abbreviation, na.rm = TRUE),
    .groups = "drop"
  )


# -----------------------------------------------------------------------------
# OPTIONAL: NAME CHECK
# If you're not sure how your team's abbreviation is spelled in this data,
# remove the # from the line below and run it. It will print a list of
# every team abbreviation available, so you can copy the exact spelling
# into my_team above.
# -----------------------------------------------------------------------------

# hockeyR::team_logos_colors %>% select(team_abbr, full_team_name) %>% print(n = 40)


###############################################################################
# STEP 6: FILTER DOWN TO YOUR TEAM (combine home + away games)
###############################################################################

home_games <- game_scores %>%
  filter(home_abbreviation == my_team) %>%
  transmute(
    game_id,
    team_goals       = home_goals,
    opp_goals        = away_goals,
    team_shots       = home_shots,
    opp_shots        = away_shots,
    pp_goals         = home_pp_goals,
    pp_opps          = home_pp_opps,
    pk_goals_against = away_pp_goals,
    pk_opps          = away_pp_opps,
    won              = home_goals > away_goals,
    home_away        = "Home"
  )

away_games <- game_scores %>%
  filter(away_abbreviation == my_team) %>%
  transmute(
    game_id,
    team_goals       = away_goals,
    opp_goals        = home_goals,
    team_shots       = away_shots,
    opp_shots        = home_shots,
    pp_goals         = away_pp_goals,
    pp_opps          = away_pp_opps,
    pk_goals_against = home_pp_goals,
    pk_opps          = home_pp_opps,
    won              = away_goals > home_goals,
    home_away        = "Away"
  )

team_games <- bind_rows(home_games, away_games)

# Safety check: if nothing matched, stop here with a clear message instead
# of saving an empty file.
if (nrow(team_games) == 0) {
  stop("No games found for '", my_team, "'. Run the NAME CHECK code above ",
       "to see the exact abbreviation hockeyR uses for your team, then ",
       "update my_team to match.")
}


###############################################################################
# STEP 7: SAVE THE DATA AS A CSV FILE
# Filename automatically includes the team and season, e.g.
# nhl_team_BOS_2024.csv
###############################################################################

team_name_clean <- gsub(" ", "_", my_team)
team_filename <- file.path(output_folder, paste0("nhl_team_", team_name_clean, "_", season_year, ".csv"))

write_csv(team_games, team_filename)

cat("Saved:", team_filename, "\n")
cat("Games found:", nrow(team_games), "\n")


###############################################################################
# DONE
# You now have one CSV file with this team's full season, game-by-game
# results (goals, shots, power play/penalty kill opportunities, no
# individual player breakdown).
#
# You (or your client) can open this directly in Excel to look around.
#
# The grade_nhl_team.qmd report can read this CSV as a starting point.
###############################################################################
