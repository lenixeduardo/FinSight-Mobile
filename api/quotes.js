// Server-side brapi proxy: never send BRAPI_TOKEN to Flutter clients.
export default async function handler(req, res) {
  if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' });
  const token = process.env.BRAPI_TOKEN;
  if (!token) return res.status(503).json({ error: 'Market provider not configured' });
  const symbols = ['PETR4', 'VALE3', 'ITUB4', 'MGLU3'];
  try {
    const upstream = await fetch('https://brapi.dev/api/quote/' + symbols.join(',') + '?range=1mo&interval=1d', {
      headers: { Authorization: 'Bearer ' + token },
      signal: AbortSignal.timeout(12000),
    });
    if (!upstream.ok) return res.status(502).json({ error: 'Market provider unavailable', status: upstream.status });
    const data = await upstream.json();
    const results = (Array.isArray(data.results) ? data.results : []).map(item => ({
      symbol: item.symbol,
      regularMarketPrice: item.regularMarketPrice,
      regularMarketChangePercent: item.regularMarketChangePercent,
      regularMarketTime: item.regularMarketTime,
      historicalDataPrice: Array.isArray(item.historicalDataPrice) ? item.historicalDataPrice.map(x => ({date:x.date,close:x.close})) : [],
    })).filter(item => symbols.includes(item.symbol));
    res.setHeader('Cache-Control', 's-maxage=60, stale-while-revalidate=120');
    return res.status(200).json({ results, fetchedAt: new Date().toISOString() });
  } catch {
    return res.status(502).json({ error: 'Market provider timeout or network error' });
  }
}
