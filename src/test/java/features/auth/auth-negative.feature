Feature: Escenarios Negativos de Autenticación – Demoblaze

  Background:
    * url apiUrl

  @negative
  Scenario: Intentar registrar un usuario ya existente en signup

    * def created  = call read('classpath:features/setup/create-user.feature')
    * def username = created.createdUsername
    * def password = created.createdPassword
    * print '>>> [negative-signup] Usuario a duplicar:', username

    * def duplicateRequest =
      """
      {
        "username": "#(username)",
        "password": "#(password)"
      }
      """

    Given path 'signup'
    And request duplicateRequest
    When method post
    Then status 200

    * print '>>> [negative-signup] POST /signup ENTRADA → username:', username, '| password:', password
    * print '>>> [negative-signup] POST /signup SALIDA  → response:', response

    * match response == { "errorMessage": "This user already exist." }

  @negative
  Scenario: Login con usuario y password incorrecto

    * def created  = call read('classpath:features/setup/create-user.feature')
    * def username = created.createdUsername
    * def wrongPwd = 'WrongPass_' + java.util.UUID.randomUUID().toString().substring(0, 4)
    * print '>>> [negative-login] username:', username, '| password incorrecto:', wrongPwd

    * def loginRequest =
      """
      {
        "username": "#(username)",
        "password": "#(wrongPwd)"
      }
      """

    Given path 'login'
    And request loginRequest
    When method post
    Then status 200

    * print '>>> [negative-login] POST /login ENTRADA → username:', username, '| password:', wrongPwd
    * print '>>> [negative-login] POST /login SALIDA  → response:', response

    * match response == { "errorMessage": "Wrong password." }
