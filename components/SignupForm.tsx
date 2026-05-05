"use client";
import { useState } from "react";

export default function SignupForm() {
  const [status, setStatus] = useState<"idle" | "loading" | "done">("idle");

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setStatus("loading");
    const email = (e.currentTarget.elements.namedItem("email") as HTMLInputElement).value;
    const endpoint = process.env.NEXT_PUBLIC_SIGNUP_ENDPOINT;
    try {
      if (endpoint) {
        await fetch(endpoint, {
          method: "POST",
          mode: "no-cors",
          body: JSON.stringify({ email, source: "landing" }),
        });
      }
      setStatus("done");
    } catch {
      setStatus("idle");
    }
  }

  return (
    <form className="signup-form" onSubmit={handleSubmit}>
      <input type="email" name="email" placeholder="you@stanford.edu" required />
      <button type="submit" disabled={status !== "idle"}>
        {status === "loading" ? "Sending…" : status === "done" ? "You're on the list ✓" : "Request invite"}
      </button>
    </form>
  );
}
