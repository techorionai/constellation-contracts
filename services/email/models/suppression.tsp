using Http;
using Constellation.Common;

namespace Constellation.Email;

/** Reason of a suppression. */
@friendlyName("SuppressionReason")
union SuppressionReason {
  "bounce",
  "complaint",
  "manual",
}

/** An address that the service does not send to. */
@friendlyName("Suppression")
model Suppression {
  /** ID of the suppression. */
  id: ResourceId;

  /** The suppressed address. */
  address: EmailAddress;

  /** Reason of the suppression. */
  reason: SuppressionReason;

  /** ID of the message that caused the suppression. */
  messageId?: ResourceId;

  /** Time when the suppression was created. */
  createdAt: utcDateTime;
}

/** Request to create a manual suppression. The reason is `manual`. */
@friendlyName("SuppressionCreate")
model SuppressionCreate {
  /** The address to suppress. */
  address: EmailAddress;
}

/**
 * Request to find one suppression by address. The address is in the body and not in the URL,
 * because logs and traces keep a URL.
 */
@friendlyName("SuppressionLookup")
model SuppressionLookup {
  /** The address. The match is exact and has no case. */
  address: EmailAddress;
}

/** Filter of the list of suppressions. */
@friendlyName("SuppressionFilters")
model SuppressionFilters {
  /** Show only suppressions with this reason. */
  @query reason?: SuppressionReason;
}

/** One page of suppressions. */
model SuppressionPage is CursorPage<Suppression>;
