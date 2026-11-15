namespace Constellation.Common;

/** Type of a resource, for example `ticket`. */
@pattern("^[a-z][a-z0-9_]*$")
@maxLength(64)
@friendlyName("ResourceType")
scalar ResourceType extends string;

/** Maps a resource type to a URL template. */
@friendlyName("LinkTemplate")
model LinkTemplate {
  /** Type of the resource. */
  resourceType: ResourceType;

  /**
   * RFC 6570 level 1 path template. It starts with `{base_url}/`. It has no `..`, no `@`, no `?`,
   * no `#`, and no reserved expansion such as `{+id}`. Example: `{base_url}/tickets/{id}`.
   */
  @format("uri-template")
  @pattern("^(?!.*\\.\\.)\\{base_url\\}/[A-Za-z0-9._~/%-]*(\\{[a-z_][a-z0-9_]*\\}[A-Za-z0-9._~/%-]*)*$")
  template: string;

  /** Description of the link. */
  description?: string;
}

/** The link templates of one application. */
@friendlyName("LinkTemplateSet")
model LinkTemplateSet {
  /** Key of the application. */
  app: AppKey;

  /**
   * Value that replaces `{base_url}`. It is `https://` and a host, or `http://localhost` for
   * development, with an optional port. It has no path, no user info, no query, and no fragment.
   */
  @pattern("^(https://[A-Za-z0-9.-]+|http://localhost)(:[0-9]{1,5})?$")
  baseUrl: url;

  /** Link templates of the application. */
  templates: LinkTemplate[];
}
