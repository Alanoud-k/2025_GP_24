// server/utils/validators.js

export const validatePhone = (phone) => /^05\d{8}$/.test(phone);

export const validatePassword = (password) => {
  const pattern =
    /^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#$%^&*])[A-Za-z\d!@#$%^&*]{8,}$/;
  return pattern.test(password);
};

export function validateName(name) {
  return /^[A-Za-z]{2,}$/.test(name.trim());
}

