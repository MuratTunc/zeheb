import React, { useState, useEffect } from "react";
import axios from "axios";

const GoldPrices = () => {
  const [goldPriceTRY, setGoldPriceTRY] = useState(null);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchGoldPrices = async () => {
      try {
        const response = await axios.get("http://localhost:8084/api/v1/scraping/goldprice");
        setGoldPriceTRY(response.data.goldPriceTRY); // Update with the scraped price field
        setError(null); // Clear errors on successful fetch
      } catch (err) {
        setError("Failed to fetch gold prices");
        setGoldPriceTRY(null);
      }
    };

    fetchGoldPrices(); // Fetch on mount
    const interval = setInterval(fetchGoldPrices, 5000); // Refresh every 5 seconds

    return () => clearInterval(interval); // Cleanup on unmount
  }, []);

  return (
    <div>
      {goldPriceTRY !== null ? (
        <p className="text-yellow-100 font-medium">
          GRAM ALTIN: {goldPriceTRY.toFixed(2)} ₺
        </p>
      ) : error ? (
        <p className="text-red-500 font-medium">{error}</p>
      ) : (
        <p className="text-gray-400">Loading gold price...</p>
      )}
    </div>
  );
};

export default GoldPrices;
