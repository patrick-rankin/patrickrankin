library(shiny)
library(bslib)
library(tidyverse)
library(readxl)
library(scales)
library(plotly)
library(DT)

# ── Data ─────────────────────────────────────────────────────────────────────

unc <- read_excel("C:/Users/Pat/Desktop/team_North_Carolina_2026.xlsx") |>
  mutate(
    game_date   = as.Date(game_date),
    team_winner = as.logical(team_winner),
    result      = if_else(team_winner, "Win", "Loss"),
    point_diff  = team_score - opponent_team_score,
    game_label  = paste0(format(game_date, "%b %d"), " vs ", opponent_team_short_display_name)
  ) |>
  arrange(game_date)

unc_blue  <- "#7bafd4"
unc_navy  <- "#13294b"
win_col   <- unc_navy
loss_col  <- "#c0392b"

seasons    <- sort(unique(unc$season))
opponents  <- sort(unique(unc$opponent_team_display_name))

# ── UI ───────────────────────────────────────────────────────────────────────

ui <- page_navbar(
  title = div(
    img(src = "https://a.espncdn.com/i/teamlogos/ncaa/500/153.png",
        height = "30px", style = "margin-right:8px; vertical-align:middle;"),
    "North Carolina Tar Heels — 2025–26 Dashboard"
  ),
  theme = bs_theme(
    bootswatch  = "cosmo",
    primary     = unc_navy,
    secondary   = unc_blue,
    base_font   = font_google("Inter"),
    heading_font = font_google("Syne")
  ),
  bg = unc_navy,
  fg = "#ffffff",

  # ── Tab 1: Season Overview ─────────────────────────────────────────────────
  nav_panel(
    "Season Overview",
    icon = icon("chart-line"),

    layout_sidebar(
      sidebar = sidebar(
        width = 260,
        bg = "#f4f6fa",

        h6("Filters", style = "font-weight:700; color:#13294b; margin-bottom:12px;"),

        selectInput("home_away", "Home / Away",
                    choices = c("All", "home", "away"), selected = "All"),

        selectInput("result_filter", "Result",
                    choices = c("All", "Win", "Loss"), selected = "All"),

        sliderInput("score_range", "Points Scored",
                    min = floor(min(unc$team_score, na.rm = TRUE)),
                    max = ceiling(max(unc$team_score, na.rm = TRUE)),
                    value = c(floor(min(unc$team_score, na.rm = TRUE)),
                              ceiling(max(unc$team_score, na.rm = TRUE))),
                    step = 1),

        hr(),
        h6("Key Stats", style = "font-weight:700; color:#13294b;"),
        uiOutput("kpi_cards")
      ),

      # Main panel
      fluidRow(
        column(12,
          card(
            card_header("Points Scored Per Game", class = "bg-primary text-white"),
            plotlyOutput("bar_scoring", height = "320px")
          )
        )
      ),
      fluidRow(
        column(6,
          card(
            card_header("FG% vs Points Scored", class = "bg-primary text-white"),
            plotlyOutput("scatter_fg", height = "300px")
          )
        ),
        column(6,
          card(
            card_header("Point Differential Per Game", class = "bg-primary text-white"),
            plotlyOutput("bar_diff", height = "300px")
          )
        )
      )
    )
  ),

  # ── Tab 2: Shooting ────────────────────────────────────────────────────────
  nav_panel(
    "Shooting",
    icon = icon("bullseye"),

    layout_columns(
      col_widths = c(6, 6, 12),

      card(
        card_header("Shooting Splits by Game", class = "bg-primary text-white"),
        plotlyOutput("line_shooting", height = "320px")
      ),
      card(
        card_header("3PT vs 2PT Made", class = "bg-primary text-white"),
        plotlyOutput("scatter_3pt", height = "320px")
      ),
      card(
        card_header("Free Throw Performance", class = "bg-primary text-white"),
        plotlyOutput("bar_ft", height = "300px")
      )
    )
  ),

  # ── Tab 3: Defense & Hustle ────────────────────────────────────────────────
  nav_panel(
    "Defense & Hustle",
    icon = icon("shield"),

    layout_columns(
      col_widths = c(6, 6, 12),

      card(
        card_header("Assists vs Turnovers", class = "bg-primary text-white"),
        plotlyOutput("bar_ast_tov", height = "320px")
      ),
      card(
        card_header("Rebounds (Off vs Def)", class = "bg-primary text-white"),
        plotlyOutput("bar_rebounds", height = "320px")
      ),
      card(
        card_header("Steals & Blocks Per Game", class = "bg-primary text-white"),
        plotlyOutput("line_steals_blocks", height = "300px")
      )
    )
  ),

  # ── Tab 4: Game Log ────────────────────────────────────────────────────────
  nav_panel(
    "Game Log",
    icon = icon("table"),

    card(
      card_header("Full Season Game Log", class = "bg-primary text-white"),
      DTOutput("game_log_table")
    )
  )
)

# ── Server ───────────────────────────────────────────────────────────────────

server <- function(input, output, session) {

  # Reactive filtered data
  filtered <- reactive({
    df <- unc
    if (input$home_away != "All") df <- filter(df, team_home_away == input$home_away)
    if (input$result_filter != "All") df <- filter(df, result == input$result_filter)
    df <- filter(df, team_score >= input$score_range[1], team_score <= input$score_range[2])
    df
  })

  # ── KPI Cards ─────────────────────────────────────────────────────────────
  output$kpi_cards <- renderUI({
    df   <- filtered()
    wins <- sum(df$team_winner, na.rm = TRUE)
    loss <- sum(!df$team_winner, na.rm = TRUE)

    tagList(
      div(style = "background:#13294b; color:#fff; border-radius:8px; padding:10px 14px; margin-bottom:8px;",
          div(style = "font-size:0.75rem; opacity:0.8;", "Record"),
          div(style = "font-size:1.4rem; font-weight:700;", paste0(wins, " – ", loss))
      ),
      div(style = "background:#7bafd4; color:#fff; border-radius:8px; padding:10px 14px; margin-bottom:8px;",
          div(style = "font-size:0.75rem; opacity:0.9;", "Avg Points"),
          div(style = "font-size:1.4rem; font-weight:700;",
              round(mean(df$team_score, na.rm = TRUE), 1))
      ),
      div(style = "background:#f4f6fa; color:#13294b; border-radius:8px; padding:10px 14px; margin-bottom:8px;
                  border:1px solid #e2e8f0;",
          div(style = "font-size:0.75rem; color:#6b7280;", "Avg FG%"),
          div(style = "font-size:1.4rem; font-weight:700;",
              paste0(round(mean(df$field_goal_pct, na.rm = TRUE), 1), "%"))
      ),
      div(style = "background:#f4f6fa; color:#13294b; border-radius:8px; padding:10px 14px;
                  border:1px solid #e2e8f0;",
          div(style = "font-size:0.75rem; color:#6b7280;", "Avg Rebounds"),
          div(style = "font-size:1.4rem; font-weight:700;",
              round(mean(df$total_rebounds, na.rm = TRUE), 1))
      )
    )
  })

  # ── Tab 1 Plots ────────────────────────────────────────────────────────────

  output$bar_scoring <- renderPlotly({
    df <- filtered() |> mutate(game_label = fct_inorder(game_label))
    p <- ggplot(df, aes(x = game_label, y = team_score, fill = result,
                        text = paste0(game_label, "<br>Score: ", team_score,
                                      "<br>Opp: ", opponent_team_score,
                                      "<br>Result: ", result))) +
      geom_col(width = 0.72) +
      geom_hline(yintercept = mean(df$team_score, na.rm = TRUE),
                 linetype = "dashed", color = "gray40", linewidth = 0.6) +
      scale_fill_manual(values = c("Win" = win_col, "Loss" = loss_col)) +
      scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
      labs(x = NULL, y = "Points", fill = NULL) +
      theme_minimal(base_size = 11) +
      theme(axis.text.x = element_text(angle = 50, hjust = 1, size = 7.5),
            legend.position = "top", panel.grid.major.x = element_blank(),
            panel.grid.minor = element_blank())
    ggplotly(p, tooltip = "text") |> layout(legend = list(orientation = "h"))
  })

  output$scatter_fg <- renderPlotly({
    df <- filtered()
    p <- ggplot(df, aes(x = field_goal_pct, y = team_score, color = result,
                        text = paste0(game_label, "<br>FG%: ", field_goal_pct,
                                      "%<br>Points: ", team_score))) +
      geom_vline(xintercept = 50, linetype = "dashed", color = "gray60") +
      geom_point(size = 3, alpha = 0.85) +
      geom_smooth(aes(group = 1), method = "lm", se = TRUE,
                  color = "gray30", fill = "gray85", linewidth = 0.7) +
      scale_color_manual(values = c("Win" = win_col, "Loss" = loss_col)) +
      scale_x_continuous(labels = function(x) paste0(x, "%")) +
      labs(x = "Field Goal %", y = "Points Scored", color = NULL) +
      theme_minimal(base_size = 11) +
      theme(legend.position = "top", panel.grid.minor = element_blank())
    ggplotly(p, tooltip = "text") |> layout(legend = list(orientation = "h"))
  })

  output$bar_diff <- renderPlotly({
    df <- filtered() |> mutate(game_label = fct_inorder(game_label))
    p <- ggplot(df, aes(x = game_label, y = point_diff, fill = result,
                        text = paste0(game_label, "<br>Diff: ", point_diff))) +
      geom_col(width = 0.72) +
      geom_hline(yintercept = 0, color = "gray30", linewidth = 0.5) +
      scale_fill_manual(values = c("Win" = win_col, "Loss" = loss_col)) +
      labs(x = NULL, y = "Point Differential", fill = NULL) +
      theme_minimal(base_size = 11) +
      theme(axis.text.x = element_text(angle = 50, hjust = 1, size = 7.5),
            legend.position = "top", panel.grid.major.x = element_blank(),
            panel.grid.minor = element_blank())
    ggplotly(p, tooltip = "text") |> layout(legend = list(orientation = "h"))
  })

  # ── Tab 2 Plots ────────────────────────────────────────────────────────────

  output$line_shooting <- renderPlotly({
    df <- filtered() |>
      select(game_date, game_label, field_goal_pct, three_point_field_goal_pct, free_throw_pct) |>
      pivot_longer(-c(game_date, game_label), names_to = "stat", values_to = "pct") |>
      mutate(stat = recode(stat,
        "field_goal_pct" = "FG%",
        "three_point_field_goal_pct" = "3PT%",
        "free_throw_pct" = "FT%"),
        game_label = fct_reorder(game_label, game_date))

    p <- ggplot(df, aes(x = game_label, y = pct, color = stat, group = stat,
                        text = paste0(game_label, "<br>", stat, ": ", pct, "%"))) +
      geom_line(linewidth = 1) +
      geom_point(size = 2.5) +
      scale_color_manual(values = c("FG%" = unc_navy, "3PT%" = unc_blue, "FT%" = "#e8a020")) +
      scale_y_continuous(labels = function(x) paste0(x, "%")) +
      labs(x = NULL, y = "Percentage", color = NULL) +
      theme_minimal(base_size = 11) +
      theme(axis.text.x = element_text(angle = 50, hjust = 1, size = 7.5),
            legend.position = "top", panel.grid.minor = element_blank())
    ggplotly(p, tooltip = "text") |> layout(legend = list(orientation = "h"))
  })

  output$scatter_3pt <- renderPlotly({
    df <- filtered() |>
      mutate(two_pt_made = field_goals_made - three_point_field_goals_made)
    p <- ggplot(df, aes(x = two_pt_made, y = three_point_field_goals_made,
                        color = result, size = team_score,
                        text = paste0(game_label, "<br>2PM: ", two_pt_made,
                                      "<br>3PM: ", three_point_field_goals_made,
                                      "<br>Points: ", team_score))) +
      geom_point(alpha = 0.8) +
      scale_color_manual(values = c("Win" = win_col, "Loss" = loss_col)) +
      scale_size_continuous(range = c(3, 10), guide = "none") +
      labs(x = "2-Point FG Made", y = "3-Point FG Made", color = NULL) +
      theme_minimal(base_size = 11) +
      theme(legend.position = "top", panel.grid.minor = element_blank())
    ggplotly(p, tooltip = "text") |> layout(legend = list(orientation = "h"))
  })

  output$bar_ft <- renderPlotly({
    df <- filtered() |> mutate(game_label = fct_inorder(game_label))
    p <- ggplot(df, aes(x = game_label, y = free_throw_pct, fill = result,
                        text = paste0(game_label, "<br>FT%: ", free_throw_pct,
                                      "%<br>Made: ", free_throws_made,
                                      "/", free_throws_attempted))) +
      geom_col(width = 0.72) +
      geom_hline(yintercept = mean(df$free_throw_pct, na.rm = TRUE),
                 linetype = "dashed", color = "gray40") +
      scale_fill_manual(values = c("Win" = win_col, "Loss" = loss_col)) +
      scale_y_continuous(labels = function(x) paste0(x, "%"),
                         expand = expansion(mult = c(0, 0.05))) +
      labs(x = NULL, y = "Free Throw %", fill = NULL) +
      theme_minimal(base_size = 11) +
      theme(axis.text.x = element_text(angle = 50, hjust = 1, size = 7.5),
            legend.position = "top", panel.grid.major.x = element_blank(),
            panel.grid.minor = element_blank())
    ggplotly(p, tooltip = "text") |> layout(legend = list(orientation = "h"))
  })

  # ── Tab 3 Plots ────────────────────────────────────────────────────────────

  output$bar_ast_tov <- renderPlotly({
    df <- filtered() |>
      select(game_date, game_label, assists, turnovers) |>
      pivot_longer(-c(game_date, game_label), names_to = "stat", values_to = "n") |>
      mutate(game_label = fct_reorder(game_label, game_date), stat = str_to_title(stat))

    p <- ggplot(df, aes(x = game_label, y = n, fill = stat,
                        text = paste0(game_label, "<br>", stat, ": ", n))) +
      geom_col(position = "dodge", width = 0.7) +
      scale_fill_manual(values = c("Assists" = unc_navy, "Turnovers" = "#e8a020")) +
      scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
      labs(x = NULL, y = "Count", fill = NULL) +
      theme_minimal(base_size = 11) +
      theme(axis.text.x = element_text(angle = 50, hjust = 1, size = 7.5),
            legend.position = "top", panel.grid.major.x = element_blank(),
            panel.grid.minor = element_blank())
    ggplotly(p, tooltip = "text") |> layout(legend = list(orientation = "h"))
  })

  output$bar_rebounds <- renderPlotly({
    df <- filtered() |>
      select(game_date, game_label, offensive_rebounds, defensive_rebounds) |>
      pivot_longer(-c(game_date, game_label), names_to = "stat", values_to = "n") |>
      mutate(game_label = fct_reorder(game_label, game_date),
             stat = recode(stat, "offensive_rebounds" = "Offensive",
                           "defensive_rebounds" = "Defensive"))

    p <- ggplot(df, aes(x = game_label, y = n, fill = stat,
                        text = paste0(game_label, "<br>", stat, ": ", n))) +
      geom_col(width = 0.72) +
      scale_fill_manual(values = c("Offensive" = unc_blue, "Defensive" = unc_navy)) +
      scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
      labs(x = NULL, y = "Rebounds", fill = NULL) +
      theme_minimal(base_size = 11) +
      theme(axis.text.x = element_text(angle = 50, hjust = 1, size = 7.5),
            legend.position = "top", panel.grid.major.x = element_blank(),
            panel.grid.minor = element_blank())
    ggplotly(p, tooltip = "text") |> layout(legend = list(orientation = "h"))
  })

  output$line_steals_blocks <- renderPlotly({
    df <- filtered() |>
      select(game_date, game_label, steals, blocks) |>
      pivot_longer(-c(game_date, game_label), names_to = "stat", values_to = "n") |>
      mutate(game_label = fct_reorder(game_label, game_date), stat = str_to_title(stat))

    p <- ggplot(df, aes(x = game_label, y = n, color = stat, group = stat,
                        text = paste0(game_label, "<br>", stat, ": ", n))) +
      geom_line(linewidth = 1) +
      geom_point(size = 2.5) +
      scale_color_manual(values = c("Steals" = unc_navy, "Blocks" = unc_blue)) +
      labs(x = NULL, y = "Count", color = NULL) +
      theme_minimal(base_size = 11) +
      theme(axis.text.x = element_text(angle = 50, hjust = 1, size = 7.5),
            legend.position = "top", panel.grid.minor = element_blank())
    ggplotly(p, tooltip = "text") |> layout(legend = list(orientation = "h"))
  })

  # ── Tab 4: Game Log Table ──────────────────────────────────────────────────

  output$game_log_table <- renderDT({
    unc |>
      select(
        Date       = game_date,
        Opponent   = opponent_team_display_name,
        `H/A`      = team_home_away,
        `UNC Pts`  = team_score,
        `Opp Pts`  = opponent_team_score,
        `+/-`      = point_diff,
        Result     = result,
        `FG%`      = field_goal_pct,
        `3PT%`     = three_point_field_goal_pct,
        `FT%`      = free_throw_pct,
        AST        = assists,
        TOV        = turnovers,
        REB        = total_rebounds,
        STL        = steals,
        BLK        = blocks
      ) |>
      datatable(
        options = list(
          pageLength = 15,
          scrollX    = TRUE,
          dom        = "Bfrtip",
          buttons    = c("copy", "csv", "excel")
        ),
        rownames  = FALSE,
        class     = "stripe hover compact",
        extension = "Buttons"
      ) |>
      formatStyle("Result",
        backgroundColor = styleEqual(c("Win","Loss"), c("#d4edda","#f8d7da")),
        fontWeight = "bold"
      ) |>
      formatStyle("+/-",
        color = styleInterval(0, c("#c0392b", "#13294b")),
        fontWeight = "bold"
      ) |>
      formatStyle(c("FG%","3PT%","FT%"),
        background = styleColorBar(c(0,100), "#7bafd4"),
        backgroundSize = "98% 60%",
        backgroundRepeat = "no-repeat",
        backgroundPosition = "center"
      )
  })
}

shinyApp(ui, server)
