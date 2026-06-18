// Re-export del `apiClientProvider` para descubrirlo desde `shared/providers/`
// (la definición vive junto al tipo en `shared/services/api_client.dart`).
export 'package:atmosphere_app/shared/services/api_client.dart'
    show ApiClient, apiClientProvider;
