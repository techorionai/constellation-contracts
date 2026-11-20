using Constellation.Common;

namespace Constellation.Identity;

/** A sign-in session of a user. */
@friendlyName("Session")
model Session {
  /** ID of the session. */
  id: string;

  /** ID of the user. */
  userId: string;

  /** Time when the session started. */
  createdAt: utcDateTime;

  /** Time of the last use of the session. */
  lastSeenAt: utcDateTime;

  /** Time when the session ends. */
  expiresAt: utcDateTime;

  /** User agent of the browser. */
  userAgent?: string;

  /** IP address of the last request. */
  ipAddress?: string;
}

/** One page of sessions. */
model SessionPage is CursorPage<Session>;
