const registerNewUser = async (fullName, email, password) => {
  const apiUrl =
    process.env.NODE_ENV === "development"
      ? "https://mutubackend.com/user-service/register"
      : "/user-service/register";

  const response = await fetch(apiUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      username: fullName,
      mailAddress: email,
      password: password,
      role: "customer", // Hardcoded role as customer
    }),
  });

  if (!response.ok) {
    const errorMessage = await response.text();
    throw new Error(errorMessage || "Failed to register user");
  }

  return await response.json(); // {message, token, mailAddress}
};

export default registerNewUser;