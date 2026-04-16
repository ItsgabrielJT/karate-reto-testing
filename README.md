# Karate PetStore Testing

Suite de pruebas automatizadas de API usando **Karate DSL** sobre **Maven**, que cubre el ciclo de vida de mascotas en la API pública de [PetStore Swagger](https://petstore.swagger.io/v2).

---

## Estructura del Proyecto

```
src/test/java/
├── karate-config.js                        # URL base y configuración global
├── data/
│   └── valid-pet-data.json                 # Datos de prueba reutilizables
├── features/
│   ├── setup/
│   │   └── create-pet.feature              # Setup reutilizable: crea un pet único
│   └── pet/
│       └── pet-lifecycle.feature           # Escenarios del ciclo de vida
│   └── PetLifecycleRunner.java             # Runner JUnit5 con parallel(5)


---

## Requisitos

- Java 17+
- Maven 3.9+
- Acceso a `https://petstore.swagger.io/v2`

---

## Ejecución

```bash
# Todos los tests
mvn test

# Solo el lifecycle
mvn test -Dtest=PetLifecycleRunner

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

### @update — Actualizar estado a "sold"

1. `create-pet.feature` crea un pet propio (distinto al de @smoke)
2. `PUT /pet` con `status: sold`
3. Valida que la respuesta confirma `id`, `name` y `status: sold`

### @search — Buscar mascotas por status

1. `GET /pet/findByStatus?status=sold`
2. `match each response` valida que todos los elementos tengan `status: sold`
3. No requiere setup: el endpoint de búsqueda no muta estado

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
open target/karate-reports/features.pet.pet-lifecycle.html
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

**`valid-pet-data.json`** — datos base y de actualización separados:

```json
{
  "base":   { "photoUrls": [...], "category": {...}, "tags": [...], "status": "available" },
  "update": { "photoUrls": [...], "category": {...}, "tags": [...], "status": "sold" }
}
```

---

## CI/CD

```bash
mvn clean test -B
```

`parallel(5)` en el Runner es seguro porque cada escenario crea su propio pet con UUID + randomId únicos.


