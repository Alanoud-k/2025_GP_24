exports.validatePhone = (phone) => /^05\d{8}$/.test(phone);

exports.validatePassword = (password) => {
  // at least 8 chars, one uppercase, one number, one special char
  return /^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*]).{8,}$/.test(password);
};
