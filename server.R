message('server.R sourced')
source('global.R')


shinyServer(
  function(input, output,session) {
    
    # whether to load cached data (must have authenticated before)
    cache <- F
    
    if (!cache) {
      # api
      app_parameters <- reactiveValues(
        authenticated=F
      )  
    } else {
      # cache
      app_parameters <- reactiveValues(
        stoken=readRDS('./cache/stoken.rds'),
        token_data=readRDS('./cache/token_data.rds'),
        activities=readRDS('./cache/activities.rds'),
        authenticated=T
      ) 
    }

    # AUTHENTICATION AND DATA DOWNLOAD ----
    authorisation_url <- reactive({

      
      strava_app_url <- input$strava_app_url
      strava_app_client_id  <- input$strava_app_client_id
      strava_app_secret <- input$strava_app_secret

      # generate authentication link as set out at https://developers.strava.com/docs/authentication/
      authorisation_url <-   glue('https://www.strava.com/oauth/authorize?client_id={strava_app_client_id}&response_type=code&redirect_uri={strava_app_url}&approval_prompt=auto&state=')

      return(authorisation_url)
    
    })
    
    # parse authentication code from current url if available
    get_authorisation_code <- reactive({
      pars <- parseQueryString(session$clientData$url_search)
      return(pars$code)
    })
    
    # authentication panel
    output$authentication_panel <- renderUI({
      if (!app_parameters$authenticated) {
        div(
          'Click to login:',
          a(
            img(src='btn_strava_connectwith_light.png'),
            href=authorisation_url()
          ),
          tags$br()
        )
      }
    })
    
    # adds welcome line and triggers authentication to take place
    output$welcome_line <- renderText({
      stoken <- get_stoken()
      token_data <- app_parameters$token_data
      glue('Welcome {token_data$athlete$firstname} {token_data$athlete$lastname}')
    })
    
    # Get stoken using client id and secret
    get_stoken <- reactive({
      if (is.null(app_parameters$stoken)) {
        # get authorisation code from url string
        authorisation_code <- get_authorisation_code()
        app_parameters$authorisation_code <- authorisation_code
        
        # validate authorisation code is not NULL
        shiny::validate(
          shiny::need(!is.null(authorisation_code),message = 'You need to authenticate')  
        )
        
        # post code to get token data
        token_data <- post_authorisation_code(authorisation_code)
        
        # check access token is available
        if ('access_token' %in% names(token_data)) message('SUCCESSFULLY AUTHENTICATED')
        
        accesstoken <- token_data$access_token
        stoken <- add_headers(Authorization = paste0("Bearer ",accesstoken))
        
        # set app parameters
        app_parameters$token_data <- token_data
        app_parameters$stoken <- stoken
        app_parameters$authenticated <- T
        
        # cache
        dir.create('cache',showWarnings = F)
        saveRDS(token_data,'./cache/token_data.rds')
        saveRDS(stoken,'./cache/stoken.rds')
        
      } else {
        stoken <- app_parameters$stoken
      }
      
      return(stoken)
    })
    
    # triggers when the app has successfullly authenticated
    # downloads and tidies activity data set
    observeEvent(app_parameters$authenticated,{
      if (!app_parameters$authenticated) return()
      
      if (is.null(app_parameters$activities)) {
        stoken <- app_parameters$stoken
        
        message('Downloading activities...')
        my_acts <- get_activity_list(stoken)
        
        # process
        my_acts.df <- my_acts %>% 
          compile_activities(acts = NULL, units = "metric") %>% 
          tidy_activities()
        
        
        app_parameters$activities <- my_acts.df
        
        # save to global parameters
        saveRDS(my_acts,'./cache/raw_activities.rds')  
        saveRDS(my_acts.df,'./cache/activities.rds')  
        
      }
      
    })
    
    # UI ----
    observeEvent(app_parameters$activities,{
      message('Update UI')
      
      activities <- app_parameters$activities
      
      daterange <- range(as.Date(activities$start_date))
      
      
      
      # update dates
      updateDateRangeInput(session=session,
                           inputId = 'selected_dates',
                           start = Sys.Date()-30,
                           end = strftime(Sys.Date(),'%Y-%m-%d'),
                           min = daterange[1],
                           max = strftime(Sys.Date(),'%Y-%m-%d')
      )
    })
    
    observeEvent(input$selected_dates,{
      if (!app_parameters$authenticated) return()
      
      activities <- app_parameters$activities
      selected_daterange <- input$selected_dates
    
      
      # update types
      types <- activities %>% 
        filter(start_date >= selected_daterange[1] & 
                 start_date <= selected_daterange[2]) %>% 
        select(type) %>% distinct %>% .[[1]] %>% sort
      
      updateCheckboxGroupInput(
        session=session,
        inputId = 'selected_types',
        choices=types,
        selected=types
      )
    })
    
    observeEvent(list(input$selected_dates,input$selected_types),{
      if (!app_parameters$authenticated) return()
      
      activities <- app_parameters$activities
      selected_daterange <- input$selected_dates
      selected_types <- input$selected_types
      
      # update cities
      cities <- activities %>% 
        filter(
          start_date >= selected_daterange[1] & 
            start_date <= selected_daterange[2]
        ) %>% 
        filter(type %in% selected_types) %>% 
        select(location_city) %>% distinct %>% .[[1]] %>% sort
      
      updateCheckboxGroupInput(
        session=session,
        inputId = 'selected_cities',
        choices=cities,
        selected=cities
      )
    })
    
    # ACTIVITY STATS ----
    output$activity_stats <- renderText({
      if (!app_parameters$authenticated) return()
      
      activities <- app_parameters$activities
      selected_daterange <- input$selected_dates
      selected_types <- input$selected_types
      
      
      filtered_activities <- activities %>% 
        filter(
          start_date >= selected_daterange[1] & 
            start_date <= selected_daterange[2]
        ) %>% 
        filter(type %in% selected_types) %>% 
        #filter(location_city %in% cities) %>% 
        filter(!is.null(map.summary_polyline))
      
      glue('{nrow(filtered_activities)} activities')
    })
    
    # HEATMAP ----
    
    get_filtered_activities <- eventReactive(input$submit,{
      if (!app_parameters$authenticated) return()
      
      activities <- app_parameters$activities
      selected_daterange <- input$selected_dates
      selected_types <- input$selected_types
      
      
      filtered_activities <- activities %>% 
        filter(
          start_date >= selected_daterange[1] & 
            start_date <= selected_daterange[2]
        ) %>% 
        filter(type %in% selected_types) %>% 
        #filter(location_city %in% cities) %>% 
        filter(!is.null(map.summary_polyline)) %>% 
        filter(!is.na(map.summary_polyline))
      
      return(filtered_activities)
    })
    
    output$heatmap <- renderPlot({
      
      filtered_activities <- get_filtered_activities()
      acts <- 1:nrow(filtered_activities)
      
      rStrava:::get_heat_map.actframe(act_data=filtered_activities,
                   acts = acts,
                   col = 'darkgreen', 
                   size = 2, 
                   dist = F, 
                   f = 0.5
      )
    })
    
    output$activity_table <- renderDataTable({
      stoken <- get_stoken()
      
      message('Downloading activities...')
      my_acts <- get_activity_list(stoken)
      saveRDS(my_acts,'my_acts.rds')
      my_acts.df <- compile_activities(my_acts, acts = NULL, units = "metric")
      my_acts.df
    })
    
    # # Download data
    # output$downloadData <- downloadHandler(
    #   filename = function() {
    #     paste('StravaActivities-', Sys.Date(), '.csv', sep='')
    #   },
    #   content = function(con) {
    #     # get and save all activities
    #     my_acts <- get_activity_list(get_stoken())
    #     
    #     # Convert activities list to data frame
    #     my_acts.df <- compile_activities(my_acts, acts = NULL, units = "metric")
    #     
    #     write.csv(my_acts.df, con, row.names = FALSE)
    #   }
    # )
  }
)
