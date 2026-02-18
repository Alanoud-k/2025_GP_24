const RULES = [
  { category: "Transport", keywords: ["uber", "careem", "taxi", "bolt"] },
  { category: "Food & Restaurants", keywords: ["albaik", "starbucks", "coffee", "cafe", "restaurant", "pizza", "burger", "shawarma"] },
  { category: "Grocery & Markets", keywords: ["panda", "carrefour", "danube", "lulu", "supermarket", "hyper", "grocery", "market"] },
  { category: "Medical", keywords: ["nahdi", "pharmacy", "clinic", "hospital", "dawaa"] },
  { category: "Digital & Subscriptions", keywords: ["netflix", "spotify", "itunes", "apple.com", "google", "playstation", "steam"] },
  { category: "Retail & Shopping", keywords: ["zara", "hm", "ikea", "noon", "amazon", "store", "mall"] }
];

export function keywordMap(merchantText) {
  const text = String(merchantText).toLowerCase();
  for (const rule of RULES) {
    for (const kw of rule.keywords) {
      if (text.includes(kw)) return rule.category;
    }
  }
  return null;
}
