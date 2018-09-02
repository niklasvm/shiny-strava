config_panel <- shinyjs::hidden(
  
  
  fluidRow(
    id='config_panel',
    box(
      width=12,
      status = 'primary',
      title = 'Set application Configuration',
      solidHeader = T,
      div(
        fluidRow(
          column(3,
                 textInput(
                   'input_strava_app_client_id',
                   "Client ID",
                   value = Sys.getenv('strava_app_client_id')
                 )
          ),
          column(
            3,
            textInput(
              'input_strava_app_secret',
              "Client Secret",
              value = Sys.getenv('strava_app_secret')
            )
          ),
          column(
            3,
            textInput(
              'input_strava_app_url',
              "Application URL",
              value = Sys.getenv('strava_app_url')
            )
          ),
          column(
            3,
            actionButton('input_save_config','Save')
            #uiOutput('auth_submit_button')
          ),
          br()
        )
      )
    )
  )
)

loggin_panel <- shinyjs::hidden(
  
  fluidRow(
    id='loggin_panel',
    box(
      width=12,
      status = 'primary',
      title = 'Click to login with Strava',
      solidHeader = T,
      div(
        uiOutput('auth_submit_button')
        
      )
    )
  )
)

ui_activity_filters <- div(
  shiny::selectInput('selected_period',
                     label='Period',
                     choices = names(periods),
                     selected = 'This week',
                     multiple = F
  ),
  conditionalPanel(
    condition="input.selected_period == 'Custom'",
    dateRangeInput(inputId = 'selected_dates',
                   label = 'Select date range'
    )
  ),
  checkboxGroupInput(
    inputId = 'selected_types',
    label='Select types'
  ),
  div(
    shiny::selectInput('selected_anchor',label='Location anchor',multiple=F,choices=c('')),
    shiny::numericInput('selected_radius','Radius (m)',min=0,max=Inf,step=1000,value=100000)
  )
)

ui_footer <- fluidRow(
  box(
    width=12,
    column(4,img(src='api_logo_pwrdBy_strava_stack_light.png',width=199*.6,height=86*.6)),
    column(8,textOutput('welcome_line'))
  )
)

ui_map <- leafletOutput('leaflet_plot')

shinyUI(
  dashboardPage(
    # HEADER ----
    dashboardHeader(
      title = 'shiny-strava',
      titleWidth = 350
    ),
    
    # SIDEBAR ----
    dashboardSidebar(
      ui_activity_filters,
      width = 350
    ),
    
    
    dashboardBody(
      useShinyjs(),
      config_panel,
      loggin_panel,
      tabBox(
        width = 12,
        tabPanel(
          'Map',
          ui_map
        )
        # tabPanel(
        #   'Chart',
        #   ui_rolling_chart
        # ) 
      ),
      
      ui_footer
    )
  )
  
)
