public void test3() throws ClientProtocolException, IOException{
    String username = "admin";
      String password = "Harbor12345";

      String token = Base64.getEncoder().encodeToString(rawToken(username, password).getBytes());

      HttpGet request = new HttpGet("http://100.64.0.86/api/users");
      request.setHeader("Authorization", "Basic " + token);

      HttpClient client = HttpClientBuilder.create().build();

      HttpResponse response = client.execute(request);
      int statusCode = response.getStatusLine().getStatusCode();
      HttpEntity entity =response.getEntity();
      System.out.println(statusCode);
      System.out.println(EntityUtils.toString(entity));
  }

  
  

  private String rawToken(String username, String password) {
     return username + ":" + password;
  }
  
