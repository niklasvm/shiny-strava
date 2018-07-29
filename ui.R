message('ui.R sourced')
source('global.R')


shinyUI(
  fluidPage(
    # show authentication panel
    
    uiOutput('authentication_panel'),
    
    titlePanel('Shiny Strava'),
    textOutput('welcome_line'),
    sidebarLayout(
      sidebarPanel(
        shiny::dateRangeInput(inputId = 'selected_dates',
                              label = 'Select date range'
        ),
        shiny::checkboxGroupInput(
          inputId = 'selected_types',
          label='Select types'
        ),
        tags$hr(),
        shiny::actionButton(inputId = 'submit',label='OK'),
        br(),
        img(src='api_logo_pwrdBy_strava_stack_light.png')
      ),
      mainPanel(
        #plotOutput('heatmap')
        leafletOutput('leaflet_plot')
      )
    )
    
  )
)
