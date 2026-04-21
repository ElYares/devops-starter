export async function GET() {
  // This route stays dependency-free so Compose can use it as a reliable probe.
  return Response.json({ status: "ok", service: "web" });
}
