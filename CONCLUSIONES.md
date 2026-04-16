# Conclusiones del Ejercicio

## Resultado General

La ejecución más reciente de la suite Pet Lifecycle fue exitosa.

- Feature ejecutada: `features/pet/pet-lifecycle.feature`
- Escenarios ejecutados: 3
- Escenarios exitosos: 3
- Escenarios fallidos: 0
- Tiempo total de la feature: ~2.47 s
- Ejecución en paralelo: 5 hilos

## Hallazgos Principales

### 1. El patrón de setup reutilizable funcionó correctamente

El feature `create-pet.feature` se invocó como setup independiente desde los escenarios que requieren una mascota previa. Esto permitió:

- Crear datos dinámicos por escenario
- Evitar IDs hardcodeados
- Mantener aislamiento entre pruebas
- Soportar ejecución paralela sin depender del orden de los escenarios

En la última ejecución, el setup creó correctamente dos mascotas distintas:

- Mascota usada por el escenario GET: `pet-c7ad2500` con `petId = 111579851`
- Mascota usada por el escenario UPDATE: `pet-6d0126d0` con `petId = 1604170053`

### 2. Los `print` agregados sí aportan valor de depuración

Los `print` permiten ver en el reporte HTML y en consola, sin expandir el request/response completo, los datos clave de trazabilidad:

- nombre generado de la mascota
- `randomId` enviado en el POST
- `petId` devuelto por la API
- `status` retornado por GET y PUT
- total de registros devueltos por la búsqueda por estado

Esto fue útil para comprobar de forma explícita que:

- la mascota realmente se creó
- el `petId` del GET coincide con el del POST
- el escenario UPDATE sí retorna `status = sold`
- la búsqueda por `sold` devuelve una colección consistente

### 3. La validación con `match` está bien orientada para una API pública

El uso de `match` en lugar de `assert` mejora los mensajes de error y hace más clara la comparación entre estructura esperada y respuesta real.

También fue correcto flexibilizar ciertas validaciones estructurales con campos opcionales como `##string` y `##[]`, porque el Petstore público contiene registros legacy o incompletos creados por terceros.

## Evidencia de la Última Ejecución

Resumen observado en el reporte de Karate:

- `scenariosPassed = 3`
- `scenariosfailed = 0`
- `featuresPassed = 1`
- `threads = 5`

Trazas relevantes observadas:

- `POST /pet RESPONSE → petId: 111579851 | petName: pet-c7ad2500 | status: available`
- `GET /pet/111579851 RESPONSE → id: 111579851 | name: pet-c7ad2500 | status: available`
- `POST /pet RESPONSE → petId: 1604170053 | petName: pet-6d0126d0 | status: available`
- `PUT /pet RESPONSE → id: 1604170053 | name: pet-6d0126d0 | status: sold`
- `GET /findByStatus?status=sold → total registros: 188`

## Conclusiones

La implementación final sí cumple el objetivo del ejercicio: demuestra un patrón reusable de setup en Karate DSL, con datos dinámicos, aislamiento entre escenarios, compatibilidad con ejecución paralela y buena trazabilidad en reporte.

### Conclusión de calidad

La principal causa de inestabilidad no estaba en Karate sino en la naturaleza compartida de la API pública y en el uso inicial de `id: 0`. Una vez corregido ese punto, la suite se comportó de forma consistente.

### Conclusión práctica

El diseño actual es una base sólida para seguir creciendo la suite. Permite agregar nuevos escenarios reutilizando el setup existente y mantiene suficiente visibilidad para investigar fallos sin depender exclusivamente de inspeccionar JSONs completos en los reportes.

## Recomendaciones

1. Mantener `create-pet.feature` como único punto de creación de mascotas para evitar duplicación.
2. Conservar los `print` solo si es necesario para depuración, para no saturar el reporte con información redundante.
3. Si en el futuro se migra a un entorno controlado, se puede reducir el nivel de trazas y endurecer algunas validaciones.
4. Si la suite crece, conviene agregar limpieza explícita o usar un entorno aislado para no depender del estado global del Petstore compartido.