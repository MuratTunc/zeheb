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
MAILADDRESS="testuser@example.com"
PASSWORD="TestPassword123"
ROLE="Admin"

# Define new parameters
NEW_PASSWORD="NewTestPassword123"
NEW_EMAIL="newmail@example.com"
NEW_ROLE="MANAGER"


# Define API URLs
# Read port from .env file
BASE_URL="http://localhost:$MAIL_SERVICE_PORT"
HEALTH_CHECK_URL="$BASE_URL/health"



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

# Function to check if the user exists (using the registration endpoint)
register_user() {
  echo "===>TEST END POINT-->REGISTER NEW USER"
  echo
  echo "REQUEST URL: $REGISTER_URL"
  
  # Prepare the request body
  REQUEST_BODY='{
    "username": "'$USERNAME'",
    "mailAddress": "'$MAILADDRESS'",
    "password": "'$PASSWORD'",
    "role": "'$ROLE'"
  }'

  # Define the HTTP request type
  REQUEST_TYPE="POST"

  # Print the full curl command and request type
  echo "REQUEST TYPE: $REQUEST_TYPE"
  echo "COMMAND: curl -X $REQUEST_TYPE \"$REGISTER_URL\" -H \"Content-Type: application/json\" -d '$REQUEST_BODY'"
  
  # Send the request and capture the response
  REGISTER_RESPONSE=$(curl -s -w "\n%{http_code}" -X $REQUEST_TYPE "$REGISTER_URL" -H "Content-Type: application/json" -d "$REQUEST_BODY")
  
  
  HTTP_BODY=$(echo "$REGISTER_RESPONSE" | sed '$ d')
  HTTP_STATUS=$(echo "$REGISTER_RESPONSE" | tail -n1)

  echo "Registration response: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "User registered successfully!"
  elif [ "$HTTP_STATUS" -eq 409 ]; then
    echo "User already exists...Deleting this user to continue test..."
    delete_user
  else
    echo "Registration failed with status code $HTTP_STATUS. Response: $HTTP_BODY"
    exit 1
  fi
  
  echo "✅ Register New User User successfully"
  echo
}

# Function to delete user by username
delete_user() {
  echo "===>TEST END POINT-->DELETE USER"
  echo
  echo "REQUEST URL: $DELETE_USER_URL"

  # Construct JSON payload dynamically
  JSON_PAYLOAD=$(jq -n --arg username "$USERNAME" '{username: $username}')

  # Print the JSON payload
  echo "JSON BODY: $JSON_PAYLOAD"

  # Define the HTTP request type
  REQUEST_TYPE="DELETE"

  # Print the full curl command and request type
  echo "REQUEST TYPE: $REQUEST_TYPE"
  echo "COMMAND: curl -X $REQUEST_TYPE \"$DELETE_USER_URL\" -H \"Authorization: Bearer $JWT_TOKEN\" -H \"Content-Type: application/json\" -d '$JSON_PAYLOAD'"

  # Perform the DELETE request and capture both status code and response body
  DELETE_RESPONSE=$(curl -s -w "%{http_code}" -X $REQUEST_TYPE "$DELETE_USER_URL" \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD")

  # Extract the response body and HTTP status code
  HTTP_STATUS=$(echo "$DELETE_RESPONSE" | tail -n1)  # Extract the last line as the HTTP status code
  HTTP_BODY=$(echo "$DELETE_RESPONSE" | sed '$ d')   # Remove the last line (HTTP status code) to get the body

  # Print the response
  echo "Delete response: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  # Check if the HTTP status code is 200
  if [ "$HTTP_STATUS" -ne 200 ]; then
    echo "❌ Error: User deletion failed."
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


show_database_table

# Final message
echo "ALL TESTS ARE DONE!!!"
