Feature: Ciclo de autenticación – Demoblaze

  Background:
    * url apiUrl
    * def signupData = read('classpath:data/signup-request.json')
    * def loginData  = read('classpath:data/login-request.json')

  @signup @auth
  Scenario: Registrar un nuevo usuario en signup

    * def uid      = java.util.UUID.randomUUID() + ''
    * def username = 'user-' + uid.substring(0, 8)
    * def password = signupData.password
    * print '>>> [signup] username generado:', username, '| password:', password

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

    * print '>>> [signup] POST /signup ENTRADA → username:', username, '| password:', password
    * print '>>> [signup] POST /signup SALIDA  → response:', response

    # Demoblaze responde con el string JSON '""' en alta exitosa (sin errorMessage)
    * assert !response.contains('errorMessage')

  @login @auth
  Scenario: Login con usuario y password correcto

    * def created  = call read('classpath:features/setup/create-user.feature')
    * def username = created.createdUsername
    * def password = created.createdPassword
    * print '>>> [login] username a autenticar:', username

    * def loginRequest =
      """
      {
        "username": "#(username)",
        "password": "#(password)"
      }
      """

    Given path 'login'
    And request loginRequest
    When method post
    Then status 200

    * print '>>> [login] POST /login ENTRADA → username:', username, '| password:', password
    * print '>>> [login] POST /login SALIDA  → response:', response

    # Demoblaze responde con el string que contiene el token de autenticación
    * match response == '#string'
    * assert response.contains('Auth_token:')
