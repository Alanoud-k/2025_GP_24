// server/utils/merchantClassification.js
import { sql } from "../config/db.js";

// 1) MCC → fine category (same as your notebook)
export const mccToFineCategory = {
  5812: "Food & Dining",
  5814: "Fast Food",
  5811: "Cafes & Coffee Shops",
  5499: "Misc Food Stores",
  5441: "Candy & Confectionery",
  5451: "Dairy Products",

  5411: "Groceries",
  5422: "Meat Markets",

  5541: "Gas Stations",
  5542: "Gas Stations",
  5533: "Automotive Parts",
  7531: "Auto Repair",
  7535: "Auto Paint Shops",
  7534: "Tire Shops",
  7538: "Auto Service Shops",
  7542: "Towing Services",
  4789: "Transportation Services",
  4121: "Taxi & Ride Services",

  5331: "Warehouse Clubs",
  5311: "Department Stores",
  5399: "General Retail",
  5999: "Misc Retail",
  5942: "Book Stores",
  5943: "Stationery Stores",
  5944: "Jewelry Stores",
  5945: "Toy Stores",
  5946: "Camera Stores",
  5947: "Gift Shops",
  5948: "Leather Stores",
  5949: "Fabric Stores",
  5651: "Clothing Stores",
  5691: "Clothing & Accessories",
  5697: "Tailors & Garments",
  5699: "Misc Apparel",
  5611: "Men’s Clothing",
  5621: "Women’s Clothing",
  5661: "Shoe Stores",

  5732: "Electronics Stores",
  5734: "Computer Software Stores",
  5722: "Home Appliances",
  5712: "Furniture Stores",
  5713: "Floor Coverings",
  5719: "Home Accessories",

  5912: "Pharmacies",
  8062: "Hospitals",
  8011: "Doctors",
  8021: "Dentists",
  8043: "Opticians",
  8049: "Medical Services",
  8099: "Medical Services (General)",

  7299: "Services",
  7399: "Business Services",
  7392: "Consulting Services",
  7393: "Detective / Security",
  7394: "Equipment Rental",
  7349: "Cleaning Services",
  7333: "Commercial Photography",
  7338: "Quick Copying",
  7210: "Laundry",
  7211: "Dry Cleaning",
  7217: "Carpet Cleaning",
  7230: "Hair Salons",
  7221: "Photographers",

  8398: "Charity Organizations",
  9211: "Court Fees",
  9399: "Government Services",
  8220: "Education",
  8299: "Schools & Education",

  1520: "Contractors",
  1711: "Plumbing Services",
  1740: "Masonry",
  1750: "Carpentry",
  1761: "Roofing",
  1771: "Concrete Work",
  1799: "Special Trade Contractors",

  5172: "Petroleum Wholesale",
  5192: "Books & Periodicals Wholesale",
  5193: "Florists Wholesale",
  5199: "Wholesale Distributors",
  5131: "Fabric Wholesale",
  5137: "Men’s Clothing Wholesale",
  5169: "Chemicals Wholesale",
  5085: "Industrial Supplies",
  5072: "Hardware Wholesale",
  5074: "Plumbing Wholesale",
  5045: "Computers Wholesale",
  5021: "Office Furniture Wholesale",
  5039: "Construction Supplies",
  5051: "Metal Products",

  4900: "Utilities",
  4812: "Telecom",
  4814: "Telecom Services",
  4816: "Computer Network Services",

  7011: "Hotels",
  4215: "Courier Services",
  4214: "Delivery Services",
  4225: "Storage",
  4582: "Airports",
  7512: "Rent-a-car",
  7523: "Parking",
  7997: "Membership Clubs",
  7999: "Recreational Services",
  7832: "Movie Theaters",
  7829: "Film Production",
   742: "Veterinary Services",
   780: "Amusement Parks",

  5200: "Home Supply",
  5211: "Building Materials",
  5261: "Nurseries",
  5231: "Glass Stores",
};

// 2) fine -> major category (for dashboards)
export const fineToMajorCategory = {
  "Fast Food": "Food & Drinks",
  "Food & Dining": "Food & Drinks",
  "Cafes & Coffee Shops": "Food & Drinks",
  "Misc Food Stores": "Food & Drinks",
  "Candy & Confectionery": "Food & Drinks",

  Groceries: "Groceries",
  "Meat Markets": "Groceries",

  "Warehouse Clubs": "Shopping",
  "Department Stores": "Shopping",
  "General Retail": "Shopping",
  "Gift Shops": "Shopping",
  "Misc Retail": "Shopping",
  "Book Stores": "Shopping",
  "Stationery Stores": "Shopping",

  "Clothing Stores": "Clothing & Accessories",
  "Tailors & Garments": "Clothing & Accessories",
  "Clothing & Accessories": "Clothing & Accessories",
  "Men’s Clothing": "Clothing & Accessories",
  "Women’s Clothing": "Clothing & Accessories",

  "Gas Stations": "Fuel",

  "Transportation Services": "Transportation",
  "Taxi & Ride Services": "Transportation",
  "Towing Services": "Transportation",

  Hospitals: "Health & Medical",
  Pharmacies: "Health & Medical",
  "Medical Services (General)": "Health & Medical",
  Doctors: "Health & Medical",

  "Electronics Stores": "Electronics & Appliances",
  "Home Appliances": "Electronics & Appliances",
  "Computer Network Services": "Electronics & Appliances",

  "Furniture Stores": "Home Improvement",
  "Home Supply": "Home Improvement",
  "Building Materials": "Home Improvement",
  Contractors: "Home Improvement",
  "Special Trade Contractors": "Home Improvement",

  "Hair Salons": "Personal Care",
  Laundry: "Personal Care",
  "Dry Cleaning": "Personal Care",

  Hotels: "Hotels & Travel",
  "Rent-a-car": "Hotels & Travel",
  Parking: "Hotels & Travel",

  "Automotive Parts": "Automotive",
  "Auto Service Shops": "Automotive",
  "Auto Repair": "Automotive",
  "Tire Shops": "Automotive",

  Telecom: "Telecom & Bills",
  "Telecom Services": "Telecom & Bills",
  Utilities: "Telecom & Bills",

  "Business Services": "Services",
  Services: "Services",
};

// 3) JS version of the cleaning used in the notebook
export function cleanMerchantName(name) {
  if (!name) return "";
  let s = name.toLowerCase();
  s = s.normalize("NFKC");
  // remove things like "-5", "/12", "#3"
  s = s.replace(/[-_/#]\d+/g, " ");
  // remove non alphanumeric
  s = s.replace(/[^a-z0-9\s]/g, " ");
  // collapse spaces
  s = s.replace(/\s+/g, " ").trim();
  return s;
}

// 4) Basic rule-based classification using MCC
export function classifyByMcc(merchantName, mcc) {
  const fine = mccToFineCategory[mcc] || "Other";
  const major = fineToMajorCategory[fine] || "Other";

  return {
    merchantName,
    mcc,
    fineCategory: fine,
    majorCategory: major,
  };
}
