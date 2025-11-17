// server/controllers/addMoneyController.js
import axios from "axios";

export const createPayment = async (req, res) => {
  try {
    const { amount, parentId } = req.body;
    if (!amount || !parentId) {
      return res.status(400).json({ message: "amount and parentId are required" });
    }

    const payload = {
      amount: Math.round(Number(amount) * 100),
      currency: "SAR",
      description: `Wallet top-up for Parent ${parentId}`,
      callback_url: "https://moyasar.com/thank-you", // dummy page; not used in app
      source: { type: "src_card" }, // ✅ THIS tells Moyasar to open hosted page
    };

    const response = await axios.post("https://api.moyasar.com/v1/payments", payload, {
      auth: {
        username: process.env.MOYASAR_SECRET_KEY,
        password: "",
      },
    });

    const transactionUrl =
      response.data?.source?.transaction_url ||
      `https://moyasar.com/pay/${response.data?.id}`;

    return res.json({
      status: response.data?.status,
      paymentId: response.data?.id,
      transactionUrl,
      amount: (response.data?.amount ?? 0) / 100,
      message: "Redirect the user to transactionUrl to complete payment.",
    });
  } catch (err) {
    console.error("❌ Payment creation error:", err.response?.data || err.message);
    return res.status(500).json({
      message: "Failed to create payment",
      error: err.response?.data || err.message,
    });
  }
};
