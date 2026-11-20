namespace Constellation.Identity;

/**
 * A public EC P-256 key in JWK format (RFC 7517).
 * The model is closed. A private field such as `d`, `p`, `q`, `dp`, `dq`, `qi`, or `k` is not valid.
 */
@friendlyName("JsonWebKey")
model JsonWebKey {
  /** Key type. */
  kty: "EC";

  /** Curve. */
  crv: "P-256";

  /** X coordinate in base64url form. */
  x: string;

  /** Y coordinate in base64url form. */
  y: string;

  /** ID of the key. */
  kid: string;

  /** Use of the key. */
  use?: "sig";

  /** Algorithm of the key. */
  alg?: "ES256";

  ...Record<never>;
}

/** A set of public keys in JWK format. */
@friendlyName("JsonWebKeySet")
model JsonWebKeySet {
  /** The public keys. */
  keys: JsonWebKey[];
}
