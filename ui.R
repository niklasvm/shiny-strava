message('ui.R sourced')
source('global.R')


shinyUI(
  fluidPage(
    # show authentication panel
    
    uiOutput('authentication_panel'),
    column(4,
           shiny::textInput('strava_app_client_id', "Enter strava_app_client_id"), tags$hr()
    ),
    column(4,
           shiny::textInput('strava_app_secret', "Enter strava_app_secret"), tags$hr()
    ),
    column(4,
           shiny::textInput('strava_app_url', "Enter strava_app_url"), tags$hr()
    ),
    titlePanel('Shiny Strava'),
    textOutput('welcome_line'),
    sidebarLayout(
      sidebarPanel(
        shiny::dateRangeInput(inputId = 'selected_dates',
                              label = 'Select date range'
                              #start = '2018-01-01',
                              #end = '2018-07-31'
        ),
        shiny::checkboxGroupInput(
          inputId = 'selected_types',
          label='Select types'
          #choices=c("Hike", "Ride", "Rowing", "Run", "StandUpPaddling", "Swim", "Walk"),
          #selected = c("Hike", "Ride", "Rowing", "Run", "StandUpPaddling", "Swim", "Walk")
        ),
        shiny::checkboxGroupInput(
          inputId = 'selected_cities',
          label='Select cities'
          # choices=c("Cape Town", "George, South Africa", "Germiston", "Knysna, South Africa", 
          #           "Langebaan", "Lanseria, South Africa", "Onrus", "Paternoster", 
          #           "Sandton", "Stellenbosch", "Warmbad, South Africa", "Wilderness"),
          # selected=c("Cape Town", "George, South Africa", "Germiston", "Knysna, South Africa", 
          #            "Langebaan", "Lanseria, South Africa", "Onrus", "Paternoster", 
          #            "Sandton", "Stellenbosch", "Warmbad, South Africa", "Wilderness")
        ),
        tags$hr(),
        textOutput('activity_stats'),
        tags$hr(),
        shiny::actionButton(inputId = 'submit',label='OK'),
        br(),
        img(src='api_logo_pwrdBy_strava_stack_light.png')
      ),
      mainPanel(
        plotOutput('heatmap')
      )
    )
    
  )
)
