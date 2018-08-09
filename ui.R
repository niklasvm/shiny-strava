message('ui.R sourced')
#source('global.R')


shinyUI(
  dashboardPage(
    #skin = 'green',
    # HEADER ----
    dashboardHeader(
      disable=T
      #title = 'shiny-strava'
    ),
    
    # SIDEBAR ----
    dashboardSidebar(
      disable=T
      # hr(),
      # 
      # # 1. Menu ----
      # sidebarMenu(
      #   menuItem('Authenticate',tabName = 'authenticate',icon = icon('sign-in')),
      #   #menuItem('Choose activities', tabName = 'controls', icon = icon('table')),
      #   menuItem('Map', tabName = 'map', icon = icon('map-signs'),selected = T)
      # ),
      # 
      # tags$hr(),
      # #shiny::actionButton(inputId = 'submit',label='OK'),
      # br(),
      # img(src='api_logo_pwrdBy_strava_stack_light.png')
    ),
    
    # BODY ----
    dashboardBody(
      fluidRow(
        box(
          textOutput('welcome_line'),
          width=12
        )
      ),
      uiOutput('authentication_panel'),
    
      fluidRow(
        tabBox(
          width=12,
          
          tabPanel(
            'Map',
            fluidRow(
              # manage leaflet plot size
              #tags$style(type = "text/css", "#leaflet_plot {height: calc(100vh - 90px) !important;};"),
              box(
                #title = 'Map',
                #status='primary',
                #solidHeader = T,
                width=9,
                height=500,
                leafletOutput('leaflet_plot',height = 440)
              ),
              box(
                #title='Filters',
                #solidHeader = T,
                #status='primary',
                width=3,
                height=500,
                shiny::dateRangeInput(inputId = 'selected_dates',
                                      label = 'Select date range'
                ),
                shiny::checkboxGroupInput(
                  inputId = 'selected_types',
                  label='Select types'
                ),
                div(
                  shiny::selectInput('selected_anchor',label='Location anchor',multiple=F,choices=c('')),
                  shiny::numericInput('selected_radius','Radius (m)',min=0,max=Inf,step=1000,value=1000)
                )
              )
            )
          ),
          tabPanel(
            'Something else'
            
          )
        )
        
      ),
      fluidRow(
        box(
          width=12,
          img(src='api_logo_pwrdBy_strava_stack_light.png')
          
          
        )
      )
    )
  )
  
)
