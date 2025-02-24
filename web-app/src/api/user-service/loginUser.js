const loginUser = async (mailAddress, password) => {
    const apiUrl =
      process.env.NODE_ENV === "development"
        ? "https://mutubackend.com/user-service/login"
        : "/user-service/login";
  
    const response = await fetch(apiUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ mailAddress, password }), // Use mailAddress instead of username
    });
  
    if (!response.ok) {
      const errorMessage = await response.text(); // Extract error message
      throw new Error(errorMessage || "Failed to login");
    }
  
    return await response.json();
  };
  
  export default loginUser;
  