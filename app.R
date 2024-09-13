# Load required libraries
library(plumber)
library(dplyr)
library(mongolite)
library(prophet)

# Define the API
#* @apiTitle EV Battery Prediction API

#* Endpoint to process data and insert forecast based on userId
#* @param userId The userId from the request
#* @post /predict
function(userId) {
  # Load MongoDB URL from environment variables directly (set by the deployment platform)
  MONGO_URL <- Sys.getenv('MONGO_URL')
  
  # Connect to MongoDB for checking existing forecast
  mongo_forecast <- mongo(
    collection = 'rangeforecasts',
    url = MONGO_URL
  )
  
  # Fetch existing forecasts for this userId
  existing_forecast <- mongo_forecast$find(query = paste0('{"userId": "', userId, '"}'))
  
  # Extract the existing dates from the forecast (if any)
  existing_dates <- as.Date(existing_forecast$date)
  
  # Connect to MongoDB for getting battery data
  mongo_batteries <- mongo(
    collection = 'batteries',
    url = MONGO_URL
  )
  
  # Fetch new data from MongoDB for the user
  data <- mongo_batteries$find()
  
  # Filter data by userId
  data <- data %>%
    filter(userId == userId)
  
  # Convert date to the correct format
  data$date <- as.Date(data$date, format='%Y-%m-%d')
  
  # Remove the 8th column (if needed) and omit missing values
  data <- data[, -8]
  data <- na.omit(data)
  
  # Check if new data contains dates not already in the forecast
  new_data <- data %>%
    filter(!date %in% existing_dates)
  
  if (nrow(new_data) == 0) {
    # No new data to process, return a message
    return(list(message = "No new data to process for this user."))
  }
  
  # Prepare the new data for Prophet model
  prophetData <- new_data %>%
    group_by(ds = date) %>%
    summarise(y = current_miles)
  
  # Train the Prophet model on the new data
  model <- prophet(prophetData)
  
  # Create future dataframe (30 days ahead)
  future <- make_future_dataframe(model, periods = 30, freq = 'day')
  
  # Generate predictions
  forecast <- predict(model, future)
  
  # Prepare the forecast for insertion
  forecast <- forecast %>%
    select(date = ds, yhat) %>%
    mutate(userId = userId)
  
  # Insert new forecast data into MongoDB
  mongo_forecast$insert(forecast)
  
  # Return a confirmation message
  return(list(message = "New data has been processed successfully."))
}

