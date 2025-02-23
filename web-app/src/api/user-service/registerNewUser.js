// registerNewUser.js

const registerNewUser = async (fullName, email, password) => {
    // Mock response for testing
    return new Promise((resolve) => {
      setTimeout(() => {
        resolve({ success: true });
      }, 1000); // Simulate a delay of 1 second
    });
  };
  
  export default registerNewUser;
  