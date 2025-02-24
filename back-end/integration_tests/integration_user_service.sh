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

echo -e "********************************************************************"
echo -e "✅✅✅ $USER_SERVICE_NAME API END POINT INTEGRATION TESTS STARTS..."
echo -e "********************************************************************"

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
BASE_URL="http://localhost:$USER_SERVICE_PORT"
HEALTH_CHECK_URL="$BASE_URL/health"
REGISTER_URL="$BASE_URL/register"
LOGIN_URL="$BASE_URL/login"
USER_URL="$BASE_URL/user"


# (Require JWT authentication)
UPDATE_PASSWORD_URL="$BASE_URL/update-password"
UPDATE_USER_URL="$BASE_URL/update-user"
DEACTIVATE_USER_URL="$BASE_URL/deactivate-user"
ACTIVATE_USER_URL="$BASE_URL/activate-user"
UPDATE_EMAIL_URL="$BASE_URL/update-email"
UPDATE_ROLE_URL="$BASE_URL/update-role"
DELETE_USER_URL="$BASE_URL/delete-user"


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

# Function to log in and get JWT token
login_user() {
  echo "===>TEST END POINT-->LOGIN USER"
  echo
  echo "REQUEST URL: $LOGIN_URL"
  
  # Prepare the request body
  JSON_BODY='{
    "mailAddress": "'$MAILADDRESS'",
    "password": "'$PASSWORD'"
  }'

  # Define the HTTP request type
  REQUEST_TYPE="POST"

  # Print the full curl command and request type
  echo "REQUEST TYPE: $REQUEST_TYPE"
  echo "COMMAND: curl -X $REQUEST_TYPE \"$LOGIN_URL\" -H \"Content-Type: application/json\" -d '$JSON_BODY'"
  
  # Print the JSON body
  echo "JSON BODY: $JSON_BODY"
  
  # Send the request and capture the response
  LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" -X $REQUEST_TYPE "$LOGIN_URL" -H "Content-Type: application/json" -d "$JSON_BODY")
  
  # Extract response body and HTTP status code
  HTTP_BODY=$(echo "$LOGIN_RESPONSE" | sed '$ d')
  HTTP_STATUS=$(echo "$LOGIN_RESPONSE" | tail -n1)

  echo "Login response: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  JWT_TOKEN=$(echo "$HTTP_BODY" | jq -r '.token')

  if [[ "$JWT_TOKEN" == "null" || -z "$JWT_TOKEN" ]]; then
    echo "❌ Error: JWT token not received from login."
    exit 1
  fi

  echo "✅ Login successful. JWT token received."
  echo
}




# Function to get user details
get_user_details() {
  echo "===>TEST END POINT-->GET USER DETAILS"
  echo
  echo "REQUEST URL: $USER_URL?username=$USERNAME"
  
  # Define the HTTP request type
  REQUEST_TYPE="GET"
  
  # Print the full curl command and request type
  echo "REQUEST TYPE: $REQUEST_TYPE"
  echo "COMMAND: curl -X $REQUEST_TYPE \"$USER_URL?username=$USERNAME\" -H \"Authorization: Bearer $JWT_TOKEN\""
  
  # Send the request and capture the response
  RESPONSE=$(curl -s -X $REQUEST_TYPE "$USER_URL?username=$USERNAME" -H "Authorization: Bearer $JWT_TOKEN")
  
  # Print the response body
  echo "Response: $RESPONSE"
  
  # Parse the user ID from the response
  USER_ID=$(echo "$RESPONSE" | jq -r '.ID')

  if [[ "$USER_ID" == "null" || -z "$USER_ID" ]]; then
    echo "❌ Error: Could not retrieve user ID."
    exit 1
  fi

  echo "✅ User ID retrieved: $USER_ID"
  echo
}

# Function to deactivate user
deactivate_user() {
  echo "===>TEST END POINT-->DEACTIVATE USER"
  echo
  echo "REQUEST URL: $DEACTIVATE_USER_URL"
  
  # Construct JSON payload
  JSON_PAYLOAD=$(jq -n --arg username "$USERNAME" '{username: $username}')

   # Print the JSON payload
  echo "JSON BODY: $JSON_PAYLOAD"

  # Define the HTTP request type
  REQUEST_TYPE="PUT"
  
  # Print the full curl command and request type
  echo "REQUEST TYPE: $REQUEST_TYPE"
  echo "COMMAND: curl -X $REQUEST_TYPE \"$DEACTIVATE_USER_URL\" -H \"Authorization: Bearer $JWT_TOKEN\" -H \"Content-Type: application/json\" -d '$JSON_PAYLOAD'"
  
  # Make the PUT request with JSON body
  DEACTIVATE_RESPONSE=$(curl -s -w "%{http_code}" -X $REQUEST_TYPE "$DEACTIVATE_USER_URL" \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD")
  
  # Extract response body and HTTP status code
  HTTP_BODY=$(echo "$DEACTIVATE_RESPONSE" | sed '$ d')
  HTTP_STATUS=$(echo "$DEACTIVATE_RESPONSE" | tail -n1)

  # Print the response
  echo "Deactivate response: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  if [ "$HTTP_STATUS" -ne 200 ]; then
    echo "❌ Error: User deactivation failed."
    exit 1
  fi

  echo "✅ User deactivated successfully."
  echo
}

# Function to activate user
activate_user() {
  echo "===>TEST END POINT-->ACTIVATE USER"
  echo
  echo "REQUEST URL: $ACTIVATE_USER_URL"
  
  # Construct JSON payload
  JSON_PAYLOAD=$(jq -n --arg username "$USERNAME" '{username: $username}')

  # Print the JSON payload
  echo "JSON BODY: $JSON_PAYLOAD"

  # Define the HTTP request type
  REQUEST_TYPE="PUT"
  
  # Print the full curl command and request type
  echo "REQUEST TYPE: $REQUEST_TYPE"
  echo "COMMAND: curl -X $REQUEST_TYPE \"$ACTIVATE_USER_URL\" -H \"Authorization: Bearer $JWT_TOKEN\" -H \"Content-Type: application/json\" -d '$JSON_PAYLOAD'"

  # Make the PUT request with JSON body
  ACTIVATE_RESPONSE=$(curl -s -w "%{http_code}" -X $REQUEST_TYPE "$ACTIVATE_USER_URL" \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD")
  
  # Extract response body and HTTP status code
  HTTP_BODY=$(echo "$ACTIVATE_RESPONSE" | sed '$ d')
  HTTP_STATUS=$(echo "$ACTIVATE_RESPONSE" | tail -n1)

  # Print the response
  echo "Activate response: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  if [ "$HTTP_STATUS" -ne 200 ]; then
    echo "❌ Error: User activation failed."
    exit 1
  fi

  echo "✅ User activated successfully."
  echo
}


# Function to update user details
update_user() {
  echo "===>TEST END POINT-->UPDATE USER"
  echo
  echo "REQUEST URL: $UPDATE_USER_URL"
  
  # Construct JSON payload dynamically
  JSON_PAYLOAD=$(jq -n \
    --arg username "$USERNAME" \
    --arg email "$EMAIL" \
    --arg role "$ROLE" \
    '{
      username: $username,
      email: ($email // empty),
      role: ($role // empty)
    }')

  # Print the JSON payload
  echo "JSON BODY: $JSON_PAYLOAD"

  # Define the HTTP request type
  REQUEST_TYPE="PUT"
  
  # Print the full curl command and request type
  echo "REQUEST TYPE: $REQUEST_TYPE"
  echo "COMMAND: curl -X $REQUEST_TYPE \"$UPDATE_USER_URL\" -H \"Authorization: Bearer $JWT_TOKEN\" -H \"Content-Type: application/json\" -d '$JSON_PAYLOAD'"

  # Make the PUT request with JSON body
  UPDATE_USER_RESPONSE=$(curl -s -w "%{http_code}" -X $REQUEST_TYPE "$UPDATE_USER_URL" \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD")

  # Extract HTTP status and response body
  HTTP_BODY=$(echo "$UPDATE_USER_RESPONSE" | sed '$ d')
  HTTP_STATUS=$(echo "$UPDATE_USER_RESPONSE" | tail -n1)

  # Print the response
  echo "Update response: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  if [ "$HTTP_STATUS" -ne 200 ]; then
    echo "❌ Error: User update failed."
    exit 1
  fi

  echo "✅ User updated successfully."
  echo
}


# Function to update user password
update_password() {
  echo "===>TEST END POINT-->UPDATE NEW PASSWORD"
  echo
  echo "REQUEST URL: $UPDATE_PASSWORD_URL"
  
  # Construct JSON payload dynamically
  JSON_PAYLOAD=$(jq -n \
    --arg username "$USERNAME" \
    --arg new_password "$NEW_PASSWORD" \
    '{
      username: $username,
      new_password: $new_password
    }')

  # Print the JSON payload
  echo "JSON BODY: $JSON_PAYLOAD"

  # Define the HTTP request type
  REQUEST_TYPE="POST"
  
  # Print the full curl command and request type
  echo "REQUEST TYPE: $REQUEST_TYPE"
  echo "COMMAND: curl -X $REQUEST_TYPE \"$UPDATE_PASSWORD_URL\" -H \"Authorization: Bearer $JWT_TOKEN\" -H \"Content-Type: application/json\" -d '$JSON_PAYLOAD'"

  # Make the POST request with JSON body
  UPDATE_PASSWORD_RESPONSE=$(curl -s -w "%{http_code}" -X $REQUEST_TYPE "$UPDATE_PASSWORD_URL" \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD")

  # Extract HTTP status and response body
  HTTP_BODY="${UPDATE_PASSWORD_RESPONSE%???}"
  HTTP_STATUS="${UPDATE_PASSWORD_RESPONSE: -3}"

  # Print the response
  echo "Update password response: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  if [ "$HTTP_STATUS" -ne 200 ]; then
    echo "❌ Error: Password update failed."
    exit 1
  fi

  echo "✅ Password updated successfully."
  echo
}


# Function to update user email address
update_email() {
  echo "===>TEST END POINT-->UPDATE EMAIL ADDRESS"
  echo
  echo "REQUEST URL: $UPDATE_EMAIL_URL"

  # Construct JSON payload dynamically
  JSON_PAYLOAD=$(jq -n \
    --arg username "$USERNAME" \
    --arg new_email "$NEW_EMAIL" \
    '{
      username: $username,
      new_email: $new_email
    }')

  # Print the JSON payload
  echo "JSON BODY: $JSON_PAYLOAD"

  # Define the HTTP request type
  REQUEST_TYPE="PUT"

  # Print the full curl command and request type
  echo "REQUEST TYPE: $REQUEST_TYPE"
  echo "COMMAND: curl -X $REQUEST_TYPE \"$UPDATE_EMAIL_URL\" -H \"Authorization: Bearer $JWT_TOKEN\" -H \"Content-Type: application/json\" -d '$JSON_PAYLOAD'"

  # Make the PUT request with JSON body
  UPDATE_EMAIL_RESPONSE=$(curl -s -w "%{http_code}" -X $REQUEST_TYPE "$UPDATE_EMAIL_URL" \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD")

  # Extract HTTP status and response body
  HTTP_BODY="${UPDATE_EMAIL_RESPONSE%???}"
  HTTP_STATUS="${UPDATE_EMAIL_RESPONSE: -3}"

  # Print the response
  echo "Update email response: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  if [ "$HTTP_STATUS" -ne 200 ]; then
    echo "❌ Error: Email update failed."
    exit 1
  fi

  echo "✅ Email updated successfully."
  echo
}


# Function to update user role
update_role() {
  echo "===>TEST END POINT-->UPDATE USER ROLE"
  echo
  echo "REQUEST URL: $UPDATE_ROLE_URL"

  # Construct JSON payload dynamically
  JSON_PAYLOAD=$(jq -n \
    --arg username "$USERNAME" \
    --arg role "$NEW_ROLE" \
    '{
      username: $username,
      role: $role
    }')

  # Print the JSON payload
  echo "JSON BODY: $JSON_PAYLOAD"

  # Define the HTTP request type
  REQUEST_TYPE="PUT"

  # Print the full curl command and request type
  echo "REQUEST TYPE: $REQUEST_TYPE"
  echo "COMMAND: curl -X $REQUEST_TYPE \"$UPDATE_ROLE_URL\" -H \"Authorization: Bearer $JWT_TOKEN\" -H \"Content-Type: application/json\" -d '$JSON_PAYLOAD'"

  # Make the PUT request with JSON body
  UPDATE_ROLE_RESPONSE=$(curl -s -w "%{http_code}" -X $REQUEST_TYPE "$UPDATE_ROLE_URL" \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD")

  # Extract HTTP status and response body
  HTTP_BODY="${UPDATE_ROLE_RESPONSE%???}"
  HTTP_STATUS="${UPDATE_ROLE_RESPONSE: -3}"

  # Print the response
  echo "Update role response: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  if [ "$HTTP_STATUS" -ne 200 ]; then
    echo "❌ Error: Role update failed."
    exit 1
  fi

  echo "✅ Role updated successfully."
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
  CONTAINER_ID=$(docker ps -qf "name=$USER_POSTGRES_DB_CONTAINER_NAME")

  # Check if the container exists
  if [ -z "$CONTAINER_ID" ]; then
      echo "Error: No running container found with name '$CONTAINER_NAME'."
      exit 1
  fi

  # Run the query to list all rows in the 'users' table
  docker exec -i "$CONTAINER_ID" psql -U "$USER_POSTGRES_DB_USER" -d "$USER_POSTGRES_DB_NAME" -c "SELECT * FROM users;"

}

### **🚀 TEST EXECUTION FLOW 🚀**


health_check

register_user
show_database_table

login_user
show_database_table

deactivate_user
show_database_table

activate_user
show_database_table

update_email
show_database_table

update_password
show_database_table

update_role
show_database_table

update_user
show_database_table

delete_user
show_database_table

# Final message
echo "ALL TESTS ARE DONE!!!"
