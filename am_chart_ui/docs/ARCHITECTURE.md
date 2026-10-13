# am_chart_ui architecture

Modular TradingView-style terminal. UI never talks to brokers or market APIs directly —
only through provider interfaces.

## Layers

- **shell/** — terminal chrome (top / chart / right / bottom)
- **chart_engine/** — viewport, scale, crosshair, paint context
- **chart_types/** — registry of renderers (`isAvailable` gate)
- **providers/** — MarketData, Historical, Realtime, Fundamental, News, Broker
- **persistence/** — WorkspaceStore (local SharedPreferences Phase 1)
- Later: indicators, drawings, alerts, trading, options, strategy, ai

## Rules

- Mock providers clearly watermarked.
- Unavailable chart types / tabs labeled Coming / Not connected.
- No silent live orders (BrokerProvider + confirmation in Phase 8).
