function fn() {
  var env = karate.env; 
  if (!env) {
    env = 'dev';
  }
  
  karate.env = {
    name: env,
    now: function() {
      return Date.now();
    }
  };
  
  var config = {
    env: env,
    apiUrl: 'https://api.demoblaze.com'
  }
  return config;
}