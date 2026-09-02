library am_auth_ui;

// Core Services (Specific to Auth)
export 'core/services/app_lock_service.dart';
export 'core/services/secure_storage_service.dart';
export 'core/services/security_alert_service.dart';
export 'core/services/step_up_service.dart';
export 'core/services/token_refresh_service.dart';
export 'core/utils/auth_redirect.dart';
export 'core/utils/pkce_utils.dart';

// Core Network
export 'core/network/auth_interceptor.dart';

// Authentication Feature
// Data layer
export 'features/authentication/data/datasources/auth_data_source.dart';
export 'features/authentication/data/datasources/auth_remote_datasource.dart';
export 'features/authentication/data/datasources/device_link_remote_datasource.dart';
export 'features/authentication/data/datasources/identity_auth_remote_datasource.dart';
export 'features/authentication/data/datasources/login_sessions_remote_datasource.dart';
export 'features/authentication/data/datasources/mock_auth_datasource.dart';
export 'features/authentication/data/repositories/auth_repository_impl.dart';
export 'features/authentication/data/services/device_link_poll_service.dart';
export 'features/authentication/data/services/google_signin_service.dart';

export 'features/authentication/data/services/mock_data_service.dart';
export 'features/authentication/data/models/user_model.dart';
export 'features/authentication/data/models/auth_tokens_model.dart';
export 'features/authentication/data/models/auth_result_model.dart';
export 'features/authentication/data/models/device_link_models.dart';
export 'features/authentication/data/models/login_session_model.dart';
export 'features/authentication/data/models/security_event_model.dart';
export 'features/authentication/data/models/web_otp_models.dart';

// Domain layer
export 'features/authentication/domain/entities/user_entity.dart';
export 'features/authentication/domain/entities/auth_tokens_entity.dart';
export 'features/authentication/domain/entities/auth_result_entity.dart';
export 'features/authentication/domain/repositories/auth_repository.dart';
export 'features/authentication/domain/usecases/email_login_usecase.dart';
export 'features/authentication/domain/usecases/google_login_usecase.dart';
export 'features/authentication/domain/usecases/demo_login_usecase.dart';
export 'features/authentication/domain/usecases/logout_usecase.dart';
export 'features/authentication/domain/usecases/register_usecase.dart';
export 'features/authentication/domain/usecases/check_auth_status_usecase.dart';
export 'features/authentication/domain/usecases/get_current_user_usecase.dart';

// Presentation layer
export 'features/authentication/presentation/cubit/auth_cubit.dart';
export 'features/authentication/presentation/cubit/auth_state.dart';
export 'features/authentication/presentation/cubit/feature_flag_cubit.dart';
export 'features/authentication/presentation/cubit/feature_flag_state.dart';
export 'features/authentication/presentation/pages/app_lock_screen.dart';
export 'features/authentication/presentation/pages/auth_wrapper.dart';
export 'features/authentication/presentation/pages/login_page.dart';
export 'features/authentication/presentation/pages/register_page.dart';
export 'features/authentication/presentation/pages/forgot_password_page.dart';
export 'features/authentication/presentation/pages/reset_password_page.dart';
export 'features/authentication/presentation/pages/verify_email_page.dart';
export 'features/authentication/presentation/pages/scan_web_login_page.dart';
export 'features/authentication/presentation/pages/scan_web_login_confirm_page.dart';

// Widgets
export 'features/authentication/presentation/widgets/demo_login_button_widget.dart';
export 'features/authentication/presentation/widgets/email_login_form_widget.dart';
export 'features/authentication/presentation/widgets/google_login_button_widget.dart';
export 'features/authentication/presentation/widgets/registration_form_widget.dart';
export 'features/authentication/presentation/widgets/feature_flag_panel_widget.dart';
export 'features/authentication/presentation/widgets/auth_layout.dart';
export 'features/authentication/presentation/widgets/security_alert_banner.dart';
export 'features/authentication/presentation/widgets/web_otp_login_widget.dart';
export 'features/authentication/presentation/widgets/web_qr_login_section.dart';

// DI
export 'di/auth_providers.dart';
