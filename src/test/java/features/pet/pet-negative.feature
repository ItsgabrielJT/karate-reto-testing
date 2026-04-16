Feature: Escenarios Negativos de Mascotas – PetStore

  Background:
    * url apiUrl

  @negative
  Scenario: Obtener mascota inexistente por ID devuelve 404
    * def invalidId = '0'
    
    Given path 'pet', invalidId
    When method get
    Then status 404
    * assert response.type == 'error' || response.type == 'unknown'
    And match response.message == 'Pet not found'

  @negative
  Scenario: Actualizar mascota con payload inválido (PUT) devuelve código de error (400 o 500)
    # The API might return 400 Bad Request, or sometimes 500 when it can't parse unescaped wrong data types.
    # We send an intentionally malformed ID (string text instead of numeric UUID).
    * def invalidRequest = 
      """
      {
        "id": "texto_no_valido_como_numero",
        "name": 12345,
        "status": "sold"
      }
      """
      
    Given path 'pet'
    And request invalidRequest
    When method put
    * assert responseStatus == 400 || responseStatus == 500
    * print '>>> [negative] PUT invalido response status:', responseStatus

  @negative
  Scenario: Buscar mascotas por status inválido en findByStatus
    Given path 'pet', 'findByStatus'
    And param status = 'invalid_status_xyz'
    When method get
    Then status 200
    # Depending on the mocked API it returns 200 with empty array, or 400 Bad Request.
    # Swagger typically returns 200 with an empty list for unmatched values.
    * assert responseStatus == 400 || (responseStatus == 200 && response.length == 0)
    * print '>>> [negative] Buscar con status inválido devuelve:', response
