# Conclusiones del Ejercicio

## Resultado General

La ejecución más reciente de la suite Auth Demoblaze fue exitosa:

- Features ejecutadas: `features/` (Ciclo de autenticación, Setup, Casos Negativos)
- Escenarios ejecutados: 5 en total (signup exitoso, login exitoso, signup duplicado, login incorrecto, setup)
- Escenarios exitosos: 5
- Escenarios fallidos: 0
- Ejecución en paralelo: 5 hilos
- Generación de reporte: Unificado a través de la carpeta raíz de features.

## Hallazgos Principales

### 1. El patrón de setup reutilizable funcionó correctamente

El feature `create-user.feature` se invocó como setup independiente desde los escenarios que requieren un usuario pre-existente (login y casos negativos). Esto permitió:

- Crear credenciales dinámicas por escenario.
- Evitar usernames hardcodeados que colisionarían si el usuario ya existe en Demoblaze.
- Mantener aislamiento entre pruebas.
- Soportar ejecución paralela sin depender del orden de los escenarios.

### 2. Implementación de Parametrización y Principio DRY

El patrón de generación de `username` único con UUID se reutilizó de forma consistente tanto en el setup como en el escenario de signup, sin duplicar la lógica de construcción del request. Los cuatro casos de prueba quedaron organizados en dos features (`auth-lifecycle.feature` y `auth-negative.feature`) con responsabilidades claramente separadas, siguiendo el Principio DRY (Don't Repeat Yourself).

### 3. Segregación de Datos (Principio de Responsabilidad Única)

Se creó `signup-request.json` y `login-request.json` para separar claramente las responsabilidades y payloads de registro vs inicio de sesión, previniendo acoplamiento. El `username` permanece siempre dinámico en las features para garantizar aislamiento por escenario.

### 4. Pruebas Negativas y Comportamiento Uniforme del Backend

Se incorporó un feature explícito (`auth-negative.feature`) para comprobar cómo el sistema maneja el intento de registro duplicado y las credenciales incorrectas.
Un hallazgo clave fue que **Demoblaze retorna siempre HTTP 200**, incluso en casos de error. La distinción entre éxito y fallo se determina exclusivamente por el cuerpo de la respuesta: la ausencia de `errorMessage` indica éxito, mientras que su presencia con valores como `"This user already exist."` o `"Wrong password."` indica fallo. Esto requirió aserciones basadas en el contenido del body en lugar del status code, haciendo innecesario el mecanismo de reintentos (`configure retry`).

### 5. Reporte Unificado y Flexible

Al concentrar la ejecución en el `AuthRunner` apuntando al classpath base (`classpath:features`), se pudo consolidar todos los features en un solo `karate-summary.html`. Esto evita que las ejecuciones individuales se sobrescriban, pero mantiene la opción de filtrar ejecuciones en la terminal mediante `--tags @signup`, `--tags @login`, `--tags @auth` o `--tags @negative`.

## Evidencia de la Última Ejecución

Resumen observado en el reporte de Karate:

- `scenariosPassed = 5`
- `scenariosfailed = 0`
- `featuresPassed = 3`
- `threads = 5`

## Conclusiones

La implementación final demuestra un entorno de pruebas robusto, con credenciales dinámicas, aislamiento entre escenarios, compatibilidad con ejecución paralela y buena trazabilidad de entradas y salidas en un reporte unificado.

### Conclusión de calidad

El comportamiento uniforme detectado en Demoblaze —retornar siempre HTTP 200 independientemente del resultado— es una particularidad del backend público que requirió adaptar las aserciones al contenido del body en lugar del status code. Las aserciones `response.contains('errorMessage')`, `response.contains('Auth_token:')` y las coincidencias exactas con `match response == { "errorMessage": "..." }` resultaron suficientes para validar cada caso con precisión sin generar falsos positivos.

### Conclusión práctica

El diseño actual es una base sólida, modular y escalable. Añadir nuevas validaciones de autenticación ahora requiere mínimo esfuerzo gracias a la arquitectura por responsabilidades (SOLID), el setup desacoplado de creación de usuario y la separación clara entre flujos positivos y negativos.

## Recomendaciones

1. **Mantener la granularidad**: Seguir creando JSONs focalizados por endpoint en lugar de tener "mega-archivos" de datos.
2. **No usar `retry until` en autenticación**: Los endpoints de Demoblaze son estables para signup y login; el mecanismo de reintentos no es necesario aquí y podría generar registros duplicados si se aplica a `POST /signup`.
3. **Migración futura a ambiente controlado**: Si se implementa un backend local o mock, se podría simular respuestas con status codes HTTP diferenciados (201, 409, 401) en lugar del HTTP 200 uniforme actual, eliminando la dependencia en el contenido del body para distinguir éxito de error.