/// Estado del health check de la API (dominio).
///
/// - [loading]: verificación en curso (estado inicial / mientras consulta).
/// - [alive]: la API respondió 200 (sistema vivo).
/// - [error]: sin red / timeout / status >= 400 (error de conexión).
enum HealthStatus { loading, alive, error }
