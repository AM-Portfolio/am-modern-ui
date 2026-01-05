# Portfolio Feature - Clean Architecture Implementation

## Overview
The portfolio feature follows Clean Architecture principles with clear separation of concerns. All feature-specific logic is contained within the `internal/` package to enforce feature isolation.

## Architecture Structure

### Feature Internal Structure (`lib/features/portfolio/internal/`)
**Purpose**: Contains ALL feature-specific business logic, isolated from other features

#### Domain Layer (`internal/domain/`)
**Purpose**: Contains business logic, entities, and interfaces - independent of external frameworks

##### Entities (`internal/domain/entities/`)
- `portfolio_holding.dart` - Core holding data with business rules
- `portfolio_summary.dart` - Portfolio summary with calculations and formatting

##### Repositories (`internal/domain/repositories/`)
- `portfolio_repository.dart` - Interface defining portfolio data operations

##### Use Cases (`internal/domain/usecases/`)
- `get_portfolio_holdings.dart` - Retrieve portfolio holdings
- `get_portfolio_summary.dart` - Retrieve portfolio summary
- `analyze_portfolio_performance.dart` - Performance analysis operations
- `search_portfolio_holdings.dart` - Search and filter holdings
- `refresh_portfolio_data.dart` - Data refresh operations

#### Data Layer (`internal/data/`)
**Purpose**: Handles external data sources and implements domain interfaces

##### DTOs (`internal/data/dtos/`)
- `portfolio_dto.dart` - Data Transfer Objects with JSON serialization and domain conversion

##### Data Sources (`internal/data/datasources/`)
- `portfolio_remote_data_source.dart` - API data source (currently mocked)

##### Repositories (`internal/data/repositories/`)
- `portfolio_repository_impl.dart` - Implementation of domain repository interface

#### Services Layer (`internal/services/`)
**Purpose**: Complex business workflows that combine multiple use cases
- `portfolio_service.dart` - Orchestration service for complex workflows like sync + analytics

### Presentation Layer (`lib/features/portfolio/presentation/`)
**Purpose**: UI components and state management

#### Cubit (`cubit/`)
- `portfolio_cubit.dart` - State management using BLoC pattern
- `portfolio_state.dart` - State definitions with Freezed

#### Pages (`pages/`)
- `portfolio_screen.dart` - Main portfolio screen

#### Widgets (`widgets/`)
- `portfolio_sidebar.dart` - Navigation sidebar
- *Note: Additional widgets need to be created for full functionality*

## Key Benefits of This Architecture

### 1. Separation of Concerns
- **Domain Layer**: Pure business logic, no dependencies on Flutter/UI
- **Data Layer**: Handles external data sources, API calls, caching
- **Presentation Layer**: UI-specific code, state management

### 2. Testability
- Each layer can be tested independently
- Domain layer has no external dependencies
- Easy to mock data sources for testing

### 3. Maintainability
- Clear boundaries between layers
- Business logic centralized in use cases
- Easy to swap data sources or UI frameworks

### 4. Scalability
- New features can be added following the same pattern
- Data sources can be easily extended (local cache, different APIs)
- UI can be customized without affecting business logic

## Implementation Status

### ✅ Completed
- Domain layer structure and entities
- Repository interfaces and use cases
- Data layer with DTOs and repository implementation
- Basic presentation layer structure
- State management with Cubit

### 🔄 Needs Build Runner
The following files need code generation:
- All Freezed entities and DTOs
- JSON serialization code
- Cubit state management code

Run: `dart run build_runner build --delete-conflicting-outputs`

### ⚠️ Pending Implementation
- Complete widget implementations (overview, holdings, analysis)
- BLoC/Cubit integration (requires flutter_bloc dependency)
- API client integration (replace mock data)
- Error handling and loading states
- Provider/dependency injection setup

## Migration from Old Structure

### Old Portfolio Screen
The original `portfolio_screen.dart` contained:
- Direct API calls
- Mixed UI and business logic  
- State management with Riverpod providers
- Monolithic structure

### New Structure Benefits
- **Clean separation**: Business logic moved to use cases
- **Better testing**: Each component can be tested in isolation
- **Flexibility**: Easy to swap state management or data sources
- **Maintainability**: Clear file organization and responsibilities

## Next Steps

1. **Run build_runner** to generate missing code
2. **Add flutter_bloc dependency** to pubspec.yaml
3. **Create remaining widget implementations**
4. **Set up dependency injection** for the new architecture
5. **Replace mock data** with actual API integration
6. **Add comprehensive error handling**
7. **Write unit tests** for each layer

## Dependencies Required

```yaml
dependencies:
  flutter_bloc: ^8.1.3
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1

dev_dependencies:
  build_runner: ^2.4.7
  freezed: ^2.4.6
  json_serializable: ^6.7.1
```

## Usage Example

```dart
// In your app, inject dependencies and use the screen
BlocProvider(
  create: (context) => PortfolioCubit(
    getPortfolioHoldings: GetPortfolioHoldings(portfolioRepository),
    getPortfolioSummary: GetPortfolioSummary(portfolioRepository),
    // ... other use cases
  ),
  child: PortfolioScreen(userId: userId),
)
```

This architecture provides a solid foundation for the portfolio feature that is maintainable, testable, and scalable.