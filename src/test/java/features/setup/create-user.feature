Feature: Setup – Crear usuario reutilizable

  Background:
    * url apiUrl

  Scenario: Registrar usuario único y exponer username y password al llamador
    * def signupData = read('classpath:data/signup-request.json')
    * def uid        = java.util.UUID.randomUUID() + ''
    * def username   = 'user-' + uid.substring(0, 8)
    * def password   = signupData.password
    * print '>>> [create-user] username generado:', username, '| password:', password

    * def signupRequest =
      """
      {
        "username": "#(username)",
        "password": "#(password)"
      }
      """

    Given path 'signup'
    And request signupRequest
    When method post
    Then status 200

    * print '>>> [create-user] POST /signup ENTRADA → username:', username, '| password:', password
    * print '>>> [create-user] POST /signup SALIDA  → response:', response

    # Demoblaze responde con el string JSON '""' en alta exitosa (sin errorMessage)
    * assert !response.contains('errorMessage')

    * def createdUsername = username
    * def createdPassword = password
