# FinSight V5.2 — validação da integração

Esta rodada passou da prévia mínima para telas navegáveis de Dashboard, Mercado, Busca, Carteira, Mais, Favoritos, Comparação, Detalhes do Ativo (Sobre/Indicadores/Resultados/Dividendos/Gráfico) e operação (compra, venda e confirmação).

## Cobertura automática
- Inicialização da aplicação e Dashboard
- Navegação para Mercado e Carteira
- Busca por ticker
- Detalhes do ativo e abertura do modal
- Bloqueio de vendas sem saldo
- Cálculo das posições de compra e venda

## Limites
**Os valores são demonstrativos.** Dados financeiros, notícias, assistente, persistência SQLite/Drift, autenticação e integrações FastAPI permanecem pendentes. O gráfico usa candles sintéticos. A identidade visual final exige integração do UI Kit original V5.2, seus logos e comparação com capturas reais. A aprovação do CI não equivale a 10/10 visual.
