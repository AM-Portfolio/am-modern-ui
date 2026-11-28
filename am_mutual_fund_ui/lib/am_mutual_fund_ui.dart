library am_mutual_fund_ui;

export 'data/mf_api_client.dart';
export 'data/mf_dto.dart';
export 'data/mf_endpoints.dart';
// mf_scheme_view / fund cards stay package-internal — extensions cannot be
// loaded through am_app deferred imports.

export 'presentation/mf_shell.dart';
export 'presentation/pages/explore_page.dart';
export 'presentation/pages/history_page.dart';
export 'presentation/pages/holdings_page.dart';
export 'presentation/pages/invest_page.dart';
export 'presentation/pages/mandate_sip_page.dart';
export 'presentation/pages/onboarding_wizard_page.dart';
export 'presentation/pages/order_detail_page.dart';
export 'presentation/pages/redeem_page.dart';
export 'presentation/pages/scheme_detail_page.dart';
export 'presentation/pages/stp_swp_page.dart';
export 'presentation/pages/switch_page.dart';
export 'providers/mf_providers.dart';
