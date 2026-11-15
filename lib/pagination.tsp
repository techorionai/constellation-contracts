import "@typespec/http";

using Http;

namespace Constellation.Common;

/** Query parameters of a list operation with cursor pagination. */
@friendlyName("CursorPageParams")
model CursorPageParams {
  /** Opaque token from `nextPageToken` of the previous page. */
  @query
  @continuationToken
  @maxLength(1024)
  pageToken?: string;

  /** Maximum number of items in the page. */
  @query
  @pageSize
  @minValue(1)
  @maxValue(200)
  pageSize?: int32 = 50;
}

/** One page of a list with cursor pagination. */
model CursorPage<T> {
  /** Items of the page. */
  @pageItems
  items: T[];

  /** Token for the next page. No value means that this is the last page. */
  @continuationToken
  nextPageToken?: string;
}
