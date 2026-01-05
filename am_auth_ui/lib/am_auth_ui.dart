library am_auth_ui;

// Core Services (Specific to Auth)
export 'core/services/secure_storage_service.dart';

// Authentication Feature
// Data layer
export 'features/authentication/data/datasources/auth_data_source.dart';
// export 'features/authentication/data/datasources/auth_remote_datasource.dart';
export 'features/authentication/data/datasources/mock_auth_datasource.dart';
export 'features/authentication/data/repositories/auth_repository_impl.dart';
export 'features/authentication/data/services/google_signin_service.dart';
// Note: google_signin_service_web/stub usually implied or internal, but exporting if needed

export 'features/authentication/data/services/mock_data_service.dart';
export 'features/authentication/data/models/user_model.dart';
export 'features/authentication/data/models/auth_tokens_model.dart';
export 'features/authentication/data/models/auth_result_model.dart';

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
export 'features/authentication/presentation/pages/auth_wrapper.dart';
export 'features/authentication/presentation/pages/login_page.dart';
export 'features/authentication/presentation/pages/register_page.dart';
export 'features/authentication/presentation/pages/forgot_password_page.dart';
export 'features/authentication/presentation/pages/reset_password_page.dart';

// Widgets
export 'features/authentication/presentation/widgets/demo_login_button_widget.dart';
export 'features/authentication/presentation/widgets/email_login_form_widget.dart';
export 'features/authentication/presentation/widgets/google_login_button_widget.dart';
export 'features/authentication/presentation/widgets/registration_form_widget.dart';
export 'features/authentication/presentation/widgets/feature_flag_panel_widget.dart';
export 'features/authentication/presentation/widgets/auth_layout.dart';


// DI
export 'di/auth_providers.dart';
