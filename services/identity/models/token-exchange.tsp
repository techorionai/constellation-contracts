namespace Constellation.Identity;

/** Type of a token in a token exchange request. The union is open. */
@friendlyName("TokenType")
union TokenType {
  "urn:ietf:params:oauth:token-type:access_token",
  "urn:constellation:params:oauth:token-type:agent-id",
  string,
}
