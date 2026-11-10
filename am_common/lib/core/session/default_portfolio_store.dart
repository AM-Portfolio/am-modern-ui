import 'package:am_library/am_library.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local per-user default portfolio for dropdown pin / auto-load.
class DefaultPortfolioStore {
  DefaultPortfolioStore._();
  static final DefaultPortfolioStore instance = DefaultPortfolioStore._();

  static const _idPrefix = 'default_portfolio_id_v1_';
  static const _namePrefix = 'default_portfolio_name_v1_';

  Future<({String id, String name})?> load(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('$_idPrefix$userId');
      if (id == null || id.isEmpty) return null;
      final name = prefs.getString('$_namePrefix$userId') ?? id;
      return (id: id, name: name);
    } catch (e) {
      AppLogger.warning('DefaultPortfolioStore.load: $e', tag: 'DefaultPortfolio');
      return null;
    }
  }

  Future<void> save(String userId, {required String id, required String name}) async {
    if (userId.isEmpty || id.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_idPrefix$userId', id);
      await prefs.setString('$_namePrefix$userId', name);
    } catch (e) {
      AppLogger.warning('DefaultPortfolioStore.save: $e', tag: 'DefaultPortfolio');
    }
  }

  Future<void> clear(String userId) async {
    if (userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_idPrefix$userId');
      await prefs.remove('$_namePrefix$userId');
    } catch (_) {}
  }
}
