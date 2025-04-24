#! /bin/bash

# Define the PSQL variable to execute queries using the freecodecamp user and salon database
PSQL="psql --username=freecodecamp --dbname=salon --tuples-only -c"

# Welcome message
echo -e "\n~~~~~ SALON APPOINTMENT SCHEDULER ~~~~~\n"

# ========== Function to select a service ========== #
select_service() {
  while true; do
    # Fetch all services from the database and show them as a menu
    SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id;")

    # Display each service in the format: 1) cut
    echo "$SERVICES" | while read SERVICE_ID BAR SERVICE_NAME
    do
      echo "$SERVICE_ID) $(echo $SERVICE_NAME | xargs)"  # Trim whitespace
    done

    # Ask user to pick a service
    echo -e "\nPlease select a service:"
    read SERVICE_ID_SELECTED

    # Validate input: must be a number
    if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]; then
      echo -e "\nThat is not a valid number. Please enter a valid service ID."
      continue
    fi

    # Check if selected service exists
    SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")

    # If not found, repeat the prompt
    if [[ -z $SERVICE_NAME ]]; then
      echo -e "\nThat service doesn't exist. Please select from the list."
      continue
    fi

    # Clean service name (trim whitespace)
    SERVICE_NAME=$(echo $SERVICE_NAME | xargs)

    # Break the loop once a valid service is selected
    break
  done
}

# ========== Function to get customer information ========== #
get_customer_info() {
  # Ask for phone number
  echo -e "\nPlease enter your phone number:"
  read CUSTOMER_PHONE

  # Look up customer by phone number on database
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")

  # If customer doesn't exist
  if [[ -z $CUSTOMER_ID ]]; then
    # Ask for their name
    echo -e "\nI don't have a record for that phone number. What's your name?"
    read CUSTOMER_NAME

    # Add new customer to the database
    $PSQL "INSERT INTO customers(phone, name) VALUES('$CUSTOMER_PHONE', '$CUSTOMER_NAME')" > /dev/null

    # Get the new customer's ID 
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")
  else
    # If customer exists, get their name
    CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")
    CUSTOMER_NAME=$(echo $CUSTOMER_NAME | xargs)  # Clean whitespace
  fi
}

# ========== Function to schedule appointment ========== #
schedule_appointment() {
  # Start an infinite loop to validate user input until it's correct
  while true; do
    # Ask for desired appointment time
    echo -e "\nWhat time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
    read SERVICE_TIME

    # Validate user input for the time format (HH:MM)
    if [[ ! "$SERVICE_TIME" =~ ^[0-9]{2}:[0-9]{2}$ ]]; then
      echo -e "I did not understand that, please input like format 13:20"
      continue  # Continue to ask for a valid input if the format is wrong
    fi

    # If input is valid, insert the appointment into the database
    $PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')" > /dev/null

    # Confirmation message
    echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME.\n"
    break  # Exit the loop after successful insertion
  done
}

# ========== Main menu to start the interaction ========== #
main_menu() {
  echo -e "Welcome to My Salon, how can I help you?\n"

  # Run each function in order
  select_service          
  get_customer_info       
  schedule_appointment   
}

# Start the script by calling the main menu
main_menu
