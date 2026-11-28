import "@typespec/http";

using Http;
using Constellation.Common;

namespace Constellation.Helpdesk;

/** A customer of the helpdesk. */
@friendlyName("Customer")
model Customer {
  /** ID of the customer. A UUID in lowercase text form. */
  @format("uuid")
  id: string;

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

/** Query filters of the customer list. All are optional. */
@friendlyName("CustomerFilters")
model CustomerFilters {
  /** Return only the customer with this email address. The match is exact and has no case. */
  @query
  @minLength(1)
  @maxLength(254)
  email?: string;
}

/** One page of customers. */
model CustomerPage is CursorPage<Customer>;
