# 🏠 RentEase – Rental Management System

A fully offline, single-file web application for managing rental properties. No server, no installation — just open the HTML file in a browser.

## Features

### Tenant Management
- Add, edit, and view tenant profiles
- Track house address, contact, Aadhaar details, deposit, rent amount, and rent cycle
- Mark tenants as Active or Inactive

### Monthly Payment Tracking
- Initiate a new month to auto-generate payment entries for all active tenants
- Record water meter readings (previous & current), water bill, maintenance, and rent
- Payment statuses: **Paid**, **Pending**, **Partial**, **Informed**
- Generate and print a **payment receipt PDF** per tenant (includes water reading)

### Expense Management
- Master expense list (building-level recurring expenses by category)
- Per-month expense instances on the dashboard — edits stay month-specific and don't affect the master list
- Track payment date and status (Paid / Pending) for each expense
- Categories: Water Bill, Electricity Bill, Maintenance, Painting, Tanker, Other

### Reports
- **Monthly Report PDF** — payment statuses + expenses summary for a selected month
- **Yearly Report PDF** — annual summary cards (total collected, water bill, expenses, pending) + full payment and expense tables

### Dashboard
- Stat cards: Active Tenants, Paid This Month, Pending/Partial, Total Water Bill, Amount Collected, Total Expenses, Expenses Pending
- Bulk-delete payments and expenses via checkboxes
- Clear Month — removes all payment and expense records for the selected month

### User Authentication
- **First-time setup**: create a username, password, and security question/answer
- **Login**: credentials checked against the stored database
- **Forgot Password**: answer your security question to reset your password

## How It Works

All data is stored in an Excel workbook (`.xlsx`) encoded as Base64 in the browser's `localStorage`. You can export and re-import the database file at any time.

**Sheets in the database:**
| Sheet | Purpose |
|---|---|
| `Tenants` | Tenant profiles |
| `Payments` | Monthly payment records |
| `Expenses` | Master expense list |
| `MonthExpenses` | Per-month expense instances |
| `Users` | Login credentials |

Excel reading/writing is powered by [SheetJS](https://sheetjs.com/) (loaded via CDN — requires internet on first load only).

## Usage

1. Download `rental_management.html`
2. Open it in any modern browser (Chrome recommended)
3. On first launch, complete the one-time account setup
4. Use the **Export DB** button to back up your data as an Excel file
5. Use **Import DB** to restore from a backup

## Requirements

- A modern browser (Chrome, Edge, Firefox)
- Internet connection on first load (to fetch SheetJS from CDN)
- No installation, no backend, no dependencies beyond the single HTML file
