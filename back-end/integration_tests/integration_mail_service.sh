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

# Define user details
USERNAME="testuser"
MAILADDRESS="murat.tunc8558@gmail.com"


# Define API URLs
# Read port from .env file
BASE_URL="http://localhost:$MAIL_SERVICE_PORT"
HEALTH_CHECK_URL="$BASE_URL/health"
SEND_AUTH_CODE_MAIL_URL="$BASE_URL/send-auth-code-mail"
DELETE_MAIL_URL="$BASE_URL/delete-mail"



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

# Function to test sending an authentication code via email
send_auth_code_mail() {
  echo "===>TEST END POINT-->SEND AUTH CODE MAIL"
  echo
  echo "REQUEST URL: $SEND_AUTH_CODE_MAIL_URL"

  # Prepare the request body
  REQUEST_BODY='{
    "username": "'$USERNAME'",
    "mailAddress": "'$MAILADDRESS'"
  }'

  # Define the HTTP request type
  REQUEST_TYPE="POST"

  # Print the full curl command and request type
  echo "REQUEST TYPE: $REQUEST_TYPE"
  echo "COMMAND: curl -X $REQUEST_TYPE \"$SEND_AUTH_CODE_MAIL_URL\" -H \"Content-Type: application/json\" -d '$REQUEST_BODY'"

  # Send the request and capture the response
  SEND_AUTH_CODE_MAIL_RESPONSE=$(curl -s -w "\n%{http_code}" -X $REQUEST_TYPE "$SEND_AUTH_CODE_MAIL_URL" -H "Content-Type: application/json" -d "$REQUEST_BODY")

  # Extract response body and HTTP status code
  HTTP_BODY=$(echo "$SEND_AUTH_CODE_MAIL_RESPONSE" | sed '$ d')
  HTTP_STATUS=$(echo "$SEND_AUTH_CODE_MAIL_RESPONSE" | tail -n1)

  echo "Send Auth Code Mail response: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  # Check if the HTTP status code is 200
  if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "✅ Authentication code sent successfully!"
  else
    echo "❌ Error: Failed to send authentication code."
    exit 1
  fi

  echo
}


# Function to delete user by username and mail address
delete_mail() {
  echo "===>TEST END POINT-->DELETE USER"
  echo
  echo "REQUEST URL: $DELETE_MAIL_URL"  # Using DELETE_MAIL_URL parameter

  # Prepare the request body with both username and mailAddress
  REQUEST_BODY='{
    "username": "'$USERNAME'",
    "mailAddress": "'$MAILADDRESS'"
  }'

  # Define the HTTP request type
  REQUEST_TYPE="DELETE"

  # Print the full curl command and request type
  echo "REQUEST TYPE: $REQUEST_TYPE"
  echo "COMMAND: curl -X $REQUEST_TYPE \"$DELETE_MAIL_URL\" -H \"Content-Type: application/json\" -d '$REQUEST_BODY'"

  # Send the request and capture the response
  DELETE_RESPONSE=$(curl -s -w "\n%{http_code}" -X $REQUEST_TYPE "$DELETE_MAIL_URL" -H "Content-Type: application/json" -d "$REQUEST_BODY")

  # Extract response body and HTTP status code
  HTTP_BODY=$(echo "$DELETE_RESPONSE" | sed '$ d')
  HTTP_STATUS=$(echo "$DELETE_RESPONSE" | tail -n1)

  echo "Delete response: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "User deleted successfully!"
  else
    echo "❌ User deletion failed with status code $HTTP_STATUS. Response: $HTTP_BODY"
    exit 1
  fi

  echo "✅ User deleted successfully."
  echo
}


show_database_table(){
  
  # Get the container ID using the container name
  CONTAINER_ID=$(docker ps -qf "name=$MAIL_POSTGRES_DB_CONTAINER_NAME")

  # Check if the container exists
  if [ -z "$CONTAINER_ID" ]; then
      echo "Error: No running container found with name '$CONTAINER_NAME'."
      exit 1
  fi

  # Run the query to list all rows in the 'users' table
  docker exec -i "$CONTAINER_ID" psql -U "$MAIL_POSTGRES_DB_USER" -d "$MAIL_POSTGRES_DB_NAME" -c "SELECT * FROM users;"

}

### **🚀 TEST EXECUTION FLOW 🚀**


health_check

#send_auth_code_mail
delete_mail
show_database_table

# Final message
echo "ALL TESTS ARE DONE!!!"
