import { spawn } from "child_process";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export function predictWithPython(merchantText) {
  return new Promise((resolve, reject) => {
    const scriptPath = path.join(__dirname, "predict.py");
    const py = spawn("python3", [scriptPath], { stdio: ["pipe", "pipe", "pipe"] });

    let out = "";
    let err = "";

    py.stdout.on("data", (d) => (out += d.toString()));
    py.stderr.on("data", (d) => (err += d.toString()));

    py.on("close", (code) => {
      if (code !== 0) return reject(new Error(err || "python_failed"));
      try {
        const obj = JSON.parse(out);
        if (!obj?.prediction) return reject(new Error("bad_python_response"));
        resolve(obj.prediction);
      } catch {
        reject(new Error("invalid_python_output"));
      }
    });

    py.stdin.write(JSON.stringify({ merchant_text: merchantText }));
    py.stdin.end();
  });
}
