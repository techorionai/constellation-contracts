namespace Constellation.Identity;

/** An invite that lets a user set up a sign-in. */
@friendlyName("Invite")
model Invite {
  /** URL of the invite. It is a secret. The server shows it one time. */
  @secret
  url: string;

  /** Time when the invite ends. */
  expiresAt: utcDateTime;
}

/** Result of the creation of a user. */
@friendlyName("UserCreated")
model UserCreated {
  /** The new user. */
  user: User;

  /** The invite of the new user. */
  invite: Invite;
}
