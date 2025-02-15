#!/bin/bash

# Load environment variables from .env file
ENV_FILE="../build-tools/.env"
if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC2046
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


# Define API URLs
# Read port from .env file
BASE_URL="http://localhost:$SALESTRACKING_SERVICE_PORT"
HEALTH_CHECK_URL="$BASE_URL/health"
INSERT_SALE_URL="$BASE_URL/insert-sale"
DELETE_SALE_URL="$BASE_URL/delete-sale"
UPDATE_INCOMMUNICATION_URL="$BASE_URL/update-incommunication"
UPDATE_DEAL_URL="$BASE_URL/update-deal"
UPDATE_CLOSED_URL="$BASE_URL/update-closed"

# Set test data
SALENAME="TestSale123"
NOTE="This is a test note for the sale record."

UPDATED_NOTE="This is the completely new note."
IN_COMMUNICATION="true"
DEAL="true"

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

# Function to insert a new sale record
insert_sale() {
  echo "===>TEST END POINT--->INSERT NEW SALE RECORD"
  echo
  echo "REQUEST URL: $INSERT_SALE_URL"

  # Define the HTTP request type
  REQUEST_TYPE="POST"

  # Define request payload
  JSON_BODY='{
    "salename": "'"$SALENAME"'",
    "note": "'"$NOTE"'"
  }'

  # Print request details
  echo "REQUEST_TYPE: $REQUEST_TYPE"
  echo "JSON_BODY: $JSON_BODY"

  # Echo the curl command
  echo "Curl Command: curl -X $REQUEST_TYPE \"$INSERT_SALE_URL\" -H \"Content-Type: application/json\" -d '$JSON_BODY'"

  # Send POST request to insert a new sale record
  INSERT_SALE_RESPONSE=$(curl -s -w "\n%{http_code}" -X "$REQUEST_TYPE" "$INSERT_SALE_URL" -H "Content-Type: application/json" -d "$JSON_BODY")

  # Extract response body and HTTP status code
  HTTP_BODY=$(echo "$INSERT_SALE_RESPONSE" | sed '$ d')
  HTTP_STATUS=$(echo "$INSERT_SALE_RESPONSE" | tail -n1)

  echo "Insert sale response body: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  # Check response status
  if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "Sale record inserted successfully!"
  elif [ "$HTTP_STATUS" -eq 409 ]; then
    echo "⚠️ Sale with this name already exists."
  else
    echo "❌ Sale insertion failed with status code $HTTP_STATUS. Response: $HTTP_BODY"
    exit 1
  fi

  echo "✅ INSERT NEW SALE RECORD successfully"
  echo
}


# Function to update the in_communication field for a sale record
update_incommunication() {

  echo "===>TEST END POINT--->UPDATE INCOMMUNICATION FIELD"
  echo
  echo "Salename: $SALENAME"
  echo "InCommunication: $IN_COMMUNICATION"
  echo "Note: $UPDATED_NOTE"
  echo "URL: $UPDATE_INCOMMUNICATION_URL"

  # Define the HTTP request type
  REQUEST_TYPE="PUT"

  # Define the JSON_BODY
  JSON_BODY=$(jq -n \
    --arg salename "$SALENAME" \
    --argjson in_communication "$IN_COMMUNICATION" \
    --arg note "$UPDATED_NOTE" \
    '{salename: $salename, in_communication: $in_communication, note: $note}')

  # Echo the request details
  echo "REQUEST_TYPE: $REQUEST_TYPE"
  echo "JSON Payload: $JSON_BODY"

  # Echo the curl command
  echo "Curl Command: curl -X $REQUEST_TYPE \"$UPDATE_INCOMMUNICATION_URL\" -H \"Content-Type: application/json\" -d \"$JSON_BODY\""

  # Send PUT request with the proper fields, including the note
  UPDATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X "$REQUEST_TYPE" "$UPDATE_INCOMMUNICATION_URL" -H "Content-Type: application/json" -d "$JSON_BODY")

  # Extract response body and HTTP status code
  HTTP_BODY=$(echo "$UPDATE_RESPONSE" | sed '$ d')
  HTTP_STATUS=$(echo "$UPDATE_RESPONSE" | tail -n1)

  echo "Update response: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  # Check the response status
  if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "Sale record updated successfully!"
  else
    echo "❌ Error: Failed to update sale record. Status code: $HTTP_STATUS"
    exit 1
  fi

  echo "✅ UPDATE INCOMMUNICATION successfully"
  echo
}


# Function to update Deal field
update_deal() {
  echo "===>TEST END POINT--->UPDATE DEAL FIELD"
  echo
  echo "Salename: $SALENAME"
  echo "Deal: $DEAL"
  echo "Note: $UPDATED_NOTE"
  echo "URL: $UPDATE_DEAL_URL"

  # Define the HTTP request type
  REQUEST_TYPE="PUT"

  # Echo the REQUEST_TYPE for clarity
  echo "REQUEST_TYPE: $REQUEST_TYPE"

  # Echo the curl command for clarity
  echo "curl -s -w \"%{http_code}\" -X $REQUEST_TYPE \"$UPDATE_DEAL_URL\" -H \"Content-Type: application/json\" -d '{
    \"salename\": \"$SALENAME\",
    \"deal\": $DEAL,
    \"note\": \"$UPDATED_NOTE\"
  }'"

  # Perform the PUT request to update the sale record and capture both status code and response body
  UPDATE_DEAL_RESPONSE=$(curl -s -w "%{http_code}" -X "$REQUEST_TYPE" "$UPDATE_DEAL_URL" -H "Content-Type: application/json" -d '{
    "salename": "'"$SALENAME"'",
    "deal": '"$DEAL"',
    "note": "'"$UPDATED_NOTE"'"
  }')

  # Extract the response body and HTTP status code
  HTTP_STATUS="${UPDATE_DEAL_RESPONSE: -3}"
  HTTP_BODY="${UPDATE_DEAL_RESPONSE%???}"

  echo "Update response: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  # Check if the HTTP status code is 200
  if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "Sale record updated successfully!"
  else
    echo "Error: Failed to update sale record."
    exit 1
  fi

  # Success message
  echo "✅ UPDATE DEAL FIELD successfully"
  echo
}

# Function to update the Closed field
update_closed() {
 
  echo "===>TEST END POINT--->UPDATE CLOSED FIELD"
  echo
  echo "Salename: $SALENAME"
  echo "Note: $UPDATED_NOTE"
  echo "URL: $UPDATE_CLOSED_URL"

  # Define the HTTP request type
  REQUEST_TYPE="PUT"

  # Echo the REQUEST_TYPE for clarity
  echo "REQUEST_TYPE: $REQUEST_TYPE"

  # Echo the curl command for clarity
  echo "curl -s -w \"%{http_code}\" -X $REQUEST_TYPE \"$UPDATE_CLOSED_URL\" -H \"Content-Type: application/json\" -d '{
    \"salename\": \"$SALENAME\",
    \"note\": \"$UPDATED_NOTE\"
  }'"

  # Perform the PUT request to update the sale record and capture both status code and response body
  UPDATE_CLOSED_RESPONSE=$(curl -s -w "%{http_code}" -X "$REQUEST_TYPE" "$UPDATE_CLOSED_URL" -H "Content-Type: application/json" -d '{
    "salename": "'"$SALENAME"'",
    "note": "'"$UPDATED_NOTE"'"
  }')

  # Extract the response body and HTTP status code
  HTTP_STATUS="${UPDATE_CLOSED_RESPONSE: -3}"
  HTTP_BODY="${UPDATE_CLOSED_RESPONSE%???}"

  echo "Update response: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  # Check if the HTTP status code is 200
  if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "Sale record closed successfully!"
  else
    echo "Error: Failed to close sale record."
    exit 1
  fi

  # Success message
  echo "✅ UPDATE CLOSED FIELD successfully"
  echo
}


# Function to delete a sale
delete_sale() {

  echo "===>TEST END POINT---> DELETE SALE"
  echo
  echo "SALE NAME: $SALENAME"
  echo "URL: $DELETE_SALE_URL"

  # Define the HTTP request type
  REQUEST_TYPE="DELETE"

  # Echo the REQUEST_TYPE for clarity
  echo "REQUEST_TYPE: $REQUEST_TYPE"

  # Echo the curl command for clarity
  echo "curl -s -w \"%{http_code}\" -X $REQUEST_TYPE \"$DELETE_SALE_URL\" -H \"Content-Type: application/json\" -d '{
    \"salename\": \"$SALENAME\"
  }'"

  # Perform the DELETE request and capture both status code and response body
  DELETE_RESPONSE=$(curl -s -w "%{http_code}" -X "$REQUEST_TYPE" "$DELETE_SALE_URL" -H "Content-Type: application/json" -d '{
    "salename": "'"$SALENAME"'"
  }')

  # Extract the response body and HTTP status code
  HTTP_STATUS="${DELETE_RESPONSE: -3}"
  HTTP_BODY="${DELETE_RESPONSE%???}"

  echo "Delete response: $HTTP_BODY"
  echo "HTTP Status Code: $HTTP_STATUS"

  # Check if the HTTP status code is 200
  if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "Sale deleted successfully."
  elif [ "$HTTP_STATUS" -eq 404 ]; then
    echo "❌ Sale not found."
  else
    echo "❌ Sale deletion failed with status code $HTTP_STATUS. Response: $HTTP_BODY"
    exit 1
  fi

  # Success message
  echo "✅ DELETE SALE successfully"
  echo
}



show_database_table(){
  
  # Get the container ID using the container name
  CONTAINER_ID=$(docker ps -qf "name=$SALESTRACKING_POSTGRES_DB_CONTAINER_NAME")

  # Check if the container exists
  if [ -z "$CONTAINER_ID" ]; then
      echo "Error: No running container found with name '$CONTAINER_NAME'."
      exit 1
  fi

  # Run the query to list all rows in the 'customers' table
  docker exec -i "$CONTAINER_ID" psql -U "$SALESTRACKING_POSTGRES_DB_USER" -d "$SALESTRACKING_POSTGRES_DB_NAME" -c "SELECT * FROM sales;"

}

### **🚀 TEST EXECUTION FLOW 🚀**


health_check

insert_sale
show_database_table

update_incommunication
show_database_table

IN_COMMUNICATION=false
update_incommunication
show_database_table

update_deal
show_database_table

update_closed
show_database_table

delete_sale
show_database_table



# Final message
echo "ALL TESTS ARE DONE!!!"
