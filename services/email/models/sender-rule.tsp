using Http;
using Constellation.Common;

namespace Constellation.Email;

/** Kind of a sender rule. */
@friendlyName("SenderRuleKind")
union SenderRuleKind {
  "domain",
  "address",
}

/**
 * The domain or the address of a sender rule. The service changes the value to lower case before it checks and stores it.
 * A rule of the kind `domain` has a domain with no `@`, for example `example.com`.
 * A rule of the kind `address` has a full address, for example `noreply@example.com`.
 * The service gives 422 `validation_failed` when the value does not agree with the kind.
 */
@friendlyName("SenderRuleValue")
@minLength(3)
@maxLength(254)
@pattern("^([A-Za-z0-9._%+-]+@)?[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)+$")
scalar SenderRuleValue extends string;

/** A rule that lets an app send from a domain or from an address. */
@friendlyName("SenderRule")
model SenderRule {
  /** ID of the rule. */
  id: ResourceId;

  /** Key of the app that the rule applies to. */
  app: AppKey;

  /** Kind of the rule. */
  kind: SenderRuleKind;

  /** The domain or the address. */
  value: SenderRuleValue;

  /** Time when the rule was created. */
  createdAt: utcDateTime;
}

/** Request to create a sender rule. */
@friendlyName("SenderRuleCreate")
model SenderRuleCreate {
  /** Key of the app that the rule applies to. */
  app: AppKey;

  /** Kind of the rule. */
  kind: SenderRuleKind;

  /** The domain or the address. */
  value: SenderRuleValue;
}

/** Filter of the list of sender rules. */
@friendlyName("SenderRuleFilters")
model SenderRuleFilters {
  /** Show only the rules of this app. */
  @query app?: AppKey;
}

/** One page of sender rules. */
model SenderRulePage is CursorPage<SenderRule>;
