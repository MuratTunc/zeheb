import React, { useState, useEffect } from "react";
import axios from "axios";

const USDTRYRate = () => {
  const [usdTryRate, setUsdTryRate] = useState(null);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchUSDTRYRate = async () => {
      try {
        const response = await axios.get("http://localhost:8083/api/v1/tcmbratings/usdtry");
        setUsdTryRate(response.data.usdTry); // Update to use `usdTry` field
        setError(null); // Clear errors on successful fetch
      } catch (err) {
        setError("Failed to fetch USD/TRY exchange rate");
        setUsdTryRate(null);
      }
    };

    fetchUSDTRYRate(); // Fetch on mount
    const interval = setInterval(fetchUSDTRYRate, 5000); // Refresh every 5 seconds

    return () => clearInterval(interval); // Cleanup on unmount
  }, []);

  return (
    <div>
      {usdTryRate !== null ? (
        <p className="text-yellow-400 font-medium">
          USD/TRY : {usdTryRate.toFixed(4)}
        </p>
      ) : error ? (
        <p className="text-red-500 font-medium">{error}</p>
      ) : (
        <p className="text-gray-400">Loading exchange rate...</p>
      )}
    </div>
  );
};

export default USDTRYRate;
