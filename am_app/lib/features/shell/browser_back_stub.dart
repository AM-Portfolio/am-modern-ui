/// Non-web: no browser history — caller uses [fallback].
void browserHistoryBack({required void Function() fallback}) => fallback();
