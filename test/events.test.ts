import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { beforeAll, describe, expect, it } from "vitest";
import {
  compileEntry,
  loadCommon,
  root,
  schemaValidator,
  type Doc,
} from "./helpers.js";

async function examples(name: string): Promise<{
  valid: unknown[];
  invalid: unknown[];
}> {
  return JSON.parse(
    await readFile(join(root, "test", "examples", name), "utf8"),
  );
}

describe("CloudEvents envelope", () => {
  // U10
  it("U10: CloudEvent<TicketCreated> has the attributes of the design", async () => {
    const result = await compileEntry(
      join(root, "test", "fixtures", "events", "main.tsp"),
    );
    expect(result.diagnostics).toEqual([]);
    const schema =
      result.files["Fixture.Events.openapi.yaml"].components.schemas
        .TicketCreatedEvent;
    expect(schema.properties.specversion.enum).toEqual(["1.0"]);
    expect([...schema.required].sort()).toEqual(
      [
        "specversion",
        "id",
        "source",
        "type",
        "time",
        "datacontenttype",
        "data",
        "actor",
        "actortype",
      ].sort(),
    );
    expect(schema.properties.data.allOf).toEqual([{
      $ref: "#/components/schemas/TicketCreated",
    }]);
  });

  describe("example documents", () => {
    let check: (name: string) => (value: unknown) => boolean;
    let common: Doc;

    beforeAll(async () => {
      common = await loadCommon();
      check = schemaValidator(common, "common.openapi");
    });

    // U11
    it("U11: valid events pass and invalid events fail", async () => {
      const validate = check("CloudEventEnvelope");
      const { valid, invalid } = await examples("cloud-event.json");
      expect(valid.length).toBeGreaterThan(0);
      expect(invalid.length).toBeGreaterThan(0);
      for (const value of valid) expect(validate(value)).toBe(true);
      for (const value of invalid) expect(validate(value)).toBe(false);
    });

    // U12
    it("U12: event type pattern", () => {
      const validate = check("EventType");
      for (const value of [
        "helpdesk.ticket.created",
        "email.inbound.received",
        "helpdesk.ticket.status_changed",
        "customer_portal.ticket.created",
      ]) {
        expect(validate(value), value).toBe(true);
      }
      for (const value of [
        "ticket.created",
        "Helpdesk.ticket.created",
        "helpdesk-ticket-created",
        "customer-portal.ticket.created",
      ]) {
        expect(validate(value), value).toBe(false);
      }
    });
  });
});
