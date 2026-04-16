# Conclusiones del Ejercicio

## Resultado General

La ejecución más reciente de la suite Pet Lifecycle fue exitosa:

- Features ejecutadas: `features/` (Ciclo de vida, Setup, Casos Negativos)
- Escenarios ejecutados: 11 en total (incluyendo Scenario Outlines y pruebas negativas)
- Escenarios exitosos: 11
- Escenarios fallidos: 0
- Ejecución en paralelo: 5 hilos
- Generación de reporte: Unificado a través de la carpeta raíz de features.

## Hallazgos Principales

### 1. El patrón de setup reutilizable funcionó correctamente

El feature `create-pet.feature` se invocó como setup independiente desde los escenarios que requieren una mascota previa. Esto permitió:

- Crear datos dinámicos por escenario.
- Evitar IDs hardcodeados.
- Mantener aislamiento entre pruebas.
- Soportar ejecución paralela sin depender del orden de los escenarios.

### 2. Implementación de Parametrización y Principio DRY

Se uso `Scenario Outline` y la tabla `Examples`. Esto permitió probar múltiples flujos de estado (`available`, `pending`, `sold`) sin duplicar líneas de código, fortaleciendo el Principio DRY (Don't Repeat Yourself).

### 3. Segregación de Datos (Principio de Responsabilidad Única)

Se creo `create-pet-request.json` y `update-pet-request.json` para separar claramente las responsabilidades y payloads de creación vs actualización, previniendo acoplamiento.

### 4. Pruebas Negativas y Resiliencia (Retry Mechanism)

Se incorporó un documento explícito (`pet-negative.feature`) para comprobar cómo el sistema maneja la corrupción de datos y peticiones a recursos que no existen (404, 400 y 500). 
Además, al descubrir que el endpoint principal de Swagger arroja errores `HTTP 500` aleatorios por sobrecarga (flakiness), implementamos un mecanismo iterativo de reintentos (`configure retry` / `retry until`) que blindó las pruebas `@search` y eliminó los falsos negativos.

### 5. Reporte Unificado y Flexible

Al concentrar la ejecución en el `PetLifecycleRunner` apuntando al classpath base (`classpath:features`), se pudo consolidar todos los features en un solo `karate-summary.html`. Esto evita que las ejecuciones individuales se sobrescriban, pero mantiene la opción de filtrar ejecuciones en la terminal mediante `--tags`.

## Evidencia de la Última Ejecución

Resumen observado en el reporte de Karate:

- `scenariosPassed = 11`
- `scenariosfailed = 0`
- `featuresPassed = 3`
- `threads = 5`

## Conclusiones

La implementación final demuestra un entorno de pruebas robusto, con datos dinámicos, aislamiento entre escenarios, compatibilidad con ejecución paralela, manejo inteligente de tiempos de respuesta inestables (reintentos) y buena trazabilidad en un reporte unificado.

### Conclusión de calidad

La inestabilidad detectada en la suite correspondía estrictamente al colapso del backend público (Swagger) frente a listas saturadas o payloads con identificadores numéricos extremadamente largos. Parametrizar tipos estrictos (ej. `invalidId = '0'`) y usar aserciones lógicas con JavaScript (`* assert`) solucionaron estos topes sintácticos.

### Conclusión práctica

El diseño actual es una base sólida, modular y escalable. Añadir nuevas validaciones o modelos de datos ahora requiere mínimo esfuerzo gracias a la arquitectura por responsabilidades (SOLID) y las tablas variables (Scenario Outline/Examples).

## Recomendaciones

1. **Mantener la granularidad**: Seguir creando JSONs focalizados por endpoint en lugar de tener "mega-archivos" de datos.
2. **Manejar Flakiness**: Mantener el uso de `retry until` estrictamente en endpoints conocidos por su sobrecarga temporal, pero no usarlo por defecto en mutaciones (POST/PUT) para evitar falsos positivos o doble inserción.
3. **Migración futura a ambiente controlado**: Si se implementa un clon del backend local, se podría prescindir del mecanismo de reintentos ya que no habría congestión de terceros afectando los `GET`.