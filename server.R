message('server.R sourced')
source('global.R')

shinyServer(
  function(input, output,session) {
    

    # APPLICATION AUTHENTICATION ----
    
    # generate authentication link as set out at https://developers.strava.com/docs/authentication/
    get_authorisation_url <- reactive({
      client_id <- Sys.getenv('strava_app_client_id')
      redirect_uri <- Sys.getenv('strava_app_url')
      glue('https://www.strava.com/oauth/authorize?client_id={client_id}&response_type=code&redirect_uri={redirect_uri}&approval_prompt=auto&state=')
     
    })
    
    # parse authentication code from current url if available
    get_authorisation_code <- reactive({
      pars <- parseQueryString(session$clientData$url_search)
      
      return(pars$code)
    })
    
    # Get stoken using client id and secret
    get_stoken <- reactive({
      # get authorisation code from url string
      authorisation_code <- get_authorisation_code()
      
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
      
      return(stoken)
    })
    
    output$authUI <- renderUI({
      if (is.null(get_authorisation_code())) {
        a('Click to authorise Strava Access',href=get_authorisation_url())
      }
    })
    
    # OTHER ----
    
    output$activity_table <- renderDataTable({
      stoken <- get_stoken()
      
      message('Downloading activities...')
      my_acts <- get_activity_list(stoken)
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
