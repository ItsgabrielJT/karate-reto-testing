Feature: Ciclo de vida completo de mascota – PetStore

  Background:
    * url apiUrl
    * def petData = read('classpath:data/valid-pet-data.json')

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
  Scenario: Actualizar estado de mascota a "sold"

    * def created = call read('classpath:features/setup/create-pet.feature')
    * def petId   = created.petId
    * def petName = created.petName
    * print '>>> [update] petId a actualizar:', petId, '| petName:', petName

    * def updateRequest =
      """
      {
        "id":        #(petId),
        "name":      "#(petName)",
        "photoUrls": #(petData.update.photoUrls),
        "category":  #(petData.update.category),
        "tags":      #(petData.update.tags),
        "status":    "sold"
      }
      """

    Given path 'pet'
    And request updateRequest
    When method put
    Then status 200

    And match response.id     == petId
    And match response.name   == petName
    And match response.status == 'sold'
    * print '>>> [update] PUT /pet RESPONSE → id:', response.id, '| name:', response.name, '| status:', response.status

  @search @lifecycle
  Scenario: Buscar mascotas por status "sold"

    Given path 'pet', 'findByStatus'
    And param status = 'sold'
    When method get
    Then status 200
    * print '>>> [search] GET /findByStatus?status=sold → total registros:', response.length

    And match each response ==
      """
      {
        "id":        "#number",
        "name":      "##string",
        "status":    "sold",
        "photoUrls": "##[]",
        "category":  "##object",
        "tags":      "##[]"
      }
      """
