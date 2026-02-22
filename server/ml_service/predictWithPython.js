import { spawn } from "node:child_process";

export function predictWithPython(merchantText) {
  return new Promise((resolve, reject) => {
    const py = spawn("python", ["./ml_service/predict.py"], {
      cwd: process.cwd(), // داخل server
      stdio: ["pipe", "pipe", "pipe"],
    });

    let out = "";
    let err = "";

    py.stdout.on("data", (d) => (out += d.toString()));
    py.stderr.on("data", (d) => (err += d.toString()));

    py.on("close", (code) => {
      if (code !== 0) {
        return reject(new Error(`Python exited with code ${code}. ${err}`));
      }
      try {
        const parsed = JSON.parse(out || "{}");
        resolve(parsed.prediction ?? null);
      } catch (e) {
        reject(new Error(`Invalid JSON from python: ${out}`));
      }
    });

    py.stdin.write(JSON.stringify({ merchant_text: merchantText || "" }));
    py.stdin.end();
  });
}