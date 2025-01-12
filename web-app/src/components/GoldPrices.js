import React, { useState, useEffect } from "react";
import axios from "axios";

const GoldPrices = () => {
  const [prices, setPrices] = useState(null);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchGoldPrices = async () => {
      try {
        const response = await axios.post(
          "http://localhost:8083/api/v1/tcmbratings/gold-prices",
          { currencyCode: "USD" } // Always fetch for "XAU"
        );
        setPrices(response.data);
        setError(null);
      } catch (err) {
        setError("Failed to fetch gold prices");
        setPrices(null);
      }
    };

    fetchGoldPrices(); // Fetch on mount
    const interval = setInterval(fetchGoldPrices, 5000); // Refresh every 5 seconds

    return () => clearInterval(interval); // Cleanup on unmount
  }, []);

  return (
    <div>
      {prices ? (
        <p className="text-yellow-400 font-medium">
          Gold Prices: Buy: {prices.forexBuying} | Sell: {prices.forexSelling}
        </p>
      ) : error ? (
        <p className="text-red-500 font-medium">{error}</p>
      ) : (
        <p className="text-gray-400">Loading gold prices...</p>
      )}
    </div>
  );
};

export default GoldPrices;
