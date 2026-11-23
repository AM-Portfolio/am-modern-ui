/// Relative paths on the MF BFF (base URL already includes `/router/am/mf`).
class MfEndpoints {
  MfEndpoints._();

  static const schemes = '/v1/mf/schemes';
  static String scheme(String isin) => '/v1/mf/schemes/$isin';
  static String schemeNav(String isin) => '/v1/mf/schemes/$isin/nav';
  static String schemePerformance(String isin) =>
      '/v1/mf/schemes/$isin/performance';

  static const meta = '/v1/mf/meta';
  static const kyc = '/v1/mf/kyc';
  static const ekycStart = '/v1/mf/kyc/ekyc/start';
  static const ucc = '/v1/mf/onboarding/ucc';
  static const fatca = '/v1/mf/onboarding/fatca';
  static const bank = '/v1/mf/onboarding/bank';

  static const purchase = '/v1/mf/orders/purchase';
  static const redeem = '/v1/mf/orders/redeem';
  static const switchOrder = '/v1/mf/orders/switch';
  static const orders = '/v1/mf/orders';
  static String order(String id) => '/v1/mf/orders/$id';
  static String orderPay(String id) => '/v1/mf/orders/$id/pay';
  static String orderCancel(String id) => '/v1/mf/orders/$id/cancel';

  static const mandates = '/v1/mf/mandates';
  static String mandate(String id) => '/v1/mf/mandates/$id';
  static const sips = '/v1/mf/sips';
  static const sipPause = '/v1/mf/sips/pause';
  static const sipResume = '/v1/mf/sips/resume';
  static const sipCancel = '/v1/mf/sips/cancel';
  static const stp = '/v1/mf/stp';
  static const swp = '/v1/mf/swp';

  static const holdings = '/v1/mf/holdings';
}
