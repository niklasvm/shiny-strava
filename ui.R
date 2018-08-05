message('ui.R sourced')
#source('global.R')


shinyUI(
  fluidPage(
    theme = shinytheme("united"),
    
    
    uiOutput('authentication_panel'),
    #titlePanel('Shiny Strava'),
    
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
        div(
          shiny::selectInput('selected_anchor',label='Location anchor',multiple=F,choices=c('')),
          shiny::numericInput('selected_radius','Radius (m)',min=0,max=Inf,step=1,value=1000)
        ),
        
        tags$hr(),
        shiny::actionButton(inputId = 'submit',label='OK'),
        br(),
        img(src='api_logo_pwrdBy_strava_stack_light.png')
      ),
      mainPanel(
        # manage leaflet plot size
        tags$style(type = "text/css", "#leaflet_plot {height: calc(100vh - 80px) !important;};"),
        
        # leaflet output
        box(
          leafletOutput('leaflet_plot'),
          width='100%',
          height='100%'
        )  
      )
    )
    
  )
  
  
)
