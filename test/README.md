# Mobile Owner App — Test Map

Offline, owner-only scope. Maps web owner features to automated tests.

## Web owner feature → test file

| Web owner feature | Mobile service | Test file |
|-------------------|----------------|-----------|
| Inventory CRUD | `InventoryService` | `inventory_service_test.dart` |
| Restock / stock-in | `InventoryService.restock` | `inventory_service_test.dart`, `smoke_service_test.dart` |
| Sales + discounts | `SalesService` | `sales_service_test.dart` |
| Delete sale | `SalesService.deleteSale` | `sales_service_test.dart` |
| Receipt PDF | `ReceiptPdfService` | `receipt_pdf_service_test.dart` |
| Orders place/receive/cancel | `OrderService` | `order_service_test.dart`, `smoke_service_test.dart` |
| Supplier debt settle/pay | `SupplierService` | `supplier_service_test.dart` |
| Financial + expenses | `FinancialService` | `financial_service_test.dart` |
| Dashboard + reports | `FinancialService` | `financial_service_test.dart` |
| Activity logs | `ActivityLogService` | `activity_log_service_test.dart` |
| End-to-end owner flows | Multiple | `owner_flows_integration_test.dart` |
| App bootstrap | `databaseInitProvider` | `widget_test.dart` |
| PDF currency | `CurrencyFormatter.formatPdf` | `currency_formatter_test.dart` |

## Intentionally not tested (by design)

- Staff login, staff dashboard, staff settings
- Cloud API / sync
- Multi-user activity log filters (no users on device)
- Category CRUD (seeded read-only on mobile)

## Manual UI checklist (emulator)

- [ ] PIN setup on first launch; seeded inventory visible
- [ ] OwnerShell tabs: Home, Inventory, Sales, Financial, More menu
- [ ] Inventory add/edit/delete, restock → payment settle sheet
- [ ] Sales multi-line + discount → post-sale share sheet
- [ ] Orders place → receive → settle sheet
- [ ] Financial month picker; add/delete expense
- [ ] Reports PDF export
- [ ] Suppliers detail: edit, delete, pay debt
- [ ] Activity logs: search, action filter, date range
- [ ] Settings: shop name updates app bar + receipt

Run all tests: `flutter test`
