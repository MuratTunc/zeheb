#!/bin/bash

# Load environment variables from .env file
ENV_FILE="../build-tools/.env"
if [ -f "$ENV_FILE" ]; then
  export $(grep -v '^#' "$ENV_FILE" | xargs)
else
  echo "⚠️ .env file not found at $ENV_FILE"
  exit 1
fi

# Get the container ID using the container name
CONTAINER_ID=$(docker ps -qf "name=$CUSTOMER_POSTGRES_DB_CONTAINER_NAME")

# Check if the container exists
if [ -z "$CONTAINER_ID" ]; then
  echo "Error: No running container found with name '$CUSTOMER_POSTGRES_DB_CONTAINER_NAME'."
  exit 1
fi

echo "🚀 Deleting all rows from the 'customers' table..."

# Run the query to delete all rows from the 'customers' table
docker exec -i "$CONTAINER_ID" psql -U "$CUSTOMER_POSTGRES_DB_USER" -d "$CUSTOMER_POSTGRES_DB_NAME" -c "DELETE FROM customers;"

# Verify that the table is empty
echo "🔍 Verifying deletion..."
docker exec -i "$CONTAINER_ID" psql -U "$CUSTOMER_POSTGRES_DB_USER" -d "$CUSTOMER_POSTGRES_DB_NAME" -c "SELECT * FROM customers;"

echo "✅ All rows deleted successfully from 'customers' table!"
