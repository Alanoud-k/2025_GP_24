const axios = require("axios");

const createPayment = async (req, res) => {
  try {
    const { amount, parentId, test } = req.body;

    // 🧩 Build the base payload
    const payload = {
      amount: amount * 100, // convert to halalas (100 = 1 SAR)
      currency: "SAR",
      description: `Wallet top-up for Parent ${parentId}`,
      callback_url: "https://example.com/payment-success", // replace later with your hosted confirmation page
      source: { type: "creditcard" },
    };

    // 💳 For sandbox testing in Postman, include test card info
    if (test) {
      payload.source = {
        type: "creditcard",
        name: "Test User",
        number: "4111111111111111",
        month: "12",
        year: "2028",
        cvc: "123",
      };
    }

    // 🔐 Send request to Moyasar API
    const response = await axios.post("https://api.moyasar.com/v1/payments", payload, {
      auth: {
        username: process.env.MOYASAR_SECRET_KEY,
        password: "",
      },
    });

    // 🌐 Determine correct transaction URL (hosted page)
    const transactionUrl =
      response.data.source?.transaction_url ||
      `https://moyasar.com/pay/${response.data.id}`;

    // ✅ Return clean JSON to frontend
    res.json({
      status: response.data.status,
      paymentId: response.data.id,
      transactionUrl: transactionUrl,
      amount: response.data.amount / 100,
      message:
        response.data.status === "initiated"
          ? "Payment created successfully. Redirect user to transactionUrl."
          : "Payment processed instantly (test mode).",
    });
  } catch (err) {
    console.error("❌ Payment creation error:");
    console.error(err.response?.data || err.message);

    // 📦 Include more info in the error for debugging
    return res.status(500).json({
      message: "Failed to create payment",
      error: err.response?.data || err.message,
    });
  }
};

module.exports = { createPayment };
