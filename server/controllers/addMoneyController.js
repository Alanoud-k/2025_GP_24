// server/controllers/addMoneyController.js  (ESM)

import axios from "axios";

/**
 * Create Moyasar payment (wallet top-up)
 * Body: { amount: number (SAR), parentId: number|string, test?: boolean }
 */
export const createPayment = async (req, res) => {
  try {
    const { amount, parentId, test } = req.body;
    if (!amount || !parentId) {
      return res.status(400).json({ message: "amount and parentId are required" });
    }

    // Build the base payload (Moyasar expects amount in halalas)
    const payload = {
      amount: Math.round(Number(amount) * 100), // 1 SAR = 100 halalas
      currency: "SAR",
      description: `Wallet top-up for Parent ${parentId}`,
      callback_url: "https://example.com/payment-success", // TODO: replace with your hosted page
      source: { type: "creditcard" },
    };

    // Optional: test card for sandboxing
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

    // Call Moyasar API (Basic Auth with secret key)
    const response = await axios.post("https://api.moyasar.com/v1/payments", payload, {
      auth: {
        username: process.env.MOYASAR_SECRET_KEY,
        password: "",
      },
    });

    // Hosted transaction URL
    const transactionUrl =
      response.data?.source?.transaction_url ||
      `https://moyasar.com/pay/${response.data?.id}`;

    // Respond to client
    return res.json({
      status: response.data?.status,
      paymentId: response.data?.id,
      transactionUrl,
      amount: (response.data?.amount ?? 0) / 100,
      message:
        response.data?.status === "initiated"
          ? "Payment created successfully. Redirect user to transactionUrl."
          : "Payment processed instantly (test mode).",
    });
  } catch (err) {
    // Log and propagate a clear error
    console.error("❌ Payment creation error:", err.response?.data || err.message);
    return res.status(500).json({
      message: "Failed to create payment",
      error: err.response?.data || err.message,
    });
  }
};
