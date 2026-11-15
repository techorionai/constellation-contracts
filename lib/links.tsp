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

  /** RFC 6570 level 1 template that starts with `{base_url}`, for example `{base_url}/tickets/{id}`. */
  @format("uri-template")
  @pattern("^\\{base_url\\}")
  template: string;

  /** Description of the link. */
  description?: string;
}

/** The link templates of one application. */
@friendlyName("LinkTemplateSet")
model LinkTemplateSet {
  /** Key of the application. */
  app: AppKey;

  /** Value that replaces `{base_url}`. */
  baseUrl: url;

  /** Link templates of the application. */
  templates: LinkTemplate[];
}
