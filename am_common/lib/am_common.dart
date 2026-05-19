library am_common;

// ============================================================================
// SHARED ENUMS
// ============================================================================
export 'shared/enums/market_cap_type.dart';
export 'shared/enums/metric_type.dart';
export 'shared/enums/sector_type.dart';
export 'shared/enums/timeframe.dart';
export 'shared/extensions/investment_extensions.dart';

// ============================================================================
// ATTACHMENT FEATURE
// ============================================================================
// Data Layer
export 'features/attachment/internal/data/datasources/cloudinary_remote_data_source.dart';
export 'features/attachment/internal/data/repositories/cloudinary_repository_impl.dart';
export 'features/attachment/internal/data/dtos/cloudinary_dto.dart';
export 'features/attachment/internal/data/mappers/cloudinary_mapper.dart';

// ============================================================================
// NOTIFICATION FEATURE
// ============================================================================
export 'features/notifications/domain/notification_entity.dart';
export 'features/notifications/providers/notification_provider.dart';
export 'features/notifications/presentation/notification_bell.dart';

// Domain Layer
export 'features/attachment/internal/domain/repositories/cloudinary_repository.dart';
export 'features/attachment/internal/domain/entities/cloudinary_resource.dart';
export 'features/attachment/internal/domain/usecases/upload_file_usecase.dart';
export 'features/attachment/internal/domain/usecases/upload_batch_files_usecase.dart';


export 'features/attachment/internal/domain/usecases/delete_file_usecase.dart';
export 'features/attachment/internal/domain/usecases/get_resource_usecase.dart';
export 'features/attachment/internal/domain/usecases/list_resources_usecase.dart';

// Presentation Layer
export 'features/attachment/internal/presentation/cubits/attachment_cubit.dart';
export 'features/attachment/internal/presentation/cubits/attachment_state.dart';

// Services
export 'features/attachment/internal/services/cloudinary_upload_service.dart';
export 'features/attachment/internal/services/file_upload_service.dart';
export 'core/services/price_service.dart';
export 'core/models/price_update_model.dart';

// Widgets
export 'features/attachment/internal/presentation/widgets/shared_attachment_section.dart';
export 'features/attachment/internal/presentation/widgets/attachment_picker/attachment_picker.dart';
export 'features/attachment/internal/presentation/widgets/attachment_picker/shared/attachment_preview_grid.dart';
export 'features/attachment/internal/presentation/models/pending_attachment.dart';

// Navigation Widgets
export 'features/navigation/widgets/vertical_scroll_navigator.dart';

// ============================================================================
// CORE TECHNICAL INFRASTRUCTURE (From am_library)
// ============================================================================
export 'package:am_library/am_library.dart';

// Remaining local core components
export 'core/config/app_config.dart';
export 'core/config/config_service.dart';
export 'core/config/env_domains.dart';
export 'core/config/upload_config.dart';
export 'core/config/user_currency_config.dart';
export 'core/di/network_providers.dart';
export 'core/constants/constants.dart';
export 'core/services/price_service.dart';
export 'core/models/price_update_model.dart';
export 'core/network/websocket/am_websocket_client.dart';
export 'core/network/websocket/websocket_cubit.dart';
export 'core/network/websocket/stomp_connection_cubit.dart';

// ============================================================================
// SHARED
// ============================================================================
// Extensions
// export 'shared/extensions/build_context_extensions.dart';
// export 'shared/extensions/date_time_extensions.dart';
// export 'shared/extensions/num_extensions.dart';
// export 'shared/extensions/string_extensions.dart';
