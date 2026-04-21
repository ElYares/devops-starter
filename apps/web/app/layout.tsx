import "./globals.css";
import type { Metadata } from "next";

// Shared metadata lives here because the starter only has one route today.
export const metadata: Metadata = {
  title: "DevOps Starter",
  description: "Starter DevOps con FastAPI, Next.js y Docker Compose",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
