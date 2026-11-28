using Http;
using Constellation.Common;

namespace Constellation.Email;

/** Kind of a sender rule. */
@friendlyName("SenderRuleKind")
union SenderRuleKind {
  "domain",
  "address",
}

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
  @minLength(1)
  @maxLength(254)
  value: string;

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
  @minLength(1)
  @maxLength(254)
  value: string;
}

/** Filter of the list of sender rules. */
@friendlyName("SenderRuleFilters")
model SenderRuleFilters {
  /** Show only the rules of this app. */
  @query app?: AppKey;
}

/** One page of sender rules. */
model SenderRulePage is CursorPage<SenderRule>;
