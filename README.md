# Product-Price Inquiry System

## Flow Explanation

### 1. Buyer App Sends Request to Main Service
- The **buyer app** sends a request to the **main service** asking for a price (e.g., through the `/buyer/giveprice` endpoint).
- The **main service** stores the buyer’s request in its database (or Redis).
- At this point, the **main service** might notify the **seller service** or have the seller service periodically check the **main service** for new requests.

### 2. Seller Service Receives Request from Main Service
- The **main service** forwards the buyer’s request to the **seller service** (via a POST request to the seller service, e.g., `/api/v1/seller/receive`).
- The **seller service** stores the incoming buyer request in its own database (to link the buyer’s request with the seller’s response).
- Now, the **seller service** can access the request details from the **main service** and display them to the **seller app**.

### 3. Seller App Receives Request and Sets Price
- The **seller app** sees the buyer’s request, reviews the question (e.g., "How much for this item?"), and decides on a price.
- The **seller app** sends a POST request with the price to the **seller service** (e.g., via `/api/v1/seller/price`).

### 4. Seller Service Stores Price and Sends to Main Service
- The **seller service** stores the seller's price in its database (linked to the buyer’s request).
- The **seller service** can then send this price (along with other details) back to the **main service** (via POST to `/api/v1/seller/price`).

### 5. Main Service Receives Price from Seller
- The **main service** receives the seller’s price and links it with the buyer’s request.
- The **main service** might then notify the **buyer app** (through a WebSocket, email, or another method) that a price has been provided.

### 6. Buyer App Sees Price
- The **buyer app** can then display the price received from the **seller**.

---

## Key Points in This Flow

- **Main Service** acts as a central hub where all buyer requests are stored.
- **Seller Service** receives buyer requests from the main service, stores them in its database, and can display these requests to the sellers.
- **Seller App** reviews buyer requests and sends a price back to the seller service.
- The **main service** stores the seller’s response and can notify the buyer app with the new price.

---

## Example Scenario

1. **Buyer**: Sends a request to buy an item, asking "What is the price for Item A?" to the **main service**.
2. **Main Service**: Stores this request and sends it to the **seller service**.
3. **Seller**: Sees the request in their app, enters a price, and sends this price to the **seller service**.
4. **Seller Service**: Stores the price and sends it to the **main service**.
5. **Main Service**: Notifies the **buyer app** that a price has been received.
6. **Buyer**: Sees the price in their app.

---

## Diagram (Simplified Flow)

1. **Buyer App** → POST Request → **Main Service** (store request)
2. **Main Service** → POST Request → **Seller Service** (store request in seller's DB)
3. **Seller App** → POST Price → **Seller Service** (store price)
4. **Seller Service** → POST Price → **Main Service** (store price)
5. **Main Service** → Notify → **Buyer App** (show price)

---

## Important Notes

- The **seller app** can indeed see the request details (the buyer’s question) after the **seller service** receives it from the **main service**.
- The **seller app** will then provide a price, which is sent back to the **main service**.

---

## Database Handling

Both the **main service** and **seller service** need to be able to store and retrieve these requests and prices efficiently. For this purpose, relational databases like **PostgreSQL** are suitable. **Redis** can also be used for fast retrieval of data in certain cases, especially for temporary storage or caching purposes.


## DB
When the buyer makes a request, that data is saved to the database.
When the seller responds with a price, this price, along with the request_id, is saved in the database, linking it to the buyer's original request.

CREATE TABLE buyer_requests (
    request_id SERIAL PRIMARY KEY,
    buyer_id TEXT NOT NULL,
    request_text TEXT NOT NULL,
    timestamp TIMESTAMP NOT NULL
);

CREATE TABLE seller_prices (
    price_id SERIAL PRIMARY KEY,
    seller_id TEXT NOT NULL,
    request_id INTEGER REFERENCES buyer_requests(request_id),
    price DECIMAL NOT NULL,
    timestamp TIMESTAMP NOT NULL



## Seller Service

The Seller Service is a part of a microservices architecture that handles buyer requests and price submissions from sellers. The service is designed to receive buyer requests from the main service, store them in the database, and allow sellers to submit price quotes for those requests.

### Database Schema

The Seller Service uses two main tables in the database:

#### `buyer_requests` Table
This table stores the requests made by buyers.

```sql
CREATE TABLE buyer_requests (
    id SERIAL PRIMARY KEY,         
    buyer_id VARCHAR(255) NOT NULL, 
    item_details TEXT NOT NULL,    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP 
);
Columns:

    id: A unique identifier for each request (auto-incremented).
    buyer_id: The ID of the buyer making the request.
    item_details: A description of the requested item.
    created_at: Timestamp of when the request was created.
    updated_at: Timestamp of the last update to the request.
    seller_prices Table

This table stores the price submissions made by sellers for a buyers request.
CREATE TABLE seller_prices (
    id SERIAL PRIMARY KEY,         
    seller_id VARCHAR(255) NOT NULL, 
    buyer_id VARCHAR(255) NOT NULL,  
    price DECIMAL(10, 2) NOT NULL,   
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    FOREIGN KEY (buyer_id) REFERENCES buyer_requests(buyer_id) ON DELETE CASCADE
);
Columns:

    id: A unique identifier for each price submission.
    seller_id: The ID of the seller submitting the price.
    buyer_id: The ID of the buyer who made the request.
    price: The price submitted by the seller.
    created_at: Timestamp of when the price was submitted.
    updated_at: Timestamp of the last update to the price.



