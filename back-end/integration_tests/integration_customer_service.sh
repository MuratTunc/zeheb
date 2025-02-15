#!/bin/bash

# Load environment variables from .env file
ENV_FILE="../build-tools/.env"
if [ -f "$ENV_FILE" ]; then
  export $(grep -v '^#' "$ENV_FILE" | xargs)
else
  echo "⚠️ .env file not found at $ENV_FILE"
  exit 1
fi

# Install jq (JSON parsing utility) if not already installed
if ! command -v jq &> /dev/null
then
  echo "jq could not be found, installing..."
  sudo apt-get update
  sudo apt-get install -y jq
fi

# Define customer details
CUSTOMERNAME="testcustomer"
MAILADDRESS="testcustomer@example.com"
PASSWORD="TestPassword123"


# Define new parameters
NEW_PASSWORD="NewTestPassword123"
NEW_EMAIL="newmail@example.com"
NEW_NOTE="This is a new note to append."
UPDATED_NOTE="This is the completely new note."


# Define API URLs
# Read port from .env file
BASE_URL="http://localhost:$CUSTOMER_SERVICE_PORT"
HEALTH_CHECK_URL="$BASE_URL/health"
REGISTER_URL="$BASE_URL/register"
LOGIN_URL="$BASE_URL/login"
CUSTOMER_URL="$BASE_URL/customer"


# (Require JWT authentication)
UPDATE_PASSWORD_URL="$BASE_URL/update-password"
UPDATE_CUSTOMER_URL="$BASE_URL/update-customer"
DEACTIVATE_CUSTOMER_URL="$BASE_URL/deactivate-customer"
ACTIVATE_CUSTOMER_URL="$BASE_URL/activate-customer"
UPDATE_EMAIL_URL="$BASE_URL/update-email"
UPDATE_NOTE_URL="$BASE_URL/update-note"
INSERT_NOTE_URL="$BASE_URL/insert-note"
GET_ALL_CUSTOMERS_URL="$BASE_URL/get_all_customer"
ORDER_CUSTOMERS_URL="$BASE_URL/order-customers"
GET_ACTIVATED_CUSTOMERS_URL="$BASE_URL/activated-customers"
GET_LOGGED_IN_CUSTOMERS_URL="$BASE_URL/logged-in-customers"
DELETE_CUSTOMER_URL="$BASE_URL/delete-customer"


health_check() {
  echo "===>TEST END POINT--->HEALTH CHECK"
  echo
  echo "REQUEST URL: $HEALTH_CHECK_URL"

  # Define the HTTP request type
  REQUEST_TYPE="GET"

  # Print the full curl command and request type
  echo "REQUEST TYPE: $REQUEST_TYPE"
  echo "COMMAND: curl -X $REQUEST_TYPE \"$HEALTH_CHECK_URL\""

  # Send the request and capture the response
  HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" -X $REQUEST_TYPE "$HEALTH_CHECK_URL")

  # Extract response body and HTTP status code
  HTTP_BODY=$(echo "$HEALTH_RESPONSE" | sed '$ d')
  HTTP_STATUS=$(echo "$HEALTH_RESPONSE" | tail -n1)

  echo "Health Check Response Body: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "Service is healthy!"
  else
    echo "❌ Health check failed with status code $HTTP_STATUS. Response: $HTTP_BODY"
    exit 1
  fi

  echo "✅ Health Check successfully"
  echo
}

register_customer() {
  echo "===>TEST END POINT--->REGISTER NEW CUSTOMER"
  echo
  echo "REQUEST URL: $REGISTER_URL"

  # Define the HTTP request type
  REQUEST_TYPE="POST"

  # Construct JSON payload dynamically
  JSON_BODY=$(jq -n \
    --arg customername "$CUSTOMERNAME" \
    --arg mailAddress "$MAILADDRESS" \
    --arg password "$PASSWORD" \
    '{
      customername: $customername,
      mailAddress: $mailAddress,
      password: $password
    }')

  # Print the full curl command and JSON_BODY
  echo "REQUEST TYPE: $REQUEST_TYPE"
  echo "JSON BODY: $JSON_BODY"
  echo "COMMAND: curl -X $REQUEST_TYPE \"$REGISTER_URL\" -H \"Content-Type: application/json\" -d '$JSON_BODY'"
  

  # Send the request and capture the response
  REGISTER_RESPONSE=$(curl -s -w "\n%{http_code}" -X $REQUEST_TYPE "$REGISTER_URL" -H "Content-Type: application/json" -d "$JSON_BODY")

  # Extract response body and HTTP status code
  HTTP_BODY=$(echo "$REGISTER_RESPONSE" | sed '$ d')
  HTTP_STATUS=$(echo "$REGISTER_RESPONSE" | tail -n1)

  echo "Registration response: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "Customer registered successfully!"
  elif [ "$HTTP_STATUS" -eq 409 ]; then
    echo "Customer already exists."
  else
    echo "Registration failed with status code $HTTP_STATUS. Response: $HTTP_BODY"
    exit 1
  fi

  echo "✅ Registration successful!"
  echo
}

login_customer() {
  echo "===>TEST END POINT--->LOGIN CUSTOMER"
  echo
  echo "REQUEST URL: $LOGIN_URL"

  # Define the HTTP request type
  REQUEST_TYPE="POST"

  # Construct JSON payload dynamically
  JSON_BODY=$(jq -n \
    --arg customername "$CUSTOMERNAME" \
    --arg password "$PASSWORD" \
    '{
      customername: $customername,
      password: $password
    }')

  # Print the full curl command and JSON_BODY
  echo "REQUEST TYPE: $REQUEST_TYPE"
  echo "JSON BODY: $JSON_BODY"
  echo "COMMAND: curl -X $REQUEST_TYPE \"$LOGIN_URL\" -H \"Content-Type: application/json\" -d '$JSON_BODY'"
  

  # Send the request and capture the response
  LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" -X $REQUEST_TYPE "$LOGIN_URL" -H "Content-Type: application/json" -d "$JSON_BODY")

  # Extract response body and HTTP status code
  HTTP_BODY=$(echo "$LOGIN_RESPONSE" | sed '$ d')
  HTTP_STATUS=$(echo "$LOGIN_RESPONSE" | tail -n1)

  echo "Login response body: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "Login successful."
  elif [ "$HTTP_STATUS" -eq 401 ]; then
    echo "Error: Invalid credentials."
    exit 1
  else
    echo "Login failed with status code $HTTP_STATUS. Response: $HTTP_BODY"
    exit 1
  fi

  echo "✅ Login successful!"
  echo
}

get_customer_details() {
  echo "===>TEST END POINT--->GET CUSTOMER DETAILS"
  echo
  echo "REQUEST URL: $CUSTOMER_URL?customername=$CUSTOMERNAME"

  # Define the HTTP request type
  REQUEST_TYPE="GET"

  # Construct the query parameters (no body needed for GET)
  JSON_BODY=$(jq -n --arg customername "$CUSTOMERNAME" '{customername: $customername}')

  # Print the full curl command and JSON_BODY
  echo "REQUEST TYPE: $REQUEST_TYPE"
  echo "JSON BODY: $JSON_BODY"
  echo "COMMAND: curl -X $REQUEST_TYPE \"$CUSTOMER_URL?customername=$CUSTOMERNAME\" -H \"Authorization: Bearer $JWT_TOKEN\""
  

  # Send the request and capture the response
  RESPONSE=$(curl -s -w "\n%{http_code}" -X $REQUEST_TYPE "$CUSTOMER_URL?customername=$CUSTOMERNAME" -H "Authorization: Bearer $JWT_TOKEN")

  # Extract response body and HTTP status code
  HTTP_BODY=$(echo "$RESPONSE" | sed '$ d')
  HTTP_STATUS=$(echo "$RESPONSE" | tail -n1)

  echo "Customer details response body: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  # Extract customer ID from the response body
  CUSTOMER_ID=$(echo "$HTTP_BODY" | jq -r '.ID')

  if [[ "$CUSTOMER_ID" == "null" || -z "$CUSTOMER_ID" ]]; then
    echo "❌ Error: Could not retrieve customer ID."
    exit 1
  fi

  echo "Customer ID retrieved: $CUSTOMER_ID"
  echo "✅ Customer details fetched successfully."
  echo
}


deactivate_customer() {
  echo "===>TEST END POINT--->DEACTIVATE CUSTOMER"
  echo
  echo "REQUEST URL: $DEACTIVATE_CUSTOMER_URL"

  # Define the HTTP request type
  REQUEST_TYPE="PUT"

  # Construct JSON payload dynamically
  JSON_BODY=$(jq -n --arg customername "$CUSTOMERNAME" '{customername: $customername}')

  # Print the full curl command and JSON_BODY
  echo "REQUEST TYPE: $REQUEST_TYPE"
  echo "JSON BODY: $JSON_BODY"
  echo "COMMAND: curl -X $REQUEST_TYPE \"$DEACTIVATE_CUSTOMER_URL\" -H \"Authorization: Bearer $JWT_TOKEN\" -H \"Content-Type: application/json\" -d \"$JSON_BODY\""
 

  # Send the request and capture the response
  DEACTIVATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X $REQUEST_TYPE "$DEACTIVATE_CUSTOMER_URL" \
    -H "Authorization: Bearer $JWT_TOKEN" -H "Content-Type: application/json" -d "$JSON_BODY")

  # Extract response body and HTTP status code
  HTTP_BODY=$(echo "$DEACTIVATE_RESPONSE" | sed '$ d')
  HTTP_STATUS=$(echo "$DEACTIVATE_RESPONSE" | tail -n1)

  echo "Deactivate response body: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  # Check the response status
  if [ "$HTTP_STATUS" -ne 200 ]; then
    echo "❌ Error: Customer deactivation failed."
    exit 1
  fi

  echo "✅ Customer deactivated successfully."
  echo
}


activate_customer() {
  echo "===>TEST END POINT--->ACTIVATE CUSTOMER"
  echo
  echo "REQUEST URL: $ACTIVATE_CUSTOMER_URL"

  # Define the HTTP request type
  REQUEST_TYPE="PUT"

  # Construct JSON payload dynamically
  JSON_BODY=$(jq -n --arg customername "$CUSTOMERNAME" '{customername: $customername}')

  # Print the full curl command and JSON_BODY
  echo "REQUEST TYPE: $REQUEST_TYPE"
  echo "JSON BODY: $JSON_BODY"
  echo "COMMAND: curl -X $REQUEST_TYPE \"$ACTIVATE_CUSTOMER_URL\" -H \"Authorization: Bearer $JWT_TOKEN\" -H \"Content-Type: application/json\" -d \"$JSON_BODY\""
  

  # Send the request and capture the response
  ACTIVATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X $REQUEST_TYPE "$ACTIVATE_CUSTOMER_URL" \
    -H "Authorization: Bearer $JWT_TOKEN" -H "Content-Type: application/json" -d "$JSON_BODY")

  # Extract response body and HTTP status code
  HTTP_BODY=$(echo "$ACTIVATE_RESPONSE" | sed '$ d')
  HTTP_STATUS=$(echo "$ACTIVATE_RESPONSE" | tail -n1)

  echo "Activate response body: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  # Check the response status
  if [ "$HTTP_STATUS" -ne 200 ]; then
    echo "❌ Error: Customer activation failed."
    exit 1
  fi

  echo "✅ Customer activated successfully."
  echo
}



update_customer() {
  echo "===>TEST END POINT--->UPDATE CUSTOMER"
  echo
  echo "REQUEST URL: $UPDATE_CUSTOMER_URL"

  # Define the HTTP request type
  REQUEST_TYPE="PUT"

  # Construct JSON payload dynamically
  JSON_BODY=$(jq -n \
    --arg customername "$CUSTOMERNAME" \
    --arg mailAddress "updatedcustomer@example.com" \
    '{customername: $customername, mailAddress: $mailAddress}')

  # Print the full curl command and JSON_BODY
  echo "REQUEST TYPE: $REQUEST_TYPE"
  echo "JSON BODY: $JSON_BODY"
  echo "COMMAND: curl -X $REQUEST_TYPE \"$UPDATE_CUSTOMER_URL\" -H \"Authorization: Bearer $JWT_TOKEN\" -H \"Content-Type: application/json\" -d \"$JSON_BODY\""
  

  # Send the request and capture the response
  UPDATE_CUSTOMER_RESPONSE=$(curl -s -w "\n%{http_code}" -X $REQUEST_TYPE "$UPDATE_CUSTOMER_URL" \
    -H "Authorization: Bearer $JWT_TOKEN" -H "Content-Type: application/json" -d "$JSON_BODY")

  # Extract response body and HTTP status code
  HTTP_BODY=$(echo "$UPDATE_CUSTOMER_RESPONSE" | sed '$ d')
  HTTP_STATUS=$(echo "$UPDATE_CUSTOMER_RESPONSE" | tail -n1)

  echo "Update response body: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  # Check the response status
  if [ "$HTTP_STATUS" -ne 200 ]; then
    echo "❌ Error: Customer update failed."
    exit 1
  fi

  echo "✅ Customer updated successfully."
  echo
}


# Function to update customer password
update_password() {
  echo "===>TEST END POINT--->UPDATE PASSWORD"
  echo
  echo "REQUEST URL: $UPDATE_PASSWORD_URL"

  # Define the HTTP request type
  REQUEST_TYPE="POST"

  # Construct JSON payload dynamically
  JSON_BODY=$(jq -n \
    --arg customername "$CUSTOMERNAME" \
    --arg new_password "$NEW_PASSWORD" \
    '{customername: $customername, new_password: $new_password}')

  # Print the full curl command and JSON_BODY
  echo "REQUEST TYPE: $REQUEST_TYPE"
  echo "JSON BODY: $JSON_BODY"
  echo "COMMAND: curl -X $REQUEST_TYPE \"$UPDATE_PASSWORD_URL\" -H \"Authorization: Bearer $JWT_TOKEN\" -H \"Content-Type: application/json\" -d \"$JSON_BODY\""
  

  # Send the request and capture the response
  UPDATE_PASSWORD_RESPONSE=$(curl -s -w "\n%{http_code}" -X $REQUEST_TYPE "$UPDATE_PASSWORD_URL" \
    -H "Authorization: Bearer $JWT_TOKEN" -H "Content-Type: application/json" -d "$JSON_BODY")

  # Extract response body and HTTP status code
  HTTP_BODY=$(echo "$UPDATE_PASSWORD_RESPONSE" | sed '$ d')
  HTTP_STATUS=$(echo "$UPDATE_PASSWORD_RESPONSE" | tail -n1)

  echo "Update password response body: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  # Check the response status
  if [ "$HTTP_STATUS" -ne 200 ]; then
    echo "❌ Error: Password update failed."
    exit 1
  fi

  echo "✅ Password updated successfully."
  echo
}

# Function to update customer email address
update_email() {
  echo "===>TEST END POINT--->UPDATE EMAIL ADDRESS"
  echo
  echo "REQUEST URL: $UPDATE_EMAIL_URL"

  # Define the HTTP request type
  REQUEST_TYPE="PUT"

  # Construct JSON payload dynamically
  JSON_BODY=$(jq -n \
    --arg customername "$CUSTOMERNAME" \
    --arg new_email "$NEW_EMAIL" \
    '{customername: $customername, new_email: $new_email}')

  # Print the full curl command and JSON_BODY
  echo "REQUEST TYPE: $REQUEST_TYPE"
  echo "JSON BODY: $JSON_BODY"
  echo "COMMAND: curl -X $REQUEST_TYPE \"$UPDATE_EMAIL_URL\" -H \"Content-Type: application/json\" -d \"$JSON_BODY\""
  

  # Send the request and capture the response
  UPDATE_EMAIL_RESPONSE=$(curl -s -w "\n%{http_code}" -X $REQUEST_TYPE "$UPDATE_EMAIL_URL" \
    -H "Content-Type: application/json" -d "$JSON_BODY")

  # Extract response body and HTTP status code
  HTTP_BODY=$(echo "$UPDATE_EMAIL_RESPONSE" | sed '$ d')
  HTTP_STATUS=$(echo "$UPDATE_EMAIL_RESPONSE" | tail -n1)

  echo "Update email response body: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  # Check the response status
  if [ "$HTTP_STATUS" -ne 200 ]; then
    echo "❌ Error: Email update failed."
    exit 1
  fi

  echo "✅ Email updated successfully."
  echo
}


# Function to update the note for a customer
update_note() {
  echo "===>TEST END POINT--->UPDATE NOTE"
  echo
  echo "REQUEST URL: $UPDATE_NOTE_URL"

  # Define the HTTP request type
  REQUEST_TYPE="PUT"

  # Construct JSON payload dynamically
  JSON_BODY=$(jq -n \
    --arg customername "$CUSTOMERNAME" \
    --arg note "$UPDATED_NOTE" \
    '{customername: $customername, note: $note}')

  # Print the full curl command and JSON_BODY
  echo "REQUEST TYPE: $REQUEST_TYPE"
  echo "JSON BODY: $JSON_BODY"
  echo "COMMAND: curl -X $REQUEST_TYPE \"$UPDATE_NOTE_URL\" -H \"Content-Type: application/json\" -d \"$JSON_BODY\""
  

  # Send the request and capture the response
  UPDATE_NOTE_RESPONSE=$(curl -s -w "\n%{http_code}" -X $REQUEST_TYPE "$UPDATE_NOTE_URL" \
    -H "Content-Type: application/json" -d "$JSON_BODY")

  # Extract response body and HTTP status code
  HTTP_BODY=$(echo "$UPDATE_NOTE_RESPONSE" | sed '$ d')
  HTTP_STATUS=$(echo "$UPDATE_NOTE_RESPONSE" | tail -n1)

  echo "Update Note response body: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  # Check the response status
  if [ "$HTTP_STATUS" -ne 200 ]; then
    echo "❌ Error: Note update failed."
    exit 1
  fi

  echo "✅ Note updated successfully."
  echo
}




# Function to insert or append a note for a customer
insert_note() {
  echo "===>TEST END POINT--->INSERT NOTE"
  echo
  echo "REQUEST URL: $INSERT_NOTE_URL"

  # Define the HTTP request type
  REQUEST_TYPE="PUT"

  # Construct JSON payload dynamically
  JSON_BODY=$(jq -n \
    --arg customername "$CUSTOMERNAME" \
    --arg new_note "$NEW_NOTE" \
    '{customername: $customername, new_note: $new_note}')
  
  
  echo "REQUEST TYPE: $REQUEST_TYPE"
  echo "JSON BODY: $JSON_BODY"
  echo "COMMAND: curl -X $REQUEST_TYPE \"$INSERT_NOTE_URL\" -H \"Content-Type: application/json\" -d \"$JSON_BODY\""
 

  # Send the request and capture the response
  INSERT_NOTE_RESPONSE=$(curl -s -w "\n%{http_code}" -X $REQUEST_TYPE "$INSERT_NOTE_URL" \
    -H "Content-Type: application/json" -d "$JSON_BODY")

  # Extract response body and HTTP status code
  HTTP_BODY=$(echo "$INSERT_NOTE_RESPONSE" | sed '$ d')
  HTTP_STATUS=$(echo "$INSERT_NOTE_RESPONSE" | tail -n1)

  echo "Insert Note response body: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  # Check the response status
  if [ "$HTTP_STATUS" -ne 200 ]; then
    echo "❌ Error: Note insertion failed."
    exit 1
  fi

  echo "✅ Note inserted successfully."
  echo
}



# Function to get all customers
get_all_customers() {
  echo "===>TEST END POINT--->GET ALL CUSTOMERS"
  echo
  echo "REQUEST URL: $GET_ALL_CUSTOMERS_URL"

  # Define the HTTP request type
  REQUEST_TYPE="GET"

  # Print the full curl command
  echo "REQUEST TYPE: $REQUEST_TYPE"
  echo "COMMAND: curl -X $REQUEST_TYPE \"$GET_ALL_CUSTOMERS_URL\" -H \"Content-Type: application/json\""
  
  # Send the request and capture the response
  RESPONSE=$(curl -s -w "\n%{http_code}" -X $REQUEST_TYPE "$GET_ALL_CUSTOMERS_URL" -H "Content-Type: application/json")

  # Extract response body and HTTP status code
  HTTP_BODY=$(echo "$RESPONSE" | sed '$ d')
  HTTP_STATUS=$(echo "$RESPONSE" | tail -n1)

  echo "Response Body: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  # Check the response status
  if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "✅ Successfully retrieved all customers."
  else
    echo "❌ Failed to fetch customers."
  fi

  echo
}



# Function to test ordering customers
order_customers() {
  echo "===>TEST END POINT--->ORDER CUSTOMERS"
  echo
  echo "REQUEST URL: $ORDER_CUSTOMERS_URL"

  # Define the HTTP request type
  REQUEST_TYPE="GET"

  # Test ordering by created_at (default)
  echo "Testing ordering by created_at (default):"
  echo "COMMAND: curl -X $REQUEST_TYPE \"$ORDER_CUSTOMERS_URL\""
  RESPONSE=$(curl -s -w "\n%{http_code}" -X $REQUEST_TYPE "$ORDER_CUSTOMERS_URL")
  HTTP_BODY=$(echo "$RESPONSE" | sed '$ d')
  HTTP_STATUS=$(echo "$RESPONSE" | tail -n1)
  echo "Response Body: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "✅ Customers ordered by created_at."
  else
    echo "❌ Failed to order customers by created_at."
  fi

  # Test ordering by customername
  echo "Testing ordering by customername:"
  echo "COMMAND: curl -X $REQUEST_TYPE \"$ORDER_CUSTOMERS_URL?order_by=customername\""
  RESPONSE=$(curl -s -w "\n%{http_code}" -X $REQUEST_TYPE "$ORDER_CUSTOMERS_URL?order_by=customername")
  HTTP_BODY=$(echo "$RESPONSE" | sed '$ d')
  HTTP_STATUS=$(echo "$RESPONSE" | tail -n1)
  echo "Response Body: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "✅ Customers ordered by customername."
  else
    echo "❌ Failed to order customers by customername."
  fi

  # Test ordering by updated_at
  echo "Testing ordering by updated_at:"
  echo "COMMAND: curl -X $REQUEST_TYPE \"$ORDER_CUSTOMERS_URL?order_by=updated_at\""
  RESPONSE=$(curl -s -w "\n%{http_code}" -X $REQUEST_TYPE "$ORDER_CUSTOMERS_URL?order_by=updated_at")
  HTTP_BODY=$(echo "$RESPONSE" | sed '$ d')
  HTTP_STATUS=$(echo "$RESPONSE" | tail -n1)
  echo "Response Body: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "✅ Customers ordered by updated_at."
  else
    echo "❌ Failed to order customers by updated_at."
  fi

  # Test with an invalid 'order_by' parameter (should default)
  echo "Testing ordering with invalid 'order_by' field (should default):"
  echo "COMMAND: curl -X $REQUEST_TYPE \"$ORDER_CUSTOMERS_URL?order_by=invalid_field\""
  RESPONSE=$(curl -s -w "\n%{http_code}" -X $REQUEST_TYPE "$ORDER_CUSTOMERS_URL?order_by=invalid_field")
  HTTP_BODY=$(echo "$RESPONSE" | sed '$ d')
  HTTP_STATUS=$(echo "$RESPONSE" | tail -n1)
  echo "Response Body: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "✅ Customers ordered with invalid 'order_by' field (default applied)."
  else
    echo "❌ Failed to apply default ordering."
  fi

  echo
}


# Function to get activated customer names
get_activated_customers() {
  echo "===>TEST END POINT--->GET ACTIVATED CUSTOMERS"
  echo
  echo "REQUEST URL: $GET_ACTIVATED_CUSTOMERS_URL"

  # Define the HTTP request type
  REQUEST_TYPE="GET"
  echo "REQUEST TYPE: $REQUEST_TYPE"

  # Send GET request to the endpoint
  echo "COMMAND: curl -X $REQUEST_TYPE \"$GET_ACTIVATED_CUSTOMERS_URL\""
  RESPONSE=$(curl -s -w "\n%{http_code}" -X $REQUEST_TYPE "$GET_ACTIVATED_CUSTOMERS_URL")

  # Extract response body and HTTP status code
  HTTP_BODY=$(echo "$RESPONSE" | sed '$ d')
  HTTP_STATUS=$(echo "$RESPONSE" | tail -n1)

  # Display the response body and status code
  echo "Response Body: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  # Check if the HTTP status code is 200
  if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "✅ Successfully retrieved activated customer names."
  else
    echo "❌ Failed to fetch activated customer names."
  fi

  echo
}



# Function to get all logged-in customers
get_logged_in_customers() {
  echo "===>TEST END POINT--->GET LOGGED-IN CUSTOMERS"
  echo
  echo "REQUEST URL: $GET_LOGGED_IN_CUSTOMERS_URL"

  # Define the HTTP request type
  REQUEST_TYPE="GET"
  echo "REQUEST TYPE: $REQUEST_TYPE"

  # Send GET request to the endpoint
  echo "COMMAND: curl -X $REQUEST_TYPE \"$GET_LOGGED_IN_CUSTOMERS_URL\" -H \"Content-Type: application/json\""
  RESPONSE=$(curl -s -w "\n%{http_code}" -X $REQUEST_TYPE "$GET_LOGGED_IN_CUSTOMERS_URL" -H "Content-Type: application/json")

  # Extract response body and HTTP status code
  HTTP_BODY=$(echo "$RESPONSE" | sed '$ d')
  HTTP_STATUS=$(echo "$RESPONSE" | tail -n1)

  # Display the response body and status code
  echo "Response Body: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  # Check if the HTTP status code is 200
  if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "✅ Successfully retrieved logged-in customers."
  else
    echo "❌ Failed to fetch logged-in customers."
  fi

  echo
}


# Function to delete customer
delete_customer() {
  echo "===>TEST END POINT--->DELETE CUSTOMER"
  echo
  echo "REQUEST URL: $DELETE_CUSTOMER_URL"

  # Define the HTTP request type
  REQUEST_TYPE="DELETE"
  echo "REQUEST TYPE: $REQUEST_TYPE"
  
  # Construct the request body
  JSON_BODY=$(jq -n --arg customername "$CUSTOMERNAME" '{customername: $customername}')
  echo "JSON BODY: $JSON_BODY"

  # Log the full curl command and JSON body
  echo "COMMAND: curl -X $REQUEST_TYPE \"$DELETE_CUSTOMER_URL\" -H \"Content-Type: application/json\" -d \"$JSON_BODY\""
  
  # Send the DELETE request and capture the response
  DELETE_RESPONSE=$(curl -s -w "\n%{http_code}" -X $REQUEST_TYPE "$DELETE_CUSTOMER_URL" -H "Content-Type: application/json" -d "$JSON_BODY")

  # Extract response body and HTTP status code
  HTTP_BODY=$(echo "$DELETE_RESPONSE" | sed '$ d')
  HTTP_STATUS=$(echo "$DELETE_RESPONSE" | tail -n1)

  # Display the response and HTTP status code
  echo "Delete response body: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  # Check if the HTTP status code is 200
  if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "✅ Customer deleted successfully."
  else
    echo "❌ Error: Customer deletion failed."
    exit 1
  fi

  echo
}



show_database_table(){
  
  # Get the container ID using the container name
  CONTAINER_ID=$(docker ps -qf "name=$CUSTOMER_POSTGRES_DB_CONTAINER_NAME")

  # Check if the container exists
  if [ -z "$CONTAINER_ID" ]; then
      echo "Error: No running container found with name '$CONTAINER_NAME'."
      exit 1
  fi

  # Run the query to list all rows in the 'customers' table
  docker exec -i "$CONTAINER_ID" psql -U "$CUSTOMER_POSTGRES_DB_USER" -d "$CUSTOMER_POSTGRES_DB_NAME" -c "SELECT * FROM customers;"

}

### **🚀 TEST EXECUTION FLOW 🚀**


health_check

register_customer

login_customer
show_database_table

deactivate_customer
show_database_table

activate_customer
show_database_table

update_email
show_database_table

update_password
show_database_table

insert_note
show_database_table

update_note
show_database_table

update_customer
show_database_table

order_customers

get_activated_customers

get_logged_in_customers

delete_customer
show_database_table

# Final message
echo "ALL TESTS ARE DONE!!!"
