Feature: Setup – Crear mascota reutilizable

  Background:
    * url apiUrl

  Scenario: Crear mascota y exponer petId y petName al llamador
    * def petData = read('classpath:data/valid-pet-data.json')
    * def uid     = java.util.UUID.randomUUID() + ''
    * def petName = 'pet-' + uid.substring(0, 8)
    * def randomId = Math.floor(Math.random() * 2000000000) + 1000000
    * print '>>> [create-pet] petName generado:', petName, '| randomId:', randomId

    * def petRequest =
      """
      {
        "id": #(randomId),
        "name": "#(petName)",
        "photoUrls": #(petData.base.photoUrls),
        "category":  #(petData.base.category),
        "tags":      #(petData.base.tags),
        "status":    "available"
      }
      """

    Given path 'pet'
    And request petRequest
    When method post
    Then status 200

    And match response.id     == '#number'
    And match response.name   == petName
    And match response.status == 'available'

    * def petId   = response.id
    * def petName = response.name
    * print '>>> [create-pet] POST /pet RESPONSE → petId:', petId, '| petName:', petName, '| status:', response.status
