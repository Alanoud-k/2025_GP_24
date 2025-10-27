exports.validatePhone = (phone) => /^05\d{8}$/.test(phone);

exports.validatePassword = (password) => {
  const pattern =
    /^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#$%^&*])[A-Za-z\d!@#$%^&*]{8,}$/;
  return pattern.test(password);
};
