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

login_panel <- shinyjs::hidden(
  
  fluidRow(
    id='login_panel',
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

ui_activity_filters <- box(
  width=12,
  fluidRow(
    
    column(
      6,
      shiny::selectInput('selected_period',
                         label='Period',
                         choices = names(periods),
                         selected = 'Last 30 days',
                         multiple = F
      ),
      conditionalPanel(
        condition="input.selected_period == 'Custom'",
        dateRangeInput(inputId = 'selected_dates',
                       label = 'Select date range'
        )
      )
    ),
    column(
      6,
      shiny::selectInput(
        inputId = 'selected_types',
        label='Select types',
        choices='',
        multiple = T
      )
    )
  )
)

ui_footer <- fluidRow(
  box(
    width=12,
    column(4,img(src='api_logo_pwrdBy_strava_stack_light.png',width=199*.6,height=86*.6)),
    column(8,textOutput('welcome_line'))
  )
)

#ui_summary_chart <- plotOutput('summary_chart')

shinyUI(
  dashboardPage(
    title = 'shiny-strava',
      
    # HEADER ----
    dashboardHeader(
      title = 'shiny-strava'
      #titleWidth = 350
    ),
    
    # SIDEBAR ----
    dashboardSidebar(
      
      sidebarMenu(
        id='menu',
        menuItem('Log In',icon = icon('th'),tabName='login'),
        menuItem('Activity List',icon = icon('th'),tabName='activity_list_tab'),
        menuItem('Activities',icon = icon('th'),tabName='activity_tab')
      ),
      div(
        img(src='1.2 strava api logos/powered by Strava/pwrdBy_strava_light/api_logo_pwrdBy_strava_stack_light.png',width=199*.6,height=86*.6),
        style='display: block;margin-left: auto;margin-right: auto;width: 50%;'
      )
      #width = 350
    ),
    
    
    dashboardBody(
      useShinyjs(),
      tabItems(
        tabItem(
          tabName = 'login',
          config_panel,
          login_panel
        ),
        tabItem(
          tabName = 'activity_list_tab',
          
          ui_activity_filters,
          tabBox(
            width = 12,
            tabPanel(
              'Chart',
              summaryDataUI('summary_data')
            ),
            tabPanel(
              'Map',
              activityMapUI('map')
            ),
            tabPanel(
              'Heatmap',
              daytimeHeatmapUI('heatmap')
            )
            
          )
        )
      )
    )
  )
  
)
