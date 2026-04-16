# Karate PetStore Testing

Suite de pruebas automatizadas de API usando **Karate DSL** sobre **Maven**, que cubre el ciclo de vida de mascotas en la API pública de [PetStore Swagger](https://petstore.swagger.io/v2).

---

## Estructura del Proyecto

```text
src/test/java/
├── karate-config.js                        # URL base y configuración global
├── data/
│   ├── create-pet-request.json             # Payload para creación de mascota
│   └── update-pet-request.json             # Payload para actualización de mascota
├── features/
│   ├── setup/
│   │   └── create-pet.feature              # Setup reutilizable: crea un pet único
│   ├── pet/
│   │   ├── pet-lifecycle.feature           # Escenarios del ciclo de vida y búqueda de mascotas
│   │   └── pet-negative.feature            # Funcionalidades negativas (404, 400/500, etc.)
│   └── PetLifecycleRunner.java             # Runner JUnit5 con suites separadas
```


---

## Requisitos

- Java 17+
- Maven 3.9+
- Acceso a `https://petstore.swagger.io/v2`

---

## Ejecución

```bash
# Ejecutar TODO el entorno de pruebas (Reporte consolidado)
mvn test

# Ejecutar solo escenarios Smoke (Filtro nativo de Karate)
mvn test -Dkarate.options="--tags @smoke"

# Ejecutar el ciclo de vida de mascotas por estados específicos
mvn test -Dkarate.options="--tags @lifecycle"

# Ejecutar validaciones negativas
mvn test -Dkarate.options="--tags @negative"
```

---

## Patrón: Reusable Feature Setup

Cada escenario en `pet-lifecycle.feature` invoca `create-pet.feature` como su propio setup:

```gherkin
* def created = call read('classpath:features/setup/create-pet.feature')
* def petId   = created.petId
```

**Por qué este patrón:**

| Problema sin el patrón | Solución aplicada |
|---|---|
| IDs hardcodeados se rompen si la API cambia | `petId` siempre viene de la respuesta real del POST |
| Escenarios dependientes entre sí se rompen en paralelo | Cada escenario crea su propio pet, sin estado compartido |
| Un fallo en el setup rompe todos los tests | Cada escenario falla de forma independiente |

---

## Por qué `randomId` en lugar de `id: 0`

```gherkin
* def randomId = Math.floor(Math.random() * 2000000000) + 1000000
```

El Petstore asigna `9223372036854775807` (Long.MAX_VALUE) cuando el request lleva `"id": 0`. Ese ID fijo es compartido por todos los clientes del mundo que mandan `id: 0`. Con `parallel(5)`, el escenario `@update` podía cambiar ese pet a `sold` antes de que `@smoke` hiciera su GET, provocando fallos intermitentes.

Con un `randomId` entre 1,000,000 y 2,000,000,000 cada test opera sobre un pet completamente independiente.

---

## Por qué los `print`

Los `* print` hacen visibles los valores clave directamente en el reporte HTML sin necesidad de expandir cada step:

```gherkin
* print '>>> [create-pet] POST /pet RESPONSE → petId:', petId, '| petName:', petName, '| status:', response.status
```

En cada ejecución aparecen como líneas en el reporte:

```
[print] >>> [create-pet] POST /pet RESPONSE → petId: 1869154502 | petName: pet-fc4ede27 | status: available
[print] >>> [smoke]  GET /pet/1869154502 RESPONSE → id: 1869154502 | name: pet-fc4ede27 | status: available
[print] >>> [update] PUT /pet RESPONSE → id: 1390252597 | name: pet-1f11d868 | status: sold
[print] >>> [search] GET /findByStatus?status=sold → total registros: 188
```

Esto permite confirmar de un vistazo que el pet se creó, que el ID es correcto y que los valores son los esperados, sin abrir el JSON completo del response.

---

## Escenarios

### @smoke — Obtener mascota por ID

1. `create-pet.feature` hace `POST /pet` con nombre único y `randomId`
2. La API responde con el pet creado → se extrae `petId`
3. `GET /pet/{petId}` → valida estructura y que `id` coincide

### @update y @search (Scenario Outline) — Ciclo interactivo parametrizado

Utilizamos tablas de ejemplos (Examples) para validar que el ciclo de vida cubre los diferentes escenarios base de manera iterativa y sin repetir código (Principio DRY):

1. **`@update`:** Se crean y actualizan mascotas con el estado (`available`, `pending` y `sold`), validando la recepción satisfactoria de la data.
2. **`@search`:** Validamos en el sistema que el conteo en `GET /pet/findByStatus` devuelve la estructura esperada (`match each`) y que los resultados son mayores a 0 con el assert length correspondientes a su estado.

### @negative — Casos de prueba negativos (pet-negative.feature)

1. `GET /pet/{invalid_id}` y valida correctamente que sea un `404 Not Found`.
2. `PUT /pet` simulando campos inválidos que el backend repela con un error `400` o `500`.
3. `GET /pet/findByStatus?status={invalid_status}` simulando búsquedas corruptas comprobando respuesta `400` o listas `[]`.

---

## Validaciones con `match`

Se usa `match` en lugar de `assert` porque genera mensajes de error estructurados que muestran el JSON real vs el esperado:

```gherkin
And match response ==
  """
  {
    "id":     "#number",
    "name":   "#string",
    "status": "#string"
  }
  """
```

Los `##` (doble almohadilla) indican campo opcional — usado para campos que el Petstore público no garantiza en registros legacy:

```gherkin
"name":      "##string"   ← puede estar ausente
"photoUrls": "##[]"       ← puede estar ausente
```

---

## Reporte HTML

```bash
open target/karate-reports/karate-summary.html
```

En el reporte se puede:
- Ver cada step en verde/rojo
- Hacer clic en `When method post/get/put` para expandir el request y response completos
- Leer los `print` directamente sin expandir nada

---

## Configuración

**`karate-config.js`** — define `apiUrl` disponible en todos los features:

```javascript
var config = {
  apiUrl: 'https://petstore.swagger.io/v2'
}
```

**`create-pet-request.json` y `update-pet-request.json`** — datos base granularizados y segregados para cumplir el Principio de Responsabilidad Única.

```json
{
  "photoUrls": ["https://example.com/photo1.jpg"],
  "category": { "id": 1, "name": "Dogs" },
  "tags": [{ "id": 1, "name": "friendly" }],
  "status": "available"
}
```

---

## CI/CD

```bash
mvn clean test -B
```

Runner seguro utilizando las etiquetas y `@tag` separados previniendo acoplamientos y controlando los threads (parallel).


