import "@typespec/http";

using Constellation.Common;

namespace Constellation.Helpdesk;

/** A customer of the helpdesk. */
@friendlyName("Customer")
model Customer {
  /** ID of the customer. A UUID in lowercase text form. */
  id: ResourceId;

  /** Name of the customer. */
  @minLength(1)
  @maxLength(200)
  name: string;

  /** Email address of the customer. It is unique without case. */
  @minLength(1)
  @maxLength(254)
  email: string;

  /** Phone number of the customer. */
  @minLength(1)
  @maxLength(32)
  phone?: string;

  /** Time when the customer was created. */
  createdAt: utcDateTime;

  /** Time when the customer was changed. */
  updatedAt: utcDateTime;
}

/** Request to create a customer. */
@friendlyName("CustomerCreate")
model CustomerCreate {
  /** Name of the customer. */
  @minLength(1)
  @maxLength(200)
  name: string;

  /** Email address of the customer. It is unique without case. */
  @minLength(1)
  @maxLength(254)
  email: string;

  /** Phone number of the customer. */
  @minLength(1)
  @maxLength(32)
  phone?: string;
}

/** Request to change a customer. A field that is not present does not change. The request needs at least one field. */
@friendlyName("CustomerUpdate")
model CustomerUpdate {
  /** Name of the customer. */
  @minLength(1)
  @maxLength(200)
  name?: string;

  /** Email address of the customer. It is unique without case. */
  @minLength(1)
  @maxLength(254)
  email?: string;

  /** Phone number of the customer. */
  @minLength(1)
  @maxLength(32)
  phone?: string;
}

/**
 * Request to find one customer by email address. The address is in the body and not in the URL,
 * because logs and traces keep a URL.
 */
@friendlyName("CustomerLookup")
model CustomerLookup {
  /** Email address of the customer. The match is exact and has no case. */
  @minLength(1)
  @maxLength(254)
  email: string;
}

/** One page of customers. */
model CustomerPage is CursorPage<Customer>;
