const sendAuthCode = async (fullName, email) => {
  const apiUrl =
    process.env.NODE_ENV === "development"
      ? "https://mutubackend.com/mail-service/send-auth-code-mail"
      : "/mail-service/send-auth-code-mail";

  try {
    const response = await fetch(apiUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ username: fullName, mailAddress: email }),
    });

    if (!response.ok) {
      // Log the response details for debugging
      const errorResponse = await response.text(); // Get the error response body
      console.error("Error Response:", errorResponse);
      throw new Error("Failed to send authentication code");
    }

    return await response.json();
  } catch (error) {
    // Log detailed error message for easier debugging
    console.error("Error in sendAuthCode:", error.message);
    console.error("Error Stack:", error.stack);
    throw new Error("Failed to send authentication code");
  }
};

export default sendAuthCode;
