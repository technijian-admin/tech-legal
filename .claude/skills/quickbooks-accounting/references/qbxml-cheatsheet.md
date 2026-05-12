# QuickBooks qbXML Cheatsheet

## Envelope

Use the standard qbXML envelope when sending raw requests:

```xml
<?xml version="1.0" encoding="utf-8"?>
<?qbxml version="16.0"?>
<QBXML>
  <QBXMLMsgsRq onError="stopOnError">
    ...
  </QBXMLMsgsRq>
</QBXML>
```

Notes:

- The `<?qbxml version="16.0"?>` processing instruction comes from the service
  config. Verify the live host version in Phase 9 if it differs.
- `onError="stopOnError"` is the standard request-batch behavior used by the
  service.

## Common request shapes

### Query request

```xml
<?xml version="1.0" encoding="utf-8"?>
<?qbxml version="16.0"?>
<QBXML>
  <QBXMLMsgsRq onError="stopOnError">
    <CustomerQueryRq>
      <MaxReturned>50</MaxReturned>
      <NameFilter>
        <MatchCriterion>Contains</MatchCriterion>
        <Name>Acme</Name>
      </NameFilter>
    </CustomerQueryRq>
  </QBXMLMsgsRq>
</QBXML>
```

### Add request

```xml
<?xml version="1.0" encoding="utf-8"?>
<?qbxml version="16.0"?>
<QBXML>
  <QBXMLMsgsRq onError="stopOnError">
    <CustomerAddRq>
      <CustomerAdd>
        <Name>Example Co</Name>
      </CustomerAdd>
    </CustomerAddRq>
  </QBXMLMsgsRq>
</QBXML>
```

### Mod request

`*ModRq` requires a fresh `EditSequence` from a current read:

```xml
<?xml version="1.0" encoding="utf-8"?>
<?qbxml version="16.0"?>
<QBXML>
  <QBXMLMsgsRq onError="stopOnError">
    <CustomerModRq>
      <CustomerMod>
        <ListID>80000001-123456789</ListID>
        <EditSequence>123456789</EditSequence>
        <Name>Example Co Updated</Name>
      </CustomerMod>
    </CustomerModRq>
  </QBXMLMsgsRq>
</QBXML>
```

### Delete / void requests

```xml
<CustomerDelRq>
  <ListID>80000001-123456789</ListID>
</CustomerDelRq>
```

```xml
<TxnVoidRq>
  <TxnVoidType>Invoice</TxnVoidType>
  <TxnID>80000002-123456789</TxnID>
</TxnVoidRq>
```

There is no wrapped Delete/Void op in v1. Use raw qbXML only with explicit
confirmation and only with `AllowWrites=true`.

## Iterators

QuickBooks list-style queries can page via iterators:

- First request: `iterator="Start"`
- Follow-up request: `iterator="Continue"`
- Reuse the returned `iteratorID`
- Stop when `iteratorRemainingCount` reaches `0`

Example:

```xml
<CustomerQueryRq iterator="Start">
  <MaxReturned>100</MaxReturned>
</CustomerQueryRq>
```

```xml
<CustomerQueryRq iterator="Continue" iteratorID="ABC-123">
  <MaxReturned>100</MaxReturned>
</CustomerQueryRq>
```

The service's `list_*` ops already do this under the hood. Use raw iterators
only when no wrapped list op fits.

## Status handling

- `statusCode="0"` means success.
- A zero-row result is still success, not an error.
- `statusSeverity` values include `Info`, `Warn`, and `Error`.
- **A non-zero `statusCode` is a business outcome reported in `result.status` -
  it is not an HTTP error; only transport/auth/op-routing problems are HTTP
  4xx/5xx.**

### `3200` stale `EditSequence`

`3200` means the object changed after you read it and before you tried the
modification. Re-read the object, do a fresh dry-run, and confirm again. Never
auto-retry a `3200`.

## HRESULT-family errors

The service maps the common `0x8004xxxx` QuickBooks COM/HRESULT failures to
friendlier messages in its `QbErrors` map. Use the surfaced `qbErrorCode` from
the API response when troubleshooting those cases.

## Phase-9 re-pin candidates

These shapes are medium-confidence until validated on the live host:

- `IncludeLineItems` element name for invoice detail queries
- Some report column/title casing in report responses
- Some `*QueryRq` child-element names when using raw ad-hoc filters

Verify those against the live host's qbXML reference and the service parser in
Phase 9.
