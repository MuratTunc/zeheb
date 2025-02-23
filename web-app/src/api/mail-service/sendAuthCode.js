const sendAuthCode = async (fullName, email) => {
  const apiUrl = process.env.NODE_ENV === "development"
    ? "https://mutubackend.com/mail-service/send-auth-code-mail"
    : "/mail-service/send-auth-code-mail";

  const response = await fetch(apiUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ username: fullName, mailAddress: email }),
  });

  if (!response.ok) {
    throw new Error("Failed to send authentication code");
  }

  return await response.json();
};

export default sendAuthCode;
