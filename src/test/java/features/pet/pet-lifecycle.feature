Feature: Ciclo de vida completo de mascota – PetStore

  Background:
    * url apiUrl
    * def updateData = read('classpath:data/update-pet-request.json')

  @smoke @lifecycle
  Scenario: Obtener mascota recién creada por ID

    * def created = call read('classpath:features/setup/create-pet.feature')
    * def petId   = created.petId
    * print '>>> [smoke] petId a consultar:', petId

    Given path 'pet', petId
    When method get
    Then status 200
    * print '>>> [smoke] GET /pet/' + petId + ' RESPONSE → id:', response.id, '| name:', response.name, '| status:', response.status

    And match response ==
      """
      {
        "id":        "#number",
        "name":      "#string",
        "status":    "#string",
        "photoUrls": "#[]",
        "category":  "##object",
        "tags":      "##[]"
      }
      """
    And match response.id     == petId
    And match response.status == '#string'

  @update @lifecycle
  Scenario Outline: Actualizar estado de mascota a "<targetStatus>"

    * def created = call read('classpath:features/setup/create-pet.feature')
    * def petId   = created.petId
    * def petName = created.petName
    * print '>>> [update] petId a actualizar:', petId, '| petName:', petName, '| targetStatus:', '<targetStatus>'

    * def updateRequest =
      """
      {
        "id":        #(petId),
        "name":      "#(petName)",
        "photoUrls": #(updateData.photoUrls),
        "category":  #(updateData.category),
        "tags":      #(updateData.tags),
        "status":    "<targetStatus>"
      }
      """

    Given path 'pet'
    And request updateRequest
    When method put
    Then status 200

    And match response.id     == petId
    And match response.name   == petName
    And match response.status == '<targetStatus>'
    * print '>>> [update] PUT /pet RESPONSE → id:', response.id, '| name:', response.name, '| status:', response.status

    Examples:
      | targetStatus |
      | available    |
      | pending      |
      | sold         |

  @search @lifecycle
  Scenario Outline: Buscar mascotas por status "<searchStatus>"

    Given path 'pet', 'findByStatus'
    And param status = '<searchStatus>'
    When method get
    Then status 200
    * print '>>> [search] GET /findByStatus?status=' + '<searchStatus>' + ' → total registros:', response.length
    
    # Validamos que el conteo sea mayor a 0
    * assert response.length > 0

    And match each response ==
      """
      {
        "id":        "#number",
        "name":      "##string",
        "status":    "<searchStatus>",
        "photoUrls": "##[]",
        "category":  "##object",
        "tags":      "##[]"
      }
      """

    Examples:
      | searchStatus |
      | pending      |
      | sold         |
