using Constellation.Common;

namespace Constellation.Identity;

/** Status of a user. */
@friendlyName("UserStatus")
union UserStatus {
  "invited",
  "active",
  "disabled",
}

/** A user. */
@friendlyName("User")
model User {
  /** ID of the user. */
  id: string;

  /** Email address of the user. */
  email: string;

  /** Display name of the user. */
  name: string;

  /** Status of the user. */
  status: UserStatus;

  /** Time when the user was created. */
  createdAt: utcDateTime;
}

/** Request to create a user. */
@friendlyName("UserCreate")
model UserCreate {
  /** Email address of the user. */
  email: string;

  /** Display name of the user. */
  name: string;
}

/** Request to change a user. A field that is not present does not change. */
@friendlyName("UserUpdate")
model UserUpdate {
  /** Display name of the user. */
  name?: string;

  /** True to disable the user. False to enable the user. */
  disabled?: boolean;
}

/** One page of users. */
model UserPage is CursorPage<User>;
