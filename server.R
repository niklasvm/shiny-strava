shinyServer(
  function(input, output,session) {
    
    # MANAGE CACHE ----
    if (!cache) {
      # app_parameters is a list that holds authentication data and activity list
      app_parameters <- reactiveValues(
        authenticated=F,
        credentials=list()
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
    
    # get_stoken ----
    # Get stoken using client id and secret
    get_stoken <- reactive({
      if (is.null(app_parameters$stoken)) {
        
        # parse authorisation code from url string
        authorisation_code <- get_authorisation_code()
        app_parameters$authorisation_code <- authorisation_code
        
        # validate authorisation code is not NULL
        shiny::validate(
          shiny::need(!is.null(authorisation_code),message = 'You need to authenticate')  
        )
        
        # post code to get token data
        message('Using client id: ',Sys.getenv('strava_app_client_id'))
        message('Using secret: ',Sys.getenv('strava_app_secret'))
        message('Using authorisation code: ',authorisation_code)
        
        token_data <- post_authorisation_code(
          authorisation_code = authorisation_code,
          strava_app_client_id = Sys.getenv('strava_app_client_id'),
          strava_app_secret = Sys.getenv('strava_app_secret')
        )
          
        
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
    
    # capture credentials from form -----
    observeEvent(c(input$input_strava_app_url,input$input_strava_app_client_id,input$input_strava_app_secret),{
      
      # load into app_parameters to dynamically update url in link
      app_parameters$credentials <- list(
        strava_app_url = input$input_strava_app_url,
        strava_app_client_id  = as.numeric(input$input_strava_app_client_id),
        strava_app_secret = input$input_strava_app_secret
      )
      
      # Set environment variables
      Sys.setenv(
        strava_app_url = input$input_strava_app_url,
        strava_app_client_id  = as.numeric(input$input_strava_app_client_id),
        strava_app_secret = input$input_strava_app_secret
      )
      
    })
    
    # generate authorisation_url ----
    authorisation_url <- reactive({
      # generate authentication link as set out at https://developers.strava.com/docs/authentication/
      if (ask_api_credentials) {
        # generate from form
        authorisation_url <-   glue('https://www.strava.com/oauth/authorize?client_id={app_parameters$credentials$strava_app_client_id}&response_type=code&redirect_uri={app_parameters$credentials$strava_app_url}&approval_prompt=auto&state=')
      } else {
        # generate from environment variables
        authorisation_url <-   glue('https://www.strava.com/oauth/authorize?client_id={Sys.getenv(\'strava_app_client_id\')}&response_type=code&redirect_uri={Sys.getenv(\'strava_app_url\')}&approval_prompt=auto&state=')
      }

      return(authorisation_url)
      
    })
    
    # parse authentication code from current url if available
    # get_authorisation_code ----
    get_authorisation_code <- reactive({
      pars <- parseQueryString(session$clientData$url_search)
      return(pars$code)
    })
    
    output$not_authenticated <- reactive({
      !app_parameters$authenticated
    })
    outputOptions(output,'not_authenticated', suspendWhenHidden = FALSE)
  
    # output$auth_submit_button ----
    output$auth_submit_button <- renderUI({
      a(
        img(src = 'btn_strava_connectwith_light.png'),
        href = authorisation_url()
      )
    })

    # output$welcome_line ----
    # adds welcome line and triggers authentication and data download to take place
    output$welcome_line <- renderText({
      stoken <- get_stoken()
      token_data <- app_parameters$token_data
      glue('{token_data$athlete$firstname} {token_data$athlete$lastname}')
    })
    
    # triggers when the app has successfullly authenticated
    # downloads and tidies activity data set
    observeEvent(app_parameters$authenticated,{
      if (!app_parameters$authenticated) return()
      
      if (is.null(app_parameters$activities)) {
        stoken <- app_parameters$stoken
        
        message('Downloading activities...')
        my_acts <- get_activity_list_by_page(stoken,per_page=100,pages=1)
        
        # process
        my_acts.df <- my_acts %>% 
          tidy_activities()
        
        
        app_parameters$activities <- my_acts.df
        
        # save to global parameters
        saveRDS(my_acts,'./cache/raw_activities.rds')  
        saveRDS(my_acts.df,'./cache/activities.rds')  
        
      }
      
    })
    
    # Initialise UI ----
    # update form controls
    observeEvent(app_parameters$activities,{
      message('Initialise UI')
      
      activities <- app_parameters$activities
      
      # filter out activities without polyline
      activities <- activities %>% 
        filter(!is.na(map.summary_polyline))
      
      # 1. initialise dates ----
      daterange <- range(as.Date(activities$start_date))
      updateDateRangeInput(session=session,
                           inputId = 'selected_dates',
                           start = lubridate::floor_date(Sys.Date(),unit = 'month'),
                           end = strftime(Sys.Date(),'%Y-%m-%d'),
                           min = daterange[1],
                           max = strftime(Sys.Date(),'%Y-%m-%d')
      )
      # 2. initialise types ----
      types <- activities$type %>% unique %>% sort
      updateCheckboxGroupInput(
        session = session,
        inputId = 'selected_types',
        choices = types,
        selected = types
      )
      
      # 3. initialise anchors ----
      anchors <- activities %>% arrange(desc(start_date)) %>% pull(title)
      updateSelectInput(
        session=session,
        inputId='selected_anchor',
        choices=anchors,
        selected=anchors[1]
      )
      
    })
    
    # observe period ----
    observeEvent(input$selected_period,{
      period <- input$selected_period
      cat(period)
      
      dates <- periods[[period]]
      
      
      updateDateRangeInput(session=session,
                           inputId = 'selected_dates',
                           start = dates[1],
                           end = dates[2])
      
      
    })
    
    # get_filtered_activities ----
    get_filtered_activities <- reactive({
    #get_filtered_activities <- eventReactive(input$submit,{
      if (!app_parameters$authenticated) return()
      
      # validate inputs are available
      req(
        input$selected_dates,
        input$selected_types,
        input$selected_anchor,
        input$selected_radius
      )
      
      message('Filter activities')
      
      # all activities
      activities <- app_parameters$activities
      
      # filter out activities without polyline
      activities <- activities %>% 
        filter(!is.na(map.summary_polyline))
      
      
      date_range_filter <- input$selected_dates
      types_filter <- input$selected_types
      location_anchor <- activities %>% filter(title==input$selected_anchor)
      radius_filter <- input$selected_radius
      
      
      filtered_activities <- activities %>% 
        filter(
          start_date >= date_range_filter[1] & 
            start_date <= date_range_filter[2] + hms('23:59:59')
        ) %>% 
        filter(type %in% types_filter) %>% 
        filter_within_radius(
          lon=location_anchor$start_longitude[1],
          lat=location_anchor$start_latitude[1],
          radius=radius_filter
        )
      
      return(filtered_activities)
    })
    
    # output$leaflet_plot ----
    output$leaflet_plot <- renderLeaflet({
      
      filtered_activities <- get_filtered_activities()
      
      shiny::validate(
        shiny::need(nrow(filtered_activities) > 0,message = 'No activities selected')  
      )
      
      filtered_activities %>% 
        get_leaflet_heat_map(
          colour='red',
          weight = 2,
          opacity=0.01,
          markers = T
        )
    })

    output$histogram_plot <- renderPlot({
      filtered_activities <- get_filtered_activities()
      ggplot(filtered_activities,
             aes(x=distance))+
        geom_histogram()+
        labs(title='Distance')+
        theme_minimal()
    })
    
    output$activity_table <- renderTable({
      filtered_activities <- get_filtered_activities()
      filtered_activities %>% 
        select(title,distance,moving_time,total_elevation_gain)
    })
    
    output$total_activities <- renderValueBox({
      filtered_activities <- get_filtered_activities()
      valueBox(
        value = nrow(filtered_activities),
        subtitle = '# Activities',
        icon=icon('calendar')
      )
    })
    
    output$total_distance <- renderValueBox({
      filtered_activities <- get_filtered_activities()
      valueBox(
        value = format_number(sum(filtered_activities$distance),2,',','',' km'),
        subtitle = 'Distance',
        color = 'green',
        icon=icon('road',lib='glyphicon')
      )
    })
    
    output$total_time <- renderValueBox({
      filtered_activities <- get_filtered_activities()
      valueBox(
        value = as.period(seconds_to_period(sum(filtered_activities$moving_time)),'hours'),
        subtitle = 'Time',
        icon=icon('time',lib='glyphicon')
      )
    })
    
    output$total_ascent <- renderValueBox({
      filtered_activities <- get_filtered_activities()
      valueBox(
        value = format_number(
          sum(filtered_activities$total_elevation_gain),
          0,
          big.mark = ',',
          '',
          ' m'
        ),
        subtitle = 'Ascent',
        icon=icon('signal',lib='glyphicon')
      )
    })
  }
)
