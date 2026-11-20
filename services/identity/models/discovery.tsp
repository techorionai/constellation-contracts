namespace Constellation.Identity;

/** The OIDC discovery document. The model is open, so the service can add fields later. */
@friendlyName("DiscoveryDocument")
model DiscoveryDocument {
  /** Issuer URL. */
  issuer: url;

  /** URL of the authorize endpoint. */
  authorization_endpoint: url;

  /** URL of the token endpoint. */
  token_endpoint: url;

  /** URL of the key set. */
  jwks_uri: url;

  /** URL of the userinfo endpoint. */
  userinfo_endpoint: url;

  /** URL of the revoke endpoint. */
  revocation_endpoint: url;

  /** URL of the end session endpoint. */
  end_session_endpoint: url;

  /** Supported response types. */
  response_types_supported: string[];

  /** Supported grant types. */
  grant_types_supported: string[];

  /** Supported subject types. */
  subject_types_supported: string[];

  /** Supported algorithms of the ID token signature. */
  id_token_signing_alg_values_supported: string[];

  /** Supported scopes. */
  scopes_supported: string[];

  /** Supported methods of client authentication. */
  token_endpoint_auth_methods_supported: string[];

  /** Supported algorithms of the client assertion signature. */
  token_endpoint_auth_signing_alg_values_supported: string[];

  /** Supported PKCE methods. */
  code_challenge_methods_supported: string[];

  ...Record<unknown>;
}

/** Claims of the userinfo endpoint. */
@friendlyName("UserInfo")
model UserInfo {
  ...NoStoreHeaders;

  /** ID of the user. */
  `sub`: string;

  /** Email address of the user. */
  email?: string;

  /** True if the email address is verified. */
  email_verified?: boolean;

  /** Display name of the user. */
  name?: string;
}
