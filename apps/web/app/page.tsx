type ApiStatus = {
  service: string;
  visits: number | null;
  postgres: boolean;
  redis: boolean;
  error?: string;
};

// This page renders on the server. Prefer the internal Docker network before
// the public URL so the frontend can talk to the API without leaving Compose.
async function getApiStatus(): Promise<ApiStatus> {
  const baseUrl =
    process.env.API_INTERNAL_BASE_URL ||
    process.env.NEXT_PUBLIC_API_BASE_URL ||
    "http://api:8000";

  try {
    const response = await fetch(`${baseUrl}/demo`, {
      cache: "no-store",
    });

    if (!response.ok) {
      throw new Error("API response was not ok");
    }

    return response.json();
  } catch {
    // Keep the homepage renderable even while the API is still booting.
    return {
      service: "api",
      visits: null,
      postgres: false,
      redis: false,
      error: "API no disponible todavia",
    };
  }
}

export default async function Home() {
  const api = await getApiStatus();

  return (
    <main className="page">
      <section className="hero">
        <p className="eyebrow">DevOps Starter</p>
        <h1>Infra realista para empezar proyectos sin improvisar.</h1>
        <p className="lede">
          Stack base con FastAPI, Next.js, PostgreSQL, Redis, Traefik,
          Prometheus y Grafana.
        </p>
      </section>

      <section className="grid">
        <article className="card">
          <h2>Estado del starter</h2>
          <ul>
            <li>Frontend corriendo detras del proxy</li>
            <li>Backend con endpoints de health y metrics</li>
            <li>Monitoreo listo para iterar</li>
          </ul>
        </article>

        <article className="card accent">
          {/* Esta tarjeta hace visible el contrato minimo entre web y API. */}
          <h2>Respuesta de la API</h2>
          <pre>{JSON.stringify(api, null, 2)}</pre>
        </article>
      </section>
    </main>
  );
}
