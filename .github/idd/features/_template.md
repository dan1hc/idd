# Feature: <!-- name -->

> **Status**: `draft` | `in-progress` | `partial` | `complete`

## What

<!-- One sentence: what does this feature do for users? -->

## Acceptance Criteria

<!-- Each criterion should be testable and specific -->

- [ ] <!-- What must be true when this is done? -->
- [ ] <!-- Another criterion -->
- [ ] <!-- Keep criteria atomic and verifiable -->

## Details

<!-- Optional: constraints, edge cases, out-of-scope items -->

### Constraints

- <!-- e.g., "Must work without external API calls" -->

### Out of Scope

- <!-- e.g., "Admin UI for managing X" -->

---

## Dependencies

<!-- What other features, services, or components does this depend on? -->

### Feature Dependencies

- <!-- e.g., "Requires user-auth feature to be complete" -->

### External Dependencies

- <!-- e.g., "Requires Redis for caching" -->
- <!-- e.g., "Needs Stripe API credentials" -->

---

## Technical Considerations

<!-- Optional: performance, security, backward compatibility requirements -->

### Performance

- <!-- e.g., "Must handle 1000 requests/second" -->
- <!-- e.g., "Response time < 200ms p99" -->

### Security

- <!-- e.g., "Must validate all user input" -->
- <!-- e.g., "Requires authentication for all endpoints" -->
- <!-- e.g., "Must not log PII" -->

### Backward Compatibility

- <!-- e.g., "Must maintain v1 API contract" -->
- <!-- e.g., "Database migrations must be reversible" -->

---

## API Contract (if applicable)

<!-- Define endpoints, request/response shapes for API features -->

```
POST /api/v1/resource
Request:  { "field": "value" }
Response: { "data": {...}, "error": null }
```

---

## Glossary

<!-- 
This section is populated by the Scribe agent after implementation.
Do not fill this in manually — it will be overwritten.

Anchor formats:
  - file.py::function        → Symbol-based (function/class)
  - file.py::Class.method    → Method reference
  - file.py::#feature:marker → IDD marker reference
-->

| Location | Type | Description |
|----------|------|-------------|
