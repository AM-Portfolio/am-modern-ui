@echo off
REM AM Modern UI - Local Development Runner
REM This script runs the Flutter app with all environment variables injected via --dart-define.

set AM_API_BASE_URL=https://am.munish.org/analysis
set AM_AUTH_BASE_URL=https://am.munish.org/auth
set AM_USER_BASE_URL=https://am.munish.org/users
set AM_PORTFOLIO_BASE_URL=https://am.munish.org/portfolio
set AM_TRADE_BASE_URL=https://am.munish.org/trade
set AM_MARKET_WS_URL=wss://am.munish.org/market/ws/market-data-stream
set AM_MARKET_BASE_URL=https://am.munish.org/market
set AM_ANALYSIS_BASE_URL=https://am.munish.org/analysis
set AM_USE_MOCK_DATA=false

echo Starting AM Trade UI with Local Environment...

cd am_trade_ui
flutter run -d chrome ^
  --dart-define=AM_API_BASE_URL=%AM_API_BASE_URL% ^
  --dart-define=AM_AUTH_BASE_URL=%AM_AUTH_BASE_URL% ^
  --dart-define=AM_USER_BASE_URL=%AM_USER_BASE_URL% ^
  --dart-define=AM_PORTFOLIO_BASE_URL=%AM_PORTFOLIO_BASE_URL% ^
  --dart-define=AM_TRADE_BASE_URL=%AM_TRADE_BASE_URL% ^
  --dart-define=AM_MARKET_WS_URL=%AM_MARKET_WS_URL% ^
  --dart-define=AM_MARKET_BASE_URL=%AM_MARKET_BASE_URL% ^
  --dart-define=AM_ANALYSIS_BASE_URL=%AM_ANALYSIS_BASE_URL% ^
  --dart-define=AM_USE_MOCK_DATA=%AM_USE_MOCK_DATA%
